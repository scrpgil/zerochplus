#============================================================================================================
#
#	拡張機能 - BE(HS)っぽいもの
#	0ch_BE_HS.pl
#
#	by ぜろちゃんねるプラス
#	http://zerochplus.sourceforge.jp/
#
#	導 入 前 に 必 ず r e a d m e . t x t を 読 ん で く だ さ い 。
#	読まないとあなたは明日の朝おきたら 首 を 寝 違 え て い ま す 。
#
#	---------------------------------------------------------------------------
#
#	2010.08.26 start
#
#============================================================================================================
package ZPL_BE_HS;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	オブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my $obj={};
	bless($obj,$this);
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能名称取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	名称文字列
#
#------------------------------------------------------------------------------------------------------------
sub getName
{
	my	$this = shift;
	return 'BE(HS)っぽいもの';
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能説明取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	説明文字列
#
#------------------------------------------------------------------------------------------------------------
sub getExplanation
{
	my	$this = shift;
	return '２ちゃんねるのBEにログインできるようにします';
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能タイプ取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	拡張機能タイプ(スレ立て:1,レス:2,read:4,index:8)
#
#------------------------------------------------------------------------------------------------------------
sub getType
{
	my	$this = shift;
	return (1 | 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能実行インタフェイス
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@return	正常終了の場合は0
#
#------------------------------------------------------------------------------------------------------------
sub execute
{
	use strict;
	use warnings;
	my $this = shift;
	my ($Sys, $Form, $type) = @_;
	
	#--------------------------------------------------------------------------------------------------------
	#	ユーザー設定項目
	#	---------------------------------------------------------------------------------
	#	詳しくはreadme.txtをご覧ください
	#--------------------------------------------------------------------------------------------------------
	
	# sssp://(BEアイコン表示)を有効にする？(1:有効,0:無効)
	my $be_icon = 0;
	
	
	# 名前欄を取得
	my $name = $Form->Get('FROM');
	
	# 悪さ対策でとりあえず空にする
	$Form->Set('BEID', '');
	$Form->Set('BEBASE', '0');
	$Form->Set('BERANK', '0');
	
	if ( $name =~ /!BE.+!HS/ ) {
		
		my ( $beid, $key );
		
		if ( $name =~ /!BE(\d+)!HS.*?#(.+)$/ ) {
			$beid = $1;
			$key = $2;
		}
		elsif ( $name =~ /!BE(\d+)-#(.+)!HS/ ) {
			$beid = $1;
			$key = $2;
		}
		
		my ($Conv, $Set, $trip, $key2, $column, @ct_arg, $CGI);
		$CGI = $Sys->Get('MainCGI');
		if (defined $CGI) {
			$Conv = $CGI->{'CONV'};
			$Set = $CGI->{'SET'};
			$column = $Set->Get('BBS_TRIPCOLUMN');
			$trip = $Conv->ConvertTrip(\$key, $column, $Sys->Get('TRIP12'));
		}
		else {
			require './module/galadriel.pl';
			$Conv = GALADRIEL->new;
			require './module/isildur.pl';
			$Set = ISILDUR->new;
			$Set->Load($Sys);
			$column = $Set->Get('BBS_TRIPCOLUMN');
			$key = "#$key";
			$Conv->ConvertTrip(\$key, $column);
			$key =~ m|◆([A-Za-z0-9\.]+)|;
			$trip = $1;
		}
		
		# とりあえず消す
		$name =~ s/!BE.+!HS//;
		if ($Form->IsExist('TRIPKEY') && $name =~ /#(.+)$/) {
			$key2 = $1;
			$ct_arg[0] = \$key2;
			$key2 = $Conv->ConvertTrip(\$key2, $column, $Sys->Get('TRIP12'));
			$Form->Set('TRIPKEY', $key2);
		}
		
		$Form->Set('FROM', $name);
		
		# BEプロフのURLですね！
		my $beprof = "http://be.2ch.net/test/p.php?i=$beid";
		
		# LWPの設定
		my ( $code, $content ) = BeGet($beprof);
		
		# HTML解析
		if ( $code ne 200 ) {
			#$Form->Set('BEID', "BE:取得エラー($code)");
			$Sys->Set('CODE', $code);
			PrintBBSError( $Sys, $Form, 891 );
			return 0;
		}
		
		# Shift_JISｪ…
		require Encode;
		Encode::from_to( $content, 'EUC-JP', 'Shift_JIS' );
		
		if ( $content =~ /<div id="sitename">\n<h1>(.+)<\/h1>/ ) {
			
			my $name = $1;
			$name =~ s|^.*◆([A-Za-z0-9\./]{10,12}).*$|$1|;
			
			# 入力トリップとプロフのトリップの一致を調べる
			if ( $trip eq $name ) {
				
				my $point = 0;
				
				# ポイント取得
				if ( $content =~ m/<p><b>be.{8}<\/b>:([0-9]+)<\/p>/ ) {
					$point = BeRank($Form, $1);
				}
				else {
					# おかしかったらみんな０ポイント
					$point = '2BP(0)';
				}
				
				# 基礎BE番号取得+セット
				$Form->Set('BEBASE', ID2BASE($beid) );
				
				# BEポイントセット
				$Form->Set('BEID', "BE:$beid-$point");
				
				# アイコンとってくるよ！
				if ( $be_icon && $Form->Get('MESSAGE') ne "" ) {
					
					if ( $content =~ m|<img .+ alt="icon:([^\"]+)" />\n\n|i ) {
						$Form->Set('MESSAGE', "sssp://img.2ch.net/ico/$1<br>".$Form->Get('MESSAGE'));
					}
					
				}
				
			}
			else {
				#$Form->Set('BEID', "BE:認証エラー($trip:$name)");
				$Sys->Set('CHK', "◆".$trip);
				PrintBBSError( $Sys, $Form, 892 );
				return 0;
			}
			
		}
		else {
			#$Form->Set('BEID', '取得エラー(-1)');
			PrintBBSError( $Sys, $Form, 890 );
			return 0;
		}
		
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	BEプロフィールページ取得
#	-------------------------------------------------------------------------------------
#	@param	$url	BEプロフ
#	@return	$code	HTTPステータス
#	@return $cont	BeプロフHTML
#
#------------------------------------------------------------------------------------------------------------
sub BeGet
{
	
	my ( $url ) = @_;
	
	require('./module/httpservice.pl');
	
	my $proxy = HTTPSERVICE->new;
	$proxy->setURI($url);
	$proxy->setAgent('Mozilla/5.0 Plugin for 0ch+; 0ch_BE_HS.pl http://zerochplus.sourceforge.jp/');
	$proxy->setTimeout(3);
	
	# とってくるよ
	$proxy->request();
	
	my $cont = $proxy->getContent();
	my $code = $proxy->getStatus();
	
	return ( $code, $cont );
	

}
#------------------------------------------------------------------------------------------------------------
#
#	BE会員ランク取得
#	-------------------------------------------------------------------------------------
#	@param	$Form	$Form
#	@param	$point	ポイント
#	@return	ランク表示形式 2BP(0)
#
#------------------------------------------------------------------------------------------------------------
sub BeRank
{
	
	my ( $Form, $point ) = @_;
	
	if ( $point < 10000 ) {
		$point = "2BP($point)";
		$Form->Set('BERANK', 1);
	}
	elsif ( $point < 12000 ) {
		$point = "BRZ($point)";
		$Form->Set('BERANK', 2);
	}
	elsif ( $point < 100000 ) {
		$point = "PLT($point)";
		$Form->Set('BERANK', 3);
	}
	elsif ( $point < 500000 ) {
		$point = "DIA($point)";
		$Form->Set('BERANK', 4);
	}
	elsif ( $point >= 500000 ) {
		$point = "S★($point)";
		$Form->Set('BERANK', 5);
	}
	else {
		$point = "2BP(0)";
		$Form->Set('BERANK', 1);
	}
	
	return $point;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	BEID->基礎BE番号取得
#	-------------------------------------------------------------------------------------
#	@param	$id		BEID
#	@return	基礎BE番号
#
#------------------------------------------------------------------------------------------------------------
sub ID2BASE
{
	
	my ($id) = @_;
	my ($base, $a, $b, $c, $d);
	
	$base = 0;
	
	if (($b = $id % 10) && ($a = ($id % 100 - $b) / 10) &&
		! (($c = ($id - $id % 100) / 100 + $a - $b - 5) % ($d = $a * $b * 3))) {
		$base = $c / $d;
	}
	
	return $base;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	基礎BE番号->BEID取得
#	-------------------------------------------------------------------------------------
#	@param	$base	基礎BE番号
#	@return	BEID配列
#
#------------------------------------------------------------------------------------------------------------
sub BASE2ID
{
	
	my ($base) = @_;
	my @id = ();
	
	for my $a (1 .. 9) {
		for my $b (1 .. 9) {
			push @id, ($base * $a * $b * 3 - $a + $b + 5) * 100 + $a * 10 + $b;
		}
	}
	
	return sort { $a <=> $b } @id;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	なんちゃってbbs.cgiエラーページ表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$err	エラー番号
#	@return	なし
#	exit	エラー番号
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSError
{
	my ($Sys,$Form,$err) = @_;
	my $CGI;
	
	require('./module/radagast.pl');
	require('./module/isildur.pl');
	require('./module/thorin.pl');
	
	$CGI->{'SYS'}		= $Sys;
	$CGI->{'FORM'}		= $Form;
	$CGI->{'COOKIE'}	= RADAGAST->new;
	$CGI->{'COOKIE'}->Init();
	$CGI->{'SET'}		= ISILDUR->new;
	$CGI->{'SET'}->Load($Sys);
	my $Page = THORIN->new;
	
	require('./module/orald.pl');
	$ERROR = ORALD->new;
	$ERROR->Load($Sys);
	
	$ERROR->Print($CGI,$Page,$err,$Sys->Get('AGENT'));
	
	$Page->Flush('',0,0);
	
	exit($err);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
__END__
=pod
# 890〜 BEシステムエラー系
890<>Be情報取得失敗<>Beユーザー情報の取得に失敗しました。
890<>Beログイン失敗<>Beログインに失敗しました。
891<>Beログイン必須<><a href="http://be.2ch.net/">be.2ch.net</a>でログインしてないと書けません。
892<>BE_TYPE2規制<>Beログインしてください(t)。<a href="http://be.2ch.net/">be.2ch.net</a>
=cut

