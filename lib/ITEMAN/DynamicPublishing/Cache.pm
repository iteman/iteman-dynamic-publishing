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

sub new {
    my $class = shift;
    bless {}, $class;
}

sub cache {
    require MT::FileMgr;
    require ITEMAN::DynamicPublishing::Config;
    require MT::Serialize;

    my $self = shift;
    my $params = shift;

    my $fmgr = MT::FileMgr->new('Local');

    unless ($fmgr->exists(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY)) {
        $fmgr->mkpath(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY);
        my $object = $params->{object_loader}->();
        return $self->save({
            cache_id => $params->{cache_id},
            data => $object,
                           });
    }

    my $cache_file = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY . '/' . $params->{cache_id};

    unless ($fmgr->exists($cache_file)) {
        my $object = $params->{object_loader}->();
        return $self->save({
            cache_id => $params->{cache_id},
            data => $object,
                           });
    }

    ${ MT::Serialize->new('Storable')->unserialize($fmgr->get_data($cache_file)) };
}

sub cache_id {
    require MT::Util;

    my $self = shift;
    my @sources = @_;

    return MT::Util::perl_sha1_digest_hex(join('', @_));
}

sub clear {
    require ITEMAN::DynamicPublishing::Config;
    require IO::Dir;
    require MT::FileMgr;
    require File::Spec;

    my $self = shift;

    unless (-d ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY) {
        return;
    }

    my $d = IO::Dir->new(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY);
    unless ($d) {
        return;
    }

    my $fmgr = MT::FileMgr->new('Local');
    while (defined($_ = $d->read)) {
        next if $_ eq '.' || $_ eq '..';
        next if /^\./;
        my $cache_file = File::Spec->catfile(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY, $_);
        next unless -f $cache_file;
        $fmgr->delete($cache_file);
    }

    undef $d;
}

sub save {
    require MT::FileMgr;
    require ITEMAN::DynamicPublishing::Config;
    require MT::Serialize;

    my $self = shift;
    my $params = shift;

    my $fmgr = MT::FileMgr->new('Local');

    unless ($fmgr->exists(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY)) {
        $fmgr->mkpath(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY);
    }

    my $cache_file = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY . '/' . $params->{cache_id};
    $fmgr->put_data(
        MT::Serialize->new('Storable')->serialize(\$params->{data}),
        $cache_file
        );

    1;
}

sub load {
    require MT::FileMgr;
    require ITEMAN::DynamicPublishing::Config;
    require MT::Serialize;

    my $self = shift;
    my $cache_id = shift;

    my $fmgr = MT::FileMgr->new('Local');

    return undef unless $fmgr->exists(ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY);

    my $cache_file = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY . '/' . $cache_id;
    return undef unless $fmgr->exists($cache_file);
    my $data = $fmgr->get_data($cache_file);
    return undef unless $data;

    ${ MT::Serialize->new('Storable')->unserialize($data) };
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
