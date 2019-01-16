package Password;

use Conf;
use Category;

my $browserDir = "../../browsers/";
my $passfile = "passfile.xml";

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'form'} =	undef;
	$self->{'data'} =	undef;
	$self->{'browser'} =	undef;
	$self->{'category'} =	undef;
	$self->{'record'} =	undef;
	$self->{'element'} =	undef;
	$self->{'conf'} =	undef;
	$self->{'title'} =	undef;
	$self->{'user_name'} =	undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}


sub request{
	my $proto = shift;
	my $fd = shift;

#warn "request caller: " . join( ' - ', caller );
#warn "form: " . $fd->field("form");
#warn "data: " . $fd->field("data");
#warn "browser: " . $fd->field("browser");
#warn "category: " . $fd->field("category");
#warn "number: " . $fd->field("number");
#warn "element: " . $fd->field("element");
	
######### load new object
	my $self = $proto->new();
	$self->{'form'} = $fd->field( 'form' );
	$self->{'data'} = $fd->field( 'data' );
	$self->{'browser'} = $fd->field( 'browser' );
	$self->{'user_name'} = $fd->field( 'user_name' );
	
######### load Conf
	$self->{'conf'} = Conf->load();

######### new form
	if( $self->{'form'} eq "new" ){
		if( $fd->field('category') =~ /\S+/ || $fd->field('id') =~ /\S+/){
			$self->{'category'} = $&;
			$self->{'type'} = $self->{'conf'}->categoryType( $self->{'category'} );
#warn "type: " . $self->{'type'};

			# get title
			if( $fd->field('data') eq "dtd" ){
				$self->{'title'} = "element";
				$self->{'element'} = $fd->field('element');
				$self->{'category'} = $fd->field('category');
			} else {
				$self->{'title'} = $self->{'type'};
			}
		}
######### edit form
	} elsif( $self->{'form'} eq "edit" ){

		# edit dtd
		if( $fd->field('data') eq "dtd" ){
			$self->{'element'} = $fd->field('element');
			$self->{'title'} = $self->{'element'};
			$self->{'category'} = $fd->field('category');
		
		# edit xml					
		} elsif( $fd->field('number') =~ /([^\s\d]+)\d+/ || $fd->field('id') =~ /([^\s\d]+)\d+/){
			$self->{'record'} = $&;
			$self->{'type'} = $1;
#warn "matching type: " . $self->{'type'};
			$self->{'category'} = $self->{'conf'}->matchType( $self->{'type'} );
#warn "category matched: " . $self->{'category'};
			# get title
			my $record = Category->loadRecord( $self->{'category'}, $self->{'record'} );
#warn "request caller: " . join( ' - ', caller );
#warn "record $record loaded from " . $self->{'category'} . ' & ' . $self->{'record'};
			if( $record < 0 ){
				warn "record " . $self->{'record'} . " not found";
				$self->resetClient();
				return -1;
			}
			$self->{'title'} = $record->title();

		} else {
			warn "invalid record number!";
			$self->resetClient();
			return -1;
		}
				
	} else {
		$self->resetClient();
		return -1;
	}

######### merge password template
	my @template = $self->{'conf'}->template( $self->{'browser'}, "password" )->merge( $self );

######### password form
	my $form = <<END;
<form method="POST" action="form.cgi">
<p>name<br />
<input type="text" name="user_name" value="$self->{'user_name'}" /></p>
<p>password<br />
<input type="password" name="password" /></p>
<input type="hidden" name="browser" value="$self->{'browser'}" />
<input type="hidden" name="category" value="$self->{'category'}" />
<input type="hidden" name="form" value="$self->{'form'}" />
<input type="hidden" name="data" value="$self->{'data'}" />
<input type="hidden" name="type" value="$self->{'type'}" />
<input type="hidden" name="number" value="$self->{'record'}" />
<input type="hidden" name="element" value="$self->{'element'}" />
<p><input type="submit" value="submit" /></p>
</form>
END

######### print content-type
	print "Content-type: text/html\015\012\015\012";
	
######### print template, replace '<password />' with password form
	foreach $line ( @template ){
		if( $line =~ /<password\s+\/>/i ){
			$line =~ s/<password\s+\/>/$form/i;
		}
		print "$line\n";
	}

}

