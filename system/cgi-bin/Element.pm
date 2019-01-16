package Element;

my $width = 60;
my $height = 10;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'parents'} =	[];	# list of parent Elements
	$self->{'children'} =	[];	# list of child Elements
	$self->{'attributes'} =	{};	# hash of attributes
	$self->{'content'} =	undef;	# contents of Element
	$self->{'dtd'} =	undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub parents{
	my $self = shift;
	return @{$self->{'parents'}};
}

sub children{
	my $self = shift;
	return @{$self->{'children'}};
}

sub attributes{
	my $self = shift;
	return keys( %{$self->{'attributes'}} );
}

sub att{
	my $self = shift;
	my $att = shift;
	return $self->{'attributes'}->{$att};
}

sub content{
	my $self = shift;
	if( @_ ){
		$self->{'content'} = shift;
	}
	return $self->{'content'};
}

sub load{
	my $proto = shift;
	my $dtd = shift;
	my $string = shift;
	
######### get new Element object
	my $self = $proto->new();
	$self->{'dtd'} = $dtd;
	
######### parse string
	if( $string =~ /#PCDATA/ ){
		$self->{'content'} = "";
	} else {
		$self->{'content'} = -1;
		if( $string !~ /EMPTY/ ){
		
			# choose field delimiter
			my $split;
			if( $string =~ /\|/ ){
				$split = '\|';
			} else {
				$split = ',';
			}
			
			# split string into children
			foreach $child ( split( /$split/, $string ) ){
				if( $child =~ /(\w+)/ ){
					push( @{$self->{'children'}}, $1 );
				}
			}
		}
	}

######### return reference to new Element object
	return $self;	
}

sub addAtt{
	my $self = shift;
	my $att = shift;
	my $default = shift;
		
	if( $default =~ /["']([^"']+)["']/ ){
		$self->{'attributes'}->{$att} = $1;
	} else {
		$self->{'attributes'}->{$att} = "";
	}
}

sub addParent{
	my $self = shift;
	my $element = shift;
	
	push( @{$self->{'parents'}}, $element );
}

sub addChild{
	my $self = shift;
	my $element = shift;
	
	push( @{$self->{'children'}}, $element );
}

sub form{
	my $self = shift;
	my $record = shift;

#warn "record: $record";
	
######### keep track of fields to call Record->field()
	my @fields;
	push( @fields, @_ );

# warn "fields: " . join( ' & ', @fields );

######### list to hold form
	my @form;
	
######### if element has content
	if( $self->{'content'} >= 0 ){
		my $name = join( '.', @fields );
		my $value;
		if( $record >= 0 && $record->field( @fields ) =~ /\S+/ && $& >= 0 ){
			$value = $& . $';
		}
		push( @form, "<p><textarea name=\"$name.#\" cols=\"$width\" rows=\"$height\">$value</textarea></p>" );
	}
	
######### indent and add attributes
	push( @form, "<ul>" );
	foreach $att ( keys(%{$self->{'attributes'}}) ){
		my $name = join( '.', @fields, $att );
	
		# get default value from dtd
		my $value = $self->{'attributes'}->{$att};
		
		# replace default value if record has value
		if( $record >= 0 && $record->field( @fields, $att ) =~ /\S+/ && $& >= 0 ){
			$value = $& . $';
		}
		
		# push tag into form
		if( $att ne "record_number" && $fields[$#] ne "last_edited" ){
			push( @form, "<p>$att<br /><input type=\"text\" size=\"$width\" name=\"$name\" value=\"$value\" /></p>" );
		} else {
			push( @form, "<input type=\"hidden\" name=\"$name\" value=\"$value\" />" );		
		}
	}
	
######### add children
	foreach $child ( $self->children() ){
# warn "child: " . $child;
		if( $child ne "last_edited" ){
			push( @form, "<p>$child</p>" );
		}
			push( @form, $self->{'dtd'}->element($child)->form($record,@fields,$child) );
	}
	
######### un-indent and return
	push( @form, "</ul>" );
	return @form;
}

1;
