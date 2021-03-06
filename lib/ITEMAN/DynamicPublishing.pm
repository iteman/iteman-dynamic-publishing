# ITEMAN Dynamic Publishing - A Perl-based dynamic publishing system for Moveble Type
# Copyright (c) 2009-2010 ITEMAN, Inc. All rights reserved.
#
# This file is part of ITEMAN Dynamic Publishing.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package ITEMAN::DynamicPublishing;

use strict;
use warnings;

use ITEMAN::DynamicPublishing::Config;
use ITEMAN::DynamicPublishing::Cache;
use ITEMAN::DynamicPublishing::ServerEnv;
use ITEMAN::DynamicPublishing::File;
use Fcntl qw(:flock);
use Encode;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub publish {
    my $self = shift;

    $self->_initialize();

    if ($self->_is_local_file) {
        $self->_publish_local_file();
        return;
    }

    $self->_publish_mt_contents();
}

sub config {
    my $self = shift;

    $self->{config} = shift if @_;
    $self->{config};
}

sub file {
    my $self = shift;

    $self->{file} = shift if @_;
    $self->{file};
}

sub mt {
    my $self = shift;

    if (!$self->{mt} && !@_) {
        require ITEMAN::DynamicPublishing::MT;

        $self->{mt} = ITEMAN::DynamicPublishing::MT->new($self->config);
    }

    $self->{mt} = shift if @_;
    $self->{mt};
}

sub generate_etag {
    require Digest::MD5;

    my $self = shift;
    my $contents = shift;

    Digest::MD5::md5_hex($self->_encode_string_if_utf8($contents));
}

sub generate_last_modified {
    require HTTP::Date;

    my $self = shift;
    my $file = shift;

    HTTP::Date::time2str(ITEMAN::DynamicPublishing::File->mtime($file));
}

sub _respond_for_success {
    my $self = shift;
    my $params = shift;

    my $last_modified = $self->generate_last_modified($params->{file});
    my $etag = $self->generate_etag($params->{contents});

    unless ($self->_is_modified({
        'Last-Modified' => $last_modified,
        'ETag' => $etag,
                                     })
        ) {
        $self->_respond({
            status_code => 304,
            headers => {
                'Last-Modified' => $last_modified,
                'ETag' => $etag,
            },
                        });
        return;
    }

    $self->_respond({
        status_code => 200,
        content_type => $self->_content_type_by_extension($params->{file}),
        response_body => $params->{contents},
        headers => {
            'Last-Modified' => $last_modified,
            'ETag' => $etag,
        },
                    });
}

sub _respond_for_404 {
    my $self = shift;
    my $error_page = shift || $self->config->{error_page_404};

    if ($error_page =~ m!^https?://!) {
        $self->_redirect($error_page);
        return;
    }

    my $contents;

    eval {
        $contents = ITEMAN::DynamicPublishing::File->get_contents($error_page);
    };
    if ($@) {
        my $error = $@;
        require ITEMAN::DynamicPublishing::File::FileNotFoundException;
        if (UNIVERSAL::isa($error, 'ITEMAN::DynamicPublishing::File::FileNotFoundException')) {
            if ($error_page eq ITEMAN::DynamicPublishing::Config->default('error_page_404')) {
                die "Failed to read the default error page [ " .
                    ITEMAN::DynamicPublishing::Config->default('error_page_404') .
                    ' ] for the "404 Not Found" error. Check the "System Plugin Settings" page for more information.';
            }

            $self->_respond_for_404(ITEMAN::DynamicPublishing::Config->default('error_page_404'));
            return;
        }

        die $error;
    }

    $self->_respond({
        status_code => 404,
        content_type => 'text/html',
        response_body => $contents =~ /<\$?mt.+\$?>/i ? $self->mt->build_template($error_page)
                                                      : $contents
                    });
}

sub _init_config {
    my $self = shift;

    my $config = ITEMAN::DynamicPublishing::Cache->new->load('ITEMAN::DynamicPublishing::Config')
        or die 'Failed to load the configuration object. See the installation guide for more information: http://oss.iteman.jp/wiki/iteman-dynamic-publishing/Installation_and_Configuration_Guide';
    $self->config($config);
}

sub _init_script_name {
    my $self = shift;

    my $script_name = ITEMAN::DynamicPublishing::ServerEnv->script_name;
    $script_name .= $self->config->directory_index if $script_name =~ m!/$!;

    $self->_script_name($script_name);
}

sub _script_name {
    my $self = shift;

    $self->{script_name} = shift if @_;
    $self->{script_name};
}

sub _fileinfo {
    my $self = shift;

    $self->{fileinfo} = shift if @_;
    $self->{fileinfo};
}

sub _redirect {
    require HTTP::Status;

    my $self = shift;
    my $uri = shift;

    print 'Status: ', 302, ' ', HTTP::Status::status_message(302), "\n";
    print 'Location: ', $uri, "\n";
}

sub _respond {
    require HTTP::Status;

    my $self = shift;
    my $params = shift;

    print 'Status: ', $params->{status_code}, ' ', HTTP::Status::status_message($params->{status_code}), "\n";
    print 'Content-Length: ', length($params->{response_body}), "\n" if exists $params->{response_body};
    print 'Content-Type: ', $params->{content_type}, "\n" if exists $params->{content_type};

    foreach (keys %{$params->{headers}}) {
        print $_, ': ', $params->{headers}->{$_}, "\n";
    }

    print "\n";
    print $self->_encode_string_if_utf8($params->{response_body}) if exists $params->{response_body};
}

sub _load_fileinfo {
    my $self = shift;

    my $cache = ITEMAN::DynamicPublishing::Cache->new;
    $cache->cache({
        cache_id => 'fileinfo' . $self->file,
        object_loader => $self->_create_object_loader_for_fileinfo,
                  });
}

