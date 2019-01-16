package Conf;

use Category;
use Template;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'records'} =	{};
	$self->{'browsers'} =	{};
	$self->{'categories'} =	{};
	$self->{'templates'} =	{};
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}
sub header{
	my $self = shift;
	my $browser = shift;
	my @header = $self->{'browsers'}->{$browser}->field('header');
	return \@header;
}
sub footer{
	my $self = shift;
	my $browser = shift;
	my @footer = $self->{'browsers'}->{$browser}->field('footer');
	return \@footer;
}
sub browsers{
	my $self = shift;
	return keys( %{$self->{'browsers'}} );
}
sub browser{
	my $self = shift;
	my $browser = shift;
	return $self->{'browsers'}->{$browser};
}
sub browserByNumber{
	my $self = shift;
	my $number = shift;
	foreach my $browser ( keys(%{$self->{'browsers'}}) ){
		if( $self->{'browsers'}->{$browser}->field('record_number') eq $number ){
			return $self->{'browsers'}->{$browser};
		}
	}
	return -1;
}
sub defaultBrowser{
	my $self = shift;
	foreach my $browser ( keys(%{$self->{'browsers'}}) ){
		if( $self->{'browsers'}->{$browser}->field('user_agent','default') eq "true" ){
			return $browser;
		}
	}
	warn "no default browser";
	return -1;
}
sub categories{
	my $self = shift;
	return keys( %{$self->{'categories'}} );
}
sub category{
	my $self = shift;
	my $category = shift;
	return $self->{'categories'}->{$category};
}
sub categoryByNumber{
	my $self = shift;
	my $number = shift;
	foreach my $category ( keys(%{$self->{'categories'}}) ){
		if( $self->{'categories'}->{$category}->field('record_number') eq $number ){
			return $self->{'categories'}->{$category};
		}
	}
	return -1;
}
sub categoryType{
	my $self = shift;
	my $category = shift;
	if( $category eq "browsers" ){
		return "browser";
	} elsif( $category eq "categories" ){
		return "category";
	} elsif( $category =~ /(\w+)_templates/ ){
		return $1 . "_template";
	} else {
		return $self->{'categories'}->{$category}->field('member','type');
	}
}
sub categoryTitle{
	my $self = shift;
	my $category = shift;
	if( $category eq "browsers" ){
		return "name";
	} elsif( $category eq "categories" ){
		return "name";
	} elsif( $category =~ /\w+_templates/ ){
		return "type";
	} else {
		return $self->{'categories'}->{$category}->field('member','type');
	}
}
sub categoryUser{
	my $self = shift;
	my $category = shift;
#warn "category: " . $category;
	if( $category eq "browsers" || $category eq "categories" || $category =~ /\w+_templates/ ){
		return "false";
	} else {
		return $self->{'categories'}->{$category}->field('member','user');
	}
}
sub templateRecord{
	my $self = shift;
	my $browser = shift;
	my $type = shift;
	my $category = shift;
	if( $category !~ /\S+/ ){
		$category = "pages";
	}
	return $self->{'templates'}->{$browser}->{$category}->{$type};
}
sub template{
	my $self = shift;
	my $browser = shift;
	my $type = shift;
	my $category = shift;
	if( $category !~ /\S+/ ){
		$category = "pages";
	}
#warn "caller: " . join( ' - ', caller );
#warn "template - browser: $browser type: $type category: $category";
#warn "browsers: " . join( ' & ', keys(%{$self->{'browsers'}}) );
#warn "browser - $browser: " . $self->{'browsers'}->{$browser};
#warn "templates: " . join( ' & ', keys(%{$self->{'templates'}}) );
#warn "static template pages: " . join( ' & ', $self->pages($browser) );
#warn "template records: " . join( ' & ', keys( %{$self->{'templates'}->{$browser}->{$category}}) );
#warn "template record: " . $self->{'templates'}->{$browser}->{$category}->{$type};
	if( $self->{'browsers'}->{$browser} ){
		my @header = $self->{'browsers'}->{$browser}->field('header');
		my @footer = $self->{'browsers'}->{$browser}->field('footer');

		if( $self->{'templates'}->{$browser}->{$category}->{$type} ){
			return Template->load( \@header, \@footer, $self->{'templates'}->{$browser}->{$category}->{$type}->field('html') );	
		} else {
			return -1;
		}
	} else {
		return -1;
	}
}
sub pages{
	my $self = shift;
	my $browser = shift;
	
	if( $self->{'templates'}->{$browser} ){
		return keys( %{$self->{'templates'}->{$browser}->{'pages'}} );
	}
	warn "unknown browser";
	return -1;
}
sub matchType{
	my $self = shift;
	my $type = shift;

	if( $type eq "browser" ){
		return "browsers";
	} elsif( $type eq "category" ){
		return "categories";
	} elsif( $type =~ /(\w+)_template/ ){
		return $1 . "_templates";
	}
	foreach my $category ( keys(%{$self->{'categories'}}) ){
#warn "checking for $type: " . $self->{'categories'}->{$category}->field('member','type');
		if( $self->{'categories'}->{$category}->field('member','type') eq $type ){
			return $category;
		}
	}
	return -1;
}

sub load{
	my $proto = shift;
	
######### get new Site object
	my $self = $proto->new();
	
######### load browsers
	Category->load( $self, "browsers" );

######### load categories
	Category->load( $self, "categories" );

######### load templates
	foreach my $browser ( keys(%{$self->{'browsers'}}) ){
		Category->load( $self, "${browser}_templates" );
	}

######### return new Conf object
	return $self;
}

sub addRecord{
	my $self = shift;
	my $record = shift;
#warn "adding conf record: " . $record->title();
	# add browsers
	if( $record->number() =~ /browser/ ){
		$self->{'browsers'}->{$record->title()} = $record;
		
	# add categories
	} elsif( $record->number() =~ /category/ ) {
		$self->{'categories'}->{$record->title()} = $record;
		
	# add templates
	} elsif( $record->number() =~ /(\w+)_template/ ) {
		my $browser = $1;
		if( $record->subcategory() =~ /\S+/ && $& >= 0 ){
# warn "template type: " . $record->title();
			$self->{'templates'}->{$browser}->{$&}->{$record->title()} = $record;
		} else {
# warn "template type: " . $record->title();
			$self->{'templates'}->{$browser}->{'pages'}->{$record->title()} = $record;
		}
		
	}
}
1;