sub resetClient{
	my $proto = shift;
warn "resetting client";	
	if( @_ ){
		my $fd = shift;
	
		my $conf = Conf->load();
	
		# if browser specified in form data exists
		if( $conf->browser($fd->field('browser')) ){
			
			# if the category is categories, browsers, templates, or elements,
			# redirect back to config page
			if( $fd->field('category') eq "categories" ||
			    $fd->field('category') eq "browsers" ||
			    $fd->field('category') =~ /\w+_templates/ || 
			    $fd->field('category') =~ /\w+_elements/ ){
				print "Location: ../cgi-bin/config.cgi?browser=" . $fd->field('browser') . "\015\012\015\012";
			# if there is a record number, redirect back to record
			} elsif( $fd->field('record_number') =~ /\S+/ ){
				print "Location: $browserDir" . $fd->field('browser') . "/" . $fd->field('record_number') . ".html\015\012\015\012";
					
			# if there is a category, redirect to category index
			} elsif( $fd->field('category') =~ /\S+/ ){
				print "Location: $browserDir" . $fd->field('browser') . "/" . $fd->field('category') . ".html\015\012\015\012";
			
			# if there is a browser, redirect to browser home page
			} else {
				print "Location: $browserDir" . $fd->field('browser') . "\015\012\015\012";	
			}
		} else {
			# dump client back to entry
			$proto->entry();
		}
	} else {
		# dump client back to entry
		$proto->entry();
	}
}

sub entry{
	my $proto = shift;
	my $self = $proto->new();
	
	# load Conf
	$self->{'conf'} = Conf->load();
	
	my $user_agent = $ENV{'HTTP_USER_AGENT'};
warn "user agent string: $user_agent";
	
	# check user agent string against browser regexps for match
	foreach my $browser ( $self->{'conf'}->browsers() ){
		my $regexp = $self->{'conf'}->browser($browser)->field('user_agent','regexp');
		if( $user_agent =~ /$regexp/ ){
			print "Location: $browserDir$browser\015\012\015\012";
			return 0;
		}
	}
	
	# if no user agent match, send to default browser
	print "Location: $browserDir" . $self->{'conf'}->defaultBrowser() . "\015\012\015\012";
}

