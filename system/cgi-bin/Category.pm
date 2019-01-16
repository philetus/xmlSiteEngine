package Category;

use XmlFile;

######
###### returns new Category object
######
sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'subcategories'} =	{};
	$self->{'title'} =		undef;
	$self->{'site'} =		undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}
sub subcategories{
	my $self = shift;
	return keys( %{$self->{'subcategories'}} );
}
sub subcategory{
	my $self = shift;
	my $subcategory = shift;
	return @{ $self->{'subcategories'}->{$subcategory} };
}
sub numbers{
	my $self = shift;
	my @numbers;
	foreach $subcategory ( keys(%{$self->{'subcategories'}}) ){
		push( @numbers, @{$self->{'subcategories'}->{$subcategory}} );
	}
	return @numbers;
}
sub record{
	my $self = shift;
	my $number = shift;
	return $self->{'site'}->record( $number );
}
sub title{
	my $self = shift;
	return $self->{'title'};
}
sub addRecord{
	my $self = shift;
	my $record = shift;

# print STDERR "adding record number " . $record->number() . " to Category!\n";	
	# add record to site
	$self->{'site'}->addRecord( $record );
	
	# add record to appropriate subcategory
	if( $record->subcategory() =~ /(\S+.*\S+)/ ){
		push( @{$self->{'subcategories'}->{$1}}, $record->number() );
	} else {
		push( @{$self->{'subcategories'}->{'default'}}, $record->number() );
	}
}
######
###### takes Site object and name string and loads matching records into Category object
######
sub load{
#warn "caller: " . join( ' - ', caller() );
	my $proto = shift;
	my $site = shift;
	my $category = shift;
	
######### get new Category object to fill
	my $self = $proto->new();

######### set site
	$self->{'site'} = $site;

######### set title
	$self->{'title'} = $category;

######### load records from XmlFile
	XmlFile->loadCategory( $self, $category );

######### return new Category object
	return $self;
}
sub loadRecord{
#warn "loading record";
#warn "loadRecord caller: " . join( ' - ', caller );
	my $proto = shift;
	my $self = $proto->new();
	$self->{'title'} = shift;
	my $number = shift;
#warn "title: " . $self->{'title'};
#warn "number: " . $number;
	return XmlFile->loadRecord( $self, $number );
}
sub loadDtd{
#warn "loading dtd";
	my $proto = shift;
	my $self = $proto->new();
	$self->{'title'} = shift;
#warn "self: " . $self;
#warn "title: " . $self->{'title'};	
	return XmlFile->loadDtd( $self );
}
######
###### sort each subcategory 
######
sub sortSubs{
	my $self = shift;
	
#warn "site: " . $self->{'site'};
#warn "title: " . $self->{'title'};

	my $field = $self->{'site'}->conf()->category( $self->{'title'} )->field( 'sort', 'field' );
	my $type = $self->{'site'}->conf()->category( $self->{'title'} )->field( 'sort', 'type' );
	my $direction = $self->{'site'}->conf()->category( $self->{'title'} )->field( 'sort', 'direction' );

#warn "sort - field: $field, direction: $direction, type: $type";	

	# check field value and split
	if( $field < 0 ){
		warn "no sort field for category " . $self->{'title'};
		return -1;
	}
	my @fields = split( /\./, $field );
	
	foreach my $subcategory ( keys(%{$self->{'subcategories'}}) ){


		# sort type -- by date (mm.dd.yyyy) or compare
		if( $type eq 'date' ){
			$self->sortDate( $self->{'subcategories'}->{$subcategory}, $direction, @fields );
		} elsif( $type eq 'last' ){
			$self->sortLast( $self->{'subcategories'}->{$subcategory}, $direction, @fields );
		} else {
			$self->sortCmp( $self->{'subcategories'}->{$subcategory}, $direction, @fields );		
		}
	}
	return 1;
}
# sort a list of records alphabetically by last whitespace-delimeted string
sub sortLast{
	my $self = shift;
	my $list = shift;
	my $direction = shift;
	my @fields = @_;

#warn "list before cmp: " . join( ', ', @{$list} );

	# loop through matches until they are sorted
	my $sorted = "false";
	while( $sorted eq "false" ){
		$sorted = "true";
		for( my $i = 0; $i < $#{ $list }; $i++ ){
			
			# get last whitespace-delimeted string
			my $fieldA;
			if( $self->{'site'}->record( $list->[$i] )->field( @fields ) =~ /(\S+)\s*$/ ){
				$fieldA = $1;
			}
			my $fieldB;
			if( $self->{'site'}->record( $list->[$i+1] )->field( @fields ) =~ /(\S+)\s*$/ ){
				$fieldB = $1;
			}
# warn "comparing $fieldA and $fieldB";					
			# compare fieldA and fieldB and switch them if fieldB should be first
			if( ($direction >= 0 && $fieldA gt $fieldB) || 
			    ($direction < 0 && $fieldA lt $fieldB) ){
				my $temp = $list->[$i];
				$list->[$i] = $list->[$i+1];
				$list->[$i+1] = $temp;
				$sorted = "false";
			}
		}
	}
#warn "list after cmp: " . join( ', ', @{$list} );

}# sort a list of records alpabetically or numerically
sub sortCmp{
	my $self = shift;
	my $list = shift;
	my $direction = shift;
	my @fields = @_;

#warn "list before cmp: " . join( ', ', @{$list} );

	# loop through matches until they are sorted
	my $sorted = "false";
	while( $sorted eq "false" ){
		$sorted = "true";
		for( my $i = 0; $i < $#{ $list }; $i++ ){
			my $fieldA = $self->{'site'}->record( $list->[$i] )->field( @fields );
			my $fieldB = $self->{'site'}->record( $list->[$i+1] )->field( @fields );
# warn "comparing $fieldA and $fieldB";					
			# compare fieldA and fieldB and switch them if fieldB should be first
			if( ($direction >= 0 && $fieldA gt $fieldB) || 
			    ($direction < 0 && $fieldA lt $fieldB) ){
				my $temp = $list->[$i];
				$list->[$i] = $list->[$i+1];
				$list->[$i+1] = $temp;
				$sorted = "false";
			}
		}
	}
#warn "list after cmp: " . join( ', ', @{$list} );

}
# sort a list of records by a tag with month(mm), day(dd), and year(yyyy) fields
sub sortDate{
	my $self = shift;
	my $list = shift;
	my $direction = shift;
	my @fields = @_;
#warn "list before date: " . join( ', ', @{$list} );

	# loop through matches until they are sorted
	my $sorted = "false";
	while( $sorted eq "false" ){
		$sorted = "true";
		for( my $i = 0; $i < $#{ $list }; $i++ ){
			my $dateA = getSortDate( $self->{'site'}->record( $list->[$i] ), @fields );
			my $dateB = getSortDate( $self->{'site'}->record( $list->[$i+1] ), @fields );
#warn "comparing $dateA and $dateB";					
			# compare dateA and dateB and switch them if dateB should be first
			if( ($direction >= 0 && $dateB > $dateA) ||
			    ($direction < 0 && $dateB < $dateA) ){
				my $temp = $list->[$i];
				$list->[$i] = $list->[$i+1];
				$list->[$i+1] = $temp;
				$sorted = "false";
			}
		}
	}
#warn "list after date: " . join( ', ', @{$list} );
}
# squish month.day.year format into one number to be compared with other dates,
#   i.e. 6.27.2001 becomes 20,010,627
sub getSortDate{
	my( $record, @fields ) = @_;
#warn "squish fields" . join( ' & ', @fields );
#warn "squishing " . join( '.', $record->field(@fields,'month'), $record->field(@fields,'day'), $record->field(@fields,'year') );
	return ( 10000 * $record->field(@fields,'year') ) +
	       ( 100 * $record->field(@fields,'month') ) +
	       $record->field(@fields,'day');
}
sub sortedSubcategories{
	my $self = shift;

#warn "sorting subcategories";
	
	my @subcategories = keys( %{$self->{'subcategories'}} );
	
	# only sort more than one subcategory
	if( $#subcategories < 1 ){
		return @subcategories;
	}
	
	# rank subcategories
	my @rankings;
	foreach my $sub ( @subcategories ){
		push( @rankings, $self->rankSubcategory($sub) );
	}

#warn "subcategories: " . join( ' & ', @subcategories );
#warn "rankings: " . join( ' & ', @rankings );

	my $sorted = "false";
	while( $sorted eq "false" ){
		$sorted = "true";
		for( my $i = 0; $i < $#subcategories; $i++ ){
			
			# switch subs if first sub's rank is higher
			if( $rankings[$i] > $rankings[$i+1] ){
				my $tempSub = $subcategories[$i];
				my $tempRank = $rankings[$i];
				$subcategories[$i] = $subcategories[$i+1];
				$rankings[$i] = $rankings[$i+1];
				$subcategories[$i+1] = $tempSub;
				$rankings[$i+1] = $tempRank;
				
				# now they could be unsorted
				$sorted = "false";
			}
		}
	}
	return @subcategories;
}
sub rankSubcategory{
	my $self = shift;
	my $subcategory = shift;
	
	my $score = 0;
	my $votes = 0;
	
	foreach my $number ( $self->subcategory($subcategory) ){
		if( $self->{'site'}->record($number)->field( 'subcategory', 'rank' ) > 0 ){
			$score += $self->{'site'}->record($number)->field( 'subcategory', 'rank' );
			$votes++;
		}
	}
	if( $votes < 1 ){
		return 0;
	}
	return $score / $votes;
}

sub sortNumbers{
	my $self = shift;
	my $numbers = shift;
	
######### sort numbers
	
	# get sort field, type and direction
	my $field = $self->{'site'}->conf()->category( $self->{'title'} )->field( 'sort', 'field' );
	my $type = $self->{'site'}->conf()->category( $self->{'title'} )->field( 'sort', 'type' );
	my $direction = $self->{'site'}->conf()->category( $self->{'title'} )->field( 'sort', 'direction' );


	# check field value and split
	if( $field < 0 ){
		warn "no sort field for category " . $self->{'title'};
		return -1;
	}
	my @fields = split( /\./, $field );
	
	# sort type -- by date (mm.dd.yyyy) or compare
	if( $type eq 'date' ){
		$self->sortDate( $numbers, $direction, @fields );
	} elsif( $type eq 'last' ){
		$self->sortLast( $numbers, $direction, @fields );
	} else {
		$self->sortCmp( $numbers, $direction, @fields );		
	}
	
	return 1;
}

1;

