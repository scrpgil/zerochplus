#!/usr/bin/perl
#============================================================================================================
#
#	読み出し専用CGI
#
#============================================================================================================

use lib './perllib';

use strict;
#use warnings;
no warnings 'once';
##use CGI::Carp qw(fatalsToBrowser warningsToBrowser);


# CGIの実行結果を終了コードとする
exit(ReadCGI());

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadCGI
{
	require './module/constant.pl';

	require './module/io.pl';
	my $Page = IO->new;

	my $CGI = {};
	my $err = Initialize($CGI, $Page);

	# 初期化・準備に成功したら内容表示
	if ($err == $ZP::E_SUCCESS) {
		# ヘッダ表示
		PrintReadHead($CGI, $Page);

		# メニュー表示
		PrintReadMenu($CGI, $Page);

		# 内容表示
		PrintReadContents($CGI, $Page);

		# フッタ表示
		PrintReadFoot($CGI, $Page);
	}
	# 初期化に失敗したらエラー表示
	else {
		# 対象スレッドが見つからなかった場合は探索画面を表示する
		if ($err == $ZP::E_PAGE_FINDTHREAD) {
			PrintReadSearch($CGI, $Page);
		}
		# それ以外は通常エラー
		else {
			PrintReadError($CGI, $Page, $err);
		}
	}

	# 表示結果を出力
	$Page->Flush(0, 0, '');

	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi初期化・前準備
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($CGI, $Page) = @_;

	# 各使用モジュールの生成と初期化
	require './module/sys_data.pl';
	require './module/settings.pl';
	require './module/dat.pl';
	require './module/data_utils.pl';

	my $Sys = SYS_DATA->new;
	my $Conv = DATA_UTILS->new;
	my $Set = SETTINGS->new;
	my $Dat = DAT->new;

	%$CGI = (
		'SYS'		=> $Sys,
		'SET'		=> $Set,
		'CONV'		=> $Conv,
		'DAT'		=> $Dat,
		'PAGE'		=> $Page,
		'CODE'		=> 'Shift_JIS',
	);

	# システム初期化
	$Sys->Init();

	# 夢が広がりんぐ
	$Sys->Set('MainCGI', $CGI);

	# 起動パラメータの解析
	my @elem = $Conv->GetArgument(\%ENV);

	# BBS指定がおかしい
	if (!defined $elem[0] || $elem[0] eq '') {
		return $ZP::E_READ_INVALIDBBS;
	}
	# スレッドキー指定がおかしい
	elsif (!defined $elem[1] || $elem[1] eq '' || ($elem[1] =~ /[^0-9]/) ||
			(length($elem[1]) != 10 && length($elem[1]) != 9)) {
		return $ZP::E_READ_INVALIDKEY;
	}

	# システム変数設定
	$Sys->Set('MODE', 0);
	$Sys->Set('BBS', $elem[0]);
	$Sys->Set('KEY', $elem[1]);
	$Sys->Set('CLIENT', $Conv->GetClient());
	$Sys->Set('AGENT', $Conv->GetAgentMode($Sys->Get('CLIENT')));
	$Sys->Set('BBSPATH_ABS', $Conv->MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH')));
	$Sys->Set('BBS_ABS', $Conv->MakePath($Sys->Get('BBSPATH_ABS'), $Sys->Get('BBS')));
	$Sys->Set('BBS_REL', $Conv->MakePath($Sys->Get('BBSPATH'), $Sys->Get('BBS')));

	# 設定ファイルの読み込みに失敗
	if ($Set->Load($Sys) == 0) {
		return $ZP::E_READ_FAILEDLOADSET;
	}

	my $submax = $Set->Get('BBS_SUBJECT_MAX') || $Sys->Get('SUBMAX');
	$Sys->Set('SUBMAX', $submax);
	my $resmax = $Set->Get('BBS_RES_MAX') || $Sys->Get('RESMAX');
	$Sys->Set('RESMAX', $resmax);

	my $path = $Conv->MakePath($Sys->Get('BBSPATH')."/$elem[0]/dat/$elem[1].dat");

	# datファイルの読み込みに失敗
	if ($Dat->Load($Sys, $path, 1) == 0) {
		return $ZP::E_READ_FAILEDLOADDAT;
	}
	$Dat->Close();

	# 表示開始終了位置の設定
	my @regs = $Conv->RegularDispNum(
				$Sys, $Dat, $elem[2], $elem[3], $elem[4]);
	$Sys->SetOption($elem[2], $regs[0], $regs[1], $elem[5], $elem[6]);

	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiヘッダ出力
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$title
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadHead
{
	my ($CGI, $Page, $title) = @_;

	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Dat = $CGI->{'DAT'};

	require './module/meta.pl';
	require './module/banner.pl';
	my $Caption = META->new;
	my $Banner = BANNER->new;

	$Caption->Load($Sys, 'META');
	$Banner->Load($Sys);

	my $code = $CGI->{'CODE'};
	$title = $Dat->GetSubject() if(!defined $title);
	$title = '' if(!defined $title);

	my $data_path	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH') . $Sys->Get('DATA');

	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE html>
<html lang="ja">
<head>

 <meta name="viewport" content="viewport-fit=cover, width=device-width" />
 <meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">
 <meta http-equiv="Content-Style-Type" content="text/css">
 <link rel="stylesheet" href="$data_path/app.css" type="text/css">

HTML

	$Caption->Print($Page, undef);

	$Page->Print(" <title>$title</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n");

	# <body>タグ出力
	{
		my @work;
		$work[0] = $Set->Get('BBS_THREAD_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');

		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n\n");
	}

	# バナー出力
	$Banner->Print($Page, 100, 2, 0) if ($Sys->Get('BANNER') & 5);
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiメニュー出力
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadMenu
{
	my ($CGI, $Page) = @_;

	# 前準備
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Dat = $CGI->{'DAT'};
	my $Conv = $CGI->{'CONV'};

	my $bbs = $Sys->Get('BBS');
	my $key = $Sys->Get('KEY');
	my $baseBBS = $Sys->Get('BBS_ABS');
	my $baseCGI = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	my $account = $Sys->Get('COUNTER');
	my $PRtext = $Sys->Get('PRTEXT');
	my $PRlink = $Sys->Get('PRLINK');
	my $pathBBS = $baseBBS;
	my $pathAll = $Conv->CreatePath($Sys, 0, $bbs, $key, '');
	my $pathLast = $Conv->CreatePath($Sys, 0, $bbs, $key, 'l50');
	my $resNum = $Dat->Size();

	$Page->Print("<div style=\"margin:0px;\">\n");

	# カウンター表示
	if ($account ne '') {
		$Page->Print('<a href="http://ofuda.cc/"><img width="400" height="15" border="0" src="http://e.ofuda.cc/');
		$Page->Print("disp/$account/00813400.gif\" alt=\"無料アクセスカウンターofuda.cc「全世界カウント計画」\"></a>\n");
	}

	$Page->Print("<div style=\"margin-top:1em;\">\n");
	$Page->Print(" <span style=\"float:left;\">\n");
	$Page->Print(" <a href=\"$pathBBS/\">■掲示板に戻る■</a>\n");
	$Page->Print(" <a href=\"$pathAll\">全部</a>\n");

	# スレッドメニューを表示
	for my $i (0 .. 9) {
		last if ($resNum <= $i * 100);

		my $st = $i * 100 + 1;
		my $ed = ($i + 1) * 100;
		my $pathMenu = $Conv->CreatePath($Sys, 0, $bbs, $key, "$st-$ed");
		$Page->Print(" <a href=\"$pathMenu\">$st-</a>\n");
	}
	$Page->Print(" <a href=\"$pathLast\">最新50</a>\n");
	$Page->Print(" </span>\n");
	$Page->Print(" <span style=\"float:right;\">\n");
	if ($PRtext ne '') {
		$Page->Print(" [PR]<a href=\"$PRlink\" target=\"_blank\">$PRtext</a>[PR]\n");
	}
	else {
		$Page->Print(" &nbsp;\n");
	}
	$Page->Print(" </span>&nbsp;\n");
	$Page->Print("</div>\n");
	$Page->Print("</div>\n\n");

	# レス数限界警告表示
	{
		my $rmax = $Sys->Get('RESMAX');

		if ($resNum >= $rmax) {
			$Page->Print("<div style=\"background-color:red;color:white;line-height:3em;margin:1px;padding:1px;\">\n");
			$Page->Print("レス数が$rmaxを超えています。残念ながら全部は表\示しません。\n");
			$Page->Print("</div>\n\n");
		}
		elsif ($resNum >= $rmax - int($rmax / 20)) {
			$Page->Print("<div style=\"background-color:red;color:white;margin:1px;padding:1px;\">\n");
			$Page->Print("レス数が".($rmax-int($rmax/20))."を超えています。$rmaxを超えると表\示できなくなるよ。\n");
			$Page->Print("</div>\n\n");
		}
		elsif ($resNum >= $rmax - int($rmax / 10)) {
			$Page->Print("<div style=\"background-color:yellow;margin:1px;padding:1px;\">\n");
			$Page->Print("レス数が".($rmax-int($rmax/10))."を超えています。$rmaxを超えると表\示できなくなるよ。\n");
			$Page->Print("</div>\n\n");
		}
	}

	# スレッドタイトル表示
	{
		my $title = $Dat->GetSubject();
		my $ttlCol = $Set->Get('BBS_SUBJECT_COLOR');
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:$ttlCol;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("<dl class=\"thread\">\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi内容出力
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadContents
{
	my ($CGI, $Page) = @_;

	my $Sys = $CGI->{'SYS'};

	# 拡張機能ロード
	require './module/plugins.pl';
	my $Plugin = PLUGINS->new;
	$Plugin->Load($Sys);

	# 有効な拡張機能一覧を取得
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);

	my $count = 0;
	my @commands = ();
	foreach my $id (@pluginSet) {
		# タイプがread.cgiの場合はロードして実行
		if ($Plugin->Get('TYPE', $id) & 4) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);

			if (-e "./plugin/$file") {
				require "./plugin/$file";
				my $Config = PLUGINCONF->new($Plugin, $id);
				$commands[$count] = $className->new($Config);
				$count++;
			}
		}
	}

	my $work = $Sys->Get('OPTION');
	my @elem = split(/\,/, $work);

	# 1表示フラグがTRUEで開始が1でなければ1を表示する
	if ($elem[3] == 0 && $elem[1] != 1) {
		PrintResponse($CGI, $Page, \@commands, 1);
	}
	# 残りのレスを表示する
	for my $i ($elem[1] .. $elem[2]) {
		PrintResponse($CGI, $Page, \@commands, $i);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiフッタ出力
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadFoot
{
	my ($CGI, $Page) = @_;

	# 前準備
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Dat = $CGI->{'DAT'};

	my $bbs = $Sys->Get('BBS');
	my $key = $Sys->Get('KEY');
	my $ver = $Sys->Get('VERSION');
	my $rmax = $Sys->Get('RESMAX');
	my $datPath = $Conv->MakePath($Sys->Get('BBS_REL')."/dat/$key.dat");
	my $datSize = int((stat $datPath)[7] / 1024);
	my $cgipath = $Sys->Get('CGIPATH');

	# datファイルのサイズ表示
	$Page->Print("</dl>\n\n<font color=\"red\" face=\"Arial\"><b>${datSize}KB</b></font>\n\n");

	# 時間制限がある場合は説明表示
	if ($Sys->Get('LIMTIME')) {
		$Page->Print('　(08:00PM - 02:00AM の間一気に全部は読めません)');
	}
	$Page->Print("<hr>\n");

	# フッタメニューの表示
	{
		# メニューリンクの項目設定
		my @elem = split(/\,/, $Sys->Get('OPTION'));
		my $nxt = ($elem[2] + 100 > $rmax ? $rmax : $elem[2] + 100);
		my $nxs = $elem[2];
		my $prv = ($elem[1] - 100 < 1 ? 1 : $elem[1] - 100);
		my $prs = $prv + 100;

		# 新着の表示
		if ($rmax > $Dat->Size()) {
			my $dispStr = ($Dat->Size() == $elem[2] ? '新着レスの表\示' : '続きを読む');
			my $pathNew = $Conv->CreatePath($Sys, 0, $bbs, $key, "$elem[2]-");
			$Page->Print("<center><a href=\"$pathNew\">$dispStr</a></center>\n");
			$Page->Print("<hr>\n\n");
		}

		# パスの設定
		my $pathBBS = $Sys->Get('BBS_ABS');
		my $pathAll = $Conv->CreatePath($Sys, 0, $bbs, $key, '');
		my $pathPrev = $Conv->CreatePath($Sys, 0, $bbs, $key, "$prv-$prs");
		my $pathNext = $Conv->CreatePath($Sys, 0, $bbs, $key, "$nxs-$nxt");
		my $pathLast = $Conv->CreatePath($Sys, 0, $bbs, $key, 'l50');

		$Page->Print("<div class=\"links\">\n");
		$Page->Print("<a href=\"$pathBBS/\">掲示板に戻る</a>\n");
		$Page->Print("<a href=\"$pathAll\">全部</a>\n");
		$Page->Print("<a href=\"$pathPrev\">前100</a>\n");
		$Page->Print("<a href=\"$pathNext\">次100</a>\n");
		$Page->Print("<a href=\"$pathLast\">最新50</a>\n");
		$Page->Print("</div>\n");
	}

	# 投稿フォームの表示
	# レス最大数を超えている場合はフォーム表示しない
	if ($rmax > $Dat->Size()) {
		my $cookName = '';
		my $cookMail = '';
		my $tm = int(time);

		# cookie設定ON時はcookieを取得する
		if (($Sys->Get('CLIENT') & $ZP::C_PC) && $Set->Equal('SUBBBS_CGI_ON', 1)) {
			require './module/cookie.pl';
			my $Cookie = COOKIE->new;
			$Cookie->Init();
			my $sanitize = sub {
				$_ = shift;
				s/&/&amp;/g;
				s/</&lt;/g;
				s/>/&gt;/g;
				s/"/&#34;/g;
				return $_;
			};
			$cookName = &$sanitize($Cookie->Get('NAME', '', 'utf8'));
			$cookMail = &$sanitize($Cookie->Get('MAIL', '', 'utf8'));
		}

		$Page->Print(<<HTML);
<form method="POST" action="$cgipath/bbs.cgi?guid=ON">
<input type="hidden" name="bbs" value="$bbs"><input type="hidden" name="key" value="$key"><input type="hidden" name="time" value="$tm">
<input type="submit" value="書き込む">
名前：<input type="text" name="FROM" value="$cookName" size="19">
E-mail<font size="1">（省略可）</font>：<input type="text" name="mail" value="$cookMail" size="19"><br>
<textarea rows="5" cols="70" name="MESSAGE"></textarea>
</form>
HTML
	}

	$Page->Print(<<HTML);
<div style="margin-top:4em;">
READ.CGI - $ver<br>
<a href="http://zerochplus.sourceforge.jp/">ぜろちゃんねるプラス</a>
</div>

</body>
</html>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiレス表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$commands
#	@param	$n
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($CGI, $Page, $commands, $n) = @_;

	# 前準備
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Dat = $CGI->{'DAT'};

	my $pDat = $Dat->Get($n - 1);
	my @elem = split(/<>/, $$pDat);
	my $nameCol	= $Set->Get('BBS_NAME_COLOR');

	# URLと引用個所の適応
	$Conv->ConvertURL($Sys, $Set, 0, \$elem[3]);
	$Conv->ConvertQuotation($Sys, \$elem[3], 0);

	# 拡張機能を実行
	$Sys->Set('_DAT_', \@elem);
	$Sys->Set('_NUM_', $n);
	foreach my $command (@$commands) {
		$command->execute($Sys, undef, 4);
	}

	$Page->Print(" <dt>$n ：");

	# メール欄有り
	if ($elem[1] eq '') {
		$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
	}
	# メール欄無し
	else {
		$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
	}
	$Page->Print("：$elem[2]</dt>\n");
	$Page->Print("  <dd>$elem[3]<br><br></dd>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi探索画面表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadSearch
{
	my ($CGI, $Page) = @_;

	return if (PrintDiscovery($CGI, $Page));

	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Dat = $CGI->{'DAT'};

	my $nameCol = $Set->Get('BBS_NAME_COLOR');
	my $var = $Sys->Get('VERSION');
	my $cgipath = $Sys->Get('CGIPATH');
	my $bbs = $Sys->Get('BBS_ABS') . '/';
	my $server = $Sys->Get('SERVER');

	# エラー用datの読み込み
	$Dat->Load($Sys, $Conv->MakePath('.'.$Sys->Get('DATA').'/2000000000.dat'), 1);
	my $size = $Dat->Size();

	# 存在しないので404を返す。
	$Page->Print("Status: 404 Not Found\n");

	PrintReadHead($CGI, $Page);

	$Page->Print("\n<div style=\"margin-top:1em;\">\n");
	$Page->Print(" <a href=\"$bbs\">■掲示板に戻る■</a>\n");
	$Page->Print("</div>\n");

	$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
	$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">指定されたスレッドは存在しません</h1>\n\n");

	$Page->Print("\n<dl class=\"thread\">\n");

	for my $i (0 .. $size - 1) {
		my $pDat = $Dat->Get($i);
		my @elem = split(/<>/, $$pDat);
		$Page->Print(' <dt>' . ($i + 1) . ' ：');

		# メール欄有り
		if ($elem[1] eq '') {
			$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
		}
		# メール欄無し
		else {
			$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
		}
		$Page->Print("：$elem[2]</dt>\n  <dd>$elem[3]<br><br></dd>\n");
	}
	$Page->Print("</dl>\n\n");

	$Dat->Close();

	$Page->Print("<hr>\n\n");

	$Page->Print(<<HTML);
<div style="margin-top:4em;">
READ.CGI - $var<br>
<a href="http://zerochplus.sourceforge.jp/">ぜろちゃんねるプラス</a>
</div>

</body>
</html>
HTML

}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiエラー表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$err
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadError
{
	my ($CGI, $Page, $err) = @_;

	my $code = $CGI->{'CODE'};

	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><head><title>ＥＲＲＯＲ！！</title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head><!--nobanner-->');
	$Page->Print('<html><body>');
	$Page->Print("<b>$err</b>");
	$Page->Print('</body></html>');
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi過去ログ倉庫探索
#	--------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	ログがどこにも見つからなければ 0 を返す
#			ログがあるなら 1 を返す
#
#------------------------------------------------------------------------------------------------------------
sub PrintDiscovery
{
	my ($CGI, $Page) = @_;

	my $Sys = $CGI->{'SYS'};
	my $Conv = $CGI->{'CONV'};

	my $cgipath = $Sys->Get('CGIPATH');
	my $spath = $Sys->Get('BBS_REL');
	my $lpath = $Sys->Get('BBS_ABS');
	my $key = $Sys->Get('KEY');
	my $kh = substr($key, 0, 4) . '/' . substr($key, 0, 5);
	my $ver = $Sys->Get('VERSION');
	my $server = $Sys->Get('SERVER');

	# 過去ログにあり
	if (-e $Conv->MakePath("$spath/kako/$kh/$key.html")) {
		my $path = $Conv->MakePath("$lpath/kako/$kh/$key");

		my $title = "隊長！過去ログ倉庫に";
		PrintReadHead($CGI, $Page, $title);
		$Page->Print("\n<div style=\"margin-top:1em;\">\n");
		$Page->Print(" <a href=\"$lpath/\">■掲示板に戻る■</a>\n");
		$Page->Print("</div>\n\n");
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("\n<blockquote>\n");
		$Page->Print("隊長! 過去ログ倉庫で、スレッド <a href=\"$path.html\">$server$path.html</a>");
		$Page->Print(" <a href=\"$path.dat\">.dat</a> を発見しました。");
		$Page->Print("</blockquote>\n");

	}
	# poolにあり
	elsif (-e $Conv->MakePath("$spath/pool/$key.cgi")) {
		my $title = "html化待ちです…";
		PrintReadHead($CGI, $Page, $title);
		$Page->Print("\n<div style=\"margin-top:1em;\">\n");
		$Page->Print(" <a href=\"$lpath/\">■掲示板に戻る■</a>\n");
		$Page->Print("</div>\n\n");
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("\n<blockquote>\n");
		$Page->Print("$key.datはhtml化を待っています。");
		$Page->Print('ここは待つしかない・・・。<br>'."\n");
		$Page->Print("</blockquote>\n");
	}
	# どこにもない
	else {
		return 0;
	}

	$Page->Print(<<HTML);

<hr>

<div style="margin-top:4em;">
READ.CGI - $ver<br>
<a href="http://zerochplus.sourceforge.jp/">ぜろちゃんねるプラス</a>
</div>

</body>
</html>
HTML

	return 1;
}
