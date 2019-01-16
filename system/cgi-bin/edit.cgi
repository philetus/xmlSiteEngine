#!/usr/local/bin/perl

######
###### edit.cgi -- get password to edit a record
######

use Password;
use FormData;

if( $ENV{'HTTP_REFERER'} =~ /([^\/]+)\/([^\/]+).html/i ){ # browser/id.html
	
	my( $browser, $id ) = ( $1, $2 );

	# load form data object
	my $fd = FormData->new();
	$fd->set( 'browser', $browser );
	$fd->set( 'id', $id );
	$fd->set( 'form', 'edit' );

	# request password
	Password->request( $fd );
	
} else {

	# something is wrong -- dump client back to entry
	Password->resetClient();

}

exit 0;
