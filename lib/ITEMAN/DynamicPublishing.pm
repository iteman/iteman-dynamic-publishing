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

package ITEMAN::DynamicPublishing;

use strict;
use warnings;

use ITEMAN::DynamicPublishing::Config;
use HTTP::Status;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub publish {
    my $self = shift;

    $self->_init_config unless $self->config;
    $self->_init_mt unless $self->mt;

    return $self->_error_page(500) unless exists $ENV{IDP_BLOG_ID};
}

sub redirect {
    my $self = shift;
    my $uri = shift;

    print 'Status: ', 302, ' ', status_message(302), "\n";
    print 'Location: ', $uri, "\n";
}

sub respond {
    my $self = shift;
    my $params = shift;

    print 'Status: ', $params->{status_code}, ' ', status_message($params->{status_code}), "\n";
    print 'Content-Length: ', length($params->{response_body}), "\n";
    print 'Content-Type: ', 'text/html', "\n";
    print "\n";
    print $params->{response_body};
}

sub mt {
    my $self = shift;

    $self->{mt} = shift if @_;
    $self->{mt};
}

sub config {
    my $self = shift;

    $self->{config} = shift if @_;
    $self->{config};
}

sub _error_page {
    my $self = shift;
    my $status_code = shift;

    my $error_page = $self->config->{ 'error_page_' . $status_code };
    if ($error_page =~ m!^https?://!) {
        $self->redirect($error_page);
        return;
    }

    $self->respond({
        'status_code' => $status_code,
        'response_body' => $self->mt->build_template_in_mem({
            'error_page' => $error_page,
            'status_code' => $status_code,
                                                            })
                   });
}

sub _init_config {
    require ITEMAN::DynamicPublishing::Cache;

    my $self = shift;

    my $cache = ITEMAN::DynamicPublishing::Cache->new;
    $self->config(
        $cache->load($cache->cache_id('ITEMAN::DynamicPublishing::Config'))
        );
}

sub _init_mt {
    require ITEMAN::DynamicPublishing::MT;

    my $self = shift;

    $self->mt(ITEMAN::DynamicPublishing::MT->new($self->config));
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
