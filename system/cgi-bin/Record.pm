package Record;

use Tag;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'type'} =	undef;
	$self->{'parent_tag'} =	undef;
	$self->{'xmlFile'} =	undef;
	$self->{'references'} =	{};
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub number{
	my $self = shift;
	return $self->{'parent_tag'}->field( "record_number" );
}

sub href{
	my $self = shift;
	return $self->{'parent_tag'}->field( "record_number" ) . ".html";
}

sub title{
	my $self = shift;
	return $self->{'parent_tag'}->title();
}
sub match{
	my $self = shift;
	my $match = shift;
	return $self->{'parent_tag'}->match($match);
}
sub subcategory{
	my $self = shift;
	return $self->{'parent_tag'}->field( "subcategory", "name" );
}

sub field{
	my $self = shift;
	my @fields = @_;
	
	return $self->{'parent_tag'}->field( @fields );
}

sub child{
	my $self = shift;
	my $child = shift;
	
	return $self->{'parent_tag'}->child( $child );
}

sub children{
	my $self = shift;
	return $self->{'parent_tag'}->children();
}

sub dtd{
	my $self = shift;
	return $self->{'xmlFile'}->dtd();
}

sub category{
	my $self = shift;
	return $self->{'xmlFile'}->category();
}

sub referenceCategories{
	my $self = shift;
	return keys( %{$self->{'references'}} );
}
sub references{
	my $self = shift;
	my $category = shift;
	return $self->{'references'}->{$category};
}

sub addReference{
	my $self = shift;
	my $referrer = shift;
	
	if( $referrer->number() =~ /(\D+\d+)/ ){
		my $number = $1;
		
		# check for existing reference to same record 
		foreach my $key ( keys(%{$self->{'references'}->{$referrer->category()->title()}}) ){
			
			if( $key eq $number ){
				return -1;
			}
		}
		
		$self->{'references'}->{$referrer->category()->title()}->{$referrer->number()} = $referrer;
		return 0;
	}
}
sub matchString{
	my $self = shift;
	return $self->{'parent_tag'}->matchString();
}
sub checkReference{
	my $self = shift;
	my $record = shift;
	
	my $match = $record->matchString();

#warn "match: $match";

	if( $match >= 0  && $match ne $self->matchString() ){
		foreach my $child ( $self->{'parent_tag'}->children() ){
			$self->{'parent_tag'}->child( $child )->checkReference( $record, $match );
		}
	}
}

sub parse{
	my $proto = shift;
	my $xmlFile = shift;
	my @xmlRecord = @_;

#for( my $i = 0; $i <= $#xmlRecord; $i++ ){
#	print STDERR "$i: $xmlRecord[$i]\n";
#}

######### get new Record object
	my $self = $proto->new();

######### set xmlFile
	$self->{'xmlFile'} = $xmlFile;

######### get parent field
	if( $xmlRecord[0] =~ /<(\w+)\s*([^>]*)>(.*)/ ){
		my $bump = $3;
		$self->{'type'} = $1;
		$self->{'parent_tag'} = Tag->load( $self, $1, $2 );
		_bump( \@xmlRecord, $i, $bump );

######### traverse remaining fields and add tags
		my $i = 1;
		my $tag = $self->{'parent_tag'};
	#	print STDERR "tag: $tag!\n";
		while( $i < $#xmlRecord ){
		
			# don't parse closing tag
			if( $xmlRecord[$i] =~ /(.*)<\/$self->{'type'}\s*>/ ){
				$xmlRecord[$i] = $1;
			}
		
			if( $xmlRecord[$i] =~ /^([^<>]*)<\/(\w+)\s*>(.*)/ ){ # closing tag
				my( $stuff, $finish, $bump ) = ( $1, $2, $3 );
#	print STDERR "finishing: $xmlRecord[$i]!\n";
				$tag->stuff( $stuff );
				$tag = $tag->finish( $finish );
				_bump( \@xmlRecord, $i, $bump );
#	print STDERR "post-finish tag: $tag!\n";
			} elsif( $xmlRecord[$i] =~ /<(\w+)\s*([^>]*)\/>(.*)/ ){ # empty tag
				my $bump = $3;
				$tag->spawn( $1, $2 ); 
				_bump( \@xmlRecord, $i, $bump );
			} elsif( $xmlRecord[$i] =~ /<(\w+)\s*([^>]*)>(.*)/ ){ # opening tag
				my $bump = $3;
				$tag = $tag->spawn( $1, $2 );
				_bump( \@xmlRecord, $i, $bump );
#	print STDERR "post-spawn tag: $tag!\n";
			} else {
#			print STDERR "stuffing line $i: $xmlRecord[$i] into $tag!\n";
				$tag->stuff( "$xmlRecord[$i]\n" );
			}
			$i++;
		}
		
######### return a reference to new Record object
		return $self;
	} else {
		warn "'$xmlRecord[0]' does not contain an opening tag";
		return -1;	
	}

}

sub _bump{
	my( $list, $position, $value ) = @_;
	if( $value =~ /(\S+.*)/ ){
		splice( @{$list}, $position+1, 0, $1 );
	}
}

sub parseForm{
	my $proto = shift;
	my $self = $proto->new();
	$self->{'xmlFile'} = shift;
	my $number = shift;
	my $conf = shift;
	my $fd = shift;
	
######### set type
#warn "number: " . $number;
#warn "conf: " . $conf;
#warn "form data: " . $fd;
#warn "category: " . $fd->field('category');
#warn "conf categories: " . join( ' & ', $conf->categories() );
#warn "conf category: " . $conf->category( $fd->field('category') );
	$self->{'type'} = $conf->categoryType( $fd->field('category') );
	
	# load parent tag
	if( $self->{'type'} =~ /(\w+)_template/ ){
		$self->{'parent_tag'} = Tag->load( $self, "template", "record_number=\"$number\"" );
	} else {
		$self->{'parent_tag'} = Tag->load( $self, $self->{'type'} );
	}
	
	# loop through form data, check it against dtd and load valid info
	foreach $name ( $fd->names() ){
# warn "adding $name";
		# if field has a value, check against dtd and add it to record
		if( $fd->field($name) =~ /\S+/ ){
			$self->addField( $&.$', split(/\./,$name) );
		}
	}
	
######### return new Record object
	return $self;
}
sub addField{
	my $self = shift;
	my $value = shift;
	my @fields = @_;

#warn "fields: " . join( ' & ', @fields );

	my $tag = $self->{'parent_tag'};
		
	for( my $i = 0; $i <= $#fields; $i++ ){
			
		# if this is the last field
		if( $#fields == $i ){
		
			# if this field is a '#' it is content, stuff it
			if( $fields[$i] eq '#' ){
				$tag->stuff( $value );
				
			# otherwise it is an attribute, load it
			} else {
				$tag->loadAtt( $fields[$i], $value )
			}
			
		# if this is not the last field
		} else {
		
			# if child already exists, move to it
			if( $tag->child($fields[$i]) ){
				$tag = $tag->child( $fields[$i] );
				
			# if child does not exist, create it
			} else {
				$tag = $tag->spawn( $fields[$i] );
			}
		}
	}
}
sub xml{
	my $self = shift;
	return $self->{'parent_tag'}->xml();
}
1;
