#!/usr/bin/perl
# ITEMAN Dynamic Publishing - A Perl-based dynamic publishing system for Moveble Type
# Copyright (c) 2010 ITEMAN, Inc. All rights reserved.
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
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";
use ITEMAN::DynamicPublishing;

use Test::More tests => 2;

{
    is('ed076287532e86365e841e92bfc50d8c', ITEMAN::DynamicPublishing->new->generate_etag('Hello World!'));
    is('9d735278cfbdb946834416adfb5aaf6c', ITEMAN::DynamicPublishing->new->generate_etag('こんにちは世界'));
}

# Local Variables:
# mode: perl
# coding: utf-8
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: nil
# End:
