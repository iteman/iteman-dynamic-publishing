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

package ITEMAN::DynamicPublishing::L10N::ja;

use strict;

use base qw( ITEMAN::DynamicPublishing::L10N::en_us );

our %Lexicon = (

# plugins/ITEMANDynamicPublishing/ITEMANDynamicPublishing.pl
    'ITEMAN Dynamic Publishing allows you to create dynamic Web pages with normal publishing workflow. Since ITEMAN Dynamic Publishing is written in Perl, it can be used with any plug-ins.' => 'ITEMAN Dynamic Publishing は通常のパブリッシングワークフローによる動的な Web ページの作成を可能にします。ITEMAN Dynamic Publishing は Perl で書かれているため、あらゆるプラグインとともに使うことができます。',
    'Directory Index is required' => 'ディレクトリインデックスは必須です',

# plugins/ITEMANDynamicPublishing/tmpl/system.tmpl
    'Directory Index' => 'ディレクトリインデックス',
    'The default value of the directory index is index.html. You should only change this if you are using a different directory index such as index.htm.' => 'ディレクトリインデックスのデフォルト値は index.html です。index.htm のように異なるディレクトリインデックスを利用する場合に限って、この設定を変更してください。',
);

1;

# Local Variables:
# mode: perl
# coding: utf-8
# tab-width: 4
# c-basic-offset: 4
# c-hanging-comment-ender-p: nil
# indent-tabs-mode: nil
# End:
