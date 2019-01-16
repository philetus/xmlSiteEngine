package Tag;

my $matchLength = 40;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'parent'} =	undef;	# parent tag
	$self->{'children'} =	{};	# hash of child tags
	$self->{'attributes'} =	{};	# hash of attributes
	$self->{'content'} =	undef;	# contents of tag
	$self->{'element'} =	undef;	# type of element of this tag
	$self->{'record'} = 	undef;	# Record containing this tag
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub parent{
	my $self = shift;
	return $self->{'parent'};
}

sub child{
	my $self = shift;
	my $child = shift;
	
	return $self->{'children'}->{$child};
}

sub children{
	my $self = shift;
	return keys( %{$self->{'children'}} );
}

sub attributes{
	my $self = shift;
	return keys( %{$self->{'attributes'}} )
}

sub att{
	my $self = shift;
	my $att = shift;
	return $self->{'attributes'}->{$att};
}

sub element{
	my $self = shift;
	return $self->{'element'};
}

sub dtdElement{
	my $self = shift;
#warn "self: $self!";
#warn "dtd: " . $self->{'record'}->dtd();
#warn "dtdElements: " . join( ' & ', $self->{'record'}->dtd()->elements() );
	return $self->{'record'}->dtd()->element( $self->{'element'} );
}

sub record{
	my $self = shift;
	return $self->{'record'};
}

sub content{
	my $self = shift;
	return $self->{'content'};
}

sub field{
	my $self = shift;
# warn "fields: " . join( ' & ', @_ );
	my $field = shift;

	# if more fields are specified
	if( @_ ){

# warn "children: " . join( ' & ', keys(%{$self->{'children'}}) );
# warn "child $field: " . $self->{'children'}->{$field};
	
		# call child with remaining arguments
		if( $self->{'children'}->{$field} ){
			return $self->{'children'}->{$field}->field( @_ );
		} else {
			return -1;
		}
		
	# otherwise this is the last field
	
	} elsif( $self->{'attributes'}->{$field} ){
	
		# if it is an attribute, return value
 		return $self->{'attributes'}->{$field};
		
	} elsif( $self->{'children'}->{$field} ){

		# if it is a child, return child's content
		if( $self->{'children'}->{$field}->content() =~ /\S+/ ){
			return $& . $';
		}
	}
	return -1;

}

sub title{
	my $self = shift;
	
	foreach $attribute ( keys(%{$self->{'attributes'}}) ){
#warn "$attribute: " . $self->{'attributes'}->{$attribute};
		if( $attribute ne "record_number" ){
			return $self->{'attributes'}->{$attribute};
		}
	}
	
	foreach $child ( keys(%{$self->{'children'}}) ){
		if( $self->{'children'}->{$child}->content() =~ /(\S+)/ ){
			return _parseTitle( $self->{'children'}->{$child}->content() );
		}
	}
}

sub match{
	my $self = shift;
	my $match = shift;

#warn "checking " . $self->{'record'}->title() . " - " . $self->{'element'} . " for $match";
	
	# don't check last edited
	if( $self->{'element'} =~ "last_edited" ){
		return -1;
	}
	
	# check content
	if( $self->{'content'} =~ /(.{0,$matchLength})($match)(.{0,$matchLength})/i ){
		return "$1<b>$2</b>$3";
	}
	
	# check attributes
	foreach my $attribute ( keys(%{$self->{'attributes'}}) ){
		if( $self->{'attributes'}->{$attribute} =~ /(.{0,$matchLength})($match)(.{0,$matchLength})/i ){
#warn "match: $1<b>$2</b>$3";
			return "$1<b>$2</b>$3";
		}
	}
	
	# check children
	foreach my $child ( keys(%{$self->{'children'}}) ){
		my $childMatch = $self->{'children'}->{$child}->match( $match );
#warn "childMatch: $childMatch";
		if( $childMatch >= 0 ){
			return $childMatch;
		}		
	}
	
	# no match
	return -1;
}

# string to cross-reference
sub matchString{
	my $self = shift;
	foreach my $attribute ( keys(%{$self->{'attributes'}}) ){
		if( $attribute ne "record_number" ){
			return $self->{'attributes'}->{$attribute};
		}
	}
	return -1;
}

sub _parseTitle{
	my $string = shift;
	
	my $length = 60;
	
	$string =~ s/\n/ /g;
	$string =~ s/\s+/ /g;
	$string =~ s/<[^>]*>//g;
	if( $string =~ /(.{$length}).+/ ){
		return "$1...";
	} else {
		return $string;
	}
}
sub loadAtt{
	my $self = shift;
	my $name = shift;
	my $value = shift;

#warn "loading $name=$value into " . $self->element();
#warn "attributes: " . join( ' & ', $self->dtdElement()->attributes() );
#warn "att: " . $self->dtdElement()->att( $name );
	
	foreach $att ( $self->dtdElement()->attributes() ){
		if( $att eq $name ){
			$self->{'attributes'}->{$name} = $self->clean( $value );
			return 1;
		}
	}
	return -1;
#warn "denied";
}
sub load{
	my $proto = shift;
	my $record = shift;
	my $element = shift;
	my $attString = shift;
	
#warn "record: $record!";
#warn "element: $element!";
#warn "attString: " . $attString;

######### get new Tag object
	my $self = $proto->new();
	
# warn "self: $self!";

######### set record
	$self->{'record'} = $record;

######### set element
	$self->{'element'} = $element;

######### parse attributes

#warn "caller: " . join( ' - ', caller );
#warn "loading element: $element!";
#warn "dtdElement: " . $self->dtdElement();
	
	
	# get list of element attributes
	my @attributes = $self->dtdElement()->attributes();
	
	# check attString for attributes and load default values
	foreach $attribute ( @attributes ){
		if( $self->dtdElement()->att( $attribute ) =~ /(\S+.*)/ ){
			$self->{'attributes'}->{$attribute} = $self->clean( $1 );
		}
		if( $attString =~ /$attribute\s*=\s*["']([^"']+)["']/ ){
			$self->{'attributes'}->{$attribute} = $self->clean( $1 );
		}
	}

######### return reference to new Tag object
	return $self;	
}

