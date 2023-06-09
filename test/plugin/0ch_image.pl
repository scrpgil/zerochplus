#============================================================================================================
#
#	拡張機能 - 画像表示機能
#	0ch_image.pl
#	---------------------------------------------------------------------------
#	2005.02.19 start
#
#============================================================================================================
package ZPL_image;

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
	my		$this = shift;
	my		$obj={};
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
	return '画像表\示機能\';
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
	return '文章中のURLで画像のものがあればimgタグに変更します。';
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
	return (4 | 8);
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能実行インタフェイス
#	-------------------------------------------------------------------------------------
#	@param	$sys	SYS_DATA
#	@param	$form	FORMS
#	@return	正常終了の場合は0
#
#------------------------------------------------------------------------------------------------------------
sub execute
{
	my	$this = shift;
	my	($sys,$form) = @_;

	my $contents = $sys->Get('_DAT_');
	IMAGE(\($contents->[3]),$sys->Get('LIMTIME'));

	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	画像タグ変換
#	-------------------------------------------------------------------------------------
#	@param	$text	対象文字列
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub IMAGE
{
	my	($text,$limit) = @_;

	if($limit){
		$$text =~ s/(http:\/\/.*?\.jpg)/<img src="$1" width=100 height=100\/>/g;
		$$text =~ s/(http:\/\/.*?\.png)/<img src="$1" width=100 height=100\/>/g;
		$$text =~ s/(http:\/\/.*?\.gif)/<img src="$1" width=100 height=100\/>/g;
		$$text =~ s/(http:\/\/.*?\.bmp)/<img src="$1" width=100 height=100\/>/g;
	}
	else{
		$$text =~ s/<a.*?>(.*?\.jpg)<\/a>/<img src="$1" width=100 height=100\/>/g;
		$$text =~ s/<a.*?>(.*?\.png)<\/a>/<img src="$1" width=100 height=100\/>/g;
		$$text =~ s/<a.*?>(.*?\.gif)<\/a>/<img src="$1" width=100 height=100\/>/g;
		$$text =~ s/<a.*?>(.*?\.bmp)<\/a>/<img src="$1" width=100 height=100\/>/g;
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
