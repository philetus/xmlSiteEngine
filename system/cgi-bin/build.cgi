#!/usr/local/bin/perl

######
###### build.cgi -- rebuild site
######

use FormData;
use Site;

# load form data object
my $fd = FormData->load();

Site->load()->printAll();

Password->resetClient( $fd );

exit 0;
