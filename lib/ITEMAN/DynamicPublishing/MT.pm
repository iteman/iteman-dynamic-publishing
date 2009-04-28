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

package ITEMAN::DynamicPublishing::MT;

use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub config {
    my $self = shift;

    $self->{config} = shift if @_;
    $self->{config};
}

sub mt {
    eval 'use MT';

    my $self = shift;

    $self->{mt} = MT->new unless $self->{mt};
    $self->{mt};
}

sub build_template_in_mem {
    my $self = shift;
    my $params = shift;

    my $tmpl = $self->mt->load_tmpl($params->{error_page});
    unless ($tmpl) {
        return $self->mt->load_tmpl($self->config->default('error_page_500')) if $params->{status_code} == 500;
        return;
    }

    require ITEMAN::DynamicPublishing::ServerEnv;

    $tmpl->param('idp_server_signature', $ENV{SERVER_SIGNATURE});
    $tmpl->param('idp_server_admin', $ENV{SERVER_ADMIN});
    $tmpl->param('idp_script_name', ITEMAN::DynamicPublishing::ServerEnv->script_name);

    my $output = $self->mt->build_page_in_mem($tmpl);
    unless ($output) {
        return $self->mt->load_tmpl($self->config->default('error_page_500')) if $params->{status_code} == 500;
        return;
    }

    $output;
}

sub rebuild_from_fileinfo {
    my $self = shift;
    my $fileinfo_id = shift;

    my $fileinfo = $self->mt->model('fileinfo')->lookup($fileinfo_id);
    die "The fileinfo object for the id [ $fileinfo_id ] does not found" unless $fileinfo;

    $self->mt->publisher->rebuild_from_fileinfo($fileinfo)
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
