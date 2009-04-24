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
 
    $tmpl->param('idp_server_signature', $ENV{SERVER_SIGNATURE});
    $tmpl->param('idp_server_admin', $ENV{SERVER_ADMIN});
    $tmpl->param('idp_script_name', $self->_script_name());
 
    my $output = $self->mt->build_page_in_mem($tmpl);
    unless ($output) {
        return $self->mt->load_tmpl($self->config->default('error_page_500')) if $params->{status_code} == 500;
        return;
    }

    $output;
}

sub _script_name {
    my $self = shift;
 
    my $script_name;
    my $position_of_question = index($self->_relative_uri, '?');
    unless ($position_of_question == -1) {
        $script_name = substr($self->_relative_uri, 0, $position_of_question);
    } else {
        $script_name = $self->_relative_uri;
    }
 
    unless (exists $ENV{PATH_INFO} and length($ENV{PATH_INFO})) {
        return $script_name;
    }
 
    {
        require MT::Util;
 
        my $position_of_pathinfo = index($script_name, MT::Util::encode_url($ENV{PATH_INFO}));;
        unless ($position_of_pathinfo == -1) {
            return substr($script_name, 0, $position_of_pathinfo);
        }
 
        $script_name;
    }
}
 
sub _relative_uri {
    my $self = shift;
 
    if (exists($ENV{REQUEST_URI})) {
        my $request_uri = $ENV{REQUEST_URI};
        $request_uri =~ s!//!/!g;
        return $request_uri;
    }
 
    my $script_name = $ENV{SCRIPT_NAME};
    $script_name =~ s!//!/!g;
 
    my $query_string = $ENV{QUERY_STRING};
    if (length($query_string)) {
        $query_string = "?$query_string";
    }
 
    my $path_info = exists $ENV{PATH_INFO} ? $ENV{PATH_INFO} : '';
    if (length($path_info)) {
        require MT::Util;
 
        $path_info = MT::Util::encode_url($path_info);
    }
 
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
