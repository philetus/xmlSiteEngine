package XmlFile;

use MonthDayYear;
use Dtd;
use Record;
use Password;
use Conf;
use Category;
use StaticPage;
use Site;

my $xmlDir = "../xml"; # location of xml files
my $backupDir = "../backup"; # location of backup files

sub new{

######### proto is reference to prototype instance or string of prototype class name
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $self = {};
	$self->{'category'} =	undef;
	$self->{'dtd'} =	undef;
	
######### bless self into class and return a reference to it
	bless( $self, $class );
}

sub loadCategory{
	my $proto = shift;
	my $category = shift;
#warn $category->title();	
	my $self = $proto->new();
	$self->{'category'} = $category;
	
	my @file = $self->openCategory( $self->{'category'}->title() );
	$self->_ripDtd( @file );
	$self->_ripRecords( @file );
}

sub loadRecord{
#warn "loadRecord caller: " . join( ' - ', caller );
	my $proto = shift;
	my $self = $proto->new();
	$self->{'category'} = shift;
	my $number = shift;
	
	my @file = $self->openCategory( $self->{'category'}->title() );
	$self->_ripDtd( @file );

	my $file = join( "\n", @file );
	
	if( $file =~ /<(\w+)[^>]+record_number\s*=\s*["']$number["'][^>]*>/ ){
		my $tag = $&;
		if( $' =~ /<\/$1\s*>/ ){
			return Record->parse( $self, split(/\n/,$tag.$`.$&) );
		}
	}
	return -1;
}

sub loadDtd{
	my $proto = shift;
	my $self = $proto->new();
	$self->{'category'} = shift;

#warn "loadDtd caller: " . join( ' - ', caller );
#warn "category: " . $self->{'category'}->title();

	my @file = $self->openCategory( $self->{'category'}->title() );
	$self->_ripDtd( @file );
	
	return $self->{'dtd'};
}

sub dtd{
	my $self = shift;
        return $self->{'dtd'};
}

sub category{
	my $self = shift;
        return $self->{'category'};
}

sub record{
	my $self = shift;
        return @{ $self->{'records'}->[shift] };
}

sub last{
	my $self = shift;
        return $#{ $self->{'records'} };
}

sub _ripDtd{
	my $self = shift;
	my @file = @_;
#warn "ripping dtd for " . $self->{'category'}->title();
#warn "ripDtd caller: " . join( ' - ', caller );
#warn "self: " . $self;
#warn "category: " . $self->{'category'}->title();
#warn "file: " . join( ' / ', @file[0..3] );
	
######### get dtd
	my $file = join( "\n", @file );
	if( $file =~ /<\!DOCTYPE\s+\w+\s+\[([^\]]+)\]\s*>/s ){
# warn "dtd: " . $1;
		$self->{'dtd'} = Dtd->parse( split(/\n/,$1) );
		return 0;
	}
	if( $file =~ /<\!DOCTYPE\s+\w+\s+SYSTEM\s*["']([^"']+)["']\s*>/s ){
# warn "dtd: " . $1;
		$self->{'dtd'} = Dtd->parse( $self->openFile($1) );
		return 0;
	}
	warn "no dtd found for " . $self->{'category'}->title();
	return -1;
}

sub _ripRecords{
	my $self = shift;
	my @file = @_;
		
######### loop through file and parse records
	my $i = 0;
	my $start = 0;
	my $tag = -1;
	
	while( $i <= $#file ){
		if( $file[$i] =~ /<record>/ ){

			# move to line past <record>
			$i++;
			
			while( $file[$i] !~ /<\/record>/ && $i <= $#file ){
				if( $file[$i] =~ /([^<>]*<\/$tag\s*>)(.*)/ ){ # closing parent tag
		
					# move everything after closing tag to the next line
					$file[$i] = $1;
					splice( @file, $i+1, 0, $2 );
			
					# set parent tag to false
					$tag = -1;
			
					# parse Record
					my $record = Record->parse( $self, @file[$start..$i] );
			
					# add record to category
					$self->{'category'}->addRecord( $record );
			
				} elsif( $tag < 0 && $file[$i] =~ /<(\w+)[^>]*>(.*)/ ){ # parent tag					
					# set starting line number and parent tag
					$start = $i;
					$tag = $1;
				}
				$i++;
			}
			$i = $#file + 1;
		}
		$i++;
	}
}

sub openFile{
	my $self = shift;
	my $file = shift;

	# location of xml files
	my $xmlFile = "$xmlDir/$file";
		
	# open xml file
	open( XMLFILE, $xmlFile ) || warn "can't open $xmlFile: $!";
	chomp( my( @xmlFile ) = <XMLFILE> );
	close( XMLFILE );
	
	return @xmlFile;
}

sub openCategory{
	my $self = shift;
	my $category = shift;
	return $self->openFile( "$category.xml" );
}

sub writeCategory{
	my $self = shift;
	my $category = shift;
	my @file = @_;

	my @xmlFile = $self->openCategory( $category );
	
	my $now = MonthDayYear->set();
#warn "now: $now";	
	$xmlBackup = join( '.', "$backupDir/$category.xml", $now->month(), $now->day(), $now->year() );
	
	# backup xml file
#warn "xmlBackup: $xmlBackup";	
	if( open( BACKUP, ">$xmlBackup" ) ){
		foreach my $line ( @xmlFile ){
			print BACKUP "$line\n";
		}
		close( BACKUP );
	
		# location of xml files
		my $xmlFile = "$xmlDir/$category.xml";
#warn "xmlFile: $xmlFile";	
		open( WRITE, ">$xmlFile" ) || warn "can't open xml file: $!";
		foreach my $line ( @file ){
			print WRITE "$line\n";
		}
		close( WRITE );
	
	} else {
		warn "can't open backup file: $!";
	}
	
	return @xmlFile;
}

sub listCategories{

	# open xml directory
	opendir( XML, $xmlDir ) || return -1;
	
	# get contents of directory
	my( @xmlFiles ) = readdir( XML );
		
	# if file ends in .xml, add it to list of categories
	my @categories;
	foreach $file ( @xmlFiles ){
		if( $file =~ /([^\.]+)\.xml$/ ){
			push( @categories, $1 );
		}
	}	
	return @categories;
}
sub formToXml{
	my $proto = shift;
	my $self = $proto->new();
	my $fd = shift;
	my $conf = Conf->load();
	
#warn "forming xml";

######### get file and dtd
	my @file = $self->openCategory( $fd->field('category') );
	$self->_ripDtd( @file );

	my $file = join( "\n", @file );
	
######### create, update or delete record
	if( $fd->field('do') eq "create" ){
	
#warn "creating new record";
	
		# if this is a new user, add them to password list
		if( $conf->categoryUser($fd->field('category')) eq 'true' ){
#warn "category title: " . $conf->category($fd->field('category'))->field('member','title');
#warn "record title: " . $fd->field( $conf->category($fd->field('category'))->field('member','title') );
			Password->create( $fd->field($conf->category($fd->field('category'))->field('member','title')) );
		}

		# if this is a new category, create new dtd and xml files
		if( $fd->field('category') eq "categories" ){
			XmlFile->newDtd( $fd );
			XmlFile->newXml( $fd );
		}
		
		# if this is a new browser, create new templates file from default and new directory
		if( $fd->field('category') eq "browsers" ){
			my $newBrowser = $fd->field('name');
			XmlFile->newTemplate( $conf->defaultBrowser(), $newBrowser );
			mkdir( "../$newBrowser" ) || warn "can't make new dir ../$newBrowser: $!";
		}

		# get new record number
		my $number = 0;
		$file =~ s/<[^>]+record_number\s*=\s*["'][^"'\d]+(\d+)["'][^>]*>/$self->_increment(\$number,$1,$&)/ge;
		
		$number = $conf->categoryType($fd->field('category')) . $number;
		
		# add new record number to form data
		$fd->set( 'record_number', $number );
		
#warn "new record number: " . $number;
		
		$self->writeRecord( $conf, $fd, $file, $number );

	} elsif( $fd->field('do') eq "update" ){

		$self->writeRecord( $conf, $fd, $file, $fd->field('record_number') );

	} elsif( $fd->field('do') eq "delete" ) {
		
		# if this was a user, delete password
		if( $conf->categoryUser($fd->field('category')) eq 'true' ){
			my $r = Category->loadRecord( $fd->field('category'), $fd->field('record_number') );
			Password->remove( $r->field($conf->category($fd->field('category'))->field('member','title')) );
		}
						
		# replace record with nothing
		$self->replaceRecord( $fd->field('category'), $fd->field('record_number'), $file, "" );
		
	} else {		
		warn "nothing to do";
			
		# cancel; start over
		Password->resetClient( $fd );
		return -1;
	}
	
	# print 'build site' page
	StaticPage->stdout( $fd, "build_site", $conf );

}
sub _increment{
	my $self = shift;
	my $numRef = shift;
	my $newNumber = shift;
	my $match = shift;
	
	# increment record number to be at least one greater than new number
	if( $newNumber >= ${$numRef} ){
		${$numRef} = $newNumber + 1;
	}
	
	return $match;
}
sub replaceRecord{
	my $self = shift;
	my $category = shift;
	my $number = shift;
	my $file = shift;
	my $record = shift;
	
	# remove trailing whitespace
	$record =~ s/[\s\n]*$/\n/s;
	
	# remove record from file and write file with new record
	if( $file =~ /<(\w+)[^>]+record_number\s*=\s*["']$number["'][^>]*>/ ){
		my $before = $`;
		if( $' =~ /<\/$1\s*>/ ){
			return $self->writeCategory( $category, split(/\n/,$before.$record.$') );
		}
	} elsif( $file =~ /<\/record\s*>/ ){
		return $self->writeCategory( $category, split(/\n/,$`.$record."\n".$&.$') );
	}
	warn "could not replace record";
	return -1;
}
sub writeRecord{
	my $self = shift;
	my $conf = shift;
	my $fd = shift;
	my $file = shift;
	my $number = shift;
	
	# new Record from form data
	my $record = Record->parseForm( $self, $number, $conf, $fd );
#warn "record: " . $record;
#warn "record number: " . $record->number();
#warn "record title: " . $record->title();
#warn "fax number: " . join( '.', $record->field('contact','fax','area_code'),$record->field('contact','fax','prefix'),$record->field('contact','fax','suffix') );
	
	# stamp last edited with time and username
	my $now = MonthDayYear->set();
	$record->addField( $now->month(), 'last_edited', 'month' );
	$record->addField( $now->day(), 'last_edited', 'day' );
	$record->addField( $now->year(), 'last_edited', 'year' );
	$record->addField( $fd->field('user_name'), 'last_edited', 'by' );
	
	# new xml from new Record object
	my $xml = join( '', $record->xml() );
#warn "xml: " . $xml;
	# replace record with new record
	$self->replaceRecord( $fd->field('category'), $fd->field('record_number'), $file, $xml );
	
	return $record;
}
sub newTemplate{
	my $self = shift;
	my $modelBrowser = shift;
	my $newBrowser = shift;
	
	# open model template file
	my $file = join( "\n", $self->openCategory("${modelBrowser}_templates") );
	
	# change record numbers
	$file =~ s/(record_number\s*=\s*["'])[^"'\d]+(\d+["'])/$1${newBrowser}_template$2/sg;
	
	# write file
	open( WRITE, ">$xmlDir/${newBrowser}_templates.xml" ) || warn "can't open '$xmlDir/${newBrowser}_templates.xml': $!";
	print WRITE $file;
	close( WRITE );
}
sub newDtd{
	my $self = shift;
	my $fd = shift;
	
	# varibles for new dtd:
	my $cName = $fd->field('name');
	my $cUnaryName = $fd->field('member.type');
	my $cId = $fd->field('member.title');

warn "form data names: " . join( ' & ', $fd->names() );
	
######### new dtd:
	my $dtd = <<END;
<!ELEMENT $cUnaryName (subcategory?,last_edited)>
<!ATTLIST $cUnaryName
END
	
	# add title field if a title is provided
	if( $cId =~ /\S+/ ){
		$dtd .= <<END;
	$cId		CDATA		#REQUIRED		
END
	}
	
	$dtd .= <<END;
	record_number	ID		#REQUIRED
>

<!ELEMENT subcategory EMPTY>
<!ATTLIST subcategory
	name		CDATA		#REQUIRED
	rank		CDATA		#IMPLIED
>

<!ELEMENT last_edited EMPTY>
<!ATTLIST last_edited
	month		CDATA 		#REQUIRED
	day		CDATA 		#REQUIRED
	year		CDATA 		#REQUIRED
	by		CDATA		#REQUIRED
>

END
	
	# write dtd to file
	open( WRITE, ">$xmlDir/$cName.dtd" ) || warn "can't open '>$xmlDir/$cName.dtd': $!";
	print WRITE $dtd;
	close( WRITE );
}
sub newXml{
	my $self = shift;
	my $fd = shift;
	
	# varibles for new dtd:
	my $cName = $fd->field('name');

#warn "form data names: " . join( ' & ', $fd->names() );
	
######### new xml file:
	my $xml = <<END;
<?xml version="1.0"?>

<!DOCTYPE record SYSTEM "$cName.dtd">

<record>

</record>
END
	
	# write dtd to file
	open( WRITE, ">$xmlDir/$cName.xml" ) || warn "can't open '>$xmlDir/$cName.xml': $!";
	print WRITE $xml;
	close( WRITE );
}
sub formToDtd{
	my $proto = shift;
	my $fd = shift;
	
######### open dtd
	my $dtd = Category->loadDtd( $fd->field('category') );
	
######### cancel?
	if( $fd->field('do') eq "cancel" ){
		
		# return to congure site page
		my $browser = $fd->field('browser');
		print "Location: config.cgi?browser=$browser\n\n";

		return -1;
	}
	
######### edit or new child?
	if( $fd->field('form') eq "edit" ){
	
		# update or delete?
		if( $fd->field('do') eq "update" ){
			$dtd->updateElement( $fd->field('element'), $fd->field('name'), $fd->field('attributes') );
		} elsif( $fd->field('do') eq "delete" ){
			$dtd->deleteElement( $fd->field('element') );
		}
		
	} elsif( $fd->field('form') eq "new" ){
		
		# create
		$dtd->createElement( $fd->field('element'), $fd->field('name'), $fd->field('attributes') );
		
	}
	
######### write new file
	my $file = $dtd->writeFile();
	
	# filename
	my $filename = $fd->field('category') . ".dtd";
	
	# backup current dtd
	my $oldFile = join ( "\n", $proto->openFile( $filename ) );
	my $now = MonthDayYear->set();
	$dtdBackup = join( '.', "$backupDir/$filename", $now->month(), $now->day(), $now->year() );
	open( BACKUP, ">$dtdBackup" ) || warn "can't open '$dtdBackup': $!";
	print BACKUP $oldFile;
	close( BACKUP );
	
	# write file
	open( WRITE, ">$xmlDir/$filename" ) || warn "can't open '$xmlDir/$filename': $!";
	print WRITE $file;
	close( WRITE );

	# browser
	my $browser = $fd->field('browser');

	# return to congure site page
	print "Location: config.cgi?browser=$browser\n\n";
	
	return 1;
}
1;
