#!/usr/bin/perl
# ITEMAN Dynamic Publishing - A Perl based dynamic publishing extension for Moveble Type
# Copyright (c) 2009 ITEMAN, Inc. All rights reserved.
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

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
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

use Test::More tests => 44;

my $output_for_success = "<html>
  <head>
  </head>
  <body>
    Hello, world
  </body>
</html>
";
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
        return ITEMAN::DynamicPublishing::MT::RuntimePublisher->new;
              }
        );
    $mt->mock('load_tmpl', sub {
        return MT::Template->new;
              }
        );
    $mt->mock('build_page_in_mem', sub {
        return ITEMAN::DynamicPublishing::File->get_contents(ITEMAN::DynamicPublishing::Config->default('error_page_404'));
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

    my $runtime_publisher = Test::MockObject->new;
    $runtime_publisher->fake_module('ITEMAN::DynamicPublishing::MT::RuntimePublisher');
    $runtime_publisher->fake_new('ITEMAN::DynamicPublishing::MT::RuntimePublisher');
    $runtime_publisher->mock('rebuild_from_fileinfo', sub {
        my $file = File::Spec->catfile($cache_directory, 'index.html');
        create_page($file, $output_for_success);
        ITEMAN::DynamicPublishing::File->get_contents($file);
                             }
        );

    my $template = Test::MockObject->new;
    $template->fake_module('MT::Template');
    $template->fake_new('MT::Template');
    $template->set_true('param');

    require ITEMAN::DynamicPublishing;
}

END {
    ITEMAN::DynamicPublishing::Cache->new->clear;
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
    $publishing->config(ITEMAN::DynamicPublishing::Config->new);
    $publishing->mock('_create_object_loader_for_fileinfo', sub {
        return sub {
            {
                fileinfo_id => 1,
                fileinfo_entry_id => undef,
                fileinfo_template_id => 1,
                fileinfo_virtual => 0,
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

    my $response_body = ITEMAN::DynamicPublishing::File->get_contents($publishing->file);

    is($response_body, $output_for_success);
    is($publishing->file, File::Spec->catfile($cache_directory, 'index.html'));
    ok(-e $publishing->file);
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

    my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
    $publishing->config(ITEMAN::DynamicPublishing::Config->new);
    $publishing->mock('_create_object_loader_for_fileinfo', sub {
        return sub {
            {
                fileinfo_id => 1,
                fileinfo_entry_id => undef,
                fileinfo_template_id => 1,
                fileinfo_virtual => 1,
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

    my $response_body = $output_for_success;

    is($publishing->file, File::Spec->catfile($cache_directory, 'index.html'));
    is(@output, 8);
    is($output[0], 'Status: ' . 200 . ' ' . status_message(200));
    is($output[1], 'Content-Length: ' . length($response_body));
    is($output[2], 'Content-Type: ' . 'text/html');
    is($output[3], 'Cache-Control: ' . 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0');
    is($output[4], 'Pragma: ' . 'no-cache');
    is($output[5], 'Expires: ' . 'Thu, 19 Nov 1981 08:52:00 GMT');
    is($output[6], '');
    is($output[7] . "\n", $response_body);
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    create_page(File::Spec->catfile($cache_directory, 'index.html'), $output_for_success);
    my $object_loader_called = 0;
    my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
    $publishing->config(ITEMAN::DynamicPublishing::Config->new);
    $publishing->mock('_create_object_loader_for_fileinfo', sub {
        return sub {
            $object_loader_called = 1;
            undef;
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
    my $mt_called = 0;
    my $config = ITEMAN::DynamicPublishing::Config->new;
    my $mt = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing::MT->new($config));
    $mt->mock('build_template', sub {
        $mt_called = 1;
        ITEMAN::DynamicPublishing::MT->new($config)->build_template(@_);
                   }
        );
    my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
    $publishing->config($config);
    $publishing->mt($mt);
    $publishing->mock('_create_object_loader_for_fileinfo',
                      sub { return sub { undef } }
                      );

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $publishing->publish;
    $capture->stop;
    my @output = $capture->read;
    chomp @output;

    my $response_body = ITEMAN::DynamicPublishing::File->get_contents(
        File::Spec->catfile($publishing->config->error_page_404)
        );

    is($mt_called, 1);
    is(@output, 5);
    is($output[0], 'Status: ' . 404 . ' ' . status_message(404));
    is($output[1], 'Content-Length: ' . length($response_body));
    is($output[2], 'Content-Type: ' . 'text/html');
    is($output[3], '');
    is($output[4] . "\n", $response_body);
}

{
    my $test = sub {
        my ($content, $expectation) = @_;
        ITEMAN::DynamicPublishing::Cache->new->clear;

        my $error_page = File::Spec->catfile($cache_directory, '404.html');
        create_page($error_page, $content);
        local $ENV{REQUEST_URI} = '/non-existing.html';
        my $mt_called = 0;
        my $config = ITEMAN::DynamicPublishing::Config->new;
        $config->error_page_404($error_page);
        my $mt = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing::MT->new($config));
        $mt->mock('build_template', sub {
            $mt_called = 1;
            ITEMAN::DynamicPublishing::MT->new($config)->build_template(@_);
                  }
            );
        my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
        $publishing->config($config);
        $publishing->mt($mt);
        $publishing->mock('_create_object_loader_for_fileinfo',
                          sub { return sub { undef } }
            );
        $publishing->publish;

        $expectation->($mt_called);
        is($publishing->config->error_page_404, $error_page);
        ok(-e $publishing->config->error_page_404);
    };

    $test->("<html>
  <head>
  </head>
  <body>
    Not Found <mt:var name=\"foo\">
  </body>
</html>
",
            sub {
                my $mt_called = shift;
                is($mt_called, 1);
            }
        );
    $test->("<html>
  <head>
  </head>
  <body>
    Not Found
  </body>
</html>
",
            sub {
                my $mt_called = shift;
                is($mt_called, 0);
            }
        );
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    local $ENV{REQUEST_URI} = '/non-existing.html';
    my $config = ITEMAN::DynamicPublishing::Config->new;
    $config->error_page_404(File::Spec->catfile($cache_directory, 'non-existing-404.html'));
    my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
    $publishing->config($config);
    $publishing->mock('_create_object_loader_for_fileinfo',
                      sub { return sub { undef } }
                      );

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $publishing->publish;
    $capture->stop;
    my @output = $capture->read;
    chomp @output;

    my $response_body = ITEMAN::DynamicPublishing::File->get_contents(
        File::Spec->catfile(ITEMAN::DynamicPublishing::Config->default('error_page_404'))
        );

    is(@output, 5);
    is($output[0], 'Status: ' . 404 . ' ' . status_message(404));
    is($output[1], 'Content-Length: ' . length($response_body));
    is($output[2], 'Content-Type: ' . 'text/html');
    is($output[3], '');
    is($output[4] . "\n", $response_body);
}

{
    ITEMAN::DynamicPublishing::Cache->new->clear;

    no warnings 'redefine';
    *ITEMAN::DynamicPublishing::Config::default = sub { '/non-existing.tmpl' };

    is(ITEMAN::DynamicPublishing::Config->default('error_page_404'),
       '/non-existing.tmpl'
        );

    local $ENV{REQUEST_URI} = '/non-existing.html';
    my $config = ITEMAN::DynamicPublishing::Config->new;
    $config->error_page_404(File::Spec->catfile($cache_directory, 'non-existing-404.html'));
    my $publishing = Test::MockObject::Extends->new(ITEMAN::DynamicPublishing->new);
    $publishing->config($config);
    $publishing->mock('_create_object_loader_for_fileinfo',
                      sub { return sub { undef } }
                      );

    eval {
        $publishing->publish;
        fail('An expected exception has not been raised');
    };
    if ($@) {
        pass();
    }
}

sub create_page {
    my $file = shift;
    my $content = shift;
    my $fh = IO::File->new($file, 'w');
    print $fh $content;
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
