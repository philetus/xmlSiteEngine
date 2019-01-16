#!/usr/local/bin/perl

######
###### form.cgi -- verify password and serve form or request password again
######

use FormData;
use Password;
use Form;
use DtdForm;

# load form data object
my $fd = FormData->load();

#warn "form: " . $fd->field("form");
#warn "browser: " . $fd->field("browser");
#warn "category: " . $fd->field("category");
#warn "number: " . $fd->field("number");
#warn "element: " . $fd->field("element");

# check for clearance
my( $allow, $status ) = Password->vet( $fd );

# if not denied, serve form
if( $allow >= 0 ){
	
#warn "form: " . $fd->field("form");
#warn "data: " . $fd->field("data");
	# if data eq dtd serve dtd form
	if( $fd->field("data") eq "dtd" ){
		DtdForm->output( $fd );
		
	# otherwise serve record form
	} else {
		Form->output( $fd->field("user_name"),
			      $fd->field("password"),
		              $status,
			      $fd->field("form"),
			      $fd->field("browser"),
			      $fd->field("category"),
			      $fd->field("number") );
	}
}

exit 0;
