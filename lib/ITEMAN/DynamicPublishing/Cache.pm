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

package ITEMAN::DynamicPublishing::Cache;

use strict;
use warnings;

use ITEMAN::DynamicPublishing::Config;
use Storable qw(lock_retrieve lock_store);
use Digest::MD5 qw(md5_hex);

sub new {
    my $class = shift;
    bless {}, $class;
}

sub cache {
    my $self = shift;
    my $params = shift;

    my $object = $self->load($params->{cache_id});
    return $object if $object;

    my $object = $params->{object_loader}->();
    return $self->save({
        cache_id => $params->{cache_id},
        data => $object,
                       });
}

sub clear {
    require IO::Dir;
    require File::Spec;

    my $self = shift;

    return unless -d ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY;

    my $d = IO::Dir->new(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY);
    return unless $d;

    while (defined($_ = $d->read)) {
        next if $_ eq '.' || $_ eq '..';
        next if /^\./;
        my $cache_file = File::Spec->catfile(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY, $_);
        next unless -f $cache_file;
        unlink $cache_file;
    }

    undef $d;
}

sub save {
    require File::Path;

    my $self = shift;
    my $params = shift;

    unless (-d ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY) {
        File::path::mkpath(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY);
    }

    lock_store \$params->{data}, (ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY . '/' . md5_hex($params->{cache_id}));
}

sub load {
    my $self = shift;
    my $cache_id = shift;

    return undef unless -d ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY;

    my $cache_file = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY . '/' . md5_hex($cache_id);
    return undef unless -r $cache_file;
    ${ lock_retrieve $cache_file };
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
