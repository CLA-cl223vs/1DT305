#!/usr/bin/perl
#
# $Id:$
#

chomp (my $host = `hostname`);
my $uHost = uc($host);

my $vyhost = qq!vy.villayddinge.lan!;

print <<END_HTML;

<HTML>
   <HEAD>
       <TITLE>VY @ $uHost</TITLE>
       <style>ul{list-style-type:none;margin:0;padding:5;}</style>
       <style>th{color:white;background-color:lightsteelblue;}</style>
   </HEAD>

   <BODY>
       
       <h3>This is a landing page of the Villa Yddinge smart home on the $uHost server. Use it to goto:</h3>
       <br/>
       
       <table border="1"  style="margin: 0px auto;">
       
	<tr><th>VYWIKI</th><td><ul>
           	<li><a target="_blank"href="http://192.168.199.13/vywiki">	The VY wiki</a></li>
       	</ul></td></tr>
       	
	<tr><th>SMARTS</th><td><ul>
           	<li><a href="http://$vyhost/cgi-bin/devices.cgi?family=controllers">Controllers</a></li>
           	<li><a href="http://$vyhost/cgi-bin/devices.cgi?family=sensors">Sensors</a></li>
           	<li><a href="http://$vyhost/cgi-bin/devices.cgi">Devices</a></li>
       	</ul></td></tr>
       	
	<tr><th>SMARTS-ADMIN</th><td><ul>
           	<li><a href="http://$vyhost/cgi-bin/locations.cgi">Locations</a></li>
       	</ul></td></tr>
       	
       	</table><br/>

	<table style="font-family:Arial;width:100%;" border="0" cellpadding="0" cellspacing="0">
		<tr>
			<td bgcolor=#E0ECF7 title="Villa Yddinge">
				<font size=-3><center>
				As is with best effort
				</center></font>
			</td>
		</tr>
	</table>
       
       
	<div style="font-size:50%;color:grey"> C G I @ $host</div>

   </BODY>
</HTML>


END_HTML

1;
## end
