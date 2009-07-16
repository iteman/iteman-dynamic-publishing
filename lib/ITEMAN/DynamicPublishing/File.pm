# ITEMAN Dynamic Publishing - A Perl-based dynamic publishing system for Moveble Type
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

package ITEMAN::DynamicPublishing::File;

use strict;
use warnings;

sub mtime {
    my $class = shift;
    my $file = shift;

    my @status_info = stat $file;
    return unless @status_info;

    $status_info[9];
}

sub get_contents {
    my $class = shift;
    my $file = shift;

    open CONTENT, "< $file" or do {
        require ITEMAN::DynamicPublishing::File::FileNotFoundException;
        die ITEMAN::DynamicPublishing::File::FileNotFoundException->new('Failed to open the file [ ' . $file . ' ]');
    };

    my @contents = <CONTENT>;
    close CONTENT;
 
    join('', @contents);
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
