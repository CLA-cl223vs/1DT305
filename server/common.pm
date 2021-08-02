#
# $Id: $
#


#
# this file is to be included into the other cgi scripts and contains all the 'common' or shared routines
#

#
# dependancies
#
# font awesome (see below in code)
# images (see below in code)
# css (see below in code)
#
#  CGI qw(:standard)
#  CGI::Carp qw(warningsToBrowser fatalsToBrowser)
#  Log::Log4perl qw(get_logger :levels)
#  DBIx::Log4perl qw{ :masks }
#  DBD::SQLite
#  base 'Exporter'
#

package common;

use strict;
use warnings;

our $VERSION = '1.00';

our (
    $q,				# the CGI object
    $dbh,			# the database handle
    $logger,			# the logger handle
    @EXPORT,			# the public variable, functions and subroutines of this module
    $indexURL,			# the url of the site's index page
    $baseURL,			# the base url of the site (usually "cgi-bin")
    $baseImagesURL,		# the url of the location of the images
    $baseCssURL,		# the url of the location of the css
    $baseJsURL,			# the url of the location of the java scripts
    $base3ppURL,		# the url of the location of any third pary scripts
    $baseLoadingImage,		# the image to use for 'loading'/working/waiting
    $baseLoadingImageURL,	# the url of the loading image (can be the same as the image if using special fonts)
    $baseAnchorImageFile,	# the image to use for 'anchoring'
    $baseAnchorImage,		# the url of the anchor image (can be the same as the image if using special fonts)
    $baseLockedImageFile,	# the image to use for 'locking'
    $baseLockedImage16URL,	# the image to use for 'locking', 16 pixels
    $baseLockedImage32URL,	# the image to use for 'locking', 32 pixels
    $baseEditImage16URL,	# the image to use for 'editing', 16 pixels
    $baseEditImage32URL,	# the image to use for 'editing', 32 pixels
    $baseEyeImageURL,		# the image to use for 'look-at'
    $COMMONDEBUG		# a debug flag for debug (possibly to html page) info 
);
		
# internal variable/constants
my (
    $LOG_FILE,		# the log file to use
    $DATABASE,		# the database to connect to
    $nnbsp,		# a narrow non breaking space
    $baseIndexImage,	# the image to use for the index link
    $sunrise,		# used for background colour change
    $sunset,		# used for background colour change
    $footerMsg		# message to use in footer with YYYY and YYYYMMDD substitutions
);

BEGIN {
    use CGI qw(:standard);
    use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
    use Log::Log4perl qw(get_logger :levels);
    use DBIx::Log4perl qw{ :masks };
    use base 'Exporter';
    
    $q = new CGI;

#    my $siteURL    = "/~user/site";$
    my $siteURL    = ""; 			# when called as e.g. http://site.example.com", i.e. root of site
    $baseURL 	   = "$siteURL/cgi-bin";	# this is where the NAAB cgi   files should reside
    $indexURL      = "$baseURL/index.cgi";
    $baseImagesURL = "$siteURL/images";		# this is where the NAAB image files should reside
    $baseCssURL    = "$siteURL/css";		# this is where the NAAB css   files should reside
    $baseJsURL     = "$siteURL/js";		# this is where the NAAB js    files should reside
    $base3ppURL    = "$siteURL/3pp";		# this is where the NAAB 3pp   files should reside
    $nnbsp         = "&nbsp;"; 	# narrow non-breaking space as thousand seperator (Note &#8239; does not seem to work on chrome mac el capitan so using simple one :-()

    # NOTE! using fonts from font-awesome! Make sure font-awsome-4.7.0 (or later) is in the $baseCssURL folder 
    $baseLoadingImage     = qq!<i class='fa fa-spinner fa-spin fa-2x'></i>!;	#"<img src='$baseImagesURL/ajax-loader.gif'>";
    $baseLoadingImageURL  = $baseLoadingImage;
    $baseAnchorImageFile  = "$baseImagesURL/500px-BSicon_ANCHOR.png";
    $baseAnchorImage      = qq!<i class='fa fa-anchor'></i>!;	#"<img src='$baseAnchorImageFile'>";
    $baseLockedImageFile  = "$baseImagesURL/locked-32.png";
    $baseLockedImage16URL = qq!<i class='fa fa-lock'></i>!;	#qq!<img style="width:16px;border:0" src='$baseImagesURL/locked-16.png'>!;
    $baseLockedImage32URL = qq!<i class='fa fa-lock'></i>!;	#qq!<img style="width:32px;border:0" src='$baseLockedImageFile'>!;
#	$baseEditImage16URL   = makeToolTip(qq!<i class='fa fa-pencil-square-o'></i>!, "Edit this");	#qq!<img src="$baseImagesURL/ic_mode_edit_48px-128.png" alt="Edit this" style="width:16px;height:16px;border:0">!;
    $baseEditImage16URL   = qq!<i class='fa fa-pencil-square-o'></i>!;	#qq!<img src="$baseImagesURL/ic_mode_edit_48px-128.png" alt="Edit this" style="width:16px;height:16px;border:0">!;
    $baseEditImage32URL   = qq!<i class='fa fa-pencil-square-o'></i>!;	#qq!<img src="$baseImagesURL/ic_mode_edit_48px-128.png" alt="Edit this" style="width:32px;height:32px;border:0">!;
    $baseEyeImageURL      = qq!<i class='fa fa-eye'></i>!;	#qq!<img src='$baseImagesURL/icon-eye-128.png'          alt='VIEW'      style='width:16px;height:16px;border:0'>!;

    $sunrise   = 7;	# TODO - change to actual lookup times
    $sunset    = 19;

    ####################################################
    #############EDIT########EDIT#########EDIT##########
    #vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv#
    $LOG_FILE       = "log/VY.log";                    # the logger file to use
    $DATABASE       = "VY.sqlite";                     # the database to connect to
    $baseIndexImage = "$baseImagesURL/VillaYddinge-128x128.png";	# 128x128
    $footerMsg = qq!Proprietary and Confidential, Internal use only, Copyright YYYY Villa Yddinge, YYYYMMDD!;
    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#
    ####################################################
    ####################################################

    Log::Log4perl::init(\ qq!
	    log4perl.logger.DBIx.Log4perl=DEBUG, A1
	    log4perl.appender.A1=Log::Log4perl::Appender::File
	    log4perl.appender.A1.filename=$LOG_FILE
	    log4perl.appender.A1.mode=append
	    log4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout
	    log4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n
    !);

    # exported variables
    $dbh    = DBIx::Log4perl->connect("dbi:SQLite:dbname=$DATABASE", "", "", {RaiseError => 1, AutoCommit => 1, dbix_l4p_logmask => DBIX_L4P_LOG_SQL|DBIX_L4P_LOG_DELAYBINDPARAM|DBIX_L4P_LOG_ERRCAPTURE}) or (die $DBI::errstr);
    $logger = $dbh->dbix_l4p_getattr('dbix_l4p_logger');


    @EXPORT = ( qw(
		    cleanText
    		    cleanSQL
                    getQuarter
                    selectFieldsToTable
                    selectFieldsToTableWithRules
                    selectFieldsToOverflowTable
                    selectFieldsToOverflowTableWithRules
                    selectFieldsToAroH
                    dateDiff
                    doSQL
                    formatNumber
                    getFields
                    getSELECT
                    getRowSELECT
                    getDDMONTHYYYY
                    getDisplayAJAX
                    getJournalJS
                    getYYYYMMDD
                    getMappingColourStyle
                    getPasterScript
                    getLockType
                    actionButton
                    linkButton
                    navigateButton
                    dropDown
                    dropDownLeft
                    navigateSet
                    htmlHeader
                    htmlH2
                    htmlFooter
                    htmlBody
                    htmlIndexLink
                    imgClass
                    tableRowHeader
                    tableStyledRowHeader
                    tableOverflowRowHeader
                    tableID
                    tableCell
                    tableCellMapping
                    tableCellWithToolTip
                    tableEnd
                    tableOverflowEnd
                    transactionViewLink
                    makeToolTip
                    cacheIgnore
                    $dbh
                    $q
                    $logger
                    $indexURL
                    $baseURL
                    $baseImagesURL
                    $baseCssURL
                    $baseJsURL
                    $base3ppURL
                    $baseLoadingImage
                    $baseLoadingImageURL
                    $baseAnchorImageFile
                    $baseAnchorImage
		    $baseLockedImageFile
		    $baseLockedImage16URL
		    $baseLockedImage32URL
		    $baseEditImage16URL
		    $baseEditImage32URL
		    $baseEyeImageURL
                    $COMMONDEBUG
                ) );
}

