#!/usr/bin/perl
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

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use ITEMAN::DynamicPublishing;
use HTTP::Status;
use Test::MockObject::Extends;
use IO::Capture::Stdout;
use ITEMAN::DynamicPublishing::Config;

use Test::More tests => 6;

{
    my $error_page_500 = '/path/to/500.tmpl';

    my $mock = Test::MockObject->new;
    $mock->mock('build_template_in_mem', sub { $_[1]->{error_page} });

    my $config = ITEMAN::DynamicPublishing::Config->new;
    $config->error_page_500($error_page_500);

    my $publishing = ITEMAN::DynamicPublishing->new;
    $publishing->mt($mock);
    $publishing->config($config);

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $publishing->publish;
    $capture->stop;
    my @output = $capture->read;
    chomp @output;

    is(@output, 5);
    is($output[0], 'Status: ' . 500 . ' ' . status_message(500));
    is($output[1], 'Content-Length: ' . length($error_page_500));
    is($output[2], 'Content-Type: ' . 'text/html');
    is($output[3], '');
    is($output[4], $error_page_500);
}

# Local Variables:
# mode: perl
# coding: iso-8859-1
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: nil
# End:
