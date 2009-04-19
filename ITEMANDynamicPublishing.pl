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
use MT;

our $VERSION = '0.1.0';

{
    require File::Spec;

    my $name = 'ITEMAN Dynamic Publishing';
    my $id = lc($name);
    $id =~ s/\s//g;
    my $description = 'ITEMAN Dynamic Publishing allows you to create dynamic Web pages with normal publishing workflow. Since ITEMAN Dynamic Publishing is written in Perl, it can be used with any plug-ins.';
    my $author_name = 'ITEMAN, Inc.';
    my $author_link = 'http://iteman.jp/';
    my $settings = [
        [ 'directory_index', { Default => 'index.html', Scope => 'system'} ],
        [ 'cache_directory', { Default => File::Spec->catdir(File::Spec->tmpdir(), "$id-cache"), Scope => 'system'} ],
        ];

    MT->add_plugin(__PACKAGE__->new({
        name => $name,
        id => $id,
        key => __PACKAGE__,
        description => "<MT_TRANS phrase=\"$description\">",
        author_name => $author_name,
        author_link => $author_link,
        version => $VERSION,
        system_config_template => 'system.tmpl',
        settings => MT::PluginSettings->new($settings),
        l10n_class => 'ITEMAN::DynamicPublishing::L10N',
                                    })
        );
}

sub save_config {
    my $plugin = shift;
    my ($args, $scope) = @_;

    unless ($scope eq 'system') {
        return;
    }

    if ($args->{directory_index} eq '') {
        return $plugin->error($plugin->translate('Directory Index is required'));
    }

    if ($args->{cache_directory} eq '') {
        return $plugin->error($plugin->translate('Cache Directory is required'));
    }

    $plugin->SUPER::save_config(@_);
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
