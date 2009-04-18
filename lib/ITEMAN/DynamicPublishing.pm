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

use base qw( MT::App );

sub id { __PACKAGE__ }

sub init {
    my $app = shift;
    $app->SUPER::init(@_) or return;
    $app->add_methods(
        'publish' => \&publish
    );
    $app->{mode} = $app->{default_mode} = 'publish';
    $app;
}

sub publish {
    my $app = shift;

    unless (exists($ENV{ITEMAN_DYNAMIC_PUBLISHING_BLOG_ID})) {
        $app->response_code('500');
        return $app->errtrans('Invalid configuration');
    }

    my $script_name = $app->_script_name;
    if ($script_name =~ m!/$!) {
        $script_name .= 'index.html'; # FIXME: an extension point
    }

    my $fileinfo = $app->_fileinfo($script_name);
    my $file_path;
    if ($fileinfo) {
        my $object = $app->_object($fileinfo);
        unless ($object) {
            $app->response_code('500');
            return $app->errtrans("Page [ $script_name ] does not found");
        }

        $app->_rebuild({ fileinfo => $fileinfo, object => $object });

        if (-f $fileinfo->file_path) {
            $file_path = $fileinfo->file_path;
        } else {
            $file_path = $ENV{DOCUMENT_ROOT} . $script_name;
        }

        unless ($fileinfo->entry_id) {
            $app->response_content_type($app->_content_type_by_extension($object->outfile));
        }
    } else {
        $file_path = $ENV{DOCUMENT_ROOT} . $script_name;
        $app->response_content_type($app->_content_type_by_extension($file_path));
    }

    my $content;
    eval {
        $content = $app->_render_as_string($file_path);
    };

    if ($@) {
        $app->response_content_type('text/html');
        $app->response_code('404');
        return $app->errtrans($@);
    }

    {
        require File::stat;
        require HTTP::Date;
        require Digest::MD5;

        $app->set_header('Last-Modified' => HTTP::Date::time2str(File::stat::stat($file_path)->mtime));
        $app->set_header('ETag' => Digest::MD5::md5_hex($content));

        if (exists($ENV{HTTP_IF_MODIFIED_SINCE})
            and $ENV{HTTP_IF_MODIFIED_SINCE} eq HTTP::Date::time2str(File::stat::stat($file_path)->mtime)
            and exists($ENV{HTTP_IF_NONE_MATCH})
            and $ENV{HTTP_IF_NONE_MATCH} eq Digest::MD5::md5_hex($content)
            ) {
            $app->response_code('304');
            return;
        }

        $content;
    }
}

sub _render_as_string {
    require IO::File;

    my $app = shift;
    my $file_path = shift;

    my $fh = IO::File->new($file_path, 'r');
    unless (defined($fh)) {
        die('Page [ ' . $app->_script_name . ' ] does not found');
    }

    my @contents = <$fh>;
    undef($fh);

    join('', @contents);
}

sub _rebuild {
    require MT;

    my $app = shift;
    my $params = shift;

    unless (-f $params->{fileinfo}->file_path) {
        MT->publisher->rebuild_from_fileinfo($params->{fileinfo});
        return;
    }

    my $st;
    {
        require File::stat;

        $st = File::stat::stat($params->{fileinfo}->file_path);
        unless ($st) {
            MT->publisher->rebuild_from_fileinfo($params->{fileinfo});
            return;
        }
    }

    {
        require Time::Local;

        my ($object_modified_on_year,
            $object_modified_on_month,
            $object_modified_on_day,
            $object_modified_on_hour,
            $object_modified_on_min,
            $object_modified_on_sec) =
                $params->{object}->modified_on =~
                /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
        my $object_mtime = Time::Local::timelocal($object_modified_on_sec,
                                                  $object_modified_on_min,
                                                  $object_modified_on_hour,
                                                  $object_modified_on_day,
                                                  $object_modified_on_month - 1,
                                                  $object_modified_on_year);
        if ($st->mtime < $object_mtime) {
            MT->publisher->rebuild_from_fileinfo($params->{fileinfo});
        }
    }
}

sub _content_type_by_extension {
    require File::Basename;

    my $app = shift;
    my $file_path = shift;

    my ($file_extension) = $file_path =~ m/\.([^.]+)$/;

    return 'application/octet-stream' unless defined($file_extension);
    return 'text/html' if $file_extension eq 'html';
    return 'text/css' if $file_extension eq 'css';
    return 'text/javascript' if $file_extension eq 'js';
    return 'application/xml' if $file_extension eq 'xml';
}

sub _script_name {
    my $app = shift;

    my $script_name;
    my $position_of_question = index($app->_relative_uri, '?');
    unless ($position_of_question == -1) {
        $script_name = substr($app->_relative_uri, 0, $position_of_question);
    } else {
        $script_name = $app->_relative_uri;
    }

    unless (length($app->path_info)) {
        return $script_name;
    }

    {
        require MT::Util;

        my $position_of_pathinfo = index($script_name, MT::Util::encode_url($app->path_info));;
        unless ($position_of_pathinfo == -1) {
            return substr($script_name, 0, $position_of_pathinfo);
        }

        $script_name;
    }
}

sub _relative_uri {
    my $app = shift;

    if (exists($ENV{REQUEST_URI})) {
        my $request_uri = $ENV{REQUEST_URI};
        $request_uri =~ s!//!/!g;
        return $request_uri;
    }

    my $script_name = $ENV{MOD_PERL} ? $app->{apache}->uri : $ENV{SCRIPT_NAME};
    $script_name =~ s!//!/!g;

    my $query_string = $app->query_string;
    if (length($query_string)) {
        $query_string = "?$query_string";
    }

    my $path_info = $app->path_info;
    if (length($path_info)) {
        require MT::Util;

        $path_info = MT::Util::encode_url($path_info);
    }

    "$script_name$path_info$query_string";
}

sub _fileinfo {
    require MT::FileInfo;

    my $app = shift;
    my $script_name = shift;

    $app->_cache($app->_cache_id('fileinfo', $script_name, $ENV{ITEMAN_DYNAMIC_PUBLISHING_BLOG_ID}),
                 sub {
                     require MT;

                     my @fileinfos = MT->model('fileinfo')->search(
                         { url => $script_name,
                           blog_id => $ENV{ITEMAN_DYNAMIC_PUBLISHING_BLOG_ID} },
                         { limit => 1 }
                         );

                     unless (@fileinfos) {
                         return undef;
                     }

                     $fileinfos[0];
                 }
        );
}

sub _object {
    my $app = shift;
    my $fileinfo = shift;

    if ($fileinfo->entry_id) {
        require MT::Entry;

        $app->_cache($app->_cache_id('entry', $fileinfo->entry_id),
                     sub {
                         require MT;
                         MT->model('entry')->lookup($fileinfo->entry_id);
                     }
            );
    } else {
        require MT::Template;

        $app->_cache($app->_cache_id('template', $fileinfo->template_id),
                     sub {
                         require MT;
                         MT->model('template')->lookup($fileinfo->template_id);
                     }
            );
    }
}

sub _cache {
    require MT::FileMgr;
    require MT::Serialize;

    my $app = shift;
    my $cache_id = shift;
    my $object_loader = shift;

    my $cache_dir = '/tmp/iteman-dynamic-publishing'; # FIXME: an extension point
    my $fmgr = MT::FileMgr->new('Local');

    unless ($fmgr->exists($cache_dir)) {
        $fmgr->mkpath($cache_dir);
    }

    my $cache_file = "$cache_dir/$cache_id";
    my $object;

    unless ($fmgr->exists($cache_file)) {
        $object = $object_loader->();
        $fmgr->put_data(MT::Serialize->new('Storable')->serialize(\$object), $cache_file);
    } else {
        $object = ${ MT::Serialize->new('Storable')->unserialize($fmgr->get_data($cache_file)) };
    }

    $object;
}

sub _cache_id {
    require MT::Util;

    my $app = shift;
    my @sources = @_;

    return MT::Util::perl_sha1_digest_hex(join('', @_));
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
