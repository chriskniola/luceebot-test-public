<cfset screenID = "825">
<cfset recordhistory = "0">

<cfinclude template="/partnernet/shared/_header.cfm">

<p><a href="default.cfm"><strong>Back to Menu</strong></a></p>

<cfparam name="attributes.MinShipDate" default="">
<cfparam name="attributes.MaxShipDate" default="">
<cfparam name="attributes.paymentnumber" default="">
<cfparam name="attributes.checknumber" default="">
<cfparam name="attributes.paymentnumbertochange" default="">

<cfparam name="attributes.method" default="">


<cfparam name="attributes.Submit" default="">
										
<cfif attributes.method IS "add" AND attributes.checknumber IS NOT "">
	
	<cfquery name="updatefb" datasource="#DSN#" dbtype="ODBC">
		UPDATE tblBrokerageBills
		SET checknumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.checknumber#">,
			datepaid = #createodbcdatetime(now())#,
			disputestatus = 'Paid'
		WHERE paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumber#">

		UPDATE tblFreightbills
		SET checknumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.checknumber#">,
			datepaid = #createodbcdatetime(now())#,
			disputestatus = 'Paid'
		OUTPUT inserted.orderID
		WHERE paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumber#">
	</cfquery>

	<cfset storeAGPUseCase = application.wirebox.getInstance('AutoStoreOrderAGPUseCase')>
	<cfloop query="#updatefb#" group="orderID">
		<cfif !isEmpty(updatefb.orderID)>
			<cfset storeAGPUseCase.storeAGP(updatefb.orderID)>
		</cfif>
	</cfloop>
	
	<cfset attributes.method = "">
</cfif>


<cfif attributes.method IS "change">
	
	<cfquery name="updatefb" datasource="#DSN#" dbtype="ODBC">
		UPDATE tblFreightbills
		SET paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumbertochange#">
			<cfif attributes.paymentnumbertochange EQ "">,disputestatus = 'Ready to Pay'</cfif>
		WHERE paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumber#">
			AND disputestatus = 'Sent to Accounting'

		UPDATE tblBrokerageBills
		SET paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumbertochange#">
			<cfif attributes.paymentnumbertochange EQ "">,disputestatus = 'Ready to Pay'</cfif>
		WHERE paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumber#">
			AND disputestatus = 'Sent to Accounting'
	</cfquery>
	
	<cfset attributes.method = "">
	
</cfif>

