package FormData;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'data'} =	{};
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub load{
	my $proto = shift;
	
	my $self = $proto->new();
	
	# get form data
	my $in;
	if ($ENV{'REQUEST_METHOD'} eq "GET") {
	    $in = $ENV{'QUERY_STRING'};
	} else {
	    chomp ($in = <STDIN>);
	}
#warn "in: $in";
	# check for hacks???
	if( $in =~ /\;/g ){
		warn "Those characters are naughty!\n";
		return -1;
	}

	# put form data into a hash
	foreach my $pair ( split(/&/,$in) ){
	    my( $name, $value ) = split( /=/, $pair );
      
	    # de-webify:
	    $name =~ s/\+/ /g;
	    $name =~ s/%(..)/pack("c",hex($1))/ge;	    
	    $value =~ s/\+/ /g;
	    $value =~ s/%(..)/pack("c",hex($1))/ge;	    
	    
	    # load formData hash
	    $self->{'data'}->{$name} = $value;
	}
	return $self;
}
sub names{
	my $self = shift;
	return keys( %{$self->{'data'}} );
}
sub field{
	my $self = shift;
	my $field = shift;
	return $self->{'data'}->{$field};
}
sub set{
	my $self = shift;
	my $field = shift;
	my $value = shift;
	$self->{'data'}->{$field} = $value;
	return 1;
}
1;
