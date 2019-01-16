package Form;

use Category;
use Conf;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'user_name'} =	undef;
	$self->{'password'} =	undef;
	$self->{'status'} =	undef;
	$self->{'form'} =	undef;
	$self->{'browser'} =	undef;
	$self->{'category'} =	undef;
	$self->{'number'} =	undef;
	$self->{'dtd'} =	undef;
	$self->{'record'} =	undef;
	$self->{'conf'} =	undef;
	$self->{'title'} =	undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub output{
	my $proto = shift;
	
######### new object from proto
	my $self = $proto->new();
	$self->{'user_name'} = shift;
	$self->{'password'} = shift;
	$self->{'status'} = shift;
	$self->{'form'} = shift;
	$self->{'browser'} = shift;
	$self->{'category'} = shift;
	$self->{'number'} = shift;
	
#warn "category: " . $self->{'category'};
#warn "number: " . $self->{'number'};
	
######### load Dtd
	$self->{'dtd'} = Category->loadDtd( $self->{'category'} );

######### load record
	$self->{'record'} = Category->loadRecord( $self->{'category'}, $self->{'number'} );
	
#warn "record: " . $self->{'record'};

######### load form
	my @form = <<END;
<form method="POST" action="write.cgi">
<input type="hidden" name="browser" value="$self->{'browser'}" />
<input type="hidden" name="category" value="$self->{'category'}" />
<input type="hidden" name="user_name" value="$self->{'user_name'}" />
<input type="hidden" name="password" value="$self->{'password'}" />
<input type="hidden" name="form" value="$self->{'form'}" />
END
	push( @form, $self->{'dtd'}->form($self->{'record'}) );
	
	if( $self->{'form'} eq "edit" ){
		push( @form, "<ul><p><input type=\"submit\" name=\"do\" value=\"update\" /> <input type=\"submit\" name=\"do\" value=\"delete\" /> <input type=\"submit\" name=\"do\" value=\"cancel\" /></p></ul>" );
	} else {
		push( @form, "<ul><p><input type=\"submit\" name=\"do\" value=\"create\" /> <input type=\"submit\" name=\"do\" value=\"cancel\" /></p></ul>" );
	}
		push( @form, "</form>" );
	
	my $form = join( "\n", @form );

######### load Conf
	$self->{'conf'} = Conf->load();

######### get title
	if( $self->{'form'} eq "edit" ){
		$self->{'title'} = $self->{'record'}->title();
	} else {
		if( $self->{'category'} eq "browsers" ){
			$self->{'title'} = "browser";
		} elsif( $self->{'category'} eq "categories" ) {
			$self->{'title'} = "category";
		} elsif( $self->{'category'} =~ /(\w+)_templates/ ) {
			$self->{'title'} = "$1_template";
		} else {
			$self->{'title'} = $self->{'conf'}->category( $self->{'category'} )->field( 'member', 'type' );
		}
	}

######### merge template
	my @template = $self->{'conf'}->template( $self->{'browser'}, "form" )->merge( $self );

######### print content-type
	print "Content-type: text/html\015\012\015\012";
	
######### print template, replace '<form />' with record form
	foreach $line ( @template ){
		if( $line =~ /<form\s+\/>/i ){
			$line =~ s/<form\s+\/>/$form/i;
		}
		print "$line\n";
	}
}
sub field{
	my $self = shift;
	my $field = shift;
	return $self->{$field};
}
1;
