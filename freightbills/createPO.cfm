<cfset screenID = "825">
<cfset recordhistory = "0">

<cfinclude template="/partnernet/shared/_header.cfm">

<p><a href="default.cfm"><strong>Back to Menu</strong></a></p>

<cfparam name="DSN" default="AHAPDB">

<cfparam name="attributes.fromDate" default="#Dateformat(DateAdd('m',-1,now()),"mm/dd/yyyy")#">
<cfparam name="attributes.uptoDate" default="#Dateformat(now(),"mm/dd/yyyy")#">
<cfparam name="attributes.paymentnumber" default="">
<cfparam name="attributes.submit" default="">
<cfparam name="attributes.mailreportto" default="josh@alpinehomeair.com">
<cfparam name="attributes.freightcompany" default="">
<cfparam name="attributes.includecsv" default=0>

<cfquery name="uniquefreightcompany" datasource="AHAPDB" dbtype="ODBC">
	SELECT CASE WHEN S.srcCompanyName IS NULL THEN f.freightcompany ELSE S.srcCompanyName + ' - ' + C.CarrierLongName END AS 'freightCompany'
		, COUNT(*) AS 'records'
		, ISNULL( CAST(C.carrierID as varChar(50)),f.freightcompany) AS 'carrierID'
		, ISNULL(C.vendorID,1000) AS 'vendorID'
	FROM (
		SELECT * FROM tblFreightBills 
			UNION 
		SELECT * FROM tblBrokerageBills) f
	LEFT JOIN tblCarriers C ON /*c.active = 1 AND*/ f.freightcompany = rtrim(C.carrierID)
	LEFT JOIN dbo.tblProductFulfillmentSources S ON S.srcID = C.vendorID
	WHERE C.carrierID IS NOT NULL 
		OR ISNUMERIC(f.freightcompany) = 0
	GROUP BY f.freightCompany,C.vendorID,S.srcCompanyName,C.CarrierLongName,C.carrierID 
	ORDER BY C.vendorID
</cfquery>

<form name="updateform" method="post" action="#CGI.SCRIPT_NAME#">
	<table cellpadding="3" cellspacing="0" border="0"><cfoutput>
		<tr><td colspan="2" valign="top">All bills <cfif attributes.paymentnumber NEQ "">with payment number #attributes.paymentnumber# <input type="hidden" value="#attributes.paymentnumber#" name="paymentnumber"><cfelse>in "Ready to Pay" status will be applied a PO.</cfif><br><br></td></tr>
		<tr>
		<tr>
			<th valign="top">Pay bills From<br> pickup date:</th>
			<td valign="top"><input type="date" name="fromDate" startrange="#Dateformat(DateAdd('m',-1,now()),'mm/dd/yyyy')#" value="#dateformat(attributes.fromDate, 'yyyy-mm-dd')#"><br><br></td>
			<th valign="top">Pay bills up to<br> pickup date:</th>
			<td valign="top"><input type="date" name="uptoDate" startrange="#Dateformat(now(),'mm/dd/yyyy')#" value="#dateformat(attributes.uptoDate, 'yyyy-mm-dd')#"><br><br></td>
        </tr>
		</tr>
		<tr>
			<th>Company:</th>
			<td colspan="3"><select name="freightcompany" class="normal">
								<!--- 	<option value="Ready to Pay" <cfif attributes.fbstatus IS "Ready to Pay">SELECTED</cfif>>Ready to Pay</option> --->
									<cfloop query="uniquefreightcompany">
										<option value="#carrierID#" <cfif attributes.freightcompany IS "#carrierID#">SELECTED</cfif>>#freightcompany# (#records#)</option>
									</cfloop>
								</select>
								</td>
		</tr>
		<tr>
			<th valign="top">Mail Report To:</th>
			<td colspan="3"><textarea name="mailreportto" cols="60" rows="3">#attributes.mailreportto#</textarea><br>
				Separate multiple addresses with semi-colon: address;address2;address3
			</td>
		</tr>
		<tr>
			<th valign="top">Include CSV?</th>
			<td colspan="3"><select name="includecsv" class="normal">
									<option value="0" <cfif attributes.includecsv EQ 0>SELECTED</cfif>>No</option>
									<option value="1" <cfif attributes.includecsv EQ 1>SELECTED</cfif>>Yes</option>
								</select>
								</td>
		</tr>
		<tr>
			<td class="normal" colspan="4">&nbsp;</td>
		</tr>
		<tr>
			<td></td>
			<td colspan="3"><input type="submit" value="Issue PO" name="submit" class="normal"></td>
		</tr></cfoutput>
	</table>

</form>

