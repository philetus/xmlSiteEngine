package PreviewPage;

use base qw( Page );
use Conf;
use Password;

sub output{
	my $proto = shift;
	my $self = $proto->_new();
	my $fd = shift;	

	
	$self->{'browser'} = $fd->field('browser');
	
######### get template
	my $conf = Conf->load();
warn "form data: " . join( ' & ', $fd->names() );
warn "browser: " . $self->{'browser'};
	$self->{'template'} = $conf->template( $self->{'browser'}, "preview" );
	
######### merge form data with template
	if( $self->{'template'} >= 0 ){
		@{ $self->{'lines'} } = $self->{'template'}->merge( $fd );
	} else {
		Password->resetClient();
		return -1;
	}
	
	my $lines = join( "\n", @{$self->{'lines'}} );
	
	$lines =~ s/<field\s*>(.*)<\/field>/$self->_preview($1,$fd)/sie;
	
	@{ $self->{'lines'} } = split( /\n/, $lines );
	
######### wrap urls with links
	$self->_linkURLs();

######### print content-type
	print "Content-type: text/html\015\012\015\012";

######### print preview page
	foreach my $line ( @{$self->{'lines'}} ){
		print "$line\n";
	}
}

sub _preview{
	my $self = shift;
	my $template = shift;
	my $fd = shift;
	
	my @fields;
	foreach $name ( $fd->names() ){
		my $temp = $template;
		my $value = $fd->field($name);
		$name =~ s/#//g;
		$temp =~ s/<name\s*\/>/$name/gsi;
		$temp =~ s/<value\s*\/>/$value/gsi;
		push( @fields, $temp );
	}
	return join( "\n", @fields );
}
1;
