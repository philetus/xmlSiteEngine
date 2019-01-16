package Search;

use Conf;
use Category;
use Site;
use Template;

sub string{
	my $proto = shift;
	my $fd = shift;

warn "searching for string: " . $fd->field('string');
	
	# hash to hold matches
	
######### load site
	my $site = Site->load();
	my $conf = $site->conf();	

######### search results
	my $results = "";

######### get categories to search
	if( $fd->field('category') =~ /\S+/ ){
		my @matches = searchCategory( $fd->field('browser'), $fd->field('category'), $fd->field('string'), $site);
		if( $#matches >= 0 ){
			$results .= "<p><font size=\"+2\"><b>$category</b></font></p>";
			foreach my $match ( @matches ){
				$results .= "<ul>$match</ul>";
			}
		}
	} else {
		my @categories = $conf->categories();
		foreach my $category ( @categories ){
			my @matches = searchCategory( $fd->field('browser'), $category, $fd->field('string'), $site );
			if( $#matches >= 0 ){
				$results .= "<p><font size=\"+2\"><b>$category</b></font></p>";
				foreach my $match ( @matches ){
					$results .= "<ul>$match</ul>";
				}
			}
		}
	}
	
	# if there are no matches, say so
	if( $results !~ /\S+/ ){
		$results = "<p><b>No matches found.</b></p>";
	}
	
######### merge template
	my $template = join( "\n", $site->conf()->template( $fd->field('browser'), "search" )->merge( $fd ) );

######### replace '<results />' with search results
	$template =~ s/<results\s*\/>/$results/si;

######### print content-type
	print "Content-type: text/html\015\012\015\012";
	
######### print template
	print $template;
}

sub searchCategory{
	my $browser = shift;
	my $category = shift;
	my $string = shift;
	my $site = shift;
	
######### get template
	my $t = $site->conf()->template( $browser, "reference", $category );

	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no reference template for $category";
		
		return -1;
	}

#	# get template html
#	my $t = $site->conf()->template( $browser, "index", $category );
#	
#	my $html = join( "\n", @{$t->{'list'}} );
#	
#	if( $html =~ /<record>(.*)<\/record>/si ){
#warn "record template: $1";
#		@{$t->{'list'}} = split( /\n/, $1 );
#	}
	
######### search category records
	my @matches;
	
	# get records and sort them
	my @numbers = $site->category( $category )->numbers();
	$site->category( $category )->sortNumbers( \@numbers );
	
	foreach $number ( @numbers ){
	
		# load record
		my $r = $site->record( $number );
		
		# get match string
		my $matchString = $r->match( $string );
			
#warn "$number: $temp";

		# if this record matches, add it to list
		if( $matchString >= 0 ){
		
			# merge template
			my $merge = join( "\n", $t->merge($r) );
		
			# add to list
			push( @matches, "<li>$merge<ul><b>match:</b>$matchString</ul></li>" );
#warn "$matches[$#]";
		}
	}
	
	return @matches;
}

# search form
sub form{

	# get categories
	my $conf = Conf->load();	
	my @categories = $conf->categories();
	
	# search form
	my $form = <<END;
<form method="GET" action="../../system/cgi-bin/search.cgi">
search <select name="category">
  <option value="" label="site">site</option>
END
	
	foreach $c ( @categories ){
		$form .= <<END;
  <option value="$c" label="$c">$c</option>
END
	}
	
	$form .= <<END;
</select> for the text string: <input name="string" type="text">
&nbsp; <input type="submit" value="search">
</form>
END
	return $form;
}
1;
