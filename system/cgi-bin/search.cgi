#!/usr/local/bin/perl

######
###### search.cgi -- search site for a string
######

use Password;
use FormData;

warn "$ENV{'HTTP_REFERER'}";

if( $ENV{'HTTP_REFERER'} =~ /([^\/]+)\/[^\/]*$/i ){ # browser/id.html
	
	my( $browser, $id ) = ( $1, $2 );

	# load form data object
	my $fd = FormData->load();
	$fd->set( 'browser', $browser );
	$fd->set( 'id', $id );

	# search for string
	Search->string( $fd );
	
} else {

	# something is wrong -- dump client back to entry
	Password->resetClient();

}

exit 0;
