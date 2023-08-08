<cfsetting requesttimeout="99999">

<cfset screenID = "825">
<cfset recordhistory = "0">

<cfinclude template="/partnernet/shared/_header.cfm">

<p><a href="default.cfm"><strong>Back to Menu</strong></a></p>
<br>
<div class="normal">
	<font color="red">NOTE: </font>
	CSV file columns expected:
	<br>
	tracking number, charges, ship date, billed weight, invoice number, invoice date, consignee state, consignee zip, shipper state, shipper zip, rma number, order ID, carrier ID, consignee name, shipper name, pieces<br>
	Consignee name, shipper name and pieces were added 3/8/2010.<br>
	Carrier ID is optional and can be overridden by selecting a carrier from the drop-down.<br>
	First row WILL BE IMPORTED.<br>
	Please note that other formats (non-CSV) and alternative columns will not import properly
</div>
<hr noshade>

<cfscript>
/**
 * Fixes a list by replacing null entries.
 * This is a modified version of the ListFix UDF
 * written by Raymond Camden. It is significantly
 * faster when parsing larger strings with nulls.
 * Version 2 was by Patrick McElhaney (pmcelhaney@amcity.com)
 *
 * @param list 	 The list to parse. (Required)
 * @param delimiter 	 The delimiter to use. Defaults to a comma. (Optional)
 * @param null 	 Null string to insert. Defaults to "NULL". (Optional)
 * @return Returns a list.
 * @author Steven Van Gemert (svg2@placs.net)
 * @version 3, July 31, 2004
 */
function listFix(list) {
var delim = ",";
  var null = "NULL";
  var special_char_list      = "\,+,*,?,.,[,],^,$,(,),{,},|,-";
  var esc_special_char_list  = "\\,\+,\*,\?,\.,\[,\],\^,\$,\(,\),\{,\},\|,\-";
  var i = "";

  if(arrayLen(arguments) gt 1) delim = arguments[2];
  if(arrayLen(arguments) gt 2) null = arguments[3];

  if(findnocase(left(list, 1),delim)) list = null & list;
  if(findnocase(right(list,1),delim)) list = list & null;

  i = len(delim) - 1;
  while(i GTE 1){
	delim = mid(delim,1,i) & "_Separator_" & mid(delim,i+1,len(delim) - (i));
	i = i - 1;
  }

  delim = ReplaceList(delim, special_char_list, esc_special_char_list);
  delim = Replace(delim, "_Separator_", "|", "ALL");

  list = rereplace(list, "(" & delim & ")(" & delim & ")", "\1" & null & "\2", "ALL");
  list = rereplace(list, "(" & delim & ")(" & delim & ")", "\1" & null & "\2", "ALL");

  return list;
}
</cfscript>



<cfparam name="attributes.submit" default="">
<cfset fileloc = "#expandPath('/')#partnernet\transfers_inbound\fedexground\">
<cfset fileloc = expandPath("\partnernet\transfers_inbound\fedexground\")>
<cfset shipmentadded = "">
<cfset returnlabel = "">
<cfset trackingfailed = "">
<cfset outbound = "">

<cfif CGI.request_method IS NOT "POST">
	<cfquery name="uniquefreightcompany" datasource="#DSN#">
		SELECT c.carrierID,carrierlongname,c.vendorID,s.srccompanyname
		FROM tblCarriers c WITH (NOLOCK)
		INNER JOIN tblProductFulfillmentSources s WITH (NOLOCK) ON c.vendorID = s.srcID
		WHERE c.active = 1 AND s.srcActive = 1
		ORDER BY s.srccompanyname,carrierlongname
	</cfquery>

	<form name="fileform" method="post" enctype="multipart/form-data" action="<cfoutput>#cgi.script_name#</cfoutput>">
		<table cellpadding="2" cellspacing="0" border="0">
			<tr>
				<td colspan="2">Browse to select the file to import.</td>
			</tr>
			<tr>
				<td>File: </td><td> <input type="file" name="fileupload" maxLength="400" size="44" /></td>
			</tr>
			<tr>
				<td>Select freight company: </td>
				<td><select name="freightcompany" onchange="changecompany(this);">
						<option value="">Use carrier provided on the imported file</option>
						<!--- <option value="Add New">Add new</option> --->
						<cfoutput query="uniquefreightcompany">
							<option value="#carrierID#">#srccompanyname# - #carrierlongname#</option>
						</cfoutput>
					</select> (will override file designations)</td>
			</tr>
			<tr>
				<td>What status would you like to import as? </td>
				<td> <select name="status">
						<option value="">None selected - will audit all</option>
						<option value="Ready to Pay">Ready to Pay</option>
						<option value="Paid">Paid</option>
					</select></td>
			</tr>
			<tr>
				<td valign="top">If importing as paid, optionally provide date paid and payment number: </td>
				<td><input type="text" size="25" name="datepaid" value="<cfoutput>#dateformat(now(),'mm/dd/yyyy')#</cfoutput>"> date paid (or leave blank)<br><input type="text" size="25" name="paymentnumber"> payment number (or leave blank)</td>
			</tr>
			<tr>
				<td colspan="2">&nbsp;</td>
			</tr>
			<tr>
				<td colspan="2"><input type="submit" name="submit" value="submit"/></td>
			</tr>
		</table>
	</form>

	<script language="JavaScript">
	function changecompany(formname) {
			if (formname.options[formname.options.selectedIndex].value == 'Add New') {
				newname = window.prompt('Please enter a name for the new company.')
				if(newname != null && newname != "undefined"){
					formname.options[formname.options.length] =	new Option(newname, newname);
					formname.selectedIndex = formname.options.length -1

				}
			}
		}
	</script>

	<br>
	Functional notes:
	<br>
	Order ID determination priority: (1) derived from tracking number; (2) derived from RMA number; (3) order ID from column<br>
	Shipper / consignee state if blank is derived from zip code match<br>

<cfelse>
	<cftry>
		<!--- <cfset filename="ground_#DateFormat(now(),'yyyymmdd'#_#timeformat(now(),'hhmmss')#.csv"> --->
		<cffile action="UPLOAD" filefield="fileupload" destination="#fileloc#" nameconflict="MAKEUNIQUE">
	  	<cfset NewFileName = cffile.serverFile>

		<br><br>
		File created...
		<br>

		<cffile action="read" file="#fileloc#\#NewFileName#" variable="thefile">

		<cfset filearray = arraynew(1)>
		<cfset thefile = trim(thefile)>

		<cfset rowcount = 0>
		<cfloop list="#thefile#" delimiters="#Chr(13)#" index="line">
			<cfset rowcount++>

			<cfset line = listfix(line)>
			<cfset tmp = listtoarray(line)>
			<cfset arrayappend(filearray,tmp)>

			<!--- fill in elements that are not there - if the line length inputted was not long enough --->
			<cfloop from="#arraylen(filearray[rowcount])#" to="16" index="o">
				<cfset arrayappend(filearray[rowcount],"")>
			</cfloop>
		</cfloop>

		<cfset freightbill = createObject("component","alpine-objects.freightbill")>
		<cfset newdate = CreateObject("component","alpine-objects.dtype.datetime")>

		<!--- the file is now in the array "filearray" --->
		<cfloop from="2" to="#arraylen(filearray)#" index="i">
			<cfif (filearray[i][1] NEQ "NULL" OR trim(filearray[i][1]) NEQ "")>
				<cfset isrejectreason = "">

				<cfloop from="1" to="13" index="d">
					<cftry>
						<cfif filearray[i][d] EQ "NULL" OR filearray[i][d] EQ "" OR filearray[i][d] EQ NULL>
							<cfset filearray[i][d] = "">
						</cfif>
						<cfcatch></cfcatch>
					</cftry>
				</cfloop>

				<cfset trackingnumber = trim(filearray[i][1])>

				<cfif len(trackingnumber)>
					<cfset charges = filearray[i][2]>
					<cfset shipdate = filearray[i][3]>
					<cfset billedweight = filearray[i][4]>
					<cfset invoicenumber = filearray[i][5]>
					<cfset invoicedate = filearray[i][6]>
					<cfset consigneestate = filearray[i][7]>
					<cfset consigneezip = filearray[i][8]>
					<cfset shipperstate = filearray[i][9]>
					<cfset shipperzip = filearray[i][10]>
					<cfset rmanumber = filearray[i][11]>
					<cfset orderID = filearray[i][12]>
					<cfset carrierID = filearray[i][13]>
					<cfset consigneename = filearray[i][14]>
					<cfset shippername = filearray[i][15]>
					<cfset pieces = filearray[i][16]>

					<!--- this is an outbound shipment --->
					<cfquery name="gettrackingID" datasource="#DSN#">
						SELECT sessionID
						FROM tblShipments WITH (NOLOCK)
						WHERE trackingnumber = <cfqueryparam sqltype="VARCHAR" value="#trackingnumber#">
					</cfquery>

					<cfif gettrackingID.recordcount>
						<cfset outbound = listappend(outbound,"#trackingnumber#")>
						<cfset orderID = gettrackingID.sessionID>
					<cfelse>
						<!--- this is a return label --->
						<cfquery name="gettrackingID" datasource="#DSN#">
							SELECT orderID
							FROM tblFedexLabels WITH (NOLOCK)
							WHERE trackingnumber = <cfqueryparam sqltype="VARCHAR" value="#trackingnumber#">
						</cfquery>

						<cfif gettrackingID.recordcount>
							<cfset returnlabel = listappend(returnlabel,"#trackingnumber#")>
							<cfset orderID = gettrackingID.orderID>
						<cfelseif len(trim(orderID))>
							<cfset shipmentadded = listappend(shipmentadded,"#trackingnumber#")>
						<cfelse>
							<cfset trackingfailed = listappend(trackingfailed,"#trackingnumber#")>
						</cfif>
					</cfif> <!--- found tracking number --->

					<!--- insert the line --->
					<cfset freightbill.init()>
					<cfset freightbill.ProNumber = trackingnumber>
					<cfset freightbill.orderID = orderID>
					<cfset freightbill.amountbilled = charges>
					<cfset freightbill.NetCharge = charges>
					<cfset freightbill.Weight = billedweight>
					<cfset freightbill.shipperzip = isValid("zipcode",shipperzip) ? left(shipperzip,5) : shipperzip>
					<cfset freightbill.consigneezip = isValid("zipcode",consigneezip) ? left(consigneezip,5) : consigneezip>
					<cfset freightbill.shipperstate = shipperstate>
					<cfset freightbill.consigneestate = consigneestate>

					<cfif len(trim(consigneename))>
						<cfset freightbill.consigneename = consigneename>
					</cfif>

					<cfif len(trim(shippername))>
						<cfset freightbill.shippername = shippername>
					</cfif>

					<cfif len(trim(pieces))>
						<cfset freightbill.pieces = pieces>
					</cfif>

					<cfif len(trim(attributes.status))>
						<cfset freightbill.disputestatus = attributes.status>

						<cfif attributes.status IS "Paid">
							<cfset freightbill.amountpaid = charges>
						</cfif>
					</cfif>

					<cfif len(trim(rmanumber)) AND rmanumber IS NOT "NULL">
						<cfset freightbill.PONumber = rmanumber>
					<cfelse>
						<cfset freightbill.PONumber = filearray[i][12]>
					</cfif>

					<cfset newdate.init().StringToDate(shipdate)>
					<cfif newdate.isValidType()>
						<cfset freightbill.pickupdatetime = dateFormat(newdate.value,"yyyy-mm-dd")>
					<cfelse>
						<cfset isrejectreason = "Pick up date is not in value format">
					</cfif>

					<cfif len(trim(attributes.datepaid)) AND attributes.status EQ "Paid">
						<cfset freightbill.datepaid = attributes.datepaid>
					</cfif>

					<cfif len(trim(attributes.paymentnumber))>
						<cfset freightbill.paymentnumber = attributes.paymentnumber>
					</cfif>


					<cfset newdate.init().StringToDate(invoicedate)>
					<cfif newdate.isValidType()>
						<cfset freightbill.statementdate = dateFormat(newdate.value,"yyyy-mm-dd")>
					<cfelse>
						<cfset isrejectreason = "Pick up date is not in value format">
					</cfif>

					<cfset freightbill.statementnumber = invoicenumber>
					<cfset freightbill.freightcompany = len(trim(attributes.freightcompany)) ? attributes.freightcompany : carrierID>

					<cfif NOT len(trim(freightbill.freightcompany))>
						<cfset isrejectreason = "Tracking number #trackingnumber# failed import - no carrier was provided.">
					</cfif>

					<cfquery name="getShipOpts" datasource="#DSN#">
						SELECT shippingoptions
						FROM tblVendorPOHeader WITH (NOLOCK)
						WHERE POID = <cfqueryparam sqltype="VARCHAR" value="#freightbill.PONumber#">
					</cfquery>

					<cfif getShipOpts.recordCount AND len(trim(getShipOpts.shippingoptions))>
						<cfset queryflags = "">
						<cfif listFindNoCase(getShipOpts.shippingoptions,"RES")>
							<cfset queryflags = "RES">
						<cfelseif listFindNoCase(getShipOpts.shippingoptions,"COM")>
							<cfset queryflags = "COM">
						</cfif>
						<cfif listFindNoCase(getShipOpts.shippingoptions,"LIFTGATE") OR listFindNoCase(getShipOpts.shippingoptions,"INSIDE")>
							<cfset queryflags = queryflags.listAppend("LIFTGATE")>
							<cfif listFindNoCase(getShipOpts.shippingoptions,"INSIDE")>
								<cfset queryflags = queryflags.listAppend("INSIDE")>
							</cfif>
						</cfif>

						<cfif len(trim(queryflags))>
							<cfquery name="getAccessorialCharge" datasource="#DSN#">
								SELECT f.shippingtypefee
								FROM tblCarrierShippingTypeLookup l WITH (NOLOCK)
								INNER JOIN tblCarrierShippingTypeFees f WITH (NOLOCK) ON l.typeID = f.shippingtypeID
									AND f.carrierID = <cfqueryparam sqltype="INT" value="#freightbill.freightcompany#">
								WHERE l.queryflags = <cfqueryparam sqltype="VARCHAR" value="#queryflags#">
							</cfquery>
							<cfif getAccessorialCharge.recordCount>
								<cfset result = freightbill.insertaccessorial(code=queryflags,cost=getAccessorialCharge.shippingtypefee)>
							</cfif>
						</cfif>
					</cfif>

					<cfif NOT len(trim(isrejectreason))>
						<cfset result = freightbill.put()>
						<cfdump var="#freightbill#">

						<cfif result.errorcode EQ 0>
							Successfully imported <cfoutput>#freightbill.ProNumber#</cfoutput><br>
						<cfelse>
							<cfoutput>#result.errormessage#</cfoutput><br>
						</cfif>

						<cfif result.errorcode NEQ 0>
							<cfoutput>Tracking number #trackingnumber# failed import.</cfoutput>
						</cfif>
					<cfelse>
						<cfoutput>#isrejectreason#. Submitted values: <cfdump var="#filearray[i]#"><br></cfoutput>
					</cfif>
				<cfelse>
					line contained no tracking number, line values were: <cfdump var="#filearray[i]#"><hr noshade>
				</cfif> <!--- tracking number is not "" --->
			</cfif>
		</cfloop>
		<br><br>
		<cfoutput>
			Outbound shipments:<br>
			<cfloop list="#outbound#" index="i">
				#i#<br>
			</cfloop>

			<br>
			Return labels:<br>
			<cfloop list="#returnlabel#" index="i">
				#i#<br>
			</cfloop>

			<br>
			Tracking number information not found as return label or outbound shipment:<br>
			<cfloop list="#trackingfailed#" index="i">
				#i#<br>
			</cfloop>
		</cfoutput>

		<cfcatch>
			Error importing Fedex file.
			<cfmail to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" subject="Error Importing Freight Bill">
				<cfmailpart type="text/html">
					Error importing freight bill file.<br />
					<cfdump var="#cfcatch#">
				</cfmailpart>
			</cfmail>
		</cfcatch>

	</cftry>

</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">
