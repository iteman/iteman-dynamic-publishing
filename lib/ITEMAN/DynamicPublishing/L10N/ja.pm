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
    'Directory Index is required' => 'ディレクトリインデックス は必須です',
    'Cache Directory is required' => 'キャッシュディレクトリ は必須です',
    'ITEMAN, Inc.' => '株式会社アイテマン',

# plugins/ITEMANDynamicPublishing/tmpl/system.tmpl
    'Directory Index' => 'ディレクトリインデックス',
    'Directory Index represents the file name which is used if a file name does not included in the requested URI. The default value of the directory index is index.html. You should only change this if you are using a different directory index such as index.htm.' => 'ディレクトリインデックス は、リクエストされた URI にファイル名が含まれない場合に使われるファイル名を表します。ディレクトリインデックス のデフォルト値は index.html です。index.htm のように異なる ディレクトリインデックス を利用する場合に限って、この設定を変更してください。',
    'Cache Directory' => 'キャッシュディレクトリ',
    'ITEMAN Dynamic Publishing caches of the result of a query to the database for performance. A cache file will be written to the directory specified by Cache Directory. The default value of Cache Directory is tmp under the directory where this plug-in has been deployed. Cache Directory should be readable/writable by the web server.' => 'ITEMAN Dynamic Publishing はパフォーマンス向上のためにデータベースへの問い合わせ結果をキャッシュします。キャッシュファイルは キャッシュディレクトリ によって指定されたディレクトリに書き込まれます。キャッシュディレクトリ のデフォルト値はこのプラグインが配備されているディレクトリの下の tmp です。キャッシュディレクトリ は Web サーバから読み込み・書き込み可能でなければなりません。',
    'Clear Caches' => 'キャッシュのクリア',
    'Error Page 404 (Not Found)' => 'エラーページ 404 (Not Found)',
    'Error Page 500 (Internal Server Error)' => 'エラーページ 500 (Internal Server Error)',
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
