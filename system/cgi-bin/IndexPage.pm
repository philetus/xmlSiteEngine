package IndexPage;

use base qw( Page );
use StaticPage;

sub output{
	my $proto = shift;
	my $site = shift;
	my $browser = shift;
	my $category = shift;
	
	my $self = $proto->_new();
	
	$self->{'site'} = $site;
	$self->{'browser'} = $browser;
	
######### get name
	$self->{'name'} = $category;

######### get template
	$self->{'template'} = $self->{'site'}->conf()->template( $browser, "index", $category );
	
	# make sure a template was returned
	if( $self->{'template'} < 0 ){
		warn "no index template for $category";
		
		# print 'under construction' page instead
		StaticPage->construction( $site, $browser, $category );
		
		return -1;
	}
	
######### merge record with template
	@{ $self->{'lines'} } = $self->{'template'}->mergeIndex( $site->category($category) );

######### wrap urls with links
	$self->_linkURLs();

######### print file
	$self->_printFile();
}

1;
