

ぜろちゃんねるプラス Ver.0.7.5 - Readme.txt

公式WEB : http://zerochplus.sourceforge.jp/


■はじめに
　このファイルは、本家ぜろちゃんねる(http://0ch.mine.nu/)のスクリプトを２ちゃんねる仕様
に改造するという目的ではじまったプロジェクト「ぜろちゃんねるプラス」の取り扱い説明書です。
　なるべくどのような人でもわかるように解説していきたいですがなにぶん製作者が面倒くさがり
なので至らない点があるかもしれませんがご了承ください。
　なおこのファイルは本家ぜろちゃんねるの/readme/readme.txtを元に編集されていますので一部
原文ままの部分があります。ご了承ください。


■ぜろちゃんねるプラスとは
　スレッドフロート型掲示板を動作させるPerlスクリプトとして製作されたぜろちゃんねるの機能
改善版です。
　もともとはぜろちゃんねるスクリプトを使って作られた掲示板群の改造が適当だったので作りな
おすことが目的でしたが「どうせならほかの人にも使ってもらおう」ということで今回の公開に至
りました。
　ぜろちゃんねると同じく２ちゃんねる専用ブラウザでも書き込みと閲覧が可能です。


■動作環境
  ★必須環境
    ・CGIの動作が可能なHTTPDが入っており，Perl 5.8以上(Perl 6は含まない)もしくはそのディ
      ストリビューション系ソフトウェアが動作するOS
    ・5MB以上のディスクスペース
  ★推奨環境
    ・suEXECでCGI動作が可能なApache HTTP Serverが入っており，Perl 5.8以上(Perl 6は含まな
      い)が動作するUNIX系もしくはLinux系のOS
    ・10MB以上のディスクスペース

■配布ファイル構成
zerochplus_x.x.x/
 + Readme/                    - 最初に読むべきファイル
 |  + ArtisticLicense.txt
 |  + Readme.txt              - ぜろちゃんねるプラスのReadmeファイル(これです)
 |  + Readme0ch.txt           - ぜろちゃんねる(本家)のReadmeファイル
 |
 + test/                      - ぜろちゃんねるプラス動作ディレクトリ
    + *.cgi                   - 基本動作用CGI
    + datas/                  - 初期データ・固定データ格納用
    |  + 1000.txt
    |  + 2000000000.dat
    |  :
    + info/
    |  + category.cgi         - 掲示板カテゴリの初期定義ファイル
    |  + errmes.cgi           - エラーメッセージ定義ファイル
    |  + users.cgi            - 初期ユーザ(Administrator)定義ファイル
    + module/
    |  + *.pl                 - ぜろちゃんねるモジュール
    + mordor/
    |  + *.pl                 - 管理CGI用モジュール
    + plugin/
    |  + 0ch_*.pl             - プラグインスクリプト
    + perllib/
       + *                    - ぜろちゃんねるプラスに必要なパッケージ

■設置方法概略
　Wikiにて画像つきの設置方法の解説を公開しています。
  ・Install - ぜろちゃんねるプラス Wiki
    http://sourceforge.jp/projects/zerochplus/wiki/Install

1.スクリプト変更

	・構成ファイルtest直下の.cgiファイルを開き、1行目に書いてあるperlパス
	  を環境に合わせて変更します。

	※以下のようになっている場所を変更します。

		#!/usr/bin/perl

2.スクリプトアップロード

	・構成ファイルのtest以下すべてを設置サーバにアップロードします。
	・アップロード後パーミッションを適切な値に設定します。

	※パーミッションの値については以下のページを参照
	・Permission - ぜろちゃんねるプラス
	  http://sourceforge.jp/projects/zerochplus/wiki/Permission

3.設定

	・[設置サーバ]/test/admin.cgiにアクセスします。
	・ユーザ名"Administrator",パス"zeroch"でログインします。
	・画面上部の"システム設定"メニューを選択します。
	・画面左側の"基本設定"メニューを選択します。
	・項目[稼動サーバ]を適切な値に設定し、[設定]ボタンを押します。
	・再度画面左側の"基本設定"メニューを選択して、稼動サーバが更新されていることを確認し
	  てください。
	  （もしされていない場合はパーミッションの設定に問題があるかもしれません）
	・画面上部の"ユーザー"メニューを選択します。
	・画面中央の[User Name]列の"Administrator"を選択します。
	・ユーザ名、パスワードを変更して[設定]ボタンを押します。
	・画面上部の"ログオフ"を選択します。

4.掲示板作成

	・先ほど設定した管理者ユーザでログインします。
	・画面上部の"掲示板"メニューを選択します。
	・画面左側の"掲示板作成"メニューを選択します。
	・必要項目を記入して[作成]ボタンを押します。

5.掲示板設定

	・画面上部の"掲示板"メニューを選択します。
	・掲示板一覧より、設定する掲示板を選択します。
	・画面上部の"掲示板設定"を選択します。
	・各項目を設定します。

-----------------------------------------------------------------------
※注意：
	・設置後のAdministratorユーザは必ず変更を行ってください。設置直後は
	  ユーザ名とパスワードが固定なので、放置しておくと管理者以外に管理
	  権限でログインされてしまう危険があります。
-----------------------------------------------------------------------


■ライセンス
　本スクリプトのライセンスは本家ぜろちゃんねると同じ扱いとします。以下は本家ぜろちゃんね
る /readme/readme.txt からの引用です。

> 本スクリプトは自由に改造・再配布してもらってかまいません。また、本スクリプトによって出
力されるクレジット表示(バージョン表示)などの表示も消して使用してもらっても構いません。
> ただし、作者は本スクリプトと付属ファイルに関する著作権を放棄しません。また、作者は本ス
クリプト使用に関して発生したいかなるトラブルにも責任を負いかねますのでご了承ください。

　またremake.cgiの著作権･ライセンスは別の方にあり、remake.cgiの作者に著作権･ライセンスを
帰属します。

　perllibに含めてあるパッケージについては後述。

■バージョンアップについて
　0.7.0からバージョンアップの際には管理画面にて通知するようになりました。
　セキュリティ修正を含むアップデートも多々ありますのでお手数かと思いますが、こまめなアッ
プデートをよろしくおねがいします。


■ヘルプ・サポート
　さらに詳しい内容をお求めの方は以下のページを参照してください。
  ・ヘルプ - ぜろちゃんねるプラス
    http://zerochplus.sourceforge.jp/help/
  ・ぜろちゃんねるプラスWiki
    http://sourceforge.jp/projects/zerochplus/wiki/

　以上のページに求めている情報がない場合や不具合報告などしていただける場合は以下からお問
い合わせください。
  ・サポート - ぜろちゃんねるプラス
    http://zerochplus.sourceforge.jp/support/

■謝辞
　ぜろちゃんねるプラスを作成するにあたって支援していただいたすべての皆様に感謝します。
　そして何より元であるスクリプトのぜろちゃんねるをつくられた精神衰弱さんには心から感謝し
ます。

■公式WEB
　http://zerochplus.sourceforge.jp/

■perllibにあるパッケージ
　これらはぜろちゃんねるプラスの実行に必要なパッケージです。すでにインストールされている
サーバーもあるかもしれませんが、一応含めておきます。
　以下はパッケージの詳細です。

Digest-SHA-PurePerl
Perl implementation of SHA-1/224/256/384/512
    Version:    5.72
    Released:   2012-09-24
    Author:     Mark Shelor <mshelor@cpan.org>
    License:    The Perl 5 License (Artistic 1 & GPL 1)
    CPAN:       http://search.cpan.org/dist/Digest-SHA-PurePerl-5.72/

Net-DNS-Lite
a pure-perl DNS resolver with support for timeout
    Version:    0.09
    Released:   2012-06-20
    Author:     Kazuho Oku <kazuhooku@gmail.com>
    License:    The Perl 5 License (Artistic 1 & GPL 1)
    CPAN:       http://search.cpan.org/dist/Net-DNS-Lite-0.09/

List-MoreUtils
Provide the stuff missing in List::Util
    Version:    0.33
    Released:   2011-08-04
    Author:     Adam Kennedy <adamk@cpan.org>
    License:    The Perl 5 License (Artistic 1 & GPL 1)
    CPAN:       http://search.cpan.org/dist/List-MoreUtils-0.33/

CGI-Session
Persistent session data in CGI applications
    Version:    4.48
    Released:   2011-07-11
    Author:     Mark Stosberg <mark@summersault.com>
    License:    Artistic License 1.0
    CPAN:       http://search.cpan.org/dist/CGI-Session-4.48/

