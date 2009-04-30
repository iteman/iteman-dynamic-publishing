# Copyright (c) 2009 ITEMAN, Inc. All rights reserved.
#
# This file is part of ITEMAN Dynamic Publishing.
# 
# ITEMAN Dynamic Publishing is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ITEMAN Dynamic Publishing is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ITEMAN Dynamic Publishing.  If not, see <http://www.gnu.org/licenses/>.

package ITEMAN::DynamicPublishing;

use strict;
use warnings;

use ITEMAN::DynamicPublishing::Config;
use ITEMAN::DynamicPublishing::Cache;
use ITEMAN::DynamicPublishing::ServerEnv;
use ITEMAN::DynamicPublishing::MT;
use Fcntl qw(:flock);

sub new {
    my $class = shift;
    bless {}, $class;
}

sub publish {
    my $self = shift;

    $self->_init_config unless $self->config;
    $self->_init_mt unless $self->mt;

    unless (exists $ENV{IDP_BLOG_ID}) {
        $self->_error_page(500);
        return;
    }

    $self->_blog_id($ENV{IDP_BLOG_ID});
    $self->_init_script_name;

    $self->_fileinfo($self->_load_fileinfo);

    unless ($self->_fileinfo) {
        my $file_path = $ENV{DOCUMENT_ROOT} . $self->_script_name;
        my $content = $self->_render_as_string($file_path);
        unless (defined $content) {
            $self->_error_page(404);
            return;
        }

        $self->_respond_for_success({ file_path => $file_path, content => $content });
        return;
    }

    my $file_path = -f $self->_fileinfo->{fileinfo_file_path} ? $self->_fileinfo->{fileinfo_file_path}
                                                              : $ENV{DOCUMENT_ROOT} . $self->_script_name;
    $self->_rebuild_if_required($file_path);
    my $content = $self->_render_as_string($file_path);
    unless (defined $content) {
        $self->_error_page(404);
        return;
    }

    $self->_respond_for_success({ file_path => $file_path, content => $content });
}

sub config {
    my $self = shift;

    $self->{config} = shift if @_;
    $self->{config};
}

sub mt {
    my $self = shift;

    $self->{mt} = shift if @_;
    $self->{mt};
}

sub _respond_for_success {
    require HTTP::Date;
    require Digest::MD5;

    my $self = shift;
    my $params = shift;

    my $last_modified = HTTP::Date::time2str($self->_mtime($params->{file_path}));
    my $etag = Digest::MD5::md5_hex($params->{content});

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
        content_type => $self->_content_type_by_extension($params->{file_path}),
        response_body => $params->{content},
        headers => {
            'Last-Modified' => $last_modified,
            'ETag' => $etag,
        },
                    });
}

sub _error_page {
    my $self = shift;
    my $status_code = shift;

    my $error_page = $self->config->{ 'error_page_' . $status_code };
    if ($error_page =~ m!^https?://!) {
        $self->_redirect($error_page);
        return;
    }

    $self->_respond({
        status_code => $status_code,
        content_type => 'text/html',
        response_body => $self->mt->build_template_in_mem({
            error_page => $error_page,
            status_code => $status_code,
                                                          }),
                    });
}

sub _init_config {
    my $self = shift;

    $self->config(ITEMAN::DynamicPublishing::Cache->new->load('ITEMAN::DynamicPublishing::Config') or ITEMAN::DynamicPublishing::Config->new);
}

sub _init_mt {
    my $self = shift;

    $self->mt(ITEMAN::DynamicPublishing::MT->new($self->config));
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

sub _blog_id {
    my $self = shift;

    $self->{blog_id} = shift if @_;
    $self->{blog_id};
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
    print $params->{response_body} if exists $params->{response_body};
}

sub _load_fileinfo {
    my $self = shift;

    my $cache = ITEMAN::DynamicPublishing::Cache->new;
    $cache->cache({
        cache_id => 'fileinfo' . $self->_script_name . $self->_blog_id,
        object_loader => sub {
            require DBI;

            my $dbh = DBI->connect_cached(
                $self->config->db_dsn,
                $self->config->db_user,
                $self->config->db_password,
                { RaiseError => 1, PrintError => 0 }
                );
            $dbh->selectrow_hashref(
                '
SELECT
  fileinfo_id,
  fileinfo_entry_id,
  fileinfo_template_id,
  fileinfo_file_path
FROM
  mt_fileinfo
WHERE
  fileinfo_url = ?
  AND fileinfo_blog_id = ?
',
                {},
                ($self->_script_name, $self->_blog_id)
                );
        }
                  });
}

sub _render_as_string {
    my $self = shift;
    my $file_path = shift;

    open CONTENT, "< $file_path" or return;
    my @contents = <CONTENT>;
    close CONTENT;
 
    join('', @contents);
}

sub _content_type_by_extension {
    my $self = shift;
    my $file_path = shift;
 
    my ($file_extension) = $file_path =~ m/\.([^.]+)$/;
 
    return 'application/octet-stream' unless defined $file_extension;
    return 'text/html' if $file_extension eq 'html';
    return 'text/css' if $file_extension eq 'css';
    return 'text/javascript' if $file_extension eq 'js';
    return 'application/xml' if $file_extension eq 'xml';
}

sub _rebuild_if_required {
    my $self = shift;
    my $file_path = shift;

    while (!$self->_lock_for_rebuild) {}

    eval {
        my $mtime = $self->_mtime($file_path);
        unless ($mtime) {
            $self->mt->rebuild_from_fileinfo($self->_fileinfo->{fileinfo_id});
            return;
        }

        unless ($self->_is_up_to_date($mtime)) {
            unlink $file_path or die "Failed to remove $file_path what will be rebuilt";
            $self->mt->rebuild_from_fileinfo($self->_fileinfo->{fileinfo_id});
        }
    }; if ($@) {
        $self->_unlock_for_rebuild;
        die $@;
    }

    $self->_unlock_for_rebuild;
}

sub _lock_for_rebuild {
    require File::Spec;

    my $self = shift;

    my $touch_file = File::Spec->catfile(
        ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY,
        '.page-rebuild-' . $self->_fileinfo->{fileinfo_id}
        );
    open REBUILD_TOUCH_FILE, "> $touch_file"
        or die "The lock for rebuilding a page failed: $!";

    flock REBUILD_TOUCH_FILE, LOCK_EX;
}

sub _unlock_for_rebuild {
    flock REBUILD_TOUCH_FILE, LOCK_UN;
    close REBUILD_TOUCH_FILE;
}

sub _is_up_to_date {
    my $self = shift;
    my $target_file_mtime = shift;

    my $rebuild_touch_file_mtime = $self->_mtime(ITEMAN::DynamicPublishing::Config::REBUILD_TOUCH_FILE)
        or die 'The file [ ' . ITEMAN::DynamicPublishing::Config::REBUILD_TOUCH_FILE . ' ] does not found';
    return $target_file_mtime >= $rebuild_touch_file_mtime;
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

sub _mtime {
    my $self = shift;
    my $file = shift;

    my @status_info = stat $file;
    return unless @status_info;

    $status_info[9];
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
