package StaticPage;

use base qw( Page );

sub output{
	my $proto = shift;
	my $site = shift;
	my $browser = shift;
	my $id = shift;
	
	my $self = $proto->_new();
	
	$self->{'site'} = $site;
	$self->{'browser'} = $browser;
	
######### get name
	$self->{'name'} = $id;

######### get template
	$self->{'template'} = $self->{'site'}->conf()->template( $self->{'browser'}, $self->{'name'} );
	
	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no page template for $id";
		
		# print 'under construction' page instead
		StaticPage->construction( $site, $browser, $id );
		
		return -1;
	}

######### merge template with no data
	@{ $self->{'lines'} } = $self->{'template'}->merge();

######### wrap urls with links
	$self->_linkURLs();

######### print file
	$self->_printFile();
}

sub stdout{
#warn "caller: " . join( ' - ', caller );
#warn "arguments: " . join( ' - ', @_ );
	my $proto = shift;
	my $self = $proto->_new();
	my $fd = shift;
	$self->{'browser'} = $fd->field( 'browser' );
	$self->{'name'} = shift;
	my $conf = shift;

#warn "fields: " . join( ' - ', $fd->names() );

######### get template
	$self->{'template'} = $conf->template( $self->{'browser'}, $self->{'name'} );
	
	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no page template for " . $self->{'name'};
		return -1;	
	}
	
######### merge template with form data
	@{ $self->{'lines'} } = $self->{'template'}->merge( $fd );

######### wrap urls with links
	$self->_linkURLs();
	
######### print

	# print content-type
	print "Content-type: text/html\015\012\015\012";

	# print page
	foreach $line ( @{$self->{'lines'}} ){
		print "$line\n";
	}
}
sub construction{
	my $proto = shift;
	my $site = shift;
	my $browser = shift;
	my $id = shift;
	
	my $self = $proto->_new();
	
	$self->{'site'} = $site;
	$self->{'browser'} = $browser;
	
######### get name
	$self->{'name'} = $id;

######### get 'under_construction' template
	$self->{'template'} = $self->{'site'}->conf()->template( $self->{'browser'}, 'under_construction' );
	
	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no page template for under_construction";
		return -1;	
	}

######### merge template with no data
	@{ $self->{'lines'} } = $self->{'template'}->merge();

######### wrap urls with links
	$self->_linkURLs();

######### print file
	$self->_printFile();
}
1;
