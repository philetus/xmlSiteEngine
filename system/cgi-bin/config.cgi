#!/usr/local/bin/perl

######
###### config.cgi -- verify password and serve config page or request password again
######

use FormData;
use Password;
use ConfigPage;

# load form data object
my $fd = FormData->load();

# if not denied, serve form
if( $allow >= 0 ){
	ConfigPage->output( $fd );
}

exit 0;
