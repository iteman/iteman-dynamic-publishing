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

    my $script_name = $app->script_name();
    if ($script_name =~ m!/$!) {
        $script_name .= 'index.html'; # FIXME: an extension point
    }

    my @fileinfos = MT->model('fileinfo')->search(
        { url => $script_name,
          blog_id => $ENV{ITEMAN_DYNAMIC_PUBLISHING_BLOG_ID} },
        { limit => 1 }
        );

    my $file_path;
    if (@fileinfos) {
        my $fileinfo = $fileinfos[0];
        my $object;

        if ($fileinfo->entry_id) {
            $object = MT->model('entry')->lookup($fileinfo->entry_id);
        } else {
            $object = MT->model('template')->lookup($fileinfo->template_id);
        }

        unless (defined($object)) {
            $app->response_code('500');
            return $app->errtrans("Page [ $script_name ] does not found");
        }

        $app->rebuild({ fileinfo => $fileinfo, object => $object });

        if (-f $fileinfo->file_path) {
            $file_path = $fileinfo->file_path;
        } else {
            $file_path = $ENV{DOCUMENT_ROOT} . $script_name;
        }

        unless ($fileinfo->entry_id) {
            $app->response_content_type($app->content_type_by_extension($object->outfile));
        }
    } else {
        $file_path = $ENV{DOCUMENT_ROOT} . $script_name;
        $app->response_content_type($app->content_type_by_extension($file_path));
    }

    my $content;
    eval {
        $content = $app->render_as_string($file_path);
    };

    if ($@) {
        $app->response_content_type('text/html');
        $app->response_code('404');
        return $app->errtrans($@);
    }

    return $content;
}

sub render_as_string {
    use IO::File;

    my $app = shift;
    my $file_path = shift;

    my $fh = IO::File->new($file_path, 'r');
    unless (defined($fh)) {
        die('Page [ ' . $app->script_name() . ' ] does not found');
    }

    my @contents = <$fh>;
    undef($fh);

    return join('', @contents);
}

sub rebuild {
    my $app = shift;
    my $params = shift;

    unless (-f $params->{fileinfo}->file_path) {
        MT->publisher->rebuild_from_fileinfo($params->{fileinfo});
        return;
    }

    use File::stat;
    my $st = stat($params->{fileinfo}->file_path) or return;

    use Time::Piece;
    use Time::Local;
    my $t_file = localtime($st->mtime);
    my ($object_modified_on_year,
        $object_modified_on_month,
        $object_modified_on_day,
        $object_modified_on_hour,
        $object_modified_on_min,
        $object_modified_on_sec) =
            $params->{object}->modified_on =~
            /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/;
    my $t_object = localtime(timelocal($object_modified_on_sec,
                                       $object_modified_on_min,
                                       $object_modified_on_hour,
                                       $object_modified_on_day,
                                       $object_modified_on_month - 1,
                                       $object_modified_on_year));
    if ($t_file < $t_object) {
        MT->publisher->rebuild_from_fileinfo($params->{fileinfo});
        return;
    }
}

sub content_type_by_extension {
    use MIME::Types qw(by_suffix import_mime_types);

    my $app = shift;
    my $file_path = shift;

    my ($mime_type, $encoding) = by_suffix($file_path);

    return $mime_type;
}

sub script_name {
    my $app = shift;

    my $script_name;
    my $relative_uri = $app->relative_uri();
    my $position_of_question = index($relative_uri, '?');
    unless ($position_of_question == -1) {
        $script_name = substr($relative_uri, 0, $position_of_question);
    } else {
        $script_name = $relative_uri;
    }

    my $path_info = $app->path_info();
    unless (length($path_info)) {
        return $script_name;
    }

    use MT::Util qw(encode_url);
    my $position_of_pathinfo = index($script_name, encode_url($path_info));;
    unless ($position_of_pathinfo == -1) {
        return substr($script_name, 0, $position_of_pathinfo);
    }

    return $script_name;
}

sub relative_uri {
    my $app = shift;

    if (exists($ENV{REQUEST_URI})) {
        my $request_uri = $ENV{REQUEST_URI};
        $request_uri =~ s!//!/!g;
        return $request_uri;
    }

    my $script_name = $ENV{MOD_PERL} ? $app->{apache}->uri : $ENV{SCRIPT_NAME};
    $script_name =~ s!//!/!g;

    my $query_string = $app->query_string();
    if (length($query_string)) {
        $query_string = "?$query_string";
    }

    my $path_info = $app->path_info();
    if (length($path_info)) {
        use MT::Util qw(encode_url);
        $path_info = encode_url($path_info);
    }

    return "$script_name$path_info$query_string";
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