<br><br>
<cfset table = attributes.freightcompany EQ 'FedEx Trade Networks' ? 'tblBrokerageBills' : 'tblFreightBills'>
<cfif attributes.submit IS "Issue PO">
	<cfquery name="getfb" datasource="#DSN#">
		SELECT f.objID
	      ,f.orderID
	      ,CONVERT(VARCHAR(15), f.PickupDateTime, 110) AS 'PickupDateTime'
	      ,CONVERT(VARCHAR(15), f.DeliveryDateTime, 110) AS 'DeliveryDateTime'
	      ,f.ProNumber
	      ,f.BOLNumber
	      ,f.PONumber
	      ,f.ShipperName
	      ,f.ConsigneeName
	      ,f.ShipperCity
	      ,f.shipperstate
	      ,f.Shipperzip
	      ,f.ConsigneeCity
	      ,f.ConsigneeState
	      ,f.ConsigneeZip
	      ,f.Pieces
	      ,f.Weight
	      ,f.Type
	      ,f.Service
	      ,f.NetCharge
	      ,f.Discount
	      ,f.Shipper1
	      ,f.Shipper2
	      ,f.estweight
	      ,f.skids
	      ,f.monthtoapply
	      ,ROUND(f.amountbilled, 2) AS 'amountbilled'
	      ,ROUND(f.amountpaid, 2) AS 'amountpaid'
	      ,CONVERT(VARCHAR(15), f.datepaid, 110) AS 'datepaid'
	      ,f.paymentnumber
	      ,f.totalforstatement
	      ,CONVERT(VARCHAR(15), f.statementdate, 110) AS 'statementdate'
	      ,f.notes
	      ,f.rate
	      ,f.discountprct
	      ,f.fuelsurcharge
	      ,f.residentialcharge
	      ,f.liftgatecharge
	      ,f.refunddue
	      ,f.disputestatus
	      ,f.statementNumber
	      ,f.[return]
	      ,f.residentialdelivery
	      ,f.liftgatedelivery
	      ,f.auditrecommendations
	      ,f.freightcompany
	      ,f.shipperacct
	      ,f.consigneeacct
	      ,f.billto
	      ,f.billtoacct
	      ,f.accessorials
	      ,f.[class]
	      ,f.corrected
	      ,f.terms
	      ,f.checknumber
	      ,f.classification
	      ,CONVERT(VARCHAR(15), f.created, 110) AS 'created'
	      ,CONVERT(VARCHAR(15), f.modified, 110) AS 'modified'
	      ,f.modifiedby
	      ,f.modifiedby
	      ,f.POID
		FROM #table# f
		WHERE <cfif attributes.paymentnumber NEQ "">paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumber#"><cfelse>disputestatus = 'Ready To Pay' AND (paymentnumber = '' OR paymentnumber IS NULL)</cfif>
			AND pickupdatetime > <cfqueryparam sqltype="TIMESTAMP" value="#Dateformat(attributes.fromdate,'mm/dd/yyyy')# 00:00:00">
			AND pickupdatetime < <cfqueryparam sqltype="TIMESTAMP" value="#Dateformat(attributes.uptodate,'mm/dd/yyyy')# 23:59:59">
			AND freightcompany = <cfqueryparam sqltype="VARCHAR" value="#attributes.freightcompany#">
		ORDER BY pickupdatetime ASC
	</cfquery>

	<cfquery name="monthallocation" datasource="#DSN#">
		SELECT sum(amountpaid) as amountpaid,monthtoapply
		FROM #table#
		WHERE <cfif attributes.paymentnumber NEQ "">paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#attributes.paymentnumber#"><cfelse>disputestatus = 'Ready To Pay' AND (paymentnumber = '' OR paymentnumber IS NULL)</cfif>
			AND pickupdatetime > <cfqueryparam sqltype="TIMESTAMP" value="#Dateformat(attributes.fromdate,'mm/dd/yyyy')# 00:00:00">
			AND pickupdatetime < <cfqueryparam sqltype="TIMESTAMP" value="#Dateformat(attributes.uptodate,'mm/dd/yyyy')# 23:59:59">
			AND freightcompany = <cfqueryparam sqltype="VARCHAR" value="#attributes.freightcompany#">
		GROUP BY monthtoapply
		ORDER BY monthtoapply ASC
	</cfquery>

	<cfquery name="carriername" datasource="#DSN#">
		SELECT carrierName
		FROM tblCarriers WITH (NOLOCK)
		WHERE CONVERT(varchar (50), carrierID) = <cfqueryparam sqltype="VARCHAR" value="#attributes.freightcompany#">
	</cfquery>

	<cfif getfb.recordcount GT 0>
		<cfset referencenumber = DateFormat(now(),"yymmdd") & TimeFormat(now(),"hhmm")>

		<cfsavecontent variable="reportHTML">
			<style type="text/css">
			table {
				font-family : Arial, Helvetica, Sans-Serif;
				font-size : 12px;
			}
			.large {
				font-size : 20px;
				font-weight : bold;
			}
			</style>

			<table width="100%" cellpadding="2" cellspacing="0" border="0">
				<tr>
					<td class="large" colspan="7"><strong>Freight Bill Payment - Alpine Reference Number: <cfoutput>#referencenumber#</cfoutput>&nbsp;&nbsp;Carrier: <cfoutput>#carriername.carrierName#</cfoutput></strong><br>Date Created: <cfoutput>#DateFormat(Now(),"mm/dd/yyyy")#</cfoutput></td>
				</tr>

				<tr>
					<td colspan="7"><strong>Attention: Payment Processor</strong>
					<p>All payments must be allocated exactly as specified on this payment detail.  In the event of an overpayment, please issue a credit notice.  Do not apply overpayments to bills with shortages.  Bills with payment shortages should be adjusted per the notes on the payment detail.  Please contact Karen Tovey at Alpine Home Air Products at 800.865.5931 ext. 303 if you have any questions regarding this payment.
					<br> &nbsp;</p></td>
				</tr>
				<tr>
					<th>Statement</th>
					<th>Bill #</th>
					<th>Billed $</th>
					<th>Paid $</th>
					<th>Pickup Date</th>
					<th>Consignee</th>
					<th>Notes</th>
				</tr>

				<cfset totalamount = 0>
				<cfoutput query="getfb">
					<tr>
						<td>#statementnumber#</td>
						<td>#pronumber#</td>
						<td><cfif amountpaid LT 0>Adjustment<cfelse>#Dollarformat(amountbilled)#</cfif></td>
						<td>#Dollarformat(amountpaid)#</td>
						<td>#DateFormat(PickupDateTime,"mm/dd/yyyy")#</td>
						<td>#Consigneename#</td>
						<td>#Notes#</td>
					</tr>

					<cfset totalamount = totalamount + amountpaid>
				</cfoutput>
				<tr>
					<td colspan="7" height="2" bgcolor="black"></td>
				</tr>
				<tr>
					<td></td>
					<td></td>
					<td>TOTAL:</td>
					<td><strong><cfoutput>#Dollarformat(totalamount)#</cfoutput></strong></td>
					<td></td>
					<td></td>
					<td></td>
				</tr>
				<tr>
					<td>Allocated to the following months:</td>
					<td></td>
					<td></td>
					<td></td>
					<td></td>
					<td></td>
					<td></td>
				</tr>

				<cfoutput query="monthallocation">

				<tr>
					<td colspan="7">
						<cfif val(monthallocation.monthtoapply) GT 0 AND val(monthallocation.monthtoapply) LT 13>
						#Monthasstring(monthallocation.monthtoapply)#: #Dollarformat(monthallocation.amountpaid)#
						<cfelse>
						Month not identified properly: #Dollarformat(monthallocation.amountpaid)#
						</cfif>
					</td>
				</tr>
				</cfoutput>
			</table>
		</cfsavecontent>

		<cfset filename = "freightPO_" & referencenumber & ".pdf">
		<cfset csvfilename = "freightPO_" & referencenumber & ".csv">
		<cfset path= "#expandPath('/')#documents/">

		<cfdocument format="pdf" filename="#path##filename#" overwrite="yes" pagetype="LETTER" marginright=".5" marginleft=".5" marginbottom=".25" margintop=".25" orientation="landscape">
		<cfoutput>#reportHTML#</cfoutput>
		</cfdocument>

		<cfif attributes.mailreportto NEQ "">
			<cfmail from="system@alpinehomeair.com" to="#attributes.mailreportto#" subject="Freight Bill Payment Number #referencenumber#">
			<cfmailparam file="#path##filename#">
			</cfmail>

			PO successfully created...

			<br><br>

			<cfoutput>#reportHTML#</cfoutput>
		</cfif>

		<cfif attributes.paymentnumber EQ "">
			<cfquery name="updatefb" datasource="#DSN#">
				UPDATE #table#
				SET paymentnumber = <cfqueryparam sqltype="VARCHAR" value="#referencenumber#">,
					disputestatus = 'Sent To Accounting'
				WHERE disputestatus = 'Ready To Pay' AND (paymentnumber = '' OR paymentnumber IS NULL)
					AND pickupdatetime > <cfqueryparam sqltype="TIMESTAMP" value="#Dateformat(attributes.fromdate,'mm/dd/yyyy')# 00:00:00">
					AND pickupdatetime < <cfqueryparam sqltype="TIMESTAMP" value="#Dateformat(attributes.uptodate,'mm/dd/yyyy')# 23:59:59">
					AND freightcompany = <cfqueryparam sqltype="VARCHAR" value="#attributes.freightcompany#">
			</cfquery>
		</cfif>


		<cfif attributes.includecsv>
			<cfset mycsv = queryToCSV(getfb)>

			<cffile file="#expandPath('/')#documents/#csvfilename#" action="write" nameconflict="OVERWRITE" output="#mycsv#">

			<cfmail from="system@alpinehomeair.com" to="#attributes.mailreportto#" subject="Freight Bill Payment Number #referencenumber# - CSV File">
			<cfmailparam file="#expandPath('/')#documents/#csvfilename#">
			</cfmail>
		</cfif>
	<cfelse> <!--- if recordcount GT 0 --->
		<cfoutput>No freight bills in Ready to Pay status.</cfoutput>
	</cfif>

	<br><br>
	<a href="default.cfm">Continue to Menu</a>
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">
