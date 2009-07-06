# ITEMAN Dynamic Publishing - A Perl based dynamic publishing extension for Moveble Type
# Copyright (c) 2009 ITEMAN, Inc. All rights reserved.
#
# This file is part of ITEMAN Dynamic Publishing.
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package MT::Plugin::ITEMANDynamicPublishing;

use strict;
use warnings;

use base qw(MT::Plugin);
use ITEMAN::DynamicPublishing::Config;
use ITEMAN::DynamicPublishing::Cache;
use Cwd;

our $VERSION = '0.2.0';

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
        callbacks => {
            'cms_post_save' => \&update_touch_file,
            'cms_post_delete' => \&update_touch_file,
        },
                                  });
    MT->add_plugin($plugin);

    my $settings = [
        [ 'directory_index', { Default => ITEMAN::DynamicPublishing::Config->default('directory_index'), Scope => 'system'} ],
        [ 'error_page_404', { Default => ITEMAN::DynamicPublishing::Config->default('error_page_404'), Scope => 'system'} ],
        ];
    $plugin->settings(MT::PluginSettings->new($settings));

}

sub update_touch_file {
    require File::Spec;
    require File::Path;

    my $app = MT->instance;
    my @unnecessary_files = (
        File::Spec->catfile($app->blog->site_path, '.htaccess'),
        File::Spec->catfile($app->blog->site_path, 'mtview.php'),
        File::Spec->catfile($app->blog->site_path, 'templates_c'),
        File::Spec->catfile($app->blog->site_path, 'cache'),
        );
    if ($app->blog->archive_path) {
        push @unnecessary_files, File::Spec->catfile($app->blog->archive_path, '.htaccess');
        push @unnecessary_files, File::Spec->catfile($app->blog->archive_path, 'mtview.php');
    }
    foreach (@unnecessary_files) {
        if (-e $_) {
            if (-d $_) {
                File::Path::rmtree($_);
            } else {
                unlink $_;
            }
        }
    }

    utime undef, undef, (ITEMAN::DynamicPublishing::Config::REBUILD_TOUCH_FILE)
        or die "Failed to change the access and modification times on " . ITEMAN::DynamicPublishing::Config::REBUILD_TOUCH_FILE;
}

sub load_config {
    my $plugin = shift;
    my ($param, $scope) = @_;

    $plugin->SUPER::load_config(@_);

    unless (ITEMAN::DynamicPublishing::Cache->new->load('ITEMAN::DynamicPublishing::Config')) {
        eval { $plugin->_save_idp_config($param) };
    }

    unless (-f ITEMAN::DynamicPublishing::Config::REBUILD_TOUCH_FILE) {
        eval {
            open REBUILD_TOUCH_FILE, '> ' . ITEMAN::DynamicPublishing::Config::REBUILD_TOUCH_FILE or die;
        };
        unless ($@) {
            close REBUILD_TOUCH_FILE;
        }
    }

    $param->{cache_directory} = ITEMAN::DynamicPublishing::Config::CACHE_DIRECTORY;

    eval {
        $plugin->_check_cache_directory($param);
    };
    if ($@) {
        $param->{cache_directory_error} = 1;
    }

    eval {
        $plugin->_check_error_page_404($param);
    };
    if ($@) {
        $param->{error_page_404_error} = 1;
    }

    $param->{is_configured} = ITEMAN::DynamicPublishing::Cache->new->load('ITEMAN::DynamicPublishing::Config') && !$param->{cache_directory_error} && !$param->{error_page_404_error} ? 1 : 0;
}

sub save_config {
    my $plugin = shift;
    my ($param, $scope) = @_;

    unless ($scope eq 'system') {
        return;
    }

    if ($param->{clear_caches} eq 'true') {
        ITEMAN::DynamicPublishing::Cache->new->clear;
        return;
    }

    if ($param->{directory_index} eq '') {
        return $plugin->error($plugin->translate('Directory Index is required'));
    }

    if ($param->{error_page_404} eq '') {
        return $plugin->error($plugin->translate('The error page for the status code 404 is required'));
    }

    $plugin->SUPER::save_config(@_);

    $plugin->_save_idp_config($param);
}

sub reset_config {
    my $plugin = shift;

    $plugin->SUPER::reset_config(@_);

    ITEMAN::DynamicPublishing::Cache->new->clear;
}

sub _save_idp_config {
    my $plugin = shift;
    my $param = shift;

    my $config = ITEMAN::DynamicPublishing::Config->new;
    $config->directory_index($param->{directory_index});
    $config->error_page_404($param->{error_page_404});
    $config->db_dsn($MT::Object::DRIVER->fallback->dsn);
    $config->db_user($MT::Object::DRIVER->fallback->username);
    $config->db_password($MT::Object::DRIVER->fallback->password);

    ITEMAN::DynamicPublishing::Cache->new->save({
        cache_id => 'ITEMAN::DynamicPublishing::Config',
        data => $config,
                                                });
}

sub _check_cache_directory {
    my $plugin = shift;
    my $param = shift;

    my $user_name = getpwuid $>;
    $user_name = $> unless $user_name;
    unless (-d $param->{cache_directory}) {
        $param->{cache_directory_error_message} = $plugin->translate('The directory is not found or not readable for [_1]', $user_name);
        die;
    }

    unless (-x $param->{cache_directory}) {
        $param->{cache_directory_error_message} = $plugin->translate('The directory is not readable for [_1]', $user_name);
        die;
    }

    unless (-w $param->{cache_directory}) {
        $param->{cache_directory_error_message} = $plugin->translate('The directory is not writable for [_1]', $user_name);
        die;
    }
}

sub _check_error_page_404 {
    my $plugin = shift;
    my $param = shift;

    my ($feature) = (caller(1))[3] =~ /(error_page_\d+)$/;

    my $user_name = getpwuid $>;
    $user_name = $> unless $user_name;
    unless (-f $param->{error_page_404}) {
        $param->{error_page_404_error_message} = $plugin->translate('The file is not found or not readable for [_1]', $user_name);
        die $param->{error_page_404_error_message};
    }

    unless (-r $param->{error_page_404}) {
        $param->{error_page_404_error_message} = $plugin->translate('The file is not readable for [_1]', $user_name);
        die $param->{error_page_404_error_message};
    }
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
