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

sub new { bless {}, $_[0] }

sub cache {
    require MT::FileMgr;
    require MT::Serialize;

    my $cache = shift;
    my $params = shift;

    my $cache_dir = MT->component('itemandynamicpublishing')
                      ->get_config_value('cache_directory');
    my $fmgr = MT::FileMgr->new('Local');

    unless ($fmgr->exists($cache_dir)) {
        $fmgr->mkpath($cache_dir);
    }

    my $cache_file = $cache_dir . '/' . $params->{cache_id};
    my $object;

    unless ($fmgr->exists($cache_file)) {
        $object = $params->{object_loader}->();
        $fmgr->put_data(MT::Serialize->new('Storable')->serialize(\$object), $cache_file);
    } else {
        $object = ${ MT::Serialize->new('Storable')->unserialize($fmgr->get_data($cache_file)) };
    }

    $object;
}

sub cache_id {
    require MT::Util;

    my $cache = shift;
    my @sources = @_;

    return MT::Util::perl_sha1_digest_hex(join('', @_));
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
