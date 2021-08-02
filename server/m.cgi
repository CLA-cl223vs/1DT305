#!/usr/bin/perl
#
# $Id:$
#

#
# Mobile devices (android/ios) should be redirected (rewriten) to here
# 
# this should be a more mobile friendly web page
#

use lib '.';
use common;

chomp (my $host = `hostname`);
print uc($host);

chomp(my $date = `date`);
print "::$date";

1;
## end
