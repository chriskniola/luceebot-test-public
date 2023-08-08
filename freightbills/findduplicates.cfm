<cfset screenID = "825">
<cfset recordhistory = "0">

<cfparam name="attributes.freightcompany" default="">
<cfparam name="attributes.submit" default="">

<cfinclude template="/partnernet/shared/_header.cfm">

<p><a href="default.cfm"><strong>Back to Menu</strong></a></p>

<cfquery name="uniquedisputestatus" datasource="AHAPDB" dbtype="ODBC">
SELECT disputestatus,count(*) AS 'records'
FROM tblFreightBills a
WHERE disputestatus = 'Ready to Pay'
	AND (SELECT COUNT(*) FROM tblFreightBills WHERE ProNumber = a.ProNumber AND (disputestatus = 'Ready to Pay' OR disputestatus = 'Paid' OR disputestatus = 'Sent to Accounting')) > 1
GROUP BY disputestatus
</cfquery>

<cfquery name="uniquefreightcompany" datasource="AHAPDB" dbtype="ODBC">
SELECT freightcompany,count(*) AS 'records'
FROM tblFreightBills a
WHERE disputestatus = 'Ready to Pay'
	AND (SELECT COUNT(*) FROM tblFreightBills WHERE ProNumber = a.ProNumber AND (disputestatus = 'Ready to Pay' OR disputestatus = 'Paid' OR disputestatus = 'Sent to Accounting')) > 1
GROUP BY freightcompany
</cfquery>

<form name="updateform" method="post" action="<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>">
	<table cellpadding="3" cellspacing="0" border="0">
		<tr>
			<td>Company:</td>
			<td><select name="freightcompany">
					<cfoutput query="uniquefreightcompany">
						<option value="#freightcompany#" <cfif attributes.freightcompany IS "#freightcompany#">SELECTED</cfif>>#freightcompany# (#records#)</option>
					</cfoutput>
				</select>
			</td>
		</tr>
		
		<tr><td colspan="2">&nbsp;</td></tr>
		<tr>
			<td></td>
			<td><input type="submit" value="search" name="submit"></td>
		</tr>
	</table>
</form>


<cfif attributes.submit IS NOT "">
	
	<script language="JavaScript">
	function highlight(therowID){
			document.getElementById(therowID).style.backgroundColor = "#FFA1A1";
	}
	
	function unhighlight(therowID){
			document.getElementById(therowID).style.backgroundColor = "#FFFFFF";
	}
	
	function highlight2(therowID){
			document.getElementById(therowID).style.backgroundColor = "#FFA1A1";
			therowID = 't' + therowID.toString();
			document.getElementById(therowID).style.backgroundColor = "#FFA1A1";
	}
	
	function unhighlight2(therowID){
			document.getElementById(therowID).style.backgroundColor = "#FFFFFF";
			therowID = 't' + therowID.toString();
			document.getElementById(therowID).style.backgroundColor = "#FFFFFF";
	}
	
	function mouseon()
	{
		document.body.style.cursor='hand';
	}
	
	function mouseoff()
	{
		document.body.style.cursor='default';
	}
	
	</script>

	<cfquery name="getduplicates" dbtype="ODBC" datasource="#DSN#">
	SELECT *
	FROM tblFreightBills
	WHERE pronumber IN (
		SELECT pronumber
		FROM tblFreightBills a
		WHERE disputestatus = 'Ready to Pay'
			AND (SELECT COUNT(*) FROM tblFreightBills WHERE ProNumber = a.ProNumber AND (disputestatus = 'Ready to Pay' OR disputestatus = 'Paid' OR disputestatus = 'Sent to Accounting')) > 1
			AND freightcompany = '#attributes.freightcompany#'
		)
	ORDER BY ProNumber,disputestatus
	</cfquery>

	<table cellpadding="3" cellspacing="0" border="0" width="100%">
		<!--- output the FreightCompany group --->
		<cfoutput query="getduplicates" group="freightcompany">
			<!--- output the pro number group --->
			<tr>
				<td class="large" colspan="13">#freightcompany#</td>
			</tr>
			<tr>
				<td><strong>Status</strong></td>
				<td><strong>Pickup Date</strong></td>
				<td><strong>BOL Number</strong></td>
				<td><strong>Order ID</strong></td>
				<td><strong>Amount Billed</strong></td>
				<td><strong>Amount Paid</strong></td>
				<td><strong>Date Paid</strong></td>
				<td><strong>Consignee</strong></td>
				<td><strong>Payment No.</strong></td>
				<td><strong>Check No.</strong></td>
				<td><strong>Audit Recommendations</strong></td>
				<td><strong>Notes</strong></td>
			</tr>
			<cfoutput group="pronumber">
				<tr>
					<td colspan="13">&nbsp;</td>
				</tr>
				<tr>
					<td colspan="13"><strong>PRO NUMBER: #pronumber#</strong></td>
				</tr>
				<!--- output the detail --->
				<cfoutput>
					<tr id="row#getduplicates.currentrow#" onmouseover="highlight('row#getduplicates.currentrow#')" onmouseout="unhighlight('row#getduplicates.currentrow#')" bordercolor="white">
						<!--- <td class="tiny" valign="top"><a href="javascript:openwin('/templates/object.cfm?objecttype=freightbill&objID=#objID#&action=edit','','850','800');" title="Open Freight Bill">open</a> &nbsp; <a href="javascript:preview('#objID#','freightbill');" title="Preview Freight Bill">preview</a></td> --->
						<td valign="top">#Disputestatus#&nbsp;</td>
						<td valign="top">#DateFormat(PickupDateTime,"mm/dd/yyyy")#&nbsp;</td>
						<td valign="top">#BOLNumber#&nbsp;</td>
						<td class="normal" valign="top"><a href="javascript:preview('#orderID#','order&showmessages=1&showinvoices=1');" title="Preview Order">#orderID#</a>&nbsp;</td>
						<td class="normal" valign="top">#Dollarformat(amountbilled)#&nbsp;</td>
						<td class="normal" valign="top">#Dollarformat(amountpaid)# <cfif amountpaid GT 0 AND val(amountpaid)-val(amountbilled) NEQ 0>#Dollarformat(val(amountpaid)-val(amountbilled))#</cfif>&nbsp;</td>
						
						<td valign="top">#DateFormat(datepaid,"mm/dd/yyyy")#&nbsp;</td>
						<td valign="top">#Consigneename#&nbsp;</td>
						<td valign="top">#paymentnumber#&nbsp;</td>
						<td valign="top">#checknumber#&nbsp;</td>
						<td valign="top">
							<cfloop list="#auditrecommendations#" index="l">
								<cfoutput>#l#<br></cfoutput>
							</cfloop>&nbsp;
						</td>
						<td valign="top">#notes#&nbsp;</td>
					</tr>
				</cfoutput>
			</cfoutput>
		</cfoutput>
	</table>
	
	<DIV ID='previewdiv' STYLE="position:absolute;top:100;left:50;background:white;overflow:scroll;height:600" onclick="closediv();"></DIV>

	<script type="text/javascript">
	closediv();
	</script>
	
</cfif> 

<cfinclude template="/partnernet/shared/_footer.cfm">