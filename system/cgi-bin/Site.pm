package Site;

use Category;
use Conf;
use HomePage;
use StaticPage;
use IndexPage;
use RecordPage;

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'records'} =	{};
	$self->{'categories'} =	{};
	$self->{'conf'} =	undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
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
sub numbers{
	my $self = shift;
	return keys( %{$self->{'records'}} );
}
sub record{
	my $self = shift;
	my $number = shift;
	return $self->{'records'}->{$number};
}
sub addRecord{
	my $self = shift;
	my $record = shift;
	
#print STDERR "adding record number " . $record->number() . " to Site!\n";
	$self->{'records'}->{$record->number()} = $record;
}
sub conf(){
	my $self = shift;
	return $self->{'conf'};
}

sub load{
	my $proto = shift;
	
######### get new Site object
	my $self = $proto->new();
	
######### load Conf
	$self->{'conf'} = Conf->load();

######### load categories and sort them
	foreach my $category ( $self->{'conf'}->categories() ){
		$self->{'categories'}->{$category} = Category->load( $self, $category );
		$self->{'categories'}->{$category}->sortSubs();
	}

######### return new Site object
	return $self;
}

sub crossReference{
	my $self = shift;
	
######### loop through hashes and check each field against the ids of each hash
	foreach my $category ( $self->{'conf'}->categories() ){
		foreach my $subcategory ( $self->{'categories'}->{$category}->subcategories() ){
			foreach my $crossRecord ( $self->{'categories'}->{$category}->subcategory($subcategory) ){
#warn "cross-referencing $crossRecord";
				foreach my $checkRecord ( keys(%{$self->{'records'}}) ){
					$self->{'records'}->{$crossRecord}->checkReference( $self->{'records'}->{$checkRecord} );
				}
			}
		}
	}
}

sub printAll{
	my $self = shift;
	
######### cross-reference records
	$self->crossReference();

######### print records
	foreach my $browser ( $self->{'conf'}->browsers() ){
		$self->_printList( $browser );
	}
}

sub _printList{
	my $self = shift;
	my $browser = shift;
	
######### print page templates
	foreach my $page ( $self->{'conf'}->pages($browser) ){
	
		# home page
		if( $page eq "index" ){
			HomePage->output( $self, $browser );
		
		# pages built on demand
		} elsif( $page eq "password" || $page eq "form" || $page eq "reference" ){
			# do nothing
			
		# static pages
		} else {
			StaticPage->output( $self, $browser, $page );
		}
	}
		
######### print category indexes
	foreach my $category ( $self->{'conf'}->categories() ){
		IndexPage->output( $self, $browser, $category );
	}

######### print records
	foreach $number ( $self->numbers() ){
		RecordPage->output( $self, $browser, $number );
	}
}
1;
