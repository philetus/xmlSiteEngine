package Page;

my $baseDir = "../../browsers/";

sub _new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;

	my $self = {};
	$self->{'lines'} =	[];
	$self->{'browser'} =	undef;
	$self->{'name'} =	undef;
	$self->{'template'} =	[];
	$self->{'site'} =	undef;
	$self->{'record'} =	undef;
		
######### bless empty template into class and return a reference to it
	bless( $self, $class );
}


sub _linkURLs{
	my $self = shift;
		
	foreach $line ( @{$self->{'lines'}} ){
		
		# look for occurrences of 'http...' and wrap them in an href tag
		$line =~ s/http:\/\/[^\s<>]*\.\w[^\s<>]*\w\/?/_resolveURLs( $&, $' )/egi;
	}
}
sub _resolveURLs{
	my( $match, $rest ) = @_;

#warn "match: $match";
		
	# if this occurrence of 'http...' is followed by a '>' before a '<'
	# it is already in a tag, or if it is followed by '</a>' it is already a
	# link, so do not wrap a new tag around it
	if( $rest =~ /^[^<]*>/ || $rest =~ /^[^<>]*<\/a\s*>/i ){
		return "$match";
	}
	
	# wrap a link tag around 'http...'
	return "<a href=\"$match\" target=\"_blank\" class=\"external\">$match</a>";
}
sub _printFile{
	my $self = shift;
	
	my $file = $baseDir . $self->{'browser'} . '/' . $self->{'name'} . '.html';

#warn "printing to $file";
	
	open( FILE, ">$file" ) || warn "can't open $file: $!";
	
	foreach my $line ( @{$self->{'lines'}} ){
		print FILE "$line\n";
	}
	close( FILE );
}
1;
