#!/usr/local/bin/perl

######
###### password.cgi -- change password
######

use Password;
use FormData;

if( $ENV{'HTTP_REFERER'} =~ /([^\/]+)\/([^\/]+).html/i ){ # browser/number.html

	my( $browser, $id ) = ( $1, $2 );

	# request password
	Password->requestChange( $browser, $number );
	
} else {

	# something is wrong -- dump client back to entry
	print "Location: ../\n\n";

}

exit 0;
