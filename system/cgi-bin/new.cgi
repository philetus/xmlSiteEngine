#!/usr/local/bin/perl

######
###### new.cgi -- get password to create a new record
######

use Password;
use FormData;

if( $ENV{'HTTP_REFERER'} =~ /([^\/]+)\/([^\/]+).html/i ){ # browser/category.html

	my( $browser, $id ) = ( $1, $2 );

	# load form data object
	my $fd = FormData->new();
	$fd->set( 'browser', $browser );
	$fd->set( 'id', $id );
	$fd->set( 'form', 'new' );

	# request password
	Password->request( $fd );
	
} else {

	# something is wrong -- dump client back to entry
	print "Location: ../\n\n";

}

exit 0;
