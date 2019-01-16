#!/usr/local/bin/perl

######
###### write.cgi -- verify password and serve form or request password again
######

use FormData;
use Password;
use XmlFile;

# load form data object
my $fd = FormData->load();

# check for clearance
my( $allow ) = Password->vet( $fd );

#warn "allowed: " . $allow;

# if not denied, write xml
if( $allow >= 0 ){
	if( $fd->field('data') eq "dtd" ){
		XmlFile->formToDtd( $fd );
	} else {
		XmlFile->formToXml( $fd );
	}
} else {
	Password->resetClient( $fd );
}

exit 0;
