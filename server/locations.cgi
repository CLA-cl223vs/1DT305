#!/usr/bin/perl
#
# $Id:$
#

use lib '.';
use common;

print $q->header(-charset=>"utf-8");

$URL            = "$baseURL/locations.cgi";
my $title       = "Locations";

my $MAINDIV     = "locations";

my $calledBy = $q->param("calledBy")	// ""; 	# if called by eg some ajax

SWITCH: for ($calledBy){
    /^AJAX-displayLocations$/      && do { displayLocations(); last; };
    /^AJAX-addLocation$/           && do { addLocationForm();  last; };
    /^FORM-submit$/	           && do { addLocation();      last; };
    # not calledBy ajax
    displayStart();    # not called by anything so simply display the start
}

1;
## end

#
# display locations
#
sub displayLocations{
    my $table = "locations";
    my %rules = ();
    
    $rules{location}{check}  = sub {my $f = shift, my $r = shift; return $r->{$f} =~ /STORAGE|TEST/ ? 1 : "";};
    $rules{location}{extra1} = sub {my $f = shift, my $r = shift; return qq!style="font-weight:bold;"!;};
    my @fields = getFields($table);
    print selectFieldsToTableWithRules("Select one of the following", $table, "", \@fields, \%rules);
    print "<br>".actionButton("NEW", "displayAJAX('', 'AJAX-addLocation', '$MAINDIV');", "", "", "");
#    print "<br>".actionButton("Back", "displayAJAX('', 'AJAX-displayLocations', '$MAINDIV');", "", "", "");
}

#
# add location
#
sub addLocation
{
    my $location    = $q->param("location");
    my $description = $q->param("description");
    my $coords      = $q->param("coords");
    my $detail      = $q->param("detail");
    # TODO do checking!!!
#    print "Would add location='$location', description='$description', coords='$coords', detail='$detail'";
#    print "<br>".actionButton("Back", "displayAJAX('', 'AJAX-displayLocations', '$MAINDIV');", "", "", "");
    doSQL("INSERT INTO locations (location,description,coords,detail) VALUES(?, ?, ?, ?)", $location, $description, $coords, $detail);
    displayLocations();
}

#
# add new location form
#
sub addLocationForm{
    # enter new location details by hand
    my $form = qq!
        <fieldset>
         <legend>New manual entry</legend>
         <br>
         <label for="location">Location</label><input type="text" name="location" id="location">
         <br>
         <label for="description">Description</label><input type="text" name="description" id="description">
         <br>
         <label for="coords">Co-ords</label><input type="text" name="coords" id="coords">
         <br>
         <label for="detail">Detail</label><input type="text" name="detail" id="detail">
    !;
    $form .= qq!</fieldset>!;
    $form .= actionButton("ADD", "submitForm()");
    $form .= qq!</form>!;
    $form .= "<br>".actionButton("Back", "displayAJAX('', 'AJAX-displayLocations', '$MAINDIV');", "", "", "");
    
    print $form;
}

#
# display start page
#
sub displayStart{

    my $displayAJAX = getDisplayAJAX($URL);
    my $js = qq@
    <script type="text/javascript">

        $displayAJAX

	///////////////////////
        function submitForm() {
            var location    = document.getElementById('location').value;
            var description = document.getElementById('description').value;
            var coords      = document.getElementById('coords').value;
            var detail      = document.getElementById('detail').value;
            displayAJAX("location="+location+"&description="+description+"&coords="+coords+"&detail="+detail, "FORM-submit", "$MAINDIV");
        }

        window.onload = function () {
            displayAJAX("", "AJAX-displayLocations", "$MAINDIV");
        }

    </script>
    @;

    print htmlHeader($title, $js);
    
    print qq!<div id="$MAINDIV">$baseLoadingImage</div><br>\n!;
    
    print htmlFooter();
}
