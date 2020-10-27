use Data::Dumper;
use File::Find;

my @file_path,@fname,@file_path_cb,@fname_cb,@control_id_name, %pg_req, %pg_query, %pg_idname;

##### Find all aspx and aspx.vb files from the Codebase Root #####
find(\&filter, "c:/wma/frontend/241208/outlookbar");

sub filter 
{
	if(($_ =~ /\.aspx$/i)||($_ =~ /\.aspx\.vb$/i))
	{
		push @file_path,$File::Find::name;
		push @fname,$_;
	}
}


####### Find files from where GET requests ORIGINATE. Find the DESTINATION page of these GET requests  #######
####### extract out the parameter name that is being passed in these requests                          #######

for(my $i=0;$i<=$#file_path;$i++)
{
	#File path and file name passed to Destination File of GET requests an the parameter that's passed to the Request
	&find_get_variables($file_path[$i],$fname[$i]); 
}


####### Find files that process GET requests i.e. the DESTINATION files. Find the variable names that  #######
####### are extracted out from the QUERY STRING                                                        #######

for(my $i=0;$i<=$#file_path;$i++)
{
	#File path and file name that process GET requests
	&find_Request_Params($file_path[$i],$fname[$i]); 
}


#print Dumper(\%pg_req_param);
#print Dumper(\%pg_query);
my @sa=keys %pg_query;
#print "\n@sa";
########## For each query string variable in the destination page, see whether it matches any parameter      #########
########## from any of the originating pages. If the query string variable on destination page is altogether #########
########## a different variable, then that variable is suspicious                                            #########

foreach $k1(@sa)
{
	$l1=$k1;
	$l1=~s/\.vb//g;
	my $p1=$pg_query{$k1};
	my @p2=@{$p1};
	my $p3=$pg_req_param{$l1};
	my @p4=@{$p3};
	#print "@p2";
	#print "\n$#p1";
	if($#p4==-1)
	{
		#print "\n$k1";
	}
	else
	{
	#print "\n$k1 -- @p4 -- @p2";
		foreach my $w1(@p2)
		{
			my $f1=0;
			my @b2=split(/\|/,$w1);
			foreach my $w2(@p4)
			{
				if($b2[0]=~/^$w2$/i)
				{
				$f1=1;
				last;
				}
			}
			if($f1==0)
			{
				print "\n Potential backdoor variable: $b2[0], line no. $b2[1], $k1";
			}
		}
	}
	#last;
	
}


sub find_get_variables
{
	my ($fn,$name)=@_;	#File path and file name are received in $fn and $name variables respectively
	#$fn="./as1.txt";
	#$name="as1.txt";

	open f, $fn or die "Cannot open $fn file";
	my (@buf);

	# Store the java file @buf array
	while(<f>)
	{
		push @buf,$_;	
	}

	my (@var,@fline, $ind, $mw);
	@fline=();
	@var=();
	$ind=0;
	$line=0;
	$flag=0;
	
	# Identify and extract dynamic sql variables after scanning each line of the java file
	foreach $l(@buf)
	{
		$mw=$l;
		$ind++;
		$dest;
		my @var=();
		if($l=~/\?.*=/gi)
		{
			$n=$l;
			#@a=($n=~/(<%=(.*?)%>)/g);
			#print "$l  -  $name\n";
			#if(($n=~/a href/)||($n=~/server\.transfer/i))
			if($n=~/a href/)
			{
				#print "\n";
				$m1=$n;
				my @a=split /\?/, $m1;
				#my $y1=$1;
				#push @var, $1;
				if ($a[0]=~/href\s*=\s*["|'](.*\.aspx)/)
				{
					$dest=$1;
					#print "$dest  ";
				}
				#print "$y1  ";
				my @b1=split(/&/,$a[1]);
				{
					foreach $s1(@b1)
					{
						@x0=split /=/, $s1;
						#print "$x0[0] ";
						push @var, $x0[0];
					}
				}
			#print "b: $var[3]\n";
			&fill_req_hash($dest,\@var);
			#last;
			}
			$flag=1;
			$mw=~s/\n$//;
			#print "$name, $mw, $ind\n";
		}
	}

	if($flag==1)
	{
		#print "$fn, $name, $mw\n";
	}
	
}

#print Dumper(\%pg_req_param);

sub fill_req_hash
{
	my($a,$b)=@_;
	@var=@{$b};
	#print @var;
	my @k=keys %pg_req_param;
	$fl=0;
	foreach $l(@k)
	{
		if($l=~/^$a$/i)
		{
		$fl=1;
		}
	}
	if($fl==0)
	{
		$pg_req_param{$a}=[@var];
	}
	else
	{
		$p1=$pg_req_param{$a};
		@p2=@{$p1};
		#print "\nearlier entries for $a: @p2";
		#print "\nnew entries for $a: @var";
		push @p2, @var;
		my %seen;
		$seen{$_}++ for @p2;
		my @unique = keys %seen;
		$pg_req_param{$a}=[@unique];
	}
}


sub find_Request_Params
{
	my ($fn,$name)=@_;	#File path and file name are received in $fn and $name variables respectively
	#$fn="c:/wma/frontend/241208/outlookbar/packagedetails.aspx";
	#$name="packagedetails.aspx";
	#print "\n $name";
	open f, $fn or die "Cannot open $fn file";
	my (@buf,@req,@qe);

	# Store the program file in @buf array
	while(<f>)
	{
		push @buf,$_;	
	}

	my (@var,@fline, $ind, $mw);
	@fline=();
	@var=();
	$ind=0;
	$line=0;
	$flag=0;
	
	# Identify and extract name and ID attributes of individual web and HTML Server Control
	foreach $l(@buf)
	{
		#Following Regex will capture all such patterns: Request.QueryString("packageid") and extract the parameter name (packageid)
		$ind++;
		$m=$l;
		if($m=~/querystring/i)
		{
			if($l=~/request\..*[\(|\[]"(.*)"[\)|\]]/i)
			{
				#print "\n$1  --  $l\n";
				$y=$1;
				my $x=$1;
				if($x=~/%=/||$x=~/&/||$x=~/\./)
				{
					next;
				}
				else
				{
				my $v1=$y."|$ind";
				#print "\n$v1";
				push @qe, $v1;
				}
			}
		}
	}	
	#print $#req;
	if($#qe!=-1)
	{
	$pg_query{$name}=[@qe];
	}
}