$COMMONDEBUG = $q->param('DEBUG') // 0;   # debug mode

if($COMMONDEBUG){
	$logger->debug( "**************************** DEBUG PARAMS");
	foreach my $p ($q->param){ $logger->debug("Param '$p' = '".$q->param($p)."'"); }
	#$logger->warn( "############################ WARN");
	#$logger->info( "############################ INFO");
	#$logger->error("############################ ERROR");
	#$logger->fatal("############################ FATAL");
}

END {
	$dbh->disconnect;
	undef($dbh);
	# nothing more to do here (but could have logger out message if needed)
}

1;

#
# image class
#
# returns the css class for displaying images (mainly size)
#
sub imgClass{
    my $fileSize = shift;
    my ($x, $y)  = ($fileSize =~ /(\d*)x(\d*)/);
    my ($medium, $large, $xtraLarge) = (500, 2000, 2600);
    my $class    = "fileImgSmall";
    $class       = "fileImgMedium"     if(($x >= $medium and $x < $large)     or ($y >= $medium and $y < $large));
    $class       = "fileImgLarge"      if(($x >= $large  and $x < $xtraLarge) or ($y >= $large  and $y < $xtraLarge));
    $class       = "fileImgXtraLarge"  if( $x >= $xtraLarge                   or  $y >= $xtraLarge);
    return $class;
}

