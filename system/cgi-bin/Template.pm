package Template;

use Search;

sub new{
######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'list'} =	[];
	$self->{'header'} =	[];
	$self->{'footer'} =	[];
	$self->{'data'} =	undef;
	$self->{'fields'} = 	{};
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub header{
	my $self = shift;
	my $title = shift;
	
	my $template = join( "\n", @{$self->{'header'}} );
	
	$template =~ s/<title\s*\/>/<title>$title<\/title>/gi;
	
	return $template;
}
sub footer{
	my $self = shift;
	return join( "\n", @{$self->{'footer'}} );
}
sub load{

# print STDERR "load args: "  . join( ' / ', @_ ) . "!\n";

	my $proto = shift;
	my $header = shift;
	my $footer = shift;
	my @list = @_;
	
	# replace '<' '>' '"' and '''
	my $dirtyHeader = templateCharacters( join("\n",@{$header}) );
	my $dirtyFooter = templateCharacters( join("\n",@{$footer}) );
	my $dirtyList = templateCharacters( join("\n",@list) );

	my $self = $proto->new();
	@{ $self->{'header'} }= split( "\n", $dirtyHeader );
	@{ $self->{'footer'} }= split( "\n", $dirtyFooter );
	@{ $self->{'list'} } = split( "\n", $dirtyList );
	
	return $self;
}
sub mergeReferences{
	my $self = shift;
	my $string = shift;
	my $browser = shift;
	my $conf = shift;
	
	my @references;

#warn "caller: " . join( ' - ', caller );
#warn "browser: " . $browser;
#warn "conf: " . $conf;

	foreach $category ( $self->{'data'}->referenceCategories() ){
	
		# get reference template
		my $t = $conf->template( $browser, "reference", $category );

#warn "reference template: $t";		
#warn "category: $category";
		
		# if template exists, merge references
		if( $t =~ /\S+/ && $t >= 0 ){
		
			my $tempString = $string;
		
			# replace category data fields
			$tempString =~ s/<data\s+field\s*=\s*["']category["']\s*\/>/$category/gi;
		
			# merge contents of <reference> tags
			$tempString =~ s/<reference\s*>(.*)<\/reference\s*>/$self->mergeLinks($category,$1,$t)/sie;
		
			push( @references, $tempString )
		}
	}
	
	return join( "\n", @references );
}
sub mergeLinks{
	my $self = shift;
	my $category = shift;
	my $string = shift;
	my $t = shift;
	
#warn "reference template: $t";
#warn join( ' / ', @{$t->{'list'}} );
	my @links;
	
	# sort referrer numbers
	my %referrers = %{$self->{'data'}->references($category)};
	my @numbers = keys( %referrers );
	$referrers{$numbers[0]}->category()->sortNumbers( \@numbers );
	
	foreach my $number ( @numbers ){
	
		my $tempString = $string;
				
		# merge record with template
		my $reference = join( "\n", $t->merge($referrers{$number}) );
		
		# replace reference data fields
		$tempString =~ s/<data\s+field\s*=\s*["']reference["']\s*\/>/$reference/gie;
				
		push( @links, $tempString )
	}
	
	return join( "\n", @links );
}

sub merge{
	my $self = shift;
	my $data = shift;
	my $browser = shift; # for reference templates
	my $conf = shift; # for reference templates

#warn "caller: " . join( ' - ', caller );
#warn "merging data: $data with $self";
# print STDERR "list: " . join( ' / ', @{$self->{'list'}} ) . "!\n";

######### load data object (must have 'field' method)
	$self->{'data'} = $data;
	
######### merge template and data
	my $merge = join( "\n", @{$self->{'list'}} );
		
	# everything from a '#' to the end of a line is a comment -- remove
	$merge =~ s/^\s*#.*$//gm;
	
######### test '<if field="field">contents</if>' tags and remove contents if they fail

	# match the last opening if tag
	while ( $merge =~ /(.*)<if\s+(field\s*=\s*["'][^"']+["'])\s*>/is ){
		my $before = $1;
		my $after = $';
		my $field = $2;
		
		# match the first closing if tag after the last opening one
		if( $after =~ /<\/if\s*>/is ){
			my $inside = $`;
			my $outside = $';
			if( $self->_field( $field ) >= 0 && $self->_field( $field ) =~ /\S+/ ){
			# print STDERR "<p>with: " . $before . $` . $' . "</p>\n";
				$merge = $before . $inside . $outside;
			} else {
				# print STDERR "<p>without: " . $before . $' . "</p>\n";
				$merge = $before . $outside;
			}
		} else {
			warn "no closing tag for '<if field=\"$field\">'";
			$merge = $before . $after;
		}
	}

	# replace '<references> />' tags with references
	$merge =~ s/<reference_category\s*>(.*)<\/reference_category\s*>/$self->mergeReferences($1,$browser,$conf)/sie;

	# replace '<data field="field" />' tags with values
	$merge =~ s/<data\s+([^<>]*)\/>/$self->_field( $1 )/gie;
	
	# replace '<header title="title" />' tag with header			
	$merge =~ s/<header\s+title\s*=\s*["']([^"']+)["']\s*\/>/$self->header($1)/ie;
		
	# replace '<footer />' tag with footer
	$merge =~ s/<footer\s*\/>/$self->footer()/ie;

	# replace '<search />' tags with search form
	$merge =~ s/<search\s*\/>/Search->form()/ie;
			
######### return template merged with data
	return split( /\n/, $merge );
}

sub mergeIndex{
	my $self = shift;
	my $category = shift;
	
	my $templateString = join( "\n", @{$self->{'list'}} );
	my @page;
	my @record;
	my @subcategory;
	
######### strip contents of '<record>' tags from page template and replace with '<record />'
	if( $templateString =~ /<record\s*>(.*)<\/record\s*>/si ){
		@page = split( /\n/, $`.'<record />'.$' );
		@record = split( /\n/, $1 );
#warn "record: " . join( "\n", @record );
#warn "page without record: " . join( "\n", @page );
	} else {
		warn "no record template for index merge";
		@page = @{ $self->{'list'} };
	}
	
	my $noRecordString = join( "\n", @page );
######### strip contents of '<subcategory>' tags from page template and replace with '<subcategory />'
	if( $noRecordString =~ /<subcategory\s*>(.*)<\/subcategory\s*>/si ){
		@page = split( /\n/, $`.'<subcategory />'.$' );
		@subcategory = split( /\n/, $1 );
#warn "subcategory: " . join( "\n", @subcategory );
#warn "page without subcategory: " . join( "\n", @page );
	}
	
######### get new template for page and merge it without data
	my $page = $self->load( $self->{'header'}, $self->{'footer'}, @page );
	my $pageString = join( "\n", $page->merge() );
	
#warn "merged page: " . $pageString;

######### get new template for subcategory
	my $subcategory = $self->load( $self->{'header'}, $self->{'footer'}, @subcategory );

######### merge records

	# load record template
	my $record = $self->load( $self->{'header'}, $self->{'footer'}, @record );
	
	# if there is a subcategory tag
	if( $pageString =~ /<subcategory\s*\/>/ ){
# warn "merging " . $category->title() . " subcategories with page";
		my $before = $`;
		my $after = $';
		
		# merge records for each subcategory
		my @subStrings;
		foreach my $sub ( $category->sortedSubcategories() ){
			
			# load fields with subcategory unless it is default
			if( $sub ne "default" ){
				$self->{'fields'}->{'subcategory'} = $sub;
			}
			
			# merge subcategory records
			my @sub;
			foreach my $number ( $category->subcategory($sub) ){
				push( @sub, $record->merge($category->record($number)) );
			}
			
			# merge subcategory template with self
			my $subString = join( "\n", $subcategory->merge($self) );
			
			if( $subString =~ /<record\s*\/>/ ){
		
				# add records to merged subcategory template
				$subString = $` . join( "\n", @sub ) . $';
				push( @subStrings, $subString );
			} else {
				warn "subcategory template but no record template for index merge: " . $subString;
			}	

			# reset fields
			$self->{'fields'} = {};
		}
		
		# replace '<subcategory />' with subcategory strings
		$pageString = $before . join( "\n", @subStrings ) . $after;

	# no subcategory tag but record tag
	} elsif( $pageString =~ /<record\s*\/>/ ){
		my $before = $`;
		my $after = $';
	
		# merge uncategorized records
		my @default;
		foreach my $data ( $category->subcategory("default") ){
			push( @default, $record->merge($data) );
		}

		$pageString = $before . join( "\n", @default ) . $after;
	} else {
		warn "no subcategory or record template for index merge";
	}
	
######### return template merged with category
	return split( /\n/, $pageString );
}

sub field{
	my $self = shift;
	my $field = shift;
	return $self->{'fields'}->{$field};
}

sub _field{
	my $self = shift;
	my $attributes = shift;
	
	# strip fields from attributes
	my @fields;
	if( $attributes =~ /field\s*=\s*["']([^"']+)["']/sgi ){
		@fields = split( /\./, $1 );
	}
	
	# strip length from attributes
	my $length = -1;
	if( $attributes =~ /length\s*=\s*["']([^"']+)["']/sgi ){
		$length = $1;
	}

#warn "caller: " . join( ' - ', caller );
	if( $self->{'data'} ){
		my $field = $self->{'data'}->field( @fields );
		
		if( $length >= 0 ){
		
			# remove newlines
			$field =~ s/\s*\n\s*/ /sg;
			
			# remove tags
			$field =~ s/\s*<[^>]*>\s*/ /sg;
			
			# trim to length
			if( $field =~ /(.{$length}).+/ ){
				$field = "$1...";
			}
			
			return $field;
		} else {
			return pureHTML( $field );
		}
	}
	warn "no data for field: " . join( '.', @fields );
	return "";
}
sub pureHTML{
	my $string = shift;
	
	$string =~ s/\n/<br \/>\n/gs;
	
	return $string;
}
sub templateCharacters{
	my $string = shift;
	
	$string =~ s/&#39;/'/gs;
	$string =~ s/&quot;/"/gs;
	$string =~ s/&lt;/</gs;
	$string =~ s/&gt;/>/gs;
	
	return $string;
}
1;