sub spawn{
	my $proto = shift;
	my $element = shift;
	my $attString = shift;
#warn "spawning $element from " . $proto->element() . " with $attString";
	foreach $child ( $proto->dtdElement()->children() ){
		if( $child eq $element ){
			# load new Tag object
			my $self = $proto->load( $proto->{'record'}, $element, $attString );
	
			# set parent to be calling object
			$self->{'parent'} = $proto;
	
			# add new Tag to hash of children
			$proto->{'children'}->{$element} = $self;
	
			# return reference to new Tag
			return $self;
		}
	}
	warn "can't add $element to " . $proto->{'element'} . "!";
	return $proto;
}

sub stuff{
	my $self = shift;
	my $string = shift;
	
	if( $self->dtdElement()->content() >= 0 ){
		$self->{'content'} .= $self->clean( $string );
	}
}

sub finish{
	my $self = shift;
	my $element = shift;

######### return reference to parent Tag
	if( $self->parent() =~ /\S+/ ){
		return $self->parent();
	} else { # this is the top level tag 
		warn "prematurely finished " . $self->{'record'}->number();
		return $self;
	}
}

sub checkReference{
	my $self = shift;
	my $record = shift;
	my $match = shift;
	
#warn "looking for $match";
	
######### check children for reference
	foreach my $child ( keys(%{$self->{'children'}}) ){
		$self->{'children'}->{$child}->checkReference( $record, $match );
	}
	
######### check attributes for reference
	foreach my $att ( keys(%{$self->{'attributes'}}) ){
#warn "\tin: " . $self->{'attributes'}->{$att};
		if( $self->{'attributes'}->{$att} =~ /$match/ ){
			$self->{'attributes'}->{$att} =~ s/$match/$self->_resolveReference( $`, $&, $', $record )/ge;
		}
	}

######### check content for reference
#warn "\tin: " . $self->{'content'};
	if( $self->{'content'} =~ /$match/ ){
		$self->{'content'} =~ s/$match/$self->_resolveReference( $`, $&, $', $record )/ge;
	}	
}

sub _resolveReference{
	my $self = shift;
	my $before = shift;
	my $match = shift;
	my $rest = shift;
	my $record = shift;

#warn "match: $match";

	# check rest for closing of tag or link
	if( $rest =~ /^[^<]*<\/a>/ ){
		return "$match";
	}
	
	# check before to see if this is an url
	if( $before =~ /http:\/\/[^\s]*$/i ){
		return "$match";
	}
	
	if( $self->{'element'} ne 'last_edited' ){
		# add reference to matched record
		$record->addReference( $self->{'record'} );
	}
	
	# return link to matched record
	return "<a href=\"" . $record->href() . "\">$match</a>";
}
# html formatting
sub clean{
	my $self = shift;
	my $string = shift;
	
#	$string =~ s/&lt;/</gs;
#	$string =~ s/&gt;/>/gs;
	
	return $string;
}
# xml formatting
sub pure{
	my $self = shift;
	my $string = shift;
	
	$string =~ s/</&lt;/gs;
	$string =~ s/>/&gt;/gs;
	$string =~ s/&(?!\S+;)/&amp;/gs;
	$string =~ s/'/&#39;/gs;
	$string =~ s/"/&quot;/gs;

	# fix whitespace
	$string	=~ s/\r//gs;
	$string =~ s/\s*$//s;
	
	return $string;
}
sub xml{
	my $self = shift;
	
	my @xml;
	
	# opening tag and attributes
	my $opening = "<" . $self->{'element'};
	foreach $attribute ( keys(%{$self->{'attributes'}}) ){
		$opening .= " $attribute=\"" . $self->pure( $self->{'attributes'}->{$attribute} ) . "\"";
	}
	
	# children and closing
	my @children = keys( %{$self->{'children'}} );
	if( $#children >= 0 ){
		$opening .= ">\n";
		push( @xml, $opening );
		foreach $child ( @children ){
			push( @xml, $self->{'children'}->{$child}->xml() );
		}		
		push( @xml, "</" . $self->{'element'} . ">\n" );
	} else {
		if( $self->{'content'} =~ /\S+/ ){
			$opening .= ">";
			push( @xml, $opening );
			push( @xml, $self->pure($self->{'content'}) );
			push( @xml, "</" . $self->{'element'} . ">\n" );
		} else {
			$opening .= " />\n";
			push( @xml, $opening );
		}
	}
	
	return @xml;
}
1;
