use Data::Dumper;
use File::Find;

my @file_path,@fname,@file_path_cb,@fname_cb,@control_id_name, %pg_req, %pg_query, %pg_idname;

##### Find all aspx and aspx.vb files from the Codebase Root #####
find(\&filter, "c:/wma/frontend/241208/outlookbar");

sub filter 
{
	if($_ =~ /\.aspx$/i) 
	{
		push @file_path,$File::Find::name;
		push @fname,$_;
	}
	if($_ =~ /\.aspx\.vb$/i) 
	{
		push @file_path_cb,$File::Find::name;
		push @fname_cb,$_;
	}
}


####### For each program file, search create list of IDs and names of web controls and HTML Server Controls  #######
for(my $i=0;$i<=$#file_path;$i++)
{
	#File path and file name passed to find web and HTML server control ID and names
	my @a=&find_control_IDs($file_path[$i],$fname[$i]); 
	$pg_idname{$fname[$i]}=[@a];

	#File path and file name passed to find parameter in Request's NameValueCollection
	my @b=&find_Request_Params($file_path[$i],$fname[$i]); 
	if($#b!=-1)
	{
	#print "$fname[$i]\n";
	$pg_req{$fname[$i]}=[@b];
	}
}


####### For each Form Post look in the code behind file, find parameters in Request's NameValueCollection   #######
for(my $i=0;$i<=$#file_path_cb;$i++)
{

	my @b=&find_Request_Params($file_path_cb[$i],$fname_cb[$i]); 
	if($#b!=-1)
	{
	#print "$fname_cb[$i]\n";
	$pg_req{$fname_cb[$i]}=[@b];
	}
}

print Dumper(\%pg_query);

########## For each parameter request in the form, see whether it matches any control in the form fields #########

foreach $k1(%pg_req)
{
	$l1=$k1;
	$l1=~s/\..*//g;
	my $p1=$pg_req{$k1};
	my @p2=@{$p1};
	#print "\n$k1";
	foreach $k2(%pg_idname)
	{
		$l2=$k2;
		$l2=~s/\..*//g;
		if($l1 eq $l2)
		{
		my $q1=$pg_idname{$k2};
		#print "\n$q1";
		my @q2=@{$q1};
			foreach my $pr(@p2)
			{
				my @s1=split(/\|/,$pr);
				my $val, $fl=0;
				#print "\n$s1[0] --  $q2[0] -- $k2 -- $l1 --- $l2";
				foreach my $qr(@q2)
				{
					if($k1=~/sendquotation/i)
					{
					print "\n $s1[0] -- $qr -- $k1 --  $k2";
					if($s1[0]=~/^$qr$/i)
					{
						$fl=1;
						last;
					}
					}
				}
				if($fl==0)
				{
					print "\nPotential backdoor variable: $s1[0], file: $k1, line number: $s1[1]\n";
				}
			}
		}
	}
}


sub find_control_IDs
{
	my ($fn,$name)=@_;	#File path and file name are received in $fn and $name variables respectively
	#$fn="c:/wma/frontend/241208/outlookbar/packagedetails.aspx";
	#$name="packagedetails.aspx";
	open f, $fn or die "Cannot open $fn file";
	my (@buf);

	# Store the program file in @buf array
	while(<f>)
	{
		push @buf,$_;	
	}

	my (@var,@fline, $ind, $mw, @ctrl_id_name);
	@ctrl_id_name=();
	@fline=();
	@var=();
	$ind=0;
	$line=0;
	$flag=0;
	
	# Identify and extract name and ID attributes of individual web and HTML Server Control
	foreach $l(@buf)
	{
		$mw=$l;
		$nw=$l;
		$pw=$l;
		$ind++;
		#Following Regex will capture all such patterns: <asp:DropDownList ID="NoofPax" runat="server"> and extract control id and name 
		if($mw=~/<input.*name\s*=\s*"(.*?)"/i)
		{
			$y=$1;
			my $x=$1;
			if($x!~/%=/)
			{
			push @ctrl_id_name, $y;
			}
		}
		if($nw=~/<input\s*.*id\s*=\s*"(.*?)"/i)
		{
			my $y=$1;
			my $x=$1;
			if($x!~/%=/)
			{
			push @ctl_id_name, $y;
			}
		}
		if($pw=~/<asp:\s*.*id\s*=\s*"(.*?)"/i)
		{
			$x=$1;
			push @ctrl_id_name, $x;
		}
	}
	if($#ctrl_id_name==-1)
	{
	#print $name;
	}
	return @ctrl_id_name;	
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
		#Following Regex will capture all such patterns: Request.Form("packageid") and extract the parameter name (packageid)
		$ind++;
		$m=$l;
		if($m!~/querystring/i)
		{
			if($l=~/request\..*[\(|\[]"(.*)"[\)|\]]/i)
			{
				#print "\n$1  --  $l\n";
				$y=$1;
				my $x=$1;
				if($x!~/%=/||$x!~/&/||$x!~/\./)
				{
				my $v1=$y."|$ind";
				#print "\n$v1";
				push @req, $v1;
				}
			}
		}
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
	return @req;
}

