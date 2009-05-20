#!/usr/bin/perl
# ITEMAN Dynamic Publishing - A Perl based dynamic publishing extension for Moveble Type
# Copyright (c) 2009 ITEMAN, Inc. All rights reserved.
#
# This file is part of ITEMAN Dynamic Publishing.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use ITEMAN::DynamicPublishing;
use File::Basename;
use File::Spec;
use IO::Capture::Stdout;
use HTTP::Status;
use Test::MockObject::Extends;
use ITEMAN::DynamicPublishing::Config;
use Test::MockObject;
use HTTP::Date;
use IO::File;
use ITEMAN::DynamicPublishing::File;
use ITEMAN::DynamicPublishing::Cache;

use Test::More tests => 17;

my $cache_directory;
local $ENV{DOCUMENT_ROOT} = $cache_directory;
local $ENV{REQUEST_URI} = '/';

BEGIN {
    $cache_directory =
        File::Spec->catfile($FindBin::Bin, basename($FindBin::Script, '.t'));

    no warnings 'redefine';
    *ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY = sub { $cache_directory };

    my $mt = Test::MockObject->new;
    $mt->fake_module('MT');
    $mt->fake_new('MT');
    $mt->set_true('set_language');
    $mt->mock('model', sub {
        return MT::FileInfo->new;
              }
        );
    $mt->mock('publisher', sub {
        return MT::WeblogPublisher->new;
              }
        );
    $mt->mock('load_tmpl', sub {
        return MT::Template->new;
              }
        );
    $mt->mock('build_page_in_mem', sub {
        return ITEMAN::DynamicPublishing::File->get_content(ITEMAN::DynamicPublishing::Config->default('error_page_404'));
              }
        );
    $mt->set_true('errstr');

    my $fileinfo = Test::MockObject->new;
    $fileinfo->fake_module('MT::FileInfo');
    $fileinfo->fake_new('MT::FileInfo');
    $fileinfo->set_true('lookup');

    my $publisher = Test::MockObject->new;
    $publisher->fake_module('MT::WeblogPublisher');
    $publisher->fake_new('MT::WeblogPublisher');
    $publisher->mock('rebuild_from_fileinfo', sub { create_page(); });

    my $template = Test::MockObject->new;
    $template->fake_module('MT::Template');
    $template->fake_new('MT::Template');
    $template->set_true('param');
}

END {
    ITEMAN::DynamicPublishing::Cache->new->clear;
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    my $publishing = ITEMAN::DynamicPublishing->new;
    $publishing->config(ITEMAN::DynamicPublishing::Config->new());
    $publishing = Test::MockObject::Extends->new($publishing);
    $publishing->mock('_create_object_loader_for_fileinfo', sub {
        return sub {
            {
                fileinfo_id => 1,
                fileinfo_entry_id => undef,
                fileinfo_template_id => 1,
            };
        };
                      }
        );

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $publishing->publish;
    $capture->stop;
    my @output = $capture->read;
    chomp @output;
 
    my $response_body = ITEMAN::DynamicPublishing::File->get_content(
        File::Spec->catfile($publishing->file)
        );

    ok(-e File::Spec->catfile($cache_directory, 'index.html'));
    is(@output, 7);
    is($output[0], 'Status: ' . 200 . ' ' . status_message(200));
    is($output[1], 'Content-Length: ' . length($response_body));
    is($output[2], 'Content-Type: ' . 'text/html');
    is($output[3], 'Last-Modified: ' . $publishing->generate_last_modified($publishing->file));
    is($output[4], 'ETag: ' . $publishing->generate_etag($response_body));
    is($output[5], '');
    is($output[6] . "\n", $response_body);
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    create_page();

    my $object_loader_called = 0;
    my $publishing = ITEMAN::DynamicPublishing->new;
    $publishing->config(ITEMAN::DynamicPublishing::Config->new());
    $publishing = Test::MockObject::Extends->new($publishing);
    $publishing->mock('_create_object_loader_for_fileinfo', sub {
        return sub {
            $object_loader_called = 1;
            undef
        };
                      }
        );

    $publishing->publish;

    is($object_loader_called, 1);

    $object_loader_called = 0;
    $publishing->publish;

    is($object_loader_called, 0);
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    local $ENV{REQUEST_URI} = '/non-existing.html';
    my $publishing = ITEMAN::DynamicPublishing->new;
    $publishing->config(ITEMAN::DynamicPublishing::Config->new());
    $publishing = Test::MockObject::Extends->new($publishing);
    $publishing->mock('_create_object_loader_for_fileinfo',
                      sub { return sub { undef } }
                      );

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $publishing->publish;
    $capture->stop;
    my @output = $capture->read;
    chomp @output;

    my $response_body = ITEMAN::DynamicPublishing::File->get_content(
        File::Spec->catfile($publishing->config->error_page_404)
        );

    is(@output, 5);
    is($output[0], 'Status: ' . 404 . ' ' . status_message(404));
    is($output[1], 'Content-Length: ' . length($response_body));
    is($output[2], 'Content-Type: ' . 'text/html');
    is($output[3], '');
    is($output[4] . "\n", $response_body);
}

sub create_page {
    my $fh = IO::File->new(File::Spec->catfile($cache_directory, 'index.html'), 'w');
    print $fh <<EOF;
<html>
  <head>
  </head>
  <body>
    Hello, world
  </body>
</html>
EOF
    $fh->close;
}

# Local Variables:
# mode: perl
# coding: iso-8859-1
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: nil
# End:
