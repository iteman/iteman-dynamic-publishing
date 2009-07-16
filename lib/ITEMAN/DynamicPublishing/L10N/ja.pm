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

package ITEMAN::DynamicPublishing::L10N::ja;

use strict;
use warnings;

use base qw(ITEMAN::DynamicPublishing::L10N::en_us);

our %Lexicon = (

# plugins/ITEMANDynamicPublishing/ITEMANDynamicPublishing.pl
    'ITEMAN Dynamic Publishing provides a Perl-based dynamic publishing system that works as a replacement for the PHP-based dynamic publishing built into Movable Type. It allows you to publish Web pages dynamically with normal publishing workflow as well as the built-in dynamic publishing.

In contrast to the built-in dynamic publishing, ITEMAN Dynamic Publishing works well with your existing Perl-based plugins.' => 'ITEMAN Dynamic Publishing は、Movable Type 標準の PHP ベースのダイナミックパブリッシングの代わりとなる、Perl ベースのダイナミックパブリッシングシステムを提供します。このシステムは、標準のダイナミックパブリッシングと同様に、通常のパブリッシングワークフローによる Web ページの動的な公開を可能にします。

標準のダイナミックパブリッシングとは対照的に、ITEMAN Dynamic Publishing では既存の Perl ベースのプラグインが問題なく動作します。',
    'ITEMAN, Inc.' => '株式会社アイテマン',
    'Directory Index is required' => 'ディレクトリインデックス は必須です',
    'The error page for the status code 404 is required' => 'ステータスコード 404 のためのエラーページは必須です',

# plugins/ITEMANDynamicPublishing/tmpl/system.tmpl
    'Configuration Check' => '構成のチェック',
    'Failed to configure ITEMAN Dynamic Publishing. See the following section for more details.' => 'ITEMAN Dynamic Publishing の構成に失敗しました。詳細は下記のセクションを参照してください。',
    'Cache' => 'キャッシュ',
    'Cache Directory' => 'キャッシュディレクトリ',
    'The directory is not found or not readable for [_1]' => 'ディレクトリが見つからないか、[_1] ユーザからディレクトリへの読み込み権限がありません',
    'The directory is not readable for [_1]' => '[_1] ユーザからディレクトリへの読み込み権限がありません',
    'The directory is not writable for [_1]' => '[_1] ユーザからディレクトリへの書き込み権限がありません',
    'Clear Caches' => 'キャッシュのクリア',
    'Directory Index' => 'ディレクトリインデックス',
    'Directory Index represents the file name which is used if the requested URI does not contain a file name. The default value of the directory index is index.html. You should only change this if you are using a different directory index such as index.htm.' => 'ディレクトリインデックス は、リクエストされた URI にファイル名が含まれない場合に使われるファイル名を表します。ディレクトリインデックス のデフォルト値は index.html です。index.htm のように異なる ディレクトリインデックス を利用する場合に限って、この設定を変更してください。',
    'ITEMAN Dynamic Publishing caches of the result of a query to the database for performance. A cache file will be written to the directory specified by Cache Directory. Cache Directory is tmp under the directory where this plug-in has been deployed. Cache Directory should be readable/writable by the web server.' => 'ITEMAN Dynamic Publishing はパフォーマンス向上のためにデータベースへの問い合わせ結果をキャッシュします。キャッシュファイルは キャッシュディレクトリ によって指定されたディレクトリに書き込まれます。キャッシュディレクトリ はこのプラグインが配備されているディレクトリの下の tmp です。キャッシュディレクトリ は Web サーバから読み込み・書き込み可能でなければなりません。',
    'Error Page for 404 (Not Found)' => '404 (Not Found) 用エラーページ',
    'Any error page can be specified for the 404 error. The value should be one of the path of a HTML file, the path of a MT template file, or a URI for redirection.' => '404 エラー用に任意のエラーページを指定することができます。値は HTML ファイルのパス、MT テンプレートファイルのパス、リダイレクション用 URI のいずれかでなければなりません。',
    'The file is not found or not readable for [_1]' => 'ファイルが見つからないか、[_1] ユーザからファイルへの読み込み権限がありません',
    'The file is not readable for [_1]' => '[_1] ユーザからファイルへの読み込み権限がありません',
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