sub _create_object_loader_for_fileinfo {
    my $self = shift;

    return sub {
        require DBI;

        DBI->connect_cached(
            $self->config->db_dsn,
            $self->config->db_user,
            $self->config->db_password,
            { RaiseError => 1, PrintError => 0 }
            )
           ->selectrow_hashref(
        '
SELECT
  fileinfo_id,
  fileinfo_entry_id,
  fileinfo_template_id,
  fileinfo_virtual
FROM
  mt_fileinfo
WHERE
  fileinfo_file_path = ?
',
        {}, ($self->file)
            );
    };
}

sub _content_type_by_extension {
    my $self = shift;
    my $file = shift;
 
    my ($file_extension) = $file =~ m/\.([^.]+)$/;
 
    return 'application/octet-stream' unless defined $file_extension;
    return 'text/html' if $file_extension eq 'html';
    return 'text/css' if $file_extension eq 'css';
    return 'text/javascript' if $file_extension eq 'js';
    return 'application/xml' if $file_extension eq 'xml';
}

sub _build {
    my $self = shift;

    while (!$self->_lock_for_rebuild) {}

    my $contents;
    eval {
        unless (-e $self->file) {
            $contents = $self->mt->build($self->_fileinfo->{fileinfo_id});
            return;
        }

        unless ($self->_is_up_to_date) {
            unlink $self->file
                or warn 'Failed to remove ' . $self->file . ' what will be rebuilt';
            $contents = $self->mt->build($self->_fileinfo->{fileinfo_id});
            return;
        }

        $contents = ITEMAN::DynamicPublishing::File->get_contents($self->file);
    };
    if ($@) {
        my $error = $@;
        $self->_unlock_for_rebuild;
        die $error;
    }

    $self->_unlock_for_rebuild;
    $contents;
}

sub _lock_for_rebuild {
    require File::Spec;

    my $self = shift;

    my $lock_file = File::Spec->catfile(
        ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY,
        '.page-rebuild-' . $self->_fileinfo->{fileinfo_id}
        );
    open REBUILD_LOCK_FILE, "> $lock_file"
        or die "The lock for rebuilding a page failed: $!";

    flock REBUILD_LOCK_FILE, LOCK_EX;
}

sub _unlock_for_rebuild {
    flock REBUILD_LOCK_FILE, LOCK_UN;
    close REBUILD_LOCK_FILE;
}

sub _is_up_to_date {
    my $self = shift;

    !ITEMAN::DynamicPublishing::Cache->is_expired($self->file);
}

sub _is_modified {
    require HTTP::Date;
 
    my $self = shift;
    my $params = shift;
 
    !(exists $ENV{HTTP_IF_MODIFIED_SINCE}
      and HTTP::Date::str2time($ENV{HTTP_IF_MODIFIED_SINCE}) >= HTTP::Date::str2time($params->{'Last-Modified'})
      and exists $ENV{HTTP_IF_NONE_MATCH}
      and $ENV{HTTP_IF_NONE_MATCH} eq $params->{'ETag'}
        );
}

sub _dynamically_build {
    my $self = shift;

    $self->mt->build($self->_fileinfo->{fileinfo_id});
}

sub _is_local_file {
    my $self = shift;

    !$self->_fileinfo;
}

sub _is_static {
    my $self = shift;

    !$self->_fileinfo->{fileinfo_virtual};
}

sub _publish_local_file {
    my $self = shift;

    my $contents;

    eval {
        $contents = ITEMAN::DynamicPublishing::File->get_contents($self->file);
    };
    if ($@) {
        my $error = $@;
        require ITEMAN::DynamicPublishing::File::FileNotFoundException;
        if (UNIVERSAL::isa($error, 'ITEMAN::DynamicPublishing::File::FileNotFoundException')) {
            $self->_respond_for_404;
            return;
        }

        die $error;
    }

    $self->_respond_for_success({ file => $self->file, contents => $contents });
    return;
}

sub _publish_mt_contents {
    my $self = shift;

    my $contents;

    eval {
        if ($self->_is_static) {
            $contents = $self->_build;
        } else {
            $contents = $self->_dynamically_build;
        }
    };
    if ($@) {
        my $error = $@;
        require ITEMAN::DynamicPublishing::File::FileNotFoundException;
        if (UNIVERSAL::isa($error, 'ITEMAN::DynamicPublishing::MT::RuntimePublisher::EntryNotReleasedException')
            || UNIVERSAL::isa($error, 'ITEMAN::DynamicPublishing::File::FileNotFoundException')
            ) {
            $self->_respond_for_404;
            return;
        }

        die $error;
    }

    if ($self->_is_static) {
        $self->_respond_for_success({ file => $self->file, contents => $contents });
    } else {
        $self->_respond({
            status_code => 200,
            content_type => $self->_content_type_by_extension($self->file),
            response_body => $contents,
            headers => {
                'Expires' => 'Thu, 19 Nov 1981 08:52:00 GMT',
                'Cache-Control' => 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0',
                'Pragma' => 'no-cache',
            },
                        });
    }
}

sub _initialize {
    my $self = shift;

    $self->_init_config unless $self->config;
    $self->_init_script_name;

    $self->file($ENV{DOCUMENT_ROOT} . $self->_script_name);
    $self->_fileinfo($self->_load_fileinfo);
}

sub _encode_string_if_utf8 {
    my $self = shift;
    my $string = shift;

    utf8::is_utf8($string) ? encode('utf8', $string) : $string;
}

1;

# Local Variables:
# mode: perl
# coding: iso-8859-1
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: nil
# End:
