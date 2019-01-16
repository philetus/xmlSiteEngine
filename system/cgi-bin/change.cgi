#!/usr/local/bin/perl

######
###### change.cgi -- change password
######

use FormData;
use Password;

# load form data object
my $fd = FormData->load();

# change password
Password->change( $fd );

exit 0;
