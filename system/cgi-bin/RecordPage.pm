package RecordPage;

use base qw( Page );

sub output{
	my $proto = shift;
	my $site = shift;
	my $browser = shift;
	my $number = shift;
	
	my $self = $proto->_new();
	
	$self->{'site'} = $site;
	$self->{'browser'} = $browser;
	
######### get name
	$self->{'name'} = $number;

######### get record
	$self->{'record'} = $self->{'site'}->record( $number );
	
######### get template
	$self->{'template'} = $self->{'site'}->conf()->template( $browser, "record", $self->{'record'}->category()->title() );
	
	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no record template for $number";
		
		# print 'under construction' page instead
		StaticPage->construction( $site, $browser, $number );
		
		return -1;
	}
	
######### merge record with template, send browser and conf for reference templates
	@{ $self->{'lines'} } = $self->{'template'}->merge( $self->{'record'}, $browser, $site->conf() );

######### wrap urls with links
	$self->_linkURLs();

######### print file
	$self->_printFile();
}
1;
