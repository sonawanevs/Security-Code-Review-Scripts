use File::Find;
use Data::Dumper;

my @file_path,@fname;
my %back1;

##### Find all .aspx and .aspx.vb from the Codebase Root #####
find(\&filter, "c:/wma/useradminmasterscode");

sub filter 
{
	if(($_ =~ /\.aspx$/i) || ($_ =~ /\.aspx\.vb$/i)|| ($_ =~ /\.aspx\.cs$/i))
	{
		#print "$_\n";
		push @file_path,$File::Find::name;
		push @fname,$_;
	}
}


####### For each .aspx/.aspx.vb file, search for calls to other program files  #######
for(my $i=0;$i<=$#file_path;$i++)
{
	#File path and file name passed to find all the calls to other .aspx/.aspx.vb files originating from this file
	&backdoor_hash($file_path[$i],$fname[$i]); 
}

#print $#fname;
#exit;

#$x=&find_b('main1.aspx');
#print "\n\n\$x = $x";

#### for each file in the codebase find out whether its part of the child files  ############
#### if its not, then its a possible backdoor                                    ############

foreach my $v1(@fname)
{
	#print "$v1 ---  ";
	my $m2=&find_b($v1);
	if($m2==0)
	{
		print "$v1\n";
	}
}


###### Subroutine to locate and extract calls to other program files  #######

sub backdoor_hash
{
	my ($fn,$name)=@_;	#File path and file name are received in $fn and $name variables respectively
	open f, $fn or die "Cannot open $fn file";
	my (@buf);

	# Store the java file @buf array
	while(<f>)
	{
		push @buf,$_;	
	}

	my (@var,@fline, $ind);
	@fline=();
	@var=();
	$ind=0;
	$line=0;
	$flag=0;
	
	# Identify and extract file name originating from currentfile after scanning each line of the .aspx|.aspx.vb file
	# Thus create index of each child file originating from the parent file

	foreach $l(@buf)
	{
		my $mw=$l;

		if(($l =~ /(\w+\.aspx)/i) || ($l =~ /(\w+\.aspx\.vb)/i))
		{
			if($1 ne $name)
			{
				$var[$ind]=$1;					
				$fline[$ind]=$line;
				$ind++;
				#print "$1, ";
				$flag=1;
			}
		}
	}

	if($flag==1)
	{
		$back1{$name}=[@var];
	}
	
}


#print Dumper(\%back1);

sub find_b
{
	my ($p1)=@_;
	#print "$p1\n";
	my $flag=0;

	######## Calls to other files can originate from .aspx and the code behind file as well #######
	######## But there won't be any direct call to the code behind fall. The fname array    #######
	######## Contains both asp and code behind file. Therefore when we scan a code behind   #######
	######## file to check if its linked from any other file, it won't succeed. Possible    #######
	######## would be that the corresponding aspx file would be called. Therefore, we need  #######
	######## to strip off the code behind extension - .vb .cs - before starting the search. #######


	if($p1=~/\.vb$/)
	{
		$p1=~s/\.vb$//;
	}
	
	if($p1=~/\.cs$/)
	{
		$p1=~s/\.cs$//;
	}
	######## Loop through
	
	foreach my $l1(keys %back1)
	{
		$f1=0;
		my $e1=$back1{$l1};
		my @e2=@{$e1};
		#print "$l1\t@e2";
		#last;
		foreach $c1(@e2)
		{
			if($p1=~/^$c1$/i)
			{
				$flag=1;
				$f1=1;
				last;
			}
		}
		if($f1==1)
		{
			#print "$p1, $l1, @e2\n\n";
			#print "\n\$flag=$flag";
			#last;
		}
	}
	return $flag;
}