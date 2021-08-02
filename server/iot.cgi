#!/usr/bin/perl
#
# $Id:$
#

#
# IoT devices should be able to reach this easily with minimal syntax
# 
# there are basically two modes of interaction, a read and a write mode
#  the read mode should query the iot database and should get a reply to the requested one or more parmaters queried on
#  the write mode (default) should set new data for one or more paramaters into the database
#
# the parameters 'read' can also be controll commands
#

#
# Use:
# the device should send a query string with:
#	d  : value that identifies device, either full uuid or session uid. Required.
#	r  : the read query
#	m  : the measurement(s) to write, where # =~ /\d*/. deliminated dictionary with measurementID:value,...
#   only r or m, never both

use lib '.';
use common;

handleQuery();

1;
## end

# handle query
sub handleQuery{
    my $id = $q->param("d") // "";
    my $deviceID = getDeviceID($id);
    if($deviceID){
        processQuery();
    }else{
        print "ERROR: not valid device";
        $logger->warn("Not valid device id - ignoring query ($id)");
    }
}

# get device id
sub getDeviceID{
    my $id = shift;
    my $deviceID = 0;
    if($id){
        $deviceID = getSELECT("SELECT id FROM controllers WHERE uuid = '$id'");
#        $logger->debug("Got '$deviceID' from uuid '$id'");
        if(not $deviceID){	# device id not found as uuid, check if short id
            # TODO do a proper short id
            $deviceID = getSELECT("SELECT id FROM controllers WHERE id = '$id'");	# simple check to see if it exists
#            $logger->debug("Got '$deviceID' from short id '$id'");
        }
    }
    return $deviceID;
}

# process query
sub processQuery{
   if($q->param("r")){
       processReadQuery();
   }elsif($q->param("m")){
       processWriteQuery();
   }else{
       print "ERROR: not valid mode";
       $logger->warn("Not valid mode - ignoring query ($mode)");
   }
}

# process read query
sub processReadQuery{
   my $readQuery = $q->param("r");
   if( $readQuery =~ /^c|^m/ ){	# get short id from controller or sensor uuid
       print getShortID($readQuery);
   }elsif( $readQuery =~ /^t/ ){	# get time
       print time;
   }else{
       print "ERROR: not valid read query";
       $logger->warn("Not valid read query - ignoring query ($readQuery)");
   }
}

# get short id from uuid
sub getShortID{
    my $readQuery = shift;
    (my $what, $uuid) = ($readQuery =~ /([cm])(.*)/);
    my $table = $what eq "c" ? "controllers" : "_sensorMeasurements";
    my $sql = "SELECT id from $table WHERE uuid = '$uuid'";
#    $logger->debug("Would run sql $sql");
    return getSELECT($sql);
}

# process write query
sub processWriteQuery{
   my $measurements = $q->param("m");
   foreach my $measurement (split /,/, $measurements){
       (my $measurementID, $value) = split /:/, $measurement;
#       $logger->debug("For measurement $measurement got $measurementID and $value");
       processMeasurement($measurementID, $value);
   }
   print "DONE";
}

# process measurement
sub processMeasurement{
    $measurementID = shift;
    $value = shift;
    if(checkMeasurementID($measurementID)){
        # should check $value
        doSQL("INSERT INTO measurements (sensorMeasurementID, measurementValue) VALUES(?, ?)", $measurementID, $value);
    }else{
        print "ERROR: not valid measurement id";
        $logger->warn("Not valid measurement id ($measurementID) - ignoring query");
    }
}

# check measurement id
sub checkMeasurementID{
    my $id = shift;
    my $measurementID = 0;
    if($id){
        $measurementID = getSELECT("SELECT id FROM _sensorMeasurements WHERE uuid = '$id'");
#        $logger->debug("Got '$measurementID' from uuid '$id'");
        if(not $measurementID){	# measurement id not found as uuid, check if short id
            # TODO do a proper short id
            $measurementID = getSELECT("SELECT id FROM _sensorMeasurements WHERE id = '$id'");	# simple check to see if it exists
#            $logger->debug("Got '$measurementID' from short id '$id'");
        }
    }
}
