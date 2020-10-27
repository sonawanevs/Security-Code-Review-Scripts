use File::Find;

my @file_path,@fname;


print "\n Enter filter name: ";
my $in=<STDIN>;
$in=chomp($in);

##### Find all java files from the Codebase Root #####
find(\&filter, "p:/web/");

sub filter 
{
	if(($_ =~ /\.asp$/i) || ($_ =~ /\.aspx\.vb$/i))
	{
		#print "$_\n";
		push @file_path,$File::Find::name;
		push @fname,$_;
	}
}


####### For each java file, search for dynamic SQL variables  #######
for(my $i=0;$i<=$#file_path;$i++)
{
	#File path and file name passed to find_unescaped_dynamic_variables subroutine
	&find_unescaped_dynamic_variables($file_path[$i],$fname[$i]); 
}


###### Subroutine to locate and extract dynamic SQL variables, and confirm  #######
###### whether escapeSQL procedure is applied on these variables or not     #######

sub find_unescaped_dynamic_variables
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
	
	# Identify and extract dynamic sql variables after scanning each line of the java file
	foreach $l(@buf)
	{
		$m="";
		if($l=~/'\s*"\s*\&\s*(\d+|\w+|_)*\s*\&\s*"\s*/g)	#Regex for dynamic variable pattern
		{							#Store dynamic variables in @var array
			$n=$l;
			@a=($n=~/('\s*"\s*\&\s*(\d+|\w+|_)*\s*\&\s*"\s*)/g);
			#print $#a;
			if($#a==1)
			{
				$var[$ind]=$a[1];					
				$fline[$ind]=$line;
				$ind++;
			}
			else
			{
				for($j=1;$j<=$#a;$j+=2)
				{
					$var[$ind]=$a[$j];
					$fline[$ind]=$line;
					$ind++;
				}
			}			
		}
		$line++;
	}

	#if($#var>=0)
	#{
	#	$res="";
	#	for (my $i=0;$i<=$#var;$i++)
	#	{
	#		#For each dynamic variable, confirm whether escapeSQL procedure is called
	#		#Output the file name, variable and line number, if escapeSQL procedure is not called
	#		print "$name,$var[$i],$fline[$i]\n";
	#	}
	#}
	
	if($#var>=0)
	{
		$res="";
		for (my $i=0;$i<=$#var;$i++)
		{
			my $f=-1;
			
			#For each dynamic variable, confirm whether escapeSQL procedure is called
			$f=&Is_Escape_SQL_Called($var[$i],\@buf); 
			if($f!=1)
			{
				#Output the file name, variable and line number, if escapeSQL procedure is not called
				print "$name|$var[$i]|$fline[$i]\n";
			}
		}
	}
}


sub Is_Escape_SQL_Called
{

	my ($par,$buf1)=@_;
	my @buf=@{$buf1};
	$flag=0;
	foreach $l(@buf)
	{
		if($l=~/$in/i && $l=~/$par/)
		{
			$flag=1;
			last;
		}
	}
	return $flag;
}

