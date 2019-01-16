package MonthDayYear;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self{'month'} =	undef;
	$self{'day'} =		undef;
	$self{'year'} =		undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub set{
	my $proto = shift;
	
######### get new MonthDayYear object
	my $self = $proto->new();
	
######### get localtime
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

######### set month, day and year
	$self->{'month'} = ( $mon + 1 );
	$self->{'day'} = ( $mday );
	$self->{'year'} = ( $year + 1900 );

######### return reference
	return $self;
}

sub month{
	my $self = shift;
        return $self->{'month'};
}
sub day{
	my $self = shift;
        return $self->{'day'};
}
sub year{
	my $self = shift;
        return $self->{'year'};
}
1;