#
# action Button
#
# returns a button with links for action (javascript) purposes
#
sub actionButton{
    my $text         = shift;
    my $action       = shift;
    my $extra        = shift // "";	# as full style="..." or class="" format
    my $tooltip      = shift // "";
    my $tooltipStyle = shift // "";
    
    # $extra might contain class info, extract that to use in $extraClass instead
    my $extraClass   = $extra =~ /.*class=['"](.*?)['"].*/ ? $1 : "";	# select out the content of the class="" or class='' string
    $extra =~ s/ +class=(.).*?$1//;	# remove (substitute out) the 'class=' part if not done above
    
    my $button = "";
    if( $action ){
	    $button = qq!
	        <button type="button" class="actionButton $extraClass" $extra onClick=\"$action\">$text</button>
	    !;
    }else{
	    $button = qq!
	        <button type="button" class="notActionButton $extraClass" $extra>$text</button>
	    !;
    }
#temp    $button = makeToolTip($button, $tooltip, $tooltipStyle) if($tooltip ne ""); ## WHY REMOVED??
    return $button;
}

#
# link Button
#
# returns a button with links
#
sub linkButton{
    my $text  = shift;
    my $link  = shift;
    my $extra = shift // "";	# as full style="..." or class="" format or formtarget="_blank" to open in new window!!
    my $class = shift // "linkButton";	# as class name if changing from default
    
    my ($blank) = ($extra =~ /target=.([^ '"]*)/);
    $extra =~ s/(form|)target=[^ ]*//;

    my $button = qq!
	        <button class="$class" onclick="window.open('$link', '$blank'); return false;" $extra>$text</button>
    			   !;
    return $button;
}

#
# navigate Button
#
# returns a button with links for navigation purposes
#
sub navigateButton{
    my $text  = shift;
    my $link  = shift;
    my $args  = shift // "";
    my $extra = shift // "";	# as full style="..." or class="" format or formtarget="_blank" to open in new window!!

    my $inputs = "";
    if(defined $args and $args ne ""){
        foreach my $pair ( split /[;&]/, $args ){
            my ($name, $value) = ($pair =~ /(.*)[:=](.*)/);
            $inputs .= qq!<input type="hidden" name="$name" value="$value">!;
        }
    }
    my $id = tableID($text);	# TODO maybe rename tableID to something more generic
    my $button = "";
    if($link){
	    $button = qq!
	        <form id="$id">
	        $inputs
	        <button class="navigationButton" formaction="$link" $extra>$text</button>
	        </form>
	    !;
    }else{	# no link so have disabled button
    		$button = qq!
    			<button class="notNavigationButton" type="button">$text</button>
    		!;
	}
    return $button;
}

#
# navigate set
#
# returns a set of navigate links
#
# the links are passed as an array of two or three parameters (text,link,args?) each row of links is passed in as an array of arrays and all rows as one big array for layout purposes
#
# e.g.:
#    my $previousTrip   = $tripID == 1 ? [] :                                    ["View previous trip", "$URL", "tripid:".($tripID - 1)];
#    my $nextTrip       = $tripID < getSELECT("SELECT MAX(tripID) FROM Trips") ? ["View next trip",     "$URL", "tripid:".($tripID + 1)] : [];
#    my $navigationSet = [
#        [
#            $previousTrip,
#            [ "View other trips",   $URL                                     ],
#            $nextTrip
#        ],
#        [
#            [ "Add transaction",    $addTransactionURL, "trip:$tripID"          ],
#            [ "Add trip",           $addTripURL                              ],
#        ]
#    ];
#
sub navigateSet{
    my $links = shift;

    my $set = qq!
        <p>    
        <nav><table class="navigationSet">
       !;
    
    foreach my $row ( @{$links} ){
        $set .= "<tr>";
        foreach my $link ( @{$row} ){
            next if(not defined $link or scalar @{$link} < 1);
            $set .= "<td>".navigateButton(shift @{$link}, shift @{$link}, shift @{$link})."</td>";
        }
        $set .= "</tr>";
    }    
    
    $set .= "</table></nav><br>";
    
    return $set;
}

#
# getYYYYMMDD
#
# returns array of YYYY, MM, DD from YYYYMMDD
#
sub getYYYYMMDD{
    my $date    = shift;
    my $singleD = shift // 1;
    my ($YYYY, $MM, $DD) = ($date =~ /^(\d{4})(\d{2})(\d{2})/);
    $DD =~ s/^0(.*)/$1/g if($DD =~ /^0/ and $singleD);
    return $YYYY, $MM, $DD;
}

#
# getDDMONTHYYYY
#
# returns array of DD, MONTH, YYYY with MONTH being three letter english month name from date with offset
#
sub getDDMONTHYYYY{
    my $date   = shift;
    my $offset = shift // "";
    
    chomp(my $newDate = `date --date="$date $offset" +"%-d %b %Y"`);	# simply changing the format to more human readable
    my ($DD, $MTH, $YYYY) = (split / /, $newDate);
    return $DD, $MTH, $YYYY;
}

#
# getQuarter
#
# returns YYYYQ# for the financial year quarter the date is in
#
sub getQuarter{
    my $date   = shift;
    
    $date =~ s/^(\d{8}).*/$1/;	# remove hours and seconds if any
    (my $YYYY) = ( $date =~ /^(\d{4})/ );
    chomp(my $month = `date --date="$date" +"%-m"`);	# the month with no leading zeros
    my $quarter = int(($month - 1)/3) + 1;	# from Q1 to Q4
    return "${YYYY}Q$quarter";
}

#
# date diff - the difference between two dates in days
#
sub dateDiff{
    my $d1 = shift;
    my $d2 = shift;
    
    chomp(my $e1 = `date -d "$d1" +%s`);
    chomp(my $e2 = `date -d "$d2" +%s`);
    return `echo \$(( ((($e1-$e2) > 0 ? ($e1-$e2) : ($e2-$e1)) + 43200) / 86400 ))`;
}


#
# returns the html header
#
sub htmlHeader{
    my $header    = shift;
    my $addtional = shift // "";
    my $bodyText  = shift // "";
    
    (my $title = $header) =~ s/<.*[^=]>//g;
####    my $html = $q->header(-charset=>"utf-8");
    my $html = "";
    my $body = htmlBody($bodyText);
    $html .= qq@
<!DOCTYPE html>
<html>
<head>
    <title>$title</title>
    <meta HTTP-EQUIV="Pragma"  CONTENT="no-cache">
    <meta HTTP-EQUIV="Expires" CONTENT="-1">
    <link rel="stylesheet" href="$baseCssURL/common.css" type="text/css" />
    <link rel="stylesheet" href="$baseCssURL/font-awesome-4.7.0/css/font-awesome.css" type="text/css" />
    <link rel="stylesheet" href="$baseCssURL/rc.css" type="text/css" />
    $addtional
</head>
$body

@;
    $html .= htmlH2($header);

    return $html;
}

#
# returns the html h2 tag
#
sub htmlH2{
    my $text = shift // "";

    my $COMMONDEBUGHTML = $COMMONDEBUG >= 1 ? debugLink($COMMONDEBUG) : "";
    
    return qq!<h2><a href="$indexURL"><img border="0" src="$baseIndexImage" width="128" height="36" align="bottom"></a>$COMMONDEBUGHTML&nbsp;&nbsp;$text</h2>\n!;
}

#
# debug link
#
# returs the link and query with debug param if debug flag active
#
sub debugLink{
    my $COMMONDEBUG         = shift;

    my $COMMONDEBUGgerImage = "$baseImagesURL/debugger-512.png";
    my $COMMONDEBUGHTML     = "";
    my $cacheIgnore   = cacheIgnore();
    foreach my $i ( ($COMMONDEBUG - 1), $COMMONDEBUG, ($COMMONDEBUG + 1) ){
        my $imgURI    = convert("..$COMMONDEBUGgerImage", $i);    # relative from the cgi script directroy
        my $imgSize   = $i == $COMMONDEBUG ? 32 : 24;
        my $query     = $i == 0            ? "" : "DEBUG=$i";
        
        my $orgParam = "";
        foreach my $p ($q->param){
            $orgParam .= "&$p=".$q->param($p) if($p !~ /DEBUG|cacheignore/);
        }
        $COMMONDEBUGHTML   .= qq!<a href="?$query$orgParam$cacheIgnore"><img border="0" src="$imgURI" width="$imgSize" height="$imgSize" align="bottom"></a>!;
    }

    return $COMMONDEBUGHTML;
}

#
# convert (image magik) image and add text then encode to base64 
#
sub convert{
    my $imageFileName = shift;
    my $text          = shift // "";
    #
    # TODO - auto the size of the image based on original ; look at colour of text ; look at caption: command for longer text ; look at better file location
    #

    chomp(my $resultFileName = `date +%Y%m%d%H%M%S%N-converted.png`);
    if($text ne ""){  # if text to add to image
        my $cmd              = "convert -size 500x500 -pointsize 500 xc:none -gravity SouthEast -stroke black -strokewidth 20 -annotate 0 '$text' -background none -shadow 300x-15+0+0 +repage -stroke none -fill CadetBlue1 -annotate 0 '$text' $imageFileName  +swap -gravity SouthEast -geometry +0-30 -composite  $resultFileName";
        my $cmdResult        = `$cmd`;
        $imageFileName       = $resultFileName;
    }

    open IMAGE, $imageFileName or next;
    my $image = do{ local $/ = undef; <IMAGE>; };
    close IMAGE;
    unlink $resultFileName if($text ne "");
    
    use MIME::Base64 qw( encode_base64 );
    my $encodedImage = encode_base64($image);
    my $imgURI       = "data:image/png;base64,$encodedImage";

    return $imgURI;
}

#
# html Body
#
# returns html tag opening body with background subdued if night
# TODO - move this to css
#
# treat webkit special
#
sub htmlBody{
    my $htmlText = shift // "";
    
    my $time    = `date +%k`;
    
    my $webkit  = $q->param('webkit') // "";	# running under webkit (wkhtmltopdf) and not normal browser	
    if($webkit ne ""){
        if($htmlText =~ /class/){	# the html text was also a class definition, so need to combine it with our class
            $htmlText =~ s/class="([^"])"/class="wkBody $1"/;
        }else{
            $htmlText =~ s/(.*)/class="wkBody" $1/;
        }
    }
    my $body =  "<body $htmlText>";
       $body =~ s/>/ style=\"background-color:gainsboro;\">/ if($time <= $sunrise or $time >= $sunset);
    return $body;
}

#
# html index link
#
sub htmlIndexLink{
    my $htmlText = shift // "";
    my $html  = qq!<a href="$indexURL" title="$htmlText"><img border="0" src=$baseIndexImage width="128" height="36" align="bottom"></a>!;
       $html .= "&nbsp;&nbsp;".navigateButton($htmlText, $indexURL) if($htmlText ne "");
    return $html;
}

#
# returns the html footer
#
# NOTE - this closes the <html> tag!! 
#
# TODO - use css
#
sub htmlFooter{
    my $numLink = shift // 1;	# zero for no link
    
    my $html = "";
    
    my $webkit = $q->param('webkit') // "";	# running under webkit (wkhtmltopdf) and not normal browser	
    if($webkit eq ""){

        chomp(my $date = `date +%Y.%m.%d\\ %H:%M:%S`);
        (my $year) = ($date =~ /^(\d{4})/);
        $html .= "\n\n<br/>\n". htmlIndexLink("Back to Index") if($numLink ne 0);
        chomp(my $time = `date +%k`);
        my $style = ( $time <= $sunrise or $time >= $sunset ) ? "background-color:lightslategrey;color:white" : "background-color:#E0ECF7";
        $html .= qq~
        <table style="font-family:Arial;width:100%;" border="0" cellpadding="0" cellspacing="0">
            <tr>
                <td style="font-size:50%;$style">
                    <center>
                        $footerMsg
                    </center>
                </td>
            </tr>
        </table>

        </body>
        </html>
       ~;
       $html =~ s/YYYYMMDD/$date/;
       $html =~ s/YYYY/$year/;
    }
    
    return $html;
}


#
# cache ignore returns a get param with a date (now) that should trick the borwser into getting a new (not cached) page
#
sub cacheIgnore{
    chomp(my $now = `date +%Y%m%d%H%M%S`);
    return "&cacheignore=$now";
}

#
# returns a html table of the selected results
#
sub selectFieldsToTable{
    my ($header, $sqlTable, $sqlWhere, @fields) = @_;
    my $overflow = 0;
    my $size     = "";

    return selectFieldsToOverflowTable($header, $sqlTable, $sqlWhere, $overflow, $size, @fields);
}

#
# returns a html table of the selected results with rules
#
sub selectFieldsToTableWithRules{
    my ($header, $sqlTable, $sqlWhere, $fieldsRef, $rulesRef) = @_;
    my $overflow = 0;
    my $size     = "";

    return selectFieldsToOverflowTableWithRules($header, $sqlTable, $sqlWhere, $overflow, $size, $fieldsRef, $rulesRef);
}

#
# returns a html table with overflow of the selected results
#
sub selectFieldsToOverflowTable{
    my ($header, $sqlTable, $sqlWhere, $overflow, $size, @fields) = @_;
    my $rules = 0;
    
    return selectFieldsToOverflowTableWithRules($header, $sqlTable, $sqlWhere, $overflow, $size, \@fields, $rules);
}

#
# returns a html table with overflow of the selected results with rules
#
# RULES
# the rules are passes as a reference to a hash of hash
# the first level is for the field ($f) the rule applies to
# the second level hash has the following rule types:
#     check     => returns a positive number ## for specifc condition matched
#     result    => returns a new result
#     result##  => same as result but matching specific check return condition ##
#     extra     => returns any extra (eg style)
#     extra##   => same as extra but matching specific check return condition ##
#     tooltip   => returns a tool tip 
#     tooltip## => same as for tooltip but matching specific check return conditon ##
#     column    => returns new column header to use (no conditional check - always use same column header for this field in this table)
# all rules are references to a function that take $f and $r with $f being the field
#     and $r the hash of the sql result 
#
sub selectFieldsToOverflowTableWithRules{
    my ($header, $sqlTable, $sqlWhere, $overflow, $size, $fieldsRef, $rulesRef) = @_;

    my @fields  = @$fieldsRef;
    my %rules   = $rulesRef ? %$rulesRef : ();
    my $tooLong = 7;	# need to repeat header within body of table

    my $table   = tableOverflowRowHeader($header, "", 0, $overflow, $size, @fields);
    my $selection = selectFieldsToAroH($sqlTable, $sqlWhere, @fields);
    my $i = 0;
    foreach my $r(@{$selection}){
        my $trClass = $i % 2 ? "class=\"even\"" : "class=\"odd\"";
        $table .= "<tr $trClass>\n";
        foreach my $f (@fields){
            $f =~ s/.*AS //;	# for the renaming of fields if AS _something_ used
            $r->{$f} = "" if( not defined $r->{$f} );	# null
            if($rulesRef and $rules{$f}){   # rules defined and have a rule for this field
                my $check   = defined $rules{$f}{check} ? $rules{$f}{check}->($f, $r) : ""; # if check condition then only use that (if exist or fall back to basic rules)
	        my $result  = defined $rules{$f}{"result$check"}  ? $rules{$f}{"result$check"}->($f, $r)  : defined $rules{$f}{result}  ? $rules{$f}{result}->($f, $r)  : $r->{$f}; # ALWAYS NEED AT LEAST RESULT
	        my $extra   = defined $rules{$f}{"extra$check"}   ? $rules{$f}{"extra$check"}->($f, $r)   : defined $rules{$f}{extra}   ? $rules{$f}{extra}->($f, $r)   : "";    # optional extra
	        my $tooltip = defined $rules{$f}{"tooltip$check"} ? $rules{$f}{"tooltip$check"}->($f, $r) : defined $rules{$f}{tooltip} ? $rules{$f}{tooltip}->($f, $r) : "";    # optional tooltip
	        my $column  = defined $rules{$f}{"column"}        ? $rules{$f}{"column"}->($f, $r)        : $f;
                $table .= tableCellWithToolTip($column, $result, $extra, $tooltip);
            }else{
                $table .= tableCell($f, $r->{$f});
            }
        }
        $table .= "</tr>\n";
        if( $i % $tooLong == 0 and $i != 0){ $table .= tableRowHeader("", "", 1, @fields); }	# long so use 'middle' header
        $i++;
    }    
    $table .= $overflow ? tableOverflowEnd($header) : tableEnd($header);

    return $table;
}

#
# returns table cell with better format
#
sub tableCell{
    my $columnHeader = shift;
    my $content      = shift // "";
    my $additional   = shift // "";	# eg style=''
    my $tooltip      = "";
    
    return tableCellWithToolTip($columnHeader, $content, $additional, $tooltip);
}

#
# returns table cell with mapping format
#
sub tableCellMapping{
    my $columnHeader     = shift;
    my $content          = shift // "";
    my $additional       = shift // "";
    my $mapping          = shift // "";
    my $mapped           = shift // "";
    my $tooltip          = shift // "";
    my $alternativeStyle = shift // "";
    
    my $style = "";
    if($mapping and $mapped and $$mapping{$mapped}){
        $columnHeader   = "Text";
### REMEBER for original NAAB:        $tooltip       .= $mapped eq "TransactionID" ? transactionViewLink($$mapping{$mapped}) : " ".$$mapping{$mapped};
        $tooltip       .= " ".$$mapping{$mapped};
        $style          = getMappingColourStyle($$mapping{'rowid'});
    }else{
        $style = " $alternativeStyle" if($alternativeStyle);
    }
    if($additional =~ /style\=/){	# comes with style so need to capture that
		(my $styleQuote)      = ($style =~ /style\=(.)/);
		my $re                = qr!style=$styleQuote([^$styleQuote]*)$styleQuote!;
		(my $additionalStyle) = ($style =~ /$re/);    	
        $additional  =~ s|style\=(.)|style\=$1;$additionalStyle|;
    }else{
        $additional .= " $style"; 
    }
   return tableCellWithToolTip($columnHeader, $content, $additional, $tooltip);
}

#
# returns table cell with better format and possible tooltip
#
sub tableCellWithToolTip{
    my $columnHeader = shift;
    my $content      = shift // "";
    my $additional   = shift // "";
    my $tooltip      = shift // "";
    
    my $localDebug = $COMMONDEBUG >= 2 ? 1 : 0;
	$logger->debug("Got\ncolumnHeader:\n$columnHeader\ncontent:\n$content\nadditonal:\n$additional\ntooltip:\n$tooltip'") if($localDebug);

    my $class   =  "";
    my $comment =  "COLUMNHEADER:$columnHeader|CONTENT:$content|ADDITIONAL:$additional|TOOLTIP:$tooltip";
    $comment    =~ s/--/- -/g if($comment =~ /--/);
    $comment    =  "<!--$comment-->";
	$logger->debug("Got\ncomment:\n$comment'") if($localDebug);

    # 
    # format as a NUMBER with various decimal accuracies, thousand seperator and negative number emphasis
    #
    if($columnHeader =~ /Amount|SEK|EUR|fAmount|Normalbelop|^Claim$|Tax|MOMS|Balance/i and not $columnHeader =~ /ID/){	# some tables have a transactions_SEK_ID for example
        my $realContent = $content;
        my $tag         = "";
        my $hasLink     = 0;
        if($content =~ /<.*>/){	# has html (well has at least '<' followed by a '>' which most likly is html
            $comment .= "<!--has html-->";
            if($content =~ /<a/){	# has a link
                $realContent =~ s/\<a.*\>([^\<]*)\<\/a\>/$1/;
                $hasLink = 1;
                $comment .= "<!--has link-->";
            }else{	# probably some span or div before (eg <span>SEK</span>123 )
                ($tag, $realContent) = ($realContent =~ /(.*>)([^<]*).*/);
                $comment .= "\n\t<!--TAG:$tag-->";
            }
        }
        $comment .= "\n\t<!--REALCONTENT:".$realContent."-->";
        $logger->debug("Real content 1 '$realContent', from content '$content'") if($localDebug);

        $class .= $realContent =~ /-\d/ ? " negamount" : " amount";
        $logger->debug("HERE with negative amount '$content' and '$realContent'") if($class =~ /negamount/ and $localDebug);
        $logger->debug("Real content 2 '$realContent', class '$class' from content '$content'") if($localDebug);
        $realContent =~ s/^0.0*$//;	# should produce an 'empty' cell if the number was zero
        $logger->debug("Real content 3 '$realContent', tag '$tag' from content '$content'") if($localDebug);
        if($realContent !~ /^$|[A-Za-z]/){	# sometimes no actual amount or a word (like 'missing' or 'add' for when number is missing and needs to be added - eg viewTrip.cgi)
            if($columnHeader =~ /SEKEUR|EURUSD|EURSEK/){
                $realContent = formatNumber($realContent, 6);
            }elsif($columnHeader =~ /X.SEK/){
                $realContent = formatNumber($realContent, 6);
                $additional .= qq! style="font-size:x-small"! ;
            }else{
#            	$logger->debug("Will format '$realContent");
                $realContent = formatNumber($realContent, 2, 1, 1, 1) ; # should add decimal to integers, 2 decimal precision, thousand seperator, smaller decimals and negative highlight
            }
        }
        $logger->debug("Real content 4 '$realContent', tag '$tag' from content '$content'") if($localDebug);
        $realContent = $tag.$realContent;
        if($hasLink){
            $content =~ s/(.*\>).*(\<.*\>)/$1$realContent$2/;
        }else{
            $content = $realContent;
        }
       $logger->debug("Amount formated to: '$content'") if($localDebug);
    }
    # 
    # format as a NUMBER
    #
    elsif($columnHeader =~ /ID|Currency/){
        $class = "number";
    }
    # 
    # format as a TEXT 
    #
    elsif($columnHeader =~ /Description|Details|Comment|note/){
        $class = "description";
    }
    # 
    # format as a DATE with . as seperator
    #
    elsif($columnHeader =~ /Date/i){
        if($content =~ /\d{8}[\.-]\d{4}/){
            $content =~ s/(\d\d\d\d)(\d\d)(\d\d).(\d\d)(\d\d)/$1.$2.$3 $4:\<span style\=\"font\-size\:80\%\;vertical-align:top"\>$5\<\/span\>/;
        }else{
            $content =~ s/(\d\d\d\d)(\d\d)(\d\d)/$1.$2.$3/ if($content !~ /\d{9}/);	# not 9 digits like the invoice numbers
        }
    }

	# FORMATS given in content or header
	####################################
    # 
    # format as EMPHASIS
    #
    if($content =~ /^TOTAL$|^Average$/i or $columnHeader =~ /^emphasise{0,1}$|TOTAL|Average/i){
        $class .= " emphasise";
    }
    # 
    # format as RIGHT (typically right align)
    #
    if($columnHeader =~ /right/i){
        $class .= " right";
    }
    # 
    # format as CENTER (typically center align)
    #
    if($columnHeader =~ /center/i){
        $class .= " center";
    }
    # 
    # format as background information (de-emphasise)
    #
    if($columnHeader =~ /deemphasise|GrossTax|CostToCompany/i){
        $class .= " deemphasise";
    }
    
    if($additional =~ /class/){	# the additional content was also a class definition, so need to combine it with our class
        (my $additionalClass) = ($additional =~ /class=['"](.*)['"]/);
        $class .= " $additionalClass";
        $additional =~ s/class=['"].*['"]//;	# TODO No check for  multiple '' or "" in additional string. Should regex not .* but something like [^'"]*
    }

    if($tooltip){
        $class .= " tooltip";
        $content  .= qq!<span class="tooltiptext">$tooltip</span>!;
    }

    if($class ne ""){
        $class =~ s/(.*)/ class=\"$1\"/ ;
    }

    my $td = "<td $class $additional>";
       $td .= "$comment" if ($comment ne "");
       $td .= "$content";
       $td .= "</td>";
       $td =~ s/ \>/\>/g;
    $logger->debug("Give td:\n$td\n") if($localDebug);
    return $td;
}

#
# number to formated
#
# TODO - check if this is a number and not some other text!!!
#
sub formatNumber{
    my $originalNumber    = shift;
    my $decimals          = shift // 2; # accurate to 2 decimal places
    my $thousandSeperator = shift // 0; # default false to thousand separator
    my $smallerDecimals   = shift // 0; # default false to smaller decimals
    my $highlightNegative = shift // 0; # default false highlighting negative numbers
    
    return "" if($originalNumber eq "");
    
    my $seperator         = $nnbsp;    # narrow non-breaking space

    my $number = sprintf "%.".$decimals."f", $originalNumber; # should add decimal to integers
    $number    =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/$seperator/g                                     if($thousandSeperator);	# should add thousand seperator
    $number    =~ s/(.*)\.(.*)/$1.\<span style\=\"font\-size\:80\%\"\>$2\<\/span\>/g          if($smallerDecimals);	    # should make the decimal parts smaller
    $number    =~ s/^\-(.*)/\<span style\=\"font\-weight\:bold\"\>&minus;$nnbsp\<\/span\>$1/g if($highlightNegative);	# should make the -ve sign bold and space
    
    return $number;
}

#
# returns array reference of hashs of the selected results
#
sub selectFieldsToAroH{
    my ($sqlTable, $sqlWhere, @fields) = @_;
    my $sql = "SELECT ".join(', ', @fields)." FROM $sqlTable $sqlWhere";
    my $selected = $dbh->selectall_arrayref($sql, { Slice => {} });
    return $selected;
}

#
# get fields - returns the fields of a table
#
sub getFields{
    my $table = shift;
    my $sth = $dbh->prepare("pragma table_info($table)");
    $sth->execute();
    my @fields = ();
    while (my $r = $sth->fetchrow_arrayref()){
       push @fields, @$r[1];
    }
    return @fields;
}

#
# gets a single value from a select statement, assumes clean SQL select with only one return param, returns empty string if undef (ie if null)
#
sub getSELECT{
    my $currentLevel = $logger->level();
    $logger->level($FATAL);
    my $q = $dbh->selectrow_array(shift) // "";
    $logger->level($currentLevel);
    return $q;
}

#
# gets value(s) from a select statement, assumes clean SQL select with only one row, returns empty string if undef (ie if null)
#
sub getRowSELECT{
#    my $currentLevel = $logger->level();
#    $logger->level($FATAL);
    my @row = $dbh->selectrow_array(shift);
#    $logger->level($currentLevel);
    return @row ? @row : "";
}

#
# returns html table tag with start marker
#
sub tableStart{
    my $id    = shift;
       $id    = tableID($id);     # in case
    my $style = shift;
    return(qq!\n<span id="startoftable-$id"></span>\n<table id="$id" $style>!);
}

#
# returns html table tag with end marker
#
sub tableEnd{
    my $id = shift // "";
       $id = tableID($id);     # in case
    $logger->debug("WARNING: table end with no id. Use header as id") if(not $id);
    return("\n</table><span id=\"endoftable-$id\"></span>\n");
}

#
# returns html overflow table tag with end marker
#
sub tableOverflowEnd{
    my $id = shift // "";
    return tableEnd($id)."</div>";

}

#
# returns table id from string (typically the table header)
#
sub tableID{
    my $id = shift;
       $id =~ s/ *//g;	# use string (or header) with no space as the id of this table
    return $id;
}

#
# returns html table row header string from array
#
sub tableRowHeader{
    my $header     = shift;
    my $extra      = shift;
    my $miniHeader = shift;
    my $overflow   = 0;     # none
    my $size       = "";    # only needed if overflow is enabled
    return tableOverflowRowHeader( $header, $extra, $miniHeader, $overflow, $size, @_);
}

#
# returns overflow html table row header string from array
#
sub tableOverflowRowHeader{
    my $header     = shift;
    my $extra      = shift;
    my $miniHeader = shift;
    my $overflow   = shift;
    my $size       = shift;
    my $style      = "";
    return tableOverflowStyledRowHeader( $header, $extra, $miniHeader, $style, $overflow, $size, @_);
}

#
# returns styled html table row header string from array
#
sub tableStyledRowHeader{
    my $header     =  shift;
    my $extra      =  shift;
    my $miniHeader =  shift;
    my $style      =  shift;
    my $overflow   =  0;
    my $size       =  "";

    return tableOverflowStyledRowHeader($header, $extra, $miniHeader, $style, $overflow, $size, @_);
}

#
# returns styled overflow html table row header string from array
#
sub tableOverflowStyledRowHeader{
    my $header     =  shift;
    my $extra      =  shift;
    my $miniHeader =  shift;
    my $id         =  tableID($header);
    my $defaultStyle = qq!border="2" rules="all" cellpadding="4" width="100%"!;
    my $style      =  shift || qq!id="$id" $defaultStyle!;   # not // as only change if empty string (ie false)
    my $overflow   =  shift;                                                                        # of type 0 = none; 1 = after header; 2 = after header and row header
    my $size       =  shift || "70vh";                                                              # for overflow, default to 70% of vh if empty and overflow on (1 or 2) ; not // as only change if empty string (ie false)
    
    my $numColumns =  scalar @_;
    my $bgcolor    =  $miniHeader ? "grey" : "teal";    # TODO move to css
    my $startTable =  "<a href=\"#startoftable-$id\">&uarr;</a>        ";
    my $endTable   =  "<a href=\"#endoftable-$id\"  >&darr;</a>&thinsp;";
    my $rowHeader  =  "";
    $numColumns++  if($extra ne "");
    $header        =  toTableHeader($header);

    if( not $miniHeader ){
        $rowHeader = $overflow ? tableStart("", $style) : tableStart($id, $style);
    }

 
    # table header
    $rowHeader    .=  qq!<tr><th colspan="$numColumns" style="color:white;background-color:navy">$header</th></tr>\n! if($header ne "" and not $miniHeader);
    if($overflow == 1){ # need to overflow after the table header
        $rowHeader .= qq!</table><div class="overflow" id="ofh-$id" style="overflow-y:auto; max-height:$size;">!;
        $rowHeader .= tableStart("oft-$id", $defaultStyle);
    }
 
    # row header
    $rowHeader .= tableCellHeaders("$startTable$endTable", $extra, $bgcolor, 1, @_);
    if($overflow == 2){ # need to overflow after the table row header
    	# NOTE and TODO, this can cause the cell widths of the overflow table to be misaligned from the header row
        $rowHeader .= qq!</table><div class="overflow" id="ofr-$id" style="overflow-y:auto; max-height:$size;">!;
        $rowHeader .= tableStart("oft-$id", $defaultStyle);
        $rowHeader .= tableCellHeaders("oft-$id", $extra, $bgcolor, 0, @_);    # trying to fix column widths accross two tables :-(  TODO
    }

    return $rowHeader;
}

#
# table cell headers
#
sub tableCellHeaders{
    my $navigationString = shift;
    my $extra            = shift;
    my $bgcolor          = shift;
    my $display          = shift;
    my @headers          = @_;

    my $hide           = $display ? "" : "height:1px !important;max-height:1px !important;color:$bgcolor !important;font-size:0px !important;";
    my $rowHeader      =  qq!<tr style="color:white;background-color:$bgcolor;$hide">\n!;
    my $needNavigation = 1;
    foreach my $f (@headers){
        my $h      =  toTableHeader($f);
        if($needNavigation){
            $rowHeader .= qq!<th align="center">$navigationString$h</th>\n!;
            $needNavigation = 0;
        }else{
            $rowHeader .= qq!<th align="center">$h</th>\n!;
        }
    }
    $rowHeader    .=  "$extra</tr>\n";
    return $rowHeader;
}

#
# to table header
#
# formats for easier reading
#
sub toTableHeader{
    my $header =  shift;

    my $toUpper    =  qr/(Pdf|Id|Uuid|Url|Paye|Cjla|Yyyymmdd|Sek|sek|Eur|eur|Zar|Cny|Gbp|Usd|usd|Thb|Dkk|Hkd|Aed|Moms|Aa|Bp|\d\d\d\dq\d|Ce|Fy\d)/;
    
    $header    =~ s/([a-z])([A-Z])/$1 $2/g; 	# split CamelCase for auto wrap in table (not mnemonics like ID), temp var to not modify array
    $header    =~ s/_/ /g;	                # split joint_words for auto wrap in table 
    $header    =~ s/.*AS //;	                # for the renaming of fields if AS _something_ used
    $header    =~ s/(\w+)/\u\L$1/g;             # first letter upper case rest lower for each word
    $header    =~ s/$toUpper/\U$1/g;            # change back to uppercase for special words and mnemonics
    return $header;
}

#
# does sql
#
sub doSQL{
    my $sql          = shift;
    my @placeholders = @_;

## leaves formating and checking to calling function
## note that using NULL here as a parameter will place it as 'NULL' in the sql ?
## if needing NULL, then best not use that specific ? in the calling sql
## swapping out empty strings to null here might NOT be what the calling function intended: removing code below:
#    my $nulls = qr!^$|''|'NULL'|""|"NULL"!i;
#    $sql =~ s/$nulls/NULL/g;
#    if(@placeholders){	# if any paramaters sent for the placeholders, then replace empty or quoted nulls with sql null
#    	foreach my $placeholder (@placeholders){
#	   $placeholder =~ s/$nulls/NULL/g;
#	}
#    }

    my $result = $dbh->do($sql, undef, @placeholders);
    $logger->debug("doSQL result: $result") if($COMMONDEBUG);
}

#
# get paster script
#
# returns javascript of 3rd party paste javascript
#
# pre-requisites:
#      1) there is a table to place the pasted image/text in, referenced by a table id. A new row will be created at the end of the table. The table MUST HAVE a tbody.
#      2) there should be a textarea to paste into, identified by the text id. This is for non FF browsers, as FF can past anywhere on page.
#			eg: ADD image by pasting the image onto this page, not on FF paste in this box: <textarea id="text" style="width:75px;height:15px;">Chrome/Safari paste here</textarea>
#      3) there is a div to place a progress or spinning wheel in, identified by the wheel id.
#
sub getPasterScript{
    my $tableID    = shift;	# id of html element to paste into
    my $IDType     = shift;	# type of $ID that this paste is for
    my $ID         = shift;	# ID this paste is for
    my $wheelID    = shift // "wheel";	# id of wheel element (where loading wheel shown)
    my $textID     = shift // "text";	# id of text element (where paste into happens)
    my $addFileURL = shift // "$baseURL/addFile.cgi";	# url to post to

	return qq!
		  //
		  // get PASTER script below
		  //

          //Define paster object with contructor
          var Paster = function(config) {
            for(var key in config){
              this[key]=config[key];
            }
            this.init();
          };

          Paster.prototype.pasteEl=null;

          Paster.prototype.init=function() {
            var paster = this;

            if (window.Clipboard) {	//IE11, Chrome, Safari
              this.pasteEl.onpaste=function(e){
                paster.handlePaste(paster, e);
              };
            }else{			//On Firefox use the contenteditable div hack
              this.canvas = document.createElement("canvas");
              this.pasteCatcher = document.createElement("div");
              this.pasteCatcher.setAttribute("id", "paste_ff");
              this.pasteCatcher.setAttribute("contenteditable", "");
              this.pasteCatcher.style.cssText = "opacity:0;position:fixed;top:0px;left:0px;";
              this.pasteCatcher.style.marginLeft = "-20px";
              document.body.appendChild(this.pasteCatcher);
              this.pasteEl.onblur=function(e) {
                paster.pasteCatcher.focus();
              };
              this.pasteCatcher.focus();
              this.pasteCatcher.onpaste=function(e) {
                document.getElementById("$wheelID").innerHTML = "$baseLoadingImage";
                paster.findImageEl(paster);
              };
            }
          };
 
          Paster.prototype.dataURItoBlob=function(dataURI, callback) {
            // convert base64 to raw binary data held in a string
            // does not handle URLEncoded DataURIs - see SO answer #6850276 for code that does this
//            console.log(dataURI);
            var byteString = atob(dataURI.split(",")[1]);
            // separate out the mime component
            var mimeString = dataURI.split(",")[0].split(":")[1].split(";")[0]
            // write the bytes of the string to an ArrayBuffer
            var ab = new ArrayBuffer(byteString.length);
            var ia = new Uint8Array(ab);
            for (var i = 0; i < byteString.length; i++) {
              ia[i] = byteString.charCodeAt(i);
            }
            // write the ArrayBuffer to a blob, and you are done
            return new Blob([ia], {type: mimeString});
          };

          Paster.prototype.findImageEl = function(paster) {
            if (paster.pasteCatcher.children.length > 0) {
              var dataURI = paster.pasteCatcher.firstElementChild.src;
              if (dataURI) {
                if (dataURI.indexOf("base64") === -1) {
                  alert("Sorry, with Firefox you can only paste local screenshots and files. Use Chrome or IE11 if you need paster feature.");
                  return;
                }
                var file = paster.dataURItoBlob(dataURI);
                paster.uploadFile(paster, file);
              }
              paster.pasteCatcher.innerHTML = "";
            }else{
              setTimeout(function() {
                paster.findImageEl(paster);
              }, 100);
            }
          };

          Paster.prototype.processing = false; //some wierd chrome bug makes the paste event fire twice when using javascript prompt for the filename

          Paster.prototype.handlePaste = function(paster, e) {
            //do not do this twice
            if (paster.processing) {
              return;
            }
            //loop through all clipBoardData items and upload it if it is a file.
            for (var i = 0; i < e.clipboardData.items.length; i++) {
              var item = e.clipboardData.items[i];
              if (item.kind === "file") {
                paster.processing = true;
                e.preventDefault();
                paster.uploadFile(paster, item.getAsFile());
              }
            }
          };

          Paster.prototype.uploadFile = function(paster, file) {
            var xhr = new XMLHttpRequest();

            //progress logging
            xhr.upload.onprogress = function(e) {
              var percentComplete = (e.loaded / e.total) * 100;
//              console.log(percentComplete);
            };

            //called when finished
            xhr.onload = function() {
              if (xhr.status === 200) {
//                alert("Sucess. Upload completed. PHP response will be put in the textarea.");
              }else{
                alert("Error. Upload failed");
              }
            };

            //error handling
            xhr.onerror = function() {
              alert("Error. Upload failed. Can not connect to server.");
            };

            //trigger a callback when it is successful
            xhr.onreadystatechange = function() {
              if (xhr.readyState === 4 && xhr.status === 200) {
                document.getElementById("$wheelID").innerHTML = "";
                var t = document.getElementById("$tableID").getElementsByTagName("tbody")[0];
                var newRow = t.insertRow(t.rows.length);
                newRow.innerHTML = xhr.responseText;
                paster.processing = false;
              }
            };

            //send the file with POST
            xhr.open("POST", "$addFileURL", true);
            //send it as multipart/form-data
            var formData = new FormData();
            formData.append("pastedFile", file);
            formData.append("IDType", "$IDType");
            formData.append("ID", "$ID");
            document.getElementById("$wheelID").innerHTML = "$baseLoadingImageURL";
            xhr.send(formData);

          };

		    //Create the paster object and connect it to the textarea.
		    function pasterDisplayImageREADY(){
		        console.log("Using $textID as the text id " + new Date().getTime());
		        var paster = new Paster({
		            pasteEl:document.getElementById('$textID'),
		            callback:function(paster, xhr){
		            }
		        });
		 
		        //blur the textarea
		        paster.pasteEl.focus();
		        paster.pasteEl.blur();
		    }

		  //
		  // end PASTER script
		  //
	!;
} 

#
# make tool tip
#
# returns content and tip as an html tooltip using special css rules
#
sub makeToolTip{
	my $content  = shift;
	my $tip      = shift;
	my $tipStyle = shift // "";
	
	return qq!
				<span class="tooltip">
					$content
					<span class= "tooltiptext" $tipStyle>
						$tip
					</span>
				</span>
			 !;
}

#
# get mapping colour style - returns inline colour style from a palette when mapping eg transaction to account entry
#
sub getMappingColourStyle{
	my $index = shift;

    # some colour TODO move to css
    my @palette  = (  'background:#332288;color:white;',
	                  'background:#88ccee;',
	                  'background:#44aa99;',
	                  'background:#117733;color:white;', 
	                  'background:#999933;',
	                  'background:#ddcc77;',
	                  'background:#cc6677;',
	                  'background:#aa4499;'
                   ); # google.github.io/palette.js tol: Tol's qualitative palette (cbf)

	my $colourIndex =  ( $index + 1 ) % scalar @palette;
	return qq!style='$palette[$colourIndex]'!;
}

#
# drop down
#
# produce a dropdown html of various actions
#
sub dropDown{
	my @actions = @_;
	return _dropDown("", @actions);
}
sub dropDownLeft{
	my @actions = @_;
	return _dropDown("leftSide", @actions);
}
sub _dropDown{
	my $side = shift // "";
	my @actions = @_;
	
	my $dropdownHTML = qq!
						<div class="dropdown">
						  <button class="dropbtn"><i class="fa fa-caret-down"></i></button>
						  <div class="dropdown-content $side">
	                     !;
	foreach my $action ( @actions ){
		$dropdownHTML.= $action =~ /^</ ? $action : qq!<li>$action</li>!;
	}
	$dropdownHTML .= qq!
						  </div>
						</div>
	                   !;
	return $dropdownHTML;
}

#
# returns clean text
#
sub cleanText{
  (my $text) = @_;
  chomp($text);
  if($text !~ /^$/){
#    $text =~ s/\xC4/Ä/g;
    $text =~ s/\xA0/ /g;	# non breaking space
#    $text =~ s/\xE5/å/g;
#    $text =~ s/\xF6/ö/g;
#    $text =~ s/\xE4/ä/g;
#    $text =~ s/\xD6/Ö/g;
    $text =~ s/^\s*|\s*$//g;	# leading or trailing white space
#    $text =~ s/\xC5/Å/g;
  }
  return $text;
}


#
# returns clean sql text
#
sub cleanSQL{
  (my $sql) = @_;
  if(defined $sql and $sql ne ""){
    $sql =~ s/(\')/$1$1/g;    # double up apostrophe
    $sql =~ s/([\`\?\%\&\*\$])/\\$1/g;
    $sql =~ s/^\s*|\s*$//g;
  }
  return $sql;
}

#
# get display ajax
#
# returns some more generic javascript code for handling ajax
#
# the displayAJAX js function takes the following arguments:
#		data     = the data to send to the $URL
#		calledBy = the string identifying what is calling this AJAX
#		id       = the element id where the result will be returned to OR the callback function 
#		wheel    = the element id of where the 'loading' image should be placed. Normally same as id. Blank/missing for none.
#		what     = describes the type of element the return will be for. Normally (default if missing) the innerHTML (eg of a div) but could be the value of an element or even a callback js function using id as the function. NOTE that any script passed back in the innerHTML will be executed - SECURITY ISSUE
#		url      = URL to call if not the default (current page)
#
sub getDisplayAJAX{
	my $URL = shift;
	
	my $js = "// this is where the displayAJAX function would have been if it had an URL";
	if($URL ne ""){
	    my $DEBUG = $COMMONDEBUG ? "&DEBUG=$COMMONDEBUG" : "";
	    $js = qq@
	    	//
	    	// get display AJAX script below
	    	//
	    	
	        /////////////////////////////////////////////////////////////////////////
	        window.displayAJAX = function(data, calledBy, id, wheel = "", what = "innerHTML", url = "$URL"){	// 20180126
	        	if(wheel !== ""){
	            	document.getElementById(wheel).innerHTML = "$baseLoadingImage";
	        	}
	            var setData = url+"?"+data+"&calledBy="+calledBy;
	            var xmlhttp_c = new XMLHttpRequest();
	            xmlhttp_c.onload=function(){	// assumes good return with no progress, timeout or other bad responce (basically website fails silently if no good responce)
	                if(what == "innerHTML"){	// innerhtml and could include a script that needs to be 'run/initiated'
	                		/////////////NOTE!!!////////////
	                		/////////CODE INJECTION/////////
	                		////////////DANGER//////////////
	                    var target = document.getElementById(id);
	                    target.innerHTML = xmlhttp_c.responseText;
	                    var scripts = target.getElementsByTagName("script");
	                    for (var i = 0; i < scripts.length; ++i) {
	                        var script = scripts[i];
	                        if(script.innerHTML){
	                            eval(script.innerHTML);
	                        }else{
	                            var newScript = document.createElement('script');
	                            newScript.src = script.src;
	                            document.head.appendChild(newScript);
	                        }
	                    }
	                }else if(what == "value"){
	                    document.getElementById.value = xmlhttp_c.responseText;
	                }else if(what == "callback"){   // id is the callback function
	                    id(xmlhttp_c.responseText);
	                }else{
	                        console.log("ERROR - unkown what "+what);
	                }
	            }
	            xmlhttp_c.open("GET", setData+"$DEBUG&cacheignore="+ new Date().getTime(), true);
	            xmlhttp_c.send();
	        }

	    	//
	    	// end display AJAX script
	    	//
		@;
	}
	return $js;
}
