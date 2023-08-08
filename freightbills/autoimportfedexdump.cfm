<cfsetting requesttimeout="180">
<!--- JT 11-01-05 --->

<!--- columns in the dump

INVOICEDATE
CORRECTED
TERMS
PRONUMBER
SHIPDATE
SHIPPER
SHIPPERACCT
SHIPPERZIP
CONSIGNEE
CONSIGNEEACCT
CONSIGNEEZIP
BILLTO
BILLTOACCT
BOLNUMBER
PIECES
SKIDS
ACCESSORIAL
DESIGNATION
FUEL CHARGE
CLASS
BILLEDWEIGHT
RATE
CHARGES
DISCOUNT
NET CHARGE
TOTAL

--->

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
	<cfset keyStructFunc=CreateObject("Component", "objects.encryptionfuncs").init()>
	<cfset keystruct = keyStructFunc.GetServerMKeysStruct(keyShortName="fedexacct")>
	<cfset fedexserver = keystruct.fedexacct.serverloc>
	<cfset fedexuser = keystruct.fedexacct.user>
	<cfset fedexpass = keystruct.fedexacct.pass>


	<cfset fileloc = "#expandPath('/partnernet/transfers_inbound/localuser/FedexFreight')#">

	<cfftp 
		name="listFiles" 
		secure="true" 
		port="60022" 
		server="#fedexserver#" 
		username="#fedexuser#" 
		password="#fedexpass#" 
		directory="/ALPINE/TXT/" 
		action="listdir" 
	/>

	<cfloop query="ListFiles">
		<cfset filedate = dateFormat(lastmodified, "yyyymmdd")>
		<cfoutput>#filedate##ListFiles.name#.fdx</cfoutput><br>

		<cfftp 
			name="sshgetfile"
			secure="true"
			port="60022"
			server="#fedexserver#"
			username="#fedexuser#"
			password="#fedexpass#"
			action="getfile"
			remoteFile="/ALPINE/TXT/#ListFiles.name#"
			localFile="#fileloc#/#filedate##ListFiles.name#.fdx"
			timeout="2400"
		/>

	</cfloop>

	<cfset lastpronumber = "">
	<cfset lastobjID = "">

	<cfdirectory action="LIST" directory="#fileloc#" recurse="no" filter="*.fdx" name="dirlist">

	<cfloop query="dirlist">
		<cfif fileExists("#fileloc#/importedbills/#dirlist.name#")>
			<cffile action="delete" file="#fileloc#/#dirlist.name#">
			<cfcontinue>
		</cfif>

		<cffile action="read" file="#fileloc#/#dirlist.name#" variable="thefile">

		<!--- <cfdump var="#thefile#"> --->

		<!--- is this one of our fedex files ?? --->
		<cfif FindNoCase("INVOICEDATE",thefile) AND FindNoCase("PRONUMBER",thefile)>

			<cfset filearray = arraynew(1)>

			<cfset rowcount = 0>
			<cfloop list="#thefile#" delimiters="#Chr(13)##Chr(10)#" index="line">
				<cfset rowcount = rowcount + 1>

				<cfset line = listfix(line)>
				<cfset tmp = listtoarray(line)>
				<cfset temp = arrayappend(filearray,tmp)>

				<cfloop from="#arraylen(filearray[rowcount])#" to="24" index="o">
					<cfset temp = arrayappend(filearray[rowcount],"")>
				</cfloop>
			</cfloop>

			<!--- <cfdump var="#filearray#"> --->
			<!--- <cfabort> --->

			<!--- the file is now in the array "filearray" --->
			<cfloop from="2" to="#arraylen(filearray)#" index="i">

				<cfif (filearray[i][17] NEQ "NULL" OR filearray[i][17] NEQ "") AND (filearray[i][18] NEQ "NULL" OR filearray[i][18] NEQ "") AND (filearray[i][1] NEQ "NULL" OR filearray[i][1] NEQ "")>

				<cfset invoicedate = "">
				<cfif filearray[i][1] NEQ "" OR filearray[i][1] NEQ "NULL">
					<cfset invoicedate = filearray[i][1]>
				</cfif>

				<cfset corrected = val(filearray[i][2])>

				<cfset terms = filearray[i][3]>
				<cfset pronumber = filearray[i][4]>
				<cfset shipdate = filearray[i][5]>
				<cfset shippername = filearray[i][6]>
				<cfset shipperacct = filearray[i][7]>
				<cfset shipperzip = filearray[i][8]>
				<cfset consigneename = filearray[i][9]>
				<cfset consigneeacct = filearray[i][10]>
				<cfset consigneezip = filearray[i][11]>
				<cfset billto = filearray[i][12]>
				<cfset billtoacct = filearray[i][13]>
				<cfset bolnumber = filearray[i][14]>
				<cfset pieces = filearray[i][15]>
				<cfset skids = filearray[i][16]>
				<cfset accessorial = ReplaceList(filearray[i][17],"$,.00",",")>
				<cfset designation = filearray[i][18]>
				<cfset fuelcharge = ReplaceList(filearray[i][19],"$,.00",",")>
				<cfset class = filearray[i][20]>
				<cfset weight = filearray[i][21]>
				<cfset rate = ReplaceList(filearray[i][22],"$,.00",",")>
				<cfset charges = ReplaceList(filearray[i][23],"$,.00",",")>
				<cfset discount = ReplaceList(filearray[i][24],"$,.00",",")>
				<cftry>
					<cfset servicelevel = filearray[i][27]>
					<cfcatch>
						<cfset servicelevel = "">
					</cfcatch>
				</cftry>

				<cfset orderID = "">
				<cfset POID = "">

				<!--- this is likely a PO number --->
				<cfif len(bolnumber) EQ 9 AND NOT isnumeric(left(bolnumber,2)) AND isnumeric(right(bolnumber,7))>
					<cfset orderID = LEFT(bolnumber,8)>
					<cfset POID = left(bolnumber,8) & "-" & right(bolnumber,1)>
				</cfif>

				<cftry>
					<cfset netcharge = ReplaceList(filearray[i][25],"$,.00",",")>
					<cfcatch>
						<cfset netcharge = "">
					</cfcatch>
				</cftry>

				<cftry>
					<cfset totalcharge = ReplaceList(filearray[i][26],"$,.00",",")>
					<cfcatch>
						<cfset totalcharge = "">
					</cfcatch>
				</cftry>


				<cfloop from="1" to="27" index="d">
					<cftry>
					<cfif filearray[i][d] EQ "NULL" OR filearray[i][d] EQ "" OR val(filearray[i][d]) EQ 0>
						<cfset filearray[i][d] = "">
					</cfif>
					<cfcatch></cfcatch></cftry>
				</cfloop>
							<!--- if the invoicedate is blank and the accessorial is not, then we're inserting accessorials for the last pro number --->
							<!--- we're inserting an accessorial for the previous freight bill --->

							<!--- we're inserting a new freight bill --->
							<cfif shipdate NEQ "" AND shipdate NEQ "NULL">

								<!--- was this row already imported?? --->
								<cfquery name="getfb" datasource="#DSN#" dbtype="ODBC">
									SELECT *
									FROM tblFreightBills
									WHERE BOLNumber = '#bolnumber#' AND pronumber = '#pronumber#' AND pieces = #pieces# AND weight = #weight# AND shipperzip = '#shipperzip#' AND consigneezip = '#consigneezip#'
										AND amountbilled = '#totalcharge#'

									UNION ALL

									SELECT *
									FROM tblBrokerageBills
									WHERE BOLNumber = '#bolnumber#' AND pronumber = '#pronumber#' AND pieces = #pieces# AND weight = #weight# AND shipperzip = '#shipperzip#' AND consigneezip = '#consigneezip#'
										AND amountbilled = '#totalcharge#'
								</cfquery>

								<cfif getfb.recordcount EQ 0>

									<!--- get a new freight bill --->
									<cfobject component="alpine-objects.freightbill" name="freightbill">

									<cfinvoke component="#freightbill#" method="init"></cfinvoke>

									<!--- for the next pass, if the bill has multiple accessorials --->
									<cfset lastobjID = freightbill.objID>
									<cfif shipdate IS "NULL" OR shipdate IS "">
										<cfset freightbill.pickupdatetime = "">
									<cfelse>
										<cfset freightbill.pickupdatetime = shipdate>
									</cfif>
									<cfset freightbill.ProNumber = pronumber>
									<cfset freightbill.BOLNumber = bolnumber>
									<cfset freightbill.POID = POID>
									<cfset freightbill.PONUmber = POID>
									<cfset freightbill.orderID = orderID>
									<cfset freightbill.shippername = shippername>
									<cfset freightbill.consigneename = consigneename>
									<cfset freightbill.Shipperzip = shipperzip>
									<cfset freightbill.ConsigneeZip = consigneezip>
									<cfset freightbill.Pieces = pieces>
									<cfset freightbill.Weight = weight>
									<cfset freightbill.NetCharge = netcharge>
									<cfset freightbill.skids = skids>
									<cfset freightbill.shipperacct = shipperacct>
									<cfset freightbill.consigneeacct = consigneeacct>
									<cfset freightbill.billto = billto>
									<cfset freightbill.billtoacct = billtoacct>

									<cfset freightbill.rate = rate>
									<cfset freightbill.discount = discount>
									<cfset freightbill.billtoacct = billtoacct>

									<cfset freightbill.fuelsurcharge = fuelcharge>
									<cfset freightbill.terms = terms>
									<cfset freightbill.amountbilled = totalcharge>

									<cfif shipperzip EQ "61108">
										<cfif servicelevel EQ "PRTY">
											<cfset freightbill.freightcompany = 197>
										<cfelse>
											<cfset freightbill.freightcompany = 198>
										</cfif>
									<cfelseif shipperzip EQ "40214" OR shipperzip EQ "40165">
										<cfif servicelevel EQ "PRTY">
											<cfset freightbill.freightcompany = 195>
										<cfelse>
											<cfset freightbill.freightcompany = 196>
										</cfif>
									<cfelseif left(consigneename,6) EQ "ALPINE" AND consigneezip EQ 61108>
										<cfif servicelevel EQ "PRTY">
											<cfset freightbill.freightcompany = 197>
										<cfelse>
											<cfset freightbill.freightcompany = 198>
										</cfif>
									<cfelseif left(consigneename,6) EQ "ALPINE" AND (consigneezip EQ 40214 OR consigneezip EQ 40165)>
										<cfif servicelevel EQ "PRTY">
											<cfset freightbill.freightcompany = 195>
										<cfelse>
											<cfset freightbill.freightcompany = 196>
										</cfif>
									<cfelse>
										<cfset freightbill.freightcompany = "Unknown">
									</cfif>

									<cfif accessorial NEQ "" AND accessorial NEQ "NULL" AND val(accessorial) NEQ 0 AND designation NEQ "" AND designation NEQ "NULL">
										<cfinvoke component="#freightbill#" method="insertaccessorial" code="#designation#" cost="#val(accessorial)#" returnvariable="result"></cfinvoke>
									</cfif>

									<cfquery name="isorder" datasource="#DSN#" dbtype="ODBC">
									SELECT *
									FROM checkouts
									WHERE sessionID = '#trim(orderID)#'
									</cfquery>

									<cfif isorder.recordcount GT 0>
										<cfquery name="weightoforder" datasource="#DSN#" dbtype="ODBC">
										SELECT SUM(products.weight * orders.quantity) AS 'theweight'
										FROM orders INNER JOIN products ON orders.productnumber = products.ID
										WHERE sessionID = '#orderID#'
										</cfquery>

										<cfset freightbill.estweight = Val(weightoforder.theweight)>
										<cfset freightbill.orderID = orderID>
									<cfelse>
										<cfset freightbill.orderID = "">
										<cfset freightbill.estweight = 0>
									</cfif>

									<cfinvoke component="#freightbill#" method="put" returnvariable="result"></cfinvoke>

									<!--- <cfdump var="#result#"> --->
								<cfelse>
									<cfoutput>Row #i# was duplicate.<br></cfoutput>
								</cfif>
							<cfelseif accessorial NEQ "" AND accessorial NEQ "NULL" AND lastobjID NEQ "" AND val(accessorial) NEQ 0 AND designation NEQ "" AND designation NEQ "NULL">
								<!--- <cfquery name="insertaccessorial" dbtype="ODBC" datasource="#DSN#">
								INSERT INTO tblFreightBillAccessorials (objID,code,cost)
								VALUES ('#lastobjID#','#trim(designation)#',#trim(accessorial)#)
								</cfquery> --->
								<cfobject component="alpine-objects.freightbill" name="freightbill">

								<cfinvoke component="#freightbill#" method="get" objID="#lastobjID#"></cfinvoke>

								<cfinvoke component="#freightbill#" method="insertaccessorial" code="#designation#" cost="#val(accessorial)#" returnvariable="result"></cfinvoke>

								<cfinvoke component="#freightbill#" method="put" returnvariable="result"></cfinvoke>

							</cfif>
						
					<cfif pronumber NEQ "" AND pronumber NEQ "NULL">
						<cfset lastpronumber = pronumber>
					</cfif>
				</cfif> <!--- the line is not a valid line --->
				<br><br>
			</cfloop>

			<!--- moves file so that it is not hit again - not used in testing --->
			<cffile action="move" source="#fileloc#/#dirlist.name#" destination="#fileloc#/importedbills/" nameconflict="MAKEUNIQUE">

		</cfif> <!--- this is a fedex freight file --->
	</cfloop>
