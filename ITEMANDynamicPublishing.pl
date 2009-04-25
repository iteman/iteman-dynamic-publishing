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

package MT::Plugin::ITEMANDynamicPublishing;

use strict;

use base qw( MT::Plugin );
use ITEMAN::DynamicPublishing::Config;

our $VERSION = '0.1.0';

{
    require MT;

    my $description = 'ITEMAN Dynamic Publishing allows you to create dynamic Web pages with normal publishing workflow. Since ITEMAN Dynamic Publishing is written in Perl, it can be used with any plug-ins.';
    my $author_name = 'ITEMAN, Inc.';
    my $author_link = 'http://iteman.jp/';

    my $plugin = __PACKAGE__->new({
        name => ITEMAN::DynamicPublishing::Config::PLUGIN_NAME,
        id => ITEMAN::DynamicPublishing::Config::PLUGIN_ID,
        key => __PACKAGE__,
        description => "<MT_TRANS phrase=\"$description\">",
        author_name => "<MT_TRANS phrase=\"$author_name\">",,
        author_link => $author_link,
        version => $VERSION,
        system_config_template => 'system.tmpl',
        l10n_class => 'ITEMAN::DynamicPublishing::L10N',
                                  });
    MT->add_plugin($plugin);

    my $settings = [
        [ 'directory_index', { Default => ITEMAN::DynamicPublishing::Config->default('directory_index'), Scope => 'system'} ],
        [ 'cache_directory', { Default => ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY, Scope => 'system'} ],
        [ 'error_page_404', { Default => ITEMAN::DynamicPublishing::Config->default('error_page_404'), Scope => 'system'} ],
        [ 'error_page_500', { Default => ITEMAN::DynamicPublishing::Config->default('error_page_500'), Scope => 'system'} ],
        ];
    $plugin->settings(MT::PluginSettings->new($settings));
}

sub save_config {
    require ITEMAN::DynamicPublishing::Cache;

    my $plugin = shift;
    my ($args, $scope) = @_;

    unless ($scope eq 'system') {
        return;
    }

    if ($args->{clear_caches} eq 'true') {
        return ITEMAN::DynamicPublishing::Cache->new->clear;
    }

    if ($args->{directory_index} eq '') {
        return $plugin->error($plugin->translate('Directory Index is required'));
    }

    if ($args->{error_page_404} eq '') {
        return $plugin->error($plugin->translate('The error page for the status code 404 is required'));
    }

    if ($args->{error_page_500} eq '') {
        return $plugin->error($plugin->translate('The error page for the status code 500 is required'));
    }

    # cache_directory must be the default value
    $args->{cache_directory} = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY;

    $plugin->SUPER::save_config(@_);

    my $config = ITEMAN::DynamicPublishing::Config->new;
    $config->directory_index($args->{directory_index});
    $config->error_page_404($args->{error_page_404});
    $config->error_page_500($args->{error_page_500});

    my $cache = ITEMAN::DynamicPublishing::Cache->new;
    $cache->save({
        cache_id => $cache->cache_id('ITEMAN::DynamicPublishing::Config'),
        data => $config,
                 });
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
