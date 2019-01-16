package Dtd;

use Element;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'elements'} =	{}; # hash of elements
	$self->{'parents'} =	[]; # list of top-level Elements
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub elements{
	my $self = shift;
	return keys( %{$self->{'elements'}} );	
}

sub element{
	my $self = shift;
	my $element = shift;
	return $self->{'elements'}->{$element};
}

sub parents{
	my $self = shift;
	return @{ $self->{'parents'} }
}

sub parse{
	my $proto = shift;
	my @xmlDtd = @_;

#warn "new dtd: " . join( ' / ', @xmlDtd );

######### get new Dtd object
	my $self = $proto->new();

######### get elements	
	my $i = 0;
	while( $i <= $#xmlDtd ){
		if( $xmlDtd[$i] =~ /<!ELEMENT\s+(\w+)\s+\(?([^>\)\*]+)\)?\*?>/ ){
			$self->{'elements'}->{$1} = Element->load( $self, $2 );
		}
		$i++;
	}

######### add attributes to elements
	my $i = 0;
	while( $i <= $#xmlDtd ){
		if( $xmlDtd[$i] =~ /<!ATTLIST\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s*>/ ){
			$self->{'elements'}->{$1}->addAtt( $2, $3, $4 );
		} elsif( $xmlDtd[$i] =~ /<!ATTLIST\s+(\w+)[^>]*$/ ){
			my $element = $1;
			while( $xmlDtd[$i] !~ />/ && $i < $#xmlDtd ){
				$i++;
				if( $xmlDtd[$i] =~ /^\s*([^>\s]+)\s+['"]([^>'"]+)['"]\s+([^>\s]+)\s*>?$/ ||
				    $xmlDtd[$i] =~ /^\s*([^>\s]+)\s+([^>\s]+)\s+([^>\s]+)\s*>?$/ ){
					$self->element( $element )->addAtt( $1, $2, $3 );
				}
			}
		}
		$i++;
	}
		
######### resolve children
	foreach my $element ( keys(%{$self->{'elements'}}) ){
		foreach my $child ( $self->element($element)->children() ){
#warn "$element is parent of $child";
			$self->element( $child )->addParent( $element );
		}
	}

######### resolve parents
	foreach my $element ( keys(%{$self->{'elements'}}) ){
		my @parents = $self->element( $element )->parents();
		if( $#parents < 0 ){
			push( @{$self->{'parents'}}, $element );
		}
	}

######### return reference to new Dtd object
	return $self;	
}
sub form{
	my $self = shift;
	my $record = shift;
	
	my @form;
	foreach $parent ( @{$self->{'parents'}} ){
	
# warn "parent: " . $self->{'elements'}->{$parent};
		push( @form, $self->{'elements'}->{$parent}->form($record) );
	}
	
	return @form;
}

sub deleteElement{
	my $self = shift;
	my $element = shift;

warn "deleting element: $element";	

	# delete children
	foreach my $child ( $self->{'elements'}->{$element}->children() ){
		$self->deleteElement( $child );
	}

	# divorce from parents
	$self->divorceParents( $element );
	
	# delete element
	delete $self->{'elements'}->{$element};
}

sub updateElement{
	my $self = shift;
	my $element = shift;
	my $name = shift;
	my $attributes = shift;
	
	# determine parents
	my @parents = $self->{'elements'}->{$element}->parents();

	# determine children
	my @children = $self->{'elements'}->{$element}->children();
	
	# divorce from parents
	$self->divorceParents( $element );
	
	# delete element
	delete $self->{'elements'}->{$element};
	
	# load element
	$self->{'elements'}->{$name} = Element->load( $self, $contents );
		
	# parse attributes
	my @attributes = split( /\,?\s+/, $attributes );
	%{$self->{'elements'}->{$element}->{'attributes'}} = ();
	foreach $attribute ( @attributes ){
		$self->{'elements'}->{$name}->addAtt( $attribute );
	}
	
	# add parents
	foreach my $parent ( @parents ){
		$self->{'elements'}->{$parent}->addChild( $name );
		$self->{'elements'}->{$name}->addParent( $parent );
	}
	
	# add children
	foreach my $child ( @children ){
		$self->{'elements'}->{$name}->addChild( $child );
		$self->{'elements'}->{$child}->addParent( $name );
	}
	
	# set content
	my $content = "";
	if( $#attributes >= 0 || $#children >= 0 ){
		$content = -1;
	}
	$self->{'elements'}->{$name}->content( $content );
	
}

sub createElement{
	my $self = shift;
	my $element = shift;
	my $name = shift;
	my $attributes = shift;

warn "element: $element";
warn "name: $name";
warn "attributes: $attributes";

	# load element
	$self->{'elements'}->{$name} = Element->load( $self, $contents );

	# parse attributes
	my @attributes = split( /\,?\s+/, $attributes );
	%{$self->{'elements'}->{$name}->{'attributes'}} = ();
	foreach $attribute ( @attributes ){
		$self->{'elements'}->{$name}->addAtt( $attribute );
	}
	
	# add parent
	$self->{'elements'}->{$element}->addChild( $name );
	$self->{'elements'}->{$name}->addParent( $element );
	
	# set content
	my $content = -1;
	if( $#attributes < 0 ){
		$content = "";
	}
	$self->{'elements'}->{$name}->content( $content );

}

sub writeFile{
	my $self = shift;
	my $file = "";
	
	foreach my $element ( keys(%{$self->{'elements'}}) ){
	
		if( $element =~ /\S+/ ){
			# get values
			my @children = $self->{'elements'}->{$element}->children();
			my $content = $self->{'elements'}->{$element}->content();
			my @attributes = $self->{'elements'}->{$element}->attributes();
		
			# determine content string
			my $string;
			if( $#children >= 0 ){
				$string = '(' . join( ',', @children ) . ')';
			} elsif( $content >= 0 ){
				$string = '(#PCDATA)';
			} else {
				$string = "EMPTY";
			}
			
			# add element to file
			$file .= "<!ELEMENT $element $string>\n";
			
			# add attributes to file
			if( $#attributes >= 0 ){
				$file .= "<!ATTLIST $element\n";
				foreach my $attribute ( @attributes ){
					$file .= "\t$attribute\tCDATA\t#IMPLIED\n";
				}
				$file .= ">\n";
			}
			
			$file .= "\n";
		}
	}
	
	return $file;
}
sub divorceParents{
	my $self = shift;
	my $element = shift;
	
#warn "element: $element: " . $self->{'elements'}->{$element};	
	
	# remove as child from parents
	foreach my $parent ( $self->{'elements'}->{$element}->parents() ){
		my $children = $self->{'elements'}->{$parent}->{'children'};
warn "${parent}'s children: " . join( ', ', @{$children} );
		for( my $i = 0; $i <= $#{$children}; $i++ ){
warn "comparing " . $children->[$i] . " and $element";
			if( $children->[$i] eq $element ){
warn "replacing $element";
				splice( @{$children}, $i, 1 );
			}
		}
	}
}
1;
