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
use ITEMAN::DynamicPublishing::Cache;

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
        [ 'error_page_404', { Default => ITEMAN::DynamicPublishing::Config->default('error_page_404'), Scope => 'system'} ],
        [ 'error_page_500', { Default => ITEMAN::DynamicPublishing::Config->default('error_page_500'), Scope => 'system'} ],
        ];
    $plugin->settings(MT::PluginSettings->new($settings));
}

sub load_config {
    my $plugin = shift;
    my ($param, $scope) = @_;

    $plugin->SUPER::load_config(@_);

    unless (ITEMAN::DynamicPublishing::Cache->new->load('ITEMAN::DynamicPublishing::Config')) {
        $plugin->_save_idp_config($param);
    }

    $param->{cache_directory} = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY;
}

sub save_config {
    my $plugin = shift;
    my ($param, $scope) = @_;

    unless ($scope eq 'system') {
        return;
    }

    if ($param->{clear_caches} eq 'true') {
        ITEMAN::DynamicPublishing::Cache->new->clear({
            excludes => [ 'ITEMAN::DynamicPublishing::Config' ]
                                                     });
        return;
    }

    if ($param->{directory_index} eq '') {
        return $plugin->error($plugin->translate('Directory Index is required'));
    }

    if ($param->{error_page_404} eq '') {
        return $plugin->error($plugin->translate('The error page for the status code 404 is required'));
    }

    if ($param->{error_page_500} eq '') {
        return $plugin->error($plugin->translate('The error page for the status code 500 is required'));
    }

    $plugin->SUPER::save_config(@_);

    $plugin->_save_idp_config($param);
}

sub reset_config {
    my $plugin = shift;

    $plugin->SUPER::reset_config(@_);

    ITEMAN::DynamicPublishing::Cache->new->remove('ITEMAN::DynamicPublishing::Config');
}

sub _save_idp_config {
    my $plugin = shift;
    my $param = shift;

    my $config = ITEMAN::DynamicPublishing::Config->new;
    $config->directory_index($param->{directory_index});
    $config->error_page_404($param->{error_page_404});
    $config->error_page_500($param->{error_page_500});
    $config->db_dsn($MT::Object::DRIVER->fallback->dsn);
    $config->db_user($MT::Object::DRIVER->fallback->username);
    $config->db_password($MT::Object::DRIVER->fallback->password);

    ITEMAN::DynamicPublishing::Cache->new->save({
        cache_id => 'ITEMAN::DynamicPublishing::Config',
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
