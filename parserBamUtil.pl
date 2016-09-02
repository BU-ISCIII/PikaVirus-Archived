#!/usr/bin/perl -w

## Parser info Pre y post filter Duplicates

#########
## VAR ##
#########

@files=@ARGV; 

%info=();

foreach $file(@files){
	if($file=~/.*txt$/){
			print "$file\n";
			fields($file,\%info);	
	}
}

# foreach $key(keys %infoPreDup){
# 	foreach $key2(keys $infoPreDup{$key}){
# 	print "$key -> $key2 -> $infoPreDup{$key}{$key2} \n";
# 	}
# }

print "<table class='tables'>
		 			<tr>
		 				<td class='sample'>Sample</td>";

@keys=keys(%info);
@keys=sort(@keys);
$len=scalar(@keys);

foreach $key(@keys){
	print "<td class='sample'>$key</td>";
}

print "</tr><tr><td colspan='",$len+1,"' class='filter'>Alignment stats</td></tr>";
table(\%info,\@keys);

print "</table>";

exit;

sub table{
	$info=$_[0];
	$keys=$_[1];

	$key = $$keys[0];

	@stats = keys %{$$info{$key}};

	foreach $key2(@stats){
	 	print "<tr>
	 	 		<td>$key2</td>";
	 	foreach $key3(@keys){
	 		print "<td>$$info{$key3}{$key2}</td>";
	 	}
	 print "</tr>";
	 }
}

sub fields{
	$file=$_[0];
	$info=$_[1];
	$i = 0;

	open (IN,$file);
	if($file=~/(.*)\.bamstat\.txt/){
		$sample=$1;
	}
	while(<IN>){
		$line=$_;
		if($line=~/^TotalReads.*(e6).*/ ||
			$line=~/^MappedReads.*(e6).*/ ||
			$line=~/^PairedReads.*(e6).*/ ||
			$line=~/^ProperPair.*(e6).*/ ||
			$line=~/^DuplicateReads.*(e6).*/ ||
			$line=~/^QCFailureReads.*(e6).*/ ||
			$line=~/^MappingRate.*(%).*/ ||
			$line=~/^PairedReads.*(%).*/ ||
			$line=~/^ProperPair.*(%).*/ ||
			$line=~/^DupRate.*(%).*/ ||
			$line=~/^TotalBases.*(e6).*/ ||
			$line=~/^BasesInMappedReads.*(e6).*/
		){
		
		@field=split("\t",$line);
		$$info{$sample}{$field[0]}=$field[1];	
		}

		if($line=~/^\d/){
			$i++;
			if($i==1){
				@line=split("\t",$line);
				$rounded = sprintf "%.2f", $line[12];
				$$info{$sample}{"Depth"}=$rounded;
			}
			if($i==2){
				@line=split("\t",$line);
				$rounded = sprintf "%.2f", $line[12];
				$$info{$sample}{"Depth Desviation"}=$rounded;
			}
		}
	}
	close IN;
}