sub field{
	my $self = shift;
	my $field = shift;
#warn "$field: " . $self->{$field};
	return $self->{$field};
}
sub verify{
	my $proto = shift;
	my $user_name = shift;
	my $password = shift;
	
	# find entry for user name
	my $file = $proto->passfile();
	if( $file =~ /<user([^>]*name\s*=\s*["']$user_name["'][^>]*)\/>/s ){
		my $attributes = $1;
		
		# check password
		if( $attributes =~ /password\s*=\s*["']$password["']/s ){		
			return 1;
		}
	}
	
	# password failed, deny
	return -1;
}

sub vet{
	my $proto = shift;
	my $fd = shift;
	
#warn "form: " . $fd->field("form");
#warn "browser: " . $fd->field("browser");
#warn "category: " . $fd->field("category");
#warn "number: " . $fd->field("number");
#warn "element: " . $fd->field("element");

	# deny client if there is not a user name and password
	if( $fd->field("user_name") !~ /\S+/ || $fd->field("password") !~ /\S+/ ){

		# if the form eq 'new' or 'edit', request password again
		if( $fd->field("form") eq "new" || $fd->field("form") eq "edit" ){
			$proto->request( $fd );
			return -1;
	
		# otherwise dump client back out to entry page
		} else {
			$proto->resetClient();
			return -1;
		}
	}

	# verify password
	my( $allow ) = $proto->verify( $fd->field("user_name"), $fd->field("password") );
	
	# if user is denied
	if( $allow < 0 ){
		
		warn $fd->field("user_name") . " denied from " . $fd->field("category") . " - " . $fd->field("number");
		
		# request password again
		$proto->request( $fd );
		
		# deny access
		return -1;
		
	# if user is not denied write form
	} else {
		warn $fd->field("user_name") . " allowed to " . $fd->field("category") . " - " . $fd->field("number");
		return 1, 1;
	}
	
}

sub create{
	my $proto = shift;
	my $self = $proto->new();
	$user_name = shift;
warn "new user name: $user_name";	
	# open passfile
	my $file = $self->passfile();
	
	# add new entry
	$file =~ s/<\/passfile\s*>/<user name="$user_name" password="$user_name" \/>\n<\/passfile>/s;

	# write passfile
	$self->writePassfile( $file );
}
sub remove{
	my $proto = shift;
	my $self = $proto->new();
	$user_name = shift;

	# open passfile
	my $file = $self->passfile();
	
	# remove entry
	$file =~ s/<user[^>]*name\s*=\s*["']$user_name["'][^>]*\/>\s*\n*//s;

	# write passfile
	$self->writePassfile( $file );
}
sub passfile{
	open( PASSFILE, $passfile ) || warn "couldn't open passfile: $!";
	chomp( my @file = <PASSFILE> );
	close( PASSFILE );
	return join( "\n", @file );
}
sub writePassfile{
	my $self = shift;
	my $file = shift;
	open( PASSFILE, ">$passfile" ) || warn "couldn't open passfile: $!";
	print PASSFILE $file;
	close( PASSFILE );
	return 1;
}
sub requestChange{
	my $proto = shift;
	my $browser = shift;
	
######### load password object
	my $self = $proto->new();
	
######### load Conf
	$self->{'conf'} = Conf->load();

######### load data
	$self->{'browser'} = $browser;

######### merge password template
	my @template = $self->{'conf'}->template( $self->{'browser'}, "password" )->merge( $self );

######### password form
	my $form = <<END;
<form method="POST" action="change.cgi">
<p>name<br />
<input type="text" name="user_name" value="$self->{'user_name'}" /></p>
<p>current password<br />
<input type="password" name="password" /></p>
<p>new password<br />
<input type="password" name="new_password" /></p>
<p>confirm new password<br />
<input type="password" name="confirm_password" /></p>
<input type="hidden" name="browser" value="$self->{'browser'}" />
<p><input type="submit" value="submit" /></p>
</form>
END

######### print content-type
	print "Content-type: text/html\015\012\015\012";
	
######### print template, replace '<password />' with password form
	foreach $line ( @template ){
		if( $line =~ /<password\s+\/>/i ){
			$line =~ s/<password\s+\/>/$form/i;
		}
		print "$line\n";
	}

}
sub change{
	my $proto = shift;
	my $fd = shift;
	
warn "changing password for " . $fd->field('user_name');

	# if all fields are not filled out, request password again
	if( $fd->field('user_name') !~ /\S+/ ||
	    $fd->field('password') !~ /\S+/ ||
	    $fd->field('new_password') !~ /\S+/ ||
	    $fd->field('new_password') ne $fd->field('confirm_password') ){
		$proto->requestChange( $fd->field('browser') );
		return -1;
	}
	
	# open passfile
	my $file = $proto->passfile();
	
	# change entry
	my $user_name = $fd->field('user_name');
	my $password = $fd->field('password');
	my $new = $fd->field('new_password');
	
	if( $file =~ /<user\s+name="$user_name"\s+password="$password"[^>]*\/>/s ){
		$file =~ s/(<user\s+name="$user_name"\s+password=")$password("[^>]*\/>)/$1$new$2/s;
	} else {
		$proto->requestChange( $fd->field('browser') );
		return -1;
	}
	
	# write passfile
	$proto->writePassfile( $file );
	
	# reset client
	$proto->resetClient( $fd );

}
1;
