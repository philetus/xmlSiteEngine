package DtdForm;

use Category;
use Conf;
use Password;

my $width = 100;
my $height = 25;

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
	$self->{'element'} =	undef;
	$self->{'dtd'} =	undef;
	$self->{'record'} =	undef;
	$self->{'conf'} =	undef;
	$self->{'title'} =	undef;
	$self->{'contains'} =	undef;
	$self->{'children'} =	undef;
	$self->{'attributes'} =	undef;
	$self->{'contents'} =	"EMPTY";
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub output{
	my $proto = shift;

warn "outputting dtd form!";

######### new object from proto
	my $self = $proto->new();
	my $fd = shift;
	$self->{'user_name'} = $fd->field('user_name');
	$self->{'password'} = $fd->field('password');
	$self->{'form'} = $fd->field('form');
	$self->{'browser'} = $fd->field('browser');
	$self->{'category'} = $fd->field('category');
	$self->{'element'} = $fd->field('element');
	if( $fd->field('status') >= 0 ){
		$self->{'status'} = $fd->field('status');
	}
	
#warn "category: " . $self->{'category'};
#warn "element: " . $self->{'element'};
	
######### load name and attributes if editing
	my $attributes = "";
	my $name = "";
	if( $self->{'form'} eq "edit" ){
		my $dtd = Category->loadDtd( $self->{'category'} );
		$attributes = join( ', ', $dtd->element($self->{'element'})->attributes() );
		$name = $self->{'element'};
	}
		
	
######### load form
	my $form = <<END;
<form method="POST" action="write.cgi">
<input type="hidden" name="browser" value="$self->{'browser'}" />
<input type="hidden" name="category" value="$self->{'category'}" />
<input type="hidden" name="user_name" value="$self->{'user_name'}" />
<input type="hidden" name="password" value="$self->{'password'}" />
<input type="hidden" name="form" value="$self->{'form'}" />
<input type="hidden" name="data" value="dtd" />
<input type="hidden" name="element" value="$self->{'element'}" />
<ul>
<p>name:<br /><input type="text" width="$width" name="name" value="$name" /></p>
<p>attributes:<br /><input type="text" width="$width" name="attributes" value="$attributes" /></p>
</ul>
END

	if( $self->{'form'} eq "edit" ){
		$form .= <<END;
<ul><p><input type="submit" name="do" value="update" /> <input type="submit" name="do" value="delete" /> <input type="submit" name="do" value="cancel" /></p></ul>
END
	} elsif( $self->{'form'} eq "new" ){
		$form .= <<END;
<ul><p><input type="submit" name="do" value="create" /> <input type="submit" name="do" value="cancel" /></p></ul>
END
	}

	$form .= "</form>";	
	
######### load Conf
	$self->{'conf'} = Conf->load();

######### get title
	$self->{'title'} = $self->{'category'} . " dtd";

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