<cfif attributes.method IS "">
		<cfquery name="getunreconciledpayments" datasource="#DSN#" dbtype="ODBC">
			SELECT b.paymentnumber,sum(b.amountpaid) as amountunpaid, ca.carrierName
			FROM tblFreightBills b
			LEFT OUTER JOIN tblCarriers ca WITH (NOLOCK) ON CONVERT(varchar(50), ca.carrierID) = b.freightcompany
			WHERE (b.checknumber = '' OR b.checknumber IS NULL) AND b.disputestatus = 'Sent to Accounting' AND b.paymentnumber <> '' AND b.paymentnumber IS NOT NULL
			GROUP BY b.paymentnumber, ca.carrierName

			UNION ALL

			SELECT b.paymentnumber,sum(b.amountpaid) as amountunpaid, ca.carrierName
			FROM tblBrokerageBills b
			LEFT OUTER JOIN tblCarriers ca WITH (NOLOCK) ON CONVERT(varchar(50), ca.carrierID) = b.freightcompany
			WHERE (b.checknumber = '' OR b.checknumber IS NULL) AND b.disputestatus = 'Sent to Accounting' AND b.paymentnumber <> '' AND b.paymentnumber IS NOT NULL
			GROUP BY b.paymentnumber, ca.carrierName
			ORDER BY b.paymentnumber
		</cfquery>
		
		<cfoutput>
			<table cellpadding="5" cellspacing="0" border="1">
				<tr>
					<td class="normal" colspan="3"><strong>Outstanding Payments to be Reconciled with checks</strong></td>
				</tr>
				
				<cfif getunreconciledpayments.recordcount GT 0>
					<tr>
						<td class="normal">Payment Number</td>
						<td class="normal">Amount</td>
						<td class="normal">Carrier</td>
					</tr>
					
					<cfloop query="getunreconciledpayments">
						<tr <cfif attributes.paymentnumber EQ paymentnumber>bgcolor="##00ff00"</cfif>>
							<td class="normal"><a href="#CGI.SCRIPT_NAME#?paymentnumber=#paymentnumber#&submit=Search">#paymentnumber#</a></td>
							<td class="normal">#Dollarformat(amountunpaid)#</td>
							<td class="normal"><cfif carrierName EQ "">&nbsp;<cfelse>#carrierName#</cfif></td>
						</tr>
					</cfloop>
				<cfelse>
					<tr>
						<td class="normal" colspan="2">No unreconciled payments</td>
					</tr>
				</cfif>
			</table>
			<form name="mygrid" method="post" action="#CGI.SCRIPT_NAME#">
				<table cellpadding="3" cellspacing="0" border="0">
					<tr>
						<td class="normal">Payment Number:</td>
						<td class="normal"><input type="text" name="paymentnumber" value="#attributes.paymentnumber#"></td>
					</tr>
					<tr>
						<td class="normal">Check Number:</td>
						<td class="normal"><input type="text" name="checknumber" value="#attributes.checknumber#"></td>
					</tr>
					<tr>
						<td class="normal"></td>
						<td class="normal"><input type="submit" value="Search" name="submit" class="normal"></td>
					</tr>
				</table>
			
			</form>
		</cfoutput>
		
		
		<script language="JavaScript">
		function highlight(therowID){
				document.getElementById(therowID).style.backgroundColor = "#FFA1A1";
		}
		
		function unhighlight(therowID){
				document.getElementById(therowID).style.backgroundColor = "#FFFFFF";
		}
		
		</script>
		
		<cfif attributes.submit IS NOT "">	
			
			<cfquery name="getfb" datasource="#DSN#" dbtype="ODBC">
				SELECT paymentnumber,checknumber,sum(amountbilled) as amountbilled,sum(amountpaid) as amountpaid,datepaid
				FROM tblFreightBills
				WHERE 1=1
					<cfif attributes.paymentnumber IS NOT "">
						AND paymentnumber = '#attributes.paymentnumber#'
					</cfif>
					<cfif attributes.checknumber IS NOT "">
						AND checknumber = '#attributes.checknumber#'
					</cfif>
					
				GROUP BY paymentnumber,checknumber,datepaid

				UNION ALL

				SELECT paymentnumber,checknumber,sum(amountbilled) as amountbilled,sum(amountpaid) as amountpaid,datepaid
				FROM tblBrokerageBills
				WHERE 1=1
					<cfif attributes.paymentnumber IS NOT "">
						AND paymentnumber = '#attributes.paymentnumber#'
					</cfif>
					<cfif attributes.checknumber IS NOT "">
						AND checknumber = '#attributes.checknumber#'
					</cfif>
					
				GROUP BY paymentnumber,checknumber,datepaid
				ORDER BY checknumber asc,paymentnumber asc,datepaid desc
			</cfquery>
			
			<cfoutput>
				<table cellpadding="3" cellspacing="0" border="1">
					<tr>
						<td class="normal"><strong>Actions</strong></td>
						<td class="normal"><strong>Payment Number</strong></td>
						<td class="normal"><strong>Check Number</strong></td>
						<td class="normal"><strong>Amount Billed</strong></td>
						<td class="normal"><strong>Amount Paid</strong></td>
						<td class="normal"><strong>Date Paid</strong></td>
					</tr>
					<cfloop query="getfb">
						<tr id="row#getfb.currentrow#" onmouseover="highlight('row#getfb.currentrow#')" onmouseout="unhighlight('row#getfb.currentrow#')">
							<td class="normal"><cfif paymentnumber NEQ ""><a href="freightbilllookup.cfm?criteria=#paymentnumber#&submit=search">see detail</a> | <a href="#CGI.SCRIPT_NAME#?paymentnumber=#paymentnumber#&method=changeform">change payment number</a> | <a href="createpo.cfm?paymentnumber=#paymentnumber#">reprint PO</a></cfif></td>
							<td class="normal"><cfif paymentnumber IS "">none</cfif>#paymentnumber# </td>
							<td class="normal"><cfif checknumber IS "" AND paymentnumber NEQ ""><a href="#CGI.SCRIPT_NAME#?paymentnumber=#paymentnumber#&method=add">ADD</a></cfif>#checknumber#</td>
							<td class="normal">#Dollarformat(amountbilled)#</td>
							<td class="normal">#Dollarformat(amountpaid)#</td>
							<td class="normal">#DateFormat(datepaid,"mm/dd/yyyy")# </td>
						</tr>
					</cfloop>
				</table>
			</cfoutput>
					
			<DIV ID='previewdiv' STYLE="position:absolute;top:100;left:50;background:white;" onclick="closediv();"></DIV>
		
			<script type="text/javascript">
			elm=document.getElementById("previewdiv")
			elm.visibility ='hidden';
			</script>
		</cfif>

</cfif> <!--- if attributes.method IS ""--->

<cfif attributes.method IS "add">

	<cfoutput>
		<form name="mygrid" method="post" action="#CGI.SCRIPT_NAME#">
		<input type="hidden" name="method" value="add">
			<table cellpadding="3" cellspacing="0" border="0">
				<tr>
					<td class="normal">For This Payment Number:</td>
					<td class="normal"><input type="text" name="paymentnumber" value="#attributes.paymentnumber#"></td>
				</tr>
				<tr>
					<td class="normal">Update With This Check Number:</td>
					<td class="normal"><input type="text" name="checknumber" value="#attributes.checknumber#"> (blank will revert status to "Ready to Pay"</td>
				</tr>
				<tr>
					<td class="normal"></td>
					<td class="normal"><input type="submit" value="Update" name="submit" class="normal"></td>
				</tr>
			</table>
		
		</form>
	</cfoutput>

</cfif>


<cfif attributes.method IS "changeform">

	<cfoutput>
		<form name="mygrid" method="post" action="#CGI.SCRIPT_NAME#">
		<input type="hidden" name="method" value="change">
			<table cellpadding="3" cellspacing="0" border="0">
				<tr>
					<td class="normal">For This Payment Number:</td>
					<td class="normal"><input type="text" name="paymentnumber" value="#attributes.paymentnumber#"></td>
				</tr>
				<tr>
					<td class="normal">Change to This Payment Number:</td>
					<td class="normal"><input type="text" name="paymentnumbertochange" value="#attributes.paymentnumbertochange#"></td>
				</tr>
				<tr>
					<td class="normal"></td>
					<td class="normal"><input type="submit" value="Update" name="submit" class="normal"></td>
				</tr>
			</table>
		
		</form>
	</cfoutput>

</cfif>
	
	
<cfinclude template="/partnernet/shared/_footer.cfm">
