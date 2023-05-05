#============================================================================================================
#
#	�������W���[��(BALROGS)
#
#============================================================================================================
package	BALROGS;

use strict;
#use warnings;
use Encode qw(encode decode);

#------------------------------------------------------------------------------------------------------------
#
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,
		'TYPE'		=> undef,
		'SEARCHSET'	=> undef,
		'RESULTSET'	=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$mode	0:�S����,1:BBS������,2:�X���b�h������
#	@param	$type	0:�S����,1:���O����,2:�{������
#					4:ID(���t)����
#	@param	$bbs	����BBS��($mode=1�̏ꍇ�Ɏw��)
#	@param	$thread	�����X���b�h��($mode=2�̏ꍇ�Ɏw��)
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my $this = shift;
	my ($Sys, $mode, $type, $bbs, $thread) = @_;
	
	$this->{'SYS'} = $Sys;
	$this->{'TYPE'} = $type;
	
	$this->{'SEARCHSET'} = [];
	$this->{'RESULTSET'} = [];
	my $pSearchSet = $this->{'SEARCHSET'};
	
	# �I���S����
	if ($mode == 0) {
		require './module/baggins.pl';
		require './module/nazguls.pl';
		my $BBSs = NAZGUL->new;
		
		$BBSs->Load($Sys);
		my @bbsSet = ();
		$BBSs->GetKeySet('ALL', '', \@bbsSet);
		
		my $BBSpath = $Sys->Get('BBSPATH');
		
		foreach my $bbsID (@bbsSet) {
			my $dir = $BBSs->Get('DIR', $bbsID);
			
			# �f�B���N�g����.0ch_hidden�Ƃ����t�@�C��������Γǂݔ�΂�
			next if (-e "$BBSpath/$dir/.0ch_hidden");
			
			$Sys->Set('BBS', $dir);
			my $Threads = BILBO->new;
			$Threads->Load($Sys);
			my @threadSet = ();
			$Threads->GetKeySet('ALL', '', \@threadSet);
			
			foreach my $threadID (@threadSet) {
				my $set = "$dir<>$threadID";
				push @$pSearchSet, $set;
			}
		}
	}
	# �f�����S����
	elsif ($mode == 1) {
		require './module/baggins.pl';
		my $Threads = BILBO->new;
		
		$Sys->Set('BBS', $bbs);
		$Threads->Load($Sys);
		my @threadSet = ();
		$Threads->GetKeySet('ALL', '', \@threadSet);
		
		foreach my $threadID (@threadSet) {
			my $set = "$bbs<>$threadID";
			push @$pSearchSet, $set;
		}
	}
	# �X���b�h���S����
	elsif ($mode == 2) {
		my $set = "$bbs<>$thread";
		push @$pSearchSet, $set;
	}
	# �w�肪��������
	else {
		return;
	}
	
	# dat���W���[���ǂݍ���
	if (! defined $this->{'ARAGORN'}) {
		require './module/gondor.pl';
		$this->{'ARAGORN'} = ARAGORN->new;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�������s
#	-------------------------------------------------------------------------------------
#	@param	$word	�������[�h
#	@param	$f		�O���ʃN���A�t���O
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Run
{
	my $this = shift;
	my ($word, $f) = @_;
	
	my $pSearchSet = $this->{'SEARCHSET'};
	$this->{'RESULTSET'} = [] if ($f);
	
	foreach (@$pSearchSet) {
		my ($bbs, $key) = split(/<>/, $_);
		$this->{'SYS'}->Set('BBS', $bbs);
		$this->{'SYS'}->Set('KEY', $key);
		$this->Search($word);
	}
	return $this->{'RESULTSET'};
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʎ擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���ʃZ�b�g
#
#------------------------------------------------------------------------------------------------------------
sub GetResultSet
{
	my $this = shift;
	
	return $this->{'RESULTSET'};
}

#------------------------------------------------------------------------------------------------------------
#
#	����������
#	-------------------------------------------------------------------------------------
#	@param	$word : �������[�h
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my $this = shift;
	my ($word) = @_;
	
	my $bbs = $this->{'SYS'}->Get('BBS');
	my $key = $this->{'SYS'}->Get('KEY');
	my $Path = $this->{'SYS'}->Get('BBSPATH') . "/$bbs/dat/$key.dat";
	my $ARAGORN = $this->{'ARAGORN'};
	
	my $word = decode('cp932', $word);
	
	if ($ARAGORN->Load($this->{'SYS'}, $Path, 1)) {
		my $pResultSet = $this->{'RESULTSET'};
		my $type = $this->{'TYPE'} || 0x7;
		
		# ���ׂẴ��X���Ń��[�v
		for (my $i = 0 ; $i < $ARAGORN->Size() ; $i++) {
			my $bFind = 0;
			my $pDat = $ARAGORN->Get($i);
			my $data = decode('cp932', $$pDat);
			my @elem = split(/<>/, $data, -1);
			
			# ���O����
			if ($type & 0x1) {
				if ($elem[0] =~ s/(\Q$word\E)(?![^<>]*>)/<span class="res">$1<\/span>/g) {
					$bFind = 1;
				}
			}
			# �{������
			if ($type & 0x2) {
				if ($elem[3] =~ s/(\Q$word\E)(?![^<>]*>)/<span class="res">$1<\/span>/g) {
					$bFind = 1;
				}
			}
			# ID or ���t����
			if ($type & 0x4) {
				if ($elem[2] =~ s/(\Q$word\E)(?![^<>]*>)/<span class="res">$1<\/span>/g) {
					$bFind = 1;
				}
			}
			if ($bFind) {
				my $SetStr = "$bbs<>$key<>" . ($i + 1) . '<>';
				$SetStr .= join('<>', @elem);
				$SetStr = encode('cp932', $SetStr);
				push @$pResultSet, $SetStr;
			}
		}
	}
	$ARAGORN->Close();
}

#============================================================================================================
#	Module END
#============================================================================================================
1;