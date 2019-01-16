package HomePage;

use base qw( Page );

sub output{
	my $proto = shift;
	my $site = shift;
	my $browser = shift;
	
	my $self = $proto->_new();
	
	$self->{'site'} = $site;
	$self->{'browser'} = $browser;
	
######### get name
	$self->{'name'} = "index";

######### get last edited record
	my $lastSquished = 0;
	foreach $number ( $self->{'site'}->numbers() ){
		if( _squished($self->{'site'}->record($number)) > $lastSquished ){
			$lastSquished = _squished( $self->{'site'}->record($number) );
			$self->{'record'} = $self->{'site'}->record( $number );
		}
	}

######### get template
	$self->{'template'} = $self->{'site'}->conf()->template( $browser, "index" );

	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no home page template";
		
		# print 'under construction' page instead
		StaticPage->construction( $site, $browser, 'index' );
		
		return -1;
	}
	
######### merge record with template
	@{ $self->{'lines'} } = $self->{'template'}->merge( $self->{'record'} );

######### wrap urls with links
	$self->_linkURLs();

######### print file
	$self->_printFile();
}

sub _squished{
	my $record = shift;
	my $month = $record->field( "last_edited", "month" );
	my $day = $record->field( "last_edited", "day" );
	my $year = $record->field( "last_edited", "year" );
	return (10000 * $year) + (100 * $month) + $day;
}
1;
