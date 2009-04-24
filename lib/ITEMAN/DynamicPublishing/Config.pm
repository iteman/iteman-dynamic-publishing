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

package ITEMAN::DynamicPublishing::Config;

use strict;
use warnings;

use File::Spec;
use File::Basename;
use Cwd;

use constant PLUGIN_NAME => 'ITEMAN Dynamic Publishing';
use constant PLUGIN_ID => 'itemandynamicpublishing';
use constant CACHE_DIRECTORY => Cwd::abs_path(File::Spec->catfile(dirname(__FILE__), '..', '..', '..', 'tmp'));

my %features_decl = (
    'directory_index' => 'index.html',
    'error_page_404' => Cwd::abs_path(File::Spec->catfile(dirname(__FILE__), '..', '..', '..', 'tmpl', '404.tmpl')),
    'error_page_500' => Cwd::abs_path(File::Spec->catfile(dirname(__FILE__), '..', '..', '..', 'tmpl', '500.tmpl')),
    );

sub new {
    my $class = shift;
    my %features = %features_decl;
    bless \%features, $class;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    (my $feature = $AUTOLOAD) =~ s/^.*:://;
    die "Use of undefined configuration $feature" unless exists $self->{$feature};
    $self->{$feature} = shift if @_;
    $self->{$feature};
}

sub default {
    my $class = shift;
    my $feature = shift;

    die "Use of undefined configuration $feature" unless exists $features_decl{$feature};
    $features_decl{$feature};
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
