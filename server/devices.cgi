#!/usr/bin/perl
#
# $Id:$
#

use lib '.';
use common;

print $q->header(-charset=>"utf-8");

$URL            = "$baseURL/devices.cgi";
my $title       = "Devices";

my $MAINDIV     = "devices";

my $calledBy = $q->param("calledBy")	// ""; 	# if called by eg some ajax

SWITCH: for ($calledBy){
    /^AJAX-displayDevices$/        && do { displayDevices(); last; };
    /^AJAX-addDevices$/            && do { addDevice();      last; };
    /^FORM-manualEntry$/           && do { addManualEntry(); last; };
    # not calledBy ajax
    displayStart();    # not called by anything so simply display the start
}

1;
## end

#
# display devices
#
sub displayDevices{
    my $family = $q->param("family") // "";
    if($family ne ""){
        my $device = $q->param("device") // "";
        if($device eq ""){
            displaySelectDevice($family);
        }else{
            displaySelectedDevice($family, $device);
        }
    }else{
        displaySelectFamily();
    }
}

#
# add device
#
sub addDevice
{
    my $family = $q->param("family") // "";
    if($family eq "controllers"){
        addNewController();
    }elsif($family eq "sensors"){
        addNewSensor();
    }else{
        print "Something wrong - no code to add devices of $family";
        $logger->warn("No Code -  cannot add devices of $family");
        die();
    }
}

#
# display select family
#
sub displaySelectFamily{
    print "<div>Select one of the following:</div><br>";
    foreach my $r (@{selectFieldsToAroH("deviceFamilies", "", ("deviceFamily"))}){
        my $family = $r->{deviceFamily};
        print "<br>".actionButton($family, "displayAJAX('family=".lc($family)."', 'AJAX-displayDevices', '$MAINDIV');", "", "", "");
    }
}

#
# display select device
#
sub displaySelectDevice{
    my $family = shift;
    my $table = "";
    my %rules = ();
    
    if($family eq "controllers"){
        $table = "controllersTypeLocation";
        $rules{uuid}{extra}    = sub {return qq!class="deemphasise"!;};
    }elsif($family eq "sensors"){
        $table = "sensorsTypeLocation";
        $rules{address}{extra} = sub {return qq!class="deemphasise"!;};
    }else{
        print "Something wrong - no code to display devices of $family";
        $logger->warn("No Code -  cannot display devices of $family");
        die();
    }
    
    $rules{name}{result} = sub {my $f = shift, my $r = shift; return qq!<a href="javascript:void(0)" onclick="displayAJAX('family=$family&device=$r->{id}', 'AJAX-displayDevices', '$MAINDIV')">$baseEyeImageURL $r->{$f}</a>!;};
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Select one of the following", $table, "", \@fields, \%rules);
    print "<br>".actionButton("ADD $family", "displayAJAX('family=$family', 'AJAX-addDevices', '$MAINDIV');", "", "", "");
    print "<br>".actionButton("Back", "displayAJAX('', 'AJAX-displayDevices', '$MAINDIV');", "", "", "");
}

#
# display selected device
#
sub displaySelectedDevice{
    my $family = shift;
    my $device = shift;
    
    if($family eq "controllers"){
        displaySelectedController($device);
    }elsif($family eq "sensors"){
        displaySelectedSensor($device);
    }else{
        print "Something wrong - no code to display device of $family";
        $logger->warn("No Code -  cannot display device of $family");
        die();
    }
}

#
# display selected controller
#
sub displaySelectedController{
    my $controllerID = shift;
    my $table = "controllersTypeLocation";
    my %rules = ();
    $rules{uuid}{extra}  = sub {return qq!class="deemphasise"!;};
    $rules{name}{result} = sub {my $f = shift, my $r = shift; return qq!<a href="javascript:void(0)" onclick="displayAJAX('family=controllers&device=$r->{id}', 'AJAX-displayDevices', '$MAINDIV')">$baseEyeImageURL $r->{$f}</a>!;};
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Controller ID $controllerID", $table, "WHERE id = $controllerID", \@fields, \%rules);

    print "<br>".actionButton("Back", "displayAJAX('family=controllers', 'AJAX-displayDevices', '$MAINDIV');", "", "", "");
}

#
# display selected sensor
#
sub displaySelectedSensor{
    my $sensorID = shift;

    # the device
    print qq!<div id=sensor>!;
    my $table = "sensorsTypeLocation";
    my %rules = ();
    $rules{address}{extra}  = sub {return qq!class="deemphasise"!;};
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Sensor ID $sensorID", $table, "WHERE id = $sensorID", \@fields, \%rules);
    print qq!<br></div>!;
    %rules = undef;

    # the location history
    print qq!<div id=locations>!;
    $table = "locatedSensors";
    my @fields = getFields($table);
    $rules{location}{result} = sub {my $f = shift, my $r = shift; return qq!<a href="locations.cgi?location=$r->{$f}">$baseEyeImageURL $r->{$f}</a>!;};
    print selectFieldsToTableWithRules("Sensor ID $sensorID location history", $table, "WHERE id = $sensorID", \@fields, \%rules);
    print qq!<br></div>!;
    
    # the sensor can measure
    print qq!<div id=measurementTypes>!;
    $table = "sensorMeasurementTypes";
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Sensor ID $sensorID can measure", $table, "WHERE id = $sensorID", \@fields, \%rules);
    print qq!<br></div>!;

    # the controller for this sensor 
    print qq!<div id=controller>!;
    $table = "controllersAndSensors";
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Sensor ID $sensorID on controller", $table, "WHERE sid = $sensorID", \@fields, \%rules);
    print qq!<br></div>!;

    # the measurements for this sensor 
    print qq!<div id=measurements>!;
    $table = "measurementsWithType";
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Sensor ID $sensorID measurements", $table, "WHERE sid = $sensorID", \@fields, \%rules);
    print qq!<br></div>!;

    print "<br>".actionButton("ADD Sensor", "displayAJAX('family=sensors', 'AJAX-addDevices', '$MAINDIV');", "", "", "");
    print "<br>".actionButton("Back", "displayAJAX('family=sensors', 'AJAX-displayDevices', '$MAINDIV');", "", "", "");
}

#
# add manual entry
#
sub addManualEntry{
    my $family  = $q->param("family");

    if($family eq "controllers"){
        # TODO         addControllerManualEntry();
    }elsif($family eq "sensors"){
        addSensorManualEntry();
    }else{
        print "Something wrong - no code to display device of $family";
        $logger->warn("No Code -  cannot display device of $family");
        die();
    }
}

#
# add sensor manual entry
#
sub addSensorManualEntry{
    my $name         = $q->param("name");
    my $address      = $q->param("address");
    my $comment      = $q->param("comment");
    my $deviceTypeID = $q->param("deviceTypeID");
    # TODO do checking!!!
    print "Would add sensor with name='$name', deviceTypeID='$deviceTypeID', address='$address', comment='$comment'";
#    doSQL("INSERT INTO sensors (name,deviceTypeID,address,comment) VALUES('?', '?', '?', '?')", $name, $deviceTypeID, $address, $comment);
#    my $sensorID = getSELECT("SELECT id FROM sensors WHERE name='?' AND deviceTypeID='?' AND address='?' AND comment='?'", $name, $deviceTypeID, $address, $comment);
#    displaySelectedSensor($sensorID);
}

#
# add new sensor
#
sub addNewSensor{
    # enter new sensor device details by hand
    my $form = qq!
        <fieldset>
         <legend>New manual entry</legend>
         <br>
         <label for="name">Name</label><input type="text" name="name" id="name">
         <br>
         <label for="address">Address</label><input type="text" name="address" id="address">
    !;

    # device types
    $form .= qq!<br><select name ="deviceTypeID" id ="deviceTypeID">!;
    $form .= qq!<option value="NONE">--select device type--</option>!;
    foreach $r (@{selectFieldsToAroH("deviceTypes", "", qw( id deviceType deviceName ))}){
        $form .= qq!<option value="$r->{id}">$r->{deviceType} $r->{deviceName}</option>!;
    }
    $form .= qq!</select>!;

    $form .= qq!
         <br>
         <label for="comment">Comment</label><input type="text" name="comment" id="comment">
         <input type="text" name="family" id="family" value="sensors" hidden>
    !;
    $form .= qq!</fieldset>!;
    $form .= actionButton("ADD", "submitForm()");
    $form .= qq!</form>!;
    $form .= "<br>".actionButton("Back", "displayAJAX('family=sensors', 'AJAX-displayDevices', '$MAINDIV');", "", "", "");
    
    print $form;
}

#
# display start page
#
sub displayStart{

    my $displayAJAX = getDisplayAJAX($URL);
    my $family = $q->param("family") // "";
    $family = "family=$family" if($family ne "");
    my $js = qq@
    <script type="text/javascript">

        $displayAJAX

	///////////////////////
        function submitForm() {
            var name         = document.getElementById('name').value;
            var address      = document.getElementById('address').value;
            var deviceTypeID = document.getElementById('deviceTypeID').value;
            var comment      = document.getElementById('comment').value;
            var family       = document.getElementById('family').value;
            displayAJAX("name="+name+"&address="+address+"&deviceTypeID="+deviceTypeID+"&comment="+comment+"&family="+family, "FORM-manualEntry", "$MAINDIV");
        }

        window.onload = function () {
            displayAJAX("$family", "AJAX-displayDevices", "$MAINDIV");
        }

    </script>
    @;

    print htmlHeader($title, $js);
    
    print qq!<div id="$MAINDIV">$baseLoadingImage</div><br>\n!;
    
    print htmlFooter();
}
