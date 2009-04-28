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

package ITEMAN::DynamicPublishing::ServerEnv;

use strict;
use warnings;

sub script_name {
    my $class = shift;
 
    my $script_name;
    my $position_of_question = index $class->relative_uri, '?';
    $script_name = $position_of_question == -1 ? $class->relative_uri
                                               : substr $class->relative_uri, 0, $position_of_question;
 
    return $script_name unless exists $ENV{PATH_INFO} and length $ENV{PATH_INFO};

    require URI::Escape;
 
    my $position_of_pathinfo = index($script_name, URI::Escape::uri_escape($ENV{PATH_INFO}));
    return substr $script_name, 0, $position_of_pathinfo unless $position_of_pathinfo == -1;

    $script_name;
}
 
sub relative_uri {
    my $class = shift;
 
    if (exists $ENV{REQUEST_URI}) {
        my $request_uri = $ENV{REQUEST_URI};
        $request_uri =~ s!//!/!g;
        return $request_uri;
    }
 
    my $script_name = $ENV{SCRIPT_NAME};
    $script_name =~ s!//!/!g;
 
    my $query_string = $ENV{QUERY_STRING};
    $query_string = "?$query_string" if length $query_string;

    require URI::Escape;
 
    my $path_info = exists $ENV{PATH_INFO} ? $ENV{PATH_INFO} : '';
    $path_info = URI::Escape::uri_escape $path_info if length $path_info;
 
    "$script_name$path_info$query_string";
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
