#============================================================================================================
#
#	�t�@�C�����샆�[�e�B���e�B���W���[��
#
#============================================================================================================
package	FILE_UTILS;

use strict;
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	�t�@�C���R�s�[
#	-------------------------------------------------------------------------------------
#	@param	$src	�R�s�[���t�@�C���p�X
#	@param	$dst	�R�s�[��t�@�C���p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Copy
{
	my ($src, $dst) = @_;

	if (open(my $fh_s, '<', $src) && open(my $fh_d, (-f $dst ? '+<' : '>'), $dst)) {
		flock($fh_s, 2);
		flock($fh_d, 2);
		seek($fh_d, 0, 0);
		binmode($fh_s);
		binmode($fh_d);
		print $fh_d (<$fh_s>);
		truncate($fh_d, tell($fh_d));
		close($fh_s);
		close($fh_d);

		# �p�[�~�b�V�����ݒ�
		chmod((stat $src)[2], $dst);
		return 1;
	}

	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�@�C���ړ�
#	-------------------------------------------------------------------------------------
#	@param	$src	�ړ����t�@�C���p�X
#	@param	$dst	�ړ���t�@�C���p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Move
{
	my ($src, $dst) = @_;

	if (Copy($src, $dst)) {
		unlink $src;	# �R�s�[���폜
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�B���N�g���ċA�폜
#	-------------------------------------------------------------------------------------
#	@param	$path	�폜����p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DeleteDirectory
{
	my ($path) = @_;

	# �t�@�C�������擾
	my %fileList = ();
	GetFileInfoList($path, \%fileList);

	foreach my $file (keys %fileList) {
		if ($file ne '.' && $file ne '..') {
			my (undef, undef, $attr) = split(/<>/, $fileList{$file}, -1);
			if ($attr & 1) {						# �f�B���N�g���Ȃ�
				DeleteDirectory("$path/$file");		# �ċA�Ăяo��
			}
			else {									# �t�@�C���Ȃ�
				unlink "$path/$file";				# ���̂܂܍폜
			}
		}
	}
	rmdir $path;
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�@�C�����ꗗ�擾
#	-------------------------------------------------------------------------------------
#	@param	$Path	�ꗗ�擾����p�X
#	@param	$pList	�ꗗ���i�[����n�b�V���̎Q��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub GetFileInfoList
{
	my ($Path, $pList) = @_;

	my @arFiles = ();
	if (opendir(my $dh, $Path)) {
		@arFiles = readdir($dh);
		closedir($dh);
	}

	# �f�B���N�g�����̑S�t�@�C���𑖍�
	foreach my $file (@arFiles) {
		my $Full = "$Path/$file";
		my $Attr = 0;
		my $Size = -s $Full;									# �T�C�Y�擾
		my $Perm = substr(sprintf('%o', (stat $Full)[2]), -4);	# �p�[�~�b�V�����擾
		$Attr |= 1 if (-d $Full);								# �f�B���N�g���H
		$Attr |= 2 if (-T $Full);								# �e�L�X�g�t�@�C���H
		$pList->{$file} = "$Size<>$Perm<>$Attr";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�w��t�@�C���ꗗ�擾
#	-------------------------------------------------------------------------------------
#	@param	$path	�ꗗ�擾����p�X
#	@param	$pList	�ꗗ���i�[����z��̎Q��
#	@param	$opt	���o�I�v�V����(���K�\��)
#	@return	���������t�@�C����
#
#------------------------------------------------------------------------------------------------------------
sub GetFileList
{
	my ($path, $pList, $opt) = @_;

	my @files = ();
	if (opendir(my $dh, $path)) {
		@files = readdir($dh);
		closedir($dh);
	}

	my $num = 0;
	foreach my $file (@files) {
		# �f�B���N�g������Ȃ����o��������v������z��Ƀv�b�V������
		if (! -d "$path/$file") {
			if ($file =~ /$opt/) { # $opt�͐��K�\��
				push @$pList, $file;
				$num++;
			}
		}
	}
	return $num;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�B���N�g���쐬
#	-------------------------------------------------------------------------------------
#	@param	$path	�쐬����p�X
#	@param	$perm	�f�B���N�g���̃p�[�~�b�V����
#	@return	�쐬�ɐ���������1��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub CreateDirectory
{
	my ($path, $perm) = @_;

	if (! -e $path) {
		return mkdir($path, $perm);
	}
	return 0;
}

#-------------------------------------------------------------------------------------------------------------
#
#	�f�B���N�g���쐬
#	------------------------------------------------------------------
#	@param	$path	�����p�X
#	@return	�Ȃ�
#
#-------------------------------------------------------------------------------------------------------------
sub CreateFolderHierarchy
{
	my ($path, $perm) = @_;

	while (1) {
		if (-d $path) {
			return;
		}
		else {
			if (mkdir($path, $perm)) {
				return;
			}
			# �f�B���N�g���쐬���s���͍ċA�I��1���̊K�w���쐬����
			else {
				my $upath = $path;
				$upath =~ s|[\\\/][^\\\/]*$||;
				CreateFolderHierarchy($upath, $perm);
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�B���N�g������
#	-------------------------------------------------------------------------------------
#	@param	$path	��������p�X
#	@param	$pHash	�������ʊi�[�p�n�b�V��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub GetFolderHierarchy
{
	my ($path, $pHash) = @_;

	my @elements = ();
	if (opendir(my $dh, $path)) {
		@elements = readdir($dh);
		closedir($dh);
	}

	foreach my $elem (sort @elements) {
		# �f�B���N�g��������������ċA�I�ɒT������
		if (-d "$path/$elem" && $elem ne '.' && $elem ne '..') {
			my %folders = ();
			GetFolderHierarchy("$path/$elem", \%folders);
			if (scalar(keys(%folders)) > 0) {
				$pHash->{$elem} = \%folders;
			}
			else {
				$pHash->{$elem} = undef; # don't delete
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�B���N�g�����X�g�擾
#	GetFolderHierarchy�Ŏ擾�����n�b�V������f�B���N�g���ꗗ�̔z����擾����
#	-------------------------------------------------------------------------------------
#	@param	$pHash	GetFolderHierarchy�Ŏ擾�����n�b�V��
#	@param	$pList	���ʊi�[�p�z��
#	@param	$base	�x�[�X�p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub GetFolderList
{
	my ($pHash, $pList, $base) = @_;

	foreach my $key (keys %$pHash) {
		push @$pList, "$base/$key";
		if (defined $pHash->{$key}) {
			GetFolderList($pHash->{$key}, $pList, "$base/$key");
		}
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;