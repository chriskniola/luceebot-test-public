<cfscript>
	screenID = '825';
	showPrototype = 0;
	title = 'Freight Bill Lookup';
	blankform = true;
	now = now();
	MinShipDate = dateFormat(now - dayofWeek(now - 1) -7, 'mm/dd/yyyy');
	MaxShipDate = dateFormat(now - dayofWeek(now - 1), 'mm/dd/yyyy');
	MinPaidDate = dateFormat(now - dayofWeek(now - 1) -7, 'mm/dd/yyyy');
	MaxPaidDate = dateFormat(now - dayofWeek(now - 1), 'mm/dd/yyyy');
	param name='attributes.fbstatus'       default='All Unpaid';
	param name='attributes.criteria'       default='';
	param name='attributes.shipDateFilter' default='';
	param name='attributes.shipDateRange'  default='';
	param name='attributes.paidDateFilter' default='';
	param name='attributes.paidDateRange' default='';
	param name='attributes.freightcompany' default='';

	param name='attributes.specialReport'  default='';

	param name='attributes.paymentnumber'  default='';
	param name='attributes.checknumber'    default='';
	param name='attributes.POVendorID'     default='';
	param name='attributes.queryflags'     default='';

	param name='attributes.format'         default='html';
	param name='attributes.Submit'         default='';
	setting showdebugoutput=true;

	if( attributes.shipDateFilter=='on' ){
		dateRangeArray = listToArray(attributes.shipDateRange, ' - ');
		MinShipDate = dateRangeArray[1];
		MaxShipDate = dateRangeArray[2];
	}
	if( attributes.paidDateFilter=='on' ){
		dateRangeArray = listToArray(attributes.paidDateRange, ' - ');
		MinPaidDate = dateRangeArray[1];
		MaxPaidDate = dateRangeArray[2];
	}

</cfscript>

<cfsavecontent variable='content'>
	<style>
		option.inactive { color: lightgrey; }
	</style>
	<cfquery name="uniquedisputestatus" datasource="AHAPDB" dbtype="ODBC">
		SELECT disputestatus, COUNT(*) AS 'records'
		FROM tblFreightBills
		GROUP BY disputestatus

		<!---
		SELECT disputestatus,count(*) AS 'records'
		FROM(SELECT disputestatus
		FROM tblFreightBills


		UNION ALL

		SELECT disputestatus
		FROM tblBrokerageBills) AS results
		GROUP BY results.disputestatus
		--->
	</cfquery>

	<cfquery name="uniquefreightcompany" datasource="AHAPDB" dbtype="ODBC">
		SELECT fb.freightcompany, c.carrierLongName, c.carrierName, COUNT(*) AS 'records', c.active
		FROM tblFreightBills fb
		LEFT JOIN tblcarriers c
			ON CONVERT(varChar(25),c.carrierID) = fb.freightCompany
		WHERE c.vendorID = 24
			OR c.vendorID = 22
		GROUP BY fb.freightcompany, c.carrierLongName, c.carrierName, c.active
		ORDER BY c.active DESC, c.carrierlongname

		<!---
		SELECT freightcompany, carrierLongName, carrierName, COUNT(*) AS 'records'
		FROM (SELECT fb.freightcompany, c.carrierLongName, c.carrierName
			FROM tblFreightBills fb
			LEFT JOIN tblcarriers c
				ON CONVERT(varChar(25),c.carrierID) = fb.freightCompany

			UNION ALL

			SELECT bb.freightcompany, c.carrierLongName, c.carrierName
			FROM tblBrokerageBills bb
			LEFT JOIN tblcarriers c
				ON CONVERT(varChar(25),c.carrierID) = bb.freightCompany) AS results
		GROUP BY results.freightcompany, results.carrierLongName, results.carrierName
		ORDER BY ISNULL(results.carrierLongName, results.freightcompany)
		--->
	</cfquery>

	<cfif attributes.submit IS "Update All Items">
		<div class="infobox">Processing... Please wait - this may take some time...</div>

		<cfloop from="1" to="#attributes.records#" index="i">
			<cfset putbill = 0>
			<cfparam name="attributes.objID#i#" default="">
			<cfparam name="attributes.amountpaid#i#" default="">
			<cfparam name="attributes.notes#i#" default="">
			<cfparam name="attributes.reaudit#i#" default="0">

			<cfset objID="#attributes['objID'&i]#">
			<cfset amountpaid="#attributes['amountpaid'&i]#">
			<cfset notes="#attributes['notes'&i]#">
			<cfset reaudit="#attributes['reaudit'&i]#">

			<cfif val(amountpaid) GT 0 OR reaudit OR putbill>
				<cfobject component="alpine-objects.freightbill" name="freightbill">
				<cfinvoke component="#freightbill#" method="init"></cfinvoke>
				<cfinvoke component="#freightbill#" method="get" objID="#objID#"></cfinvoke>
			</cfif>

			<cfif val(amountpaid) GT 0>

				<cfset freightbill.amountpaid = amountpaid>
				<cfset freightbill.notes = notes>

				<cfif NOT reaudit>
					<cfset freightbill.disputestatus = "Ready to Pay">
					<cfset putbill = 1>
				</cfif>
			</cfif>

			<cfif reaudit>
				<cfinvoke component="#freightbill#" method="audit"></cfinvoke>
				<cfset putbill = 1>
			</cfif>

			<cfif putbill>
				<cfinvoke component="#freightbill#" method="put"></cfinvoke>
			</cfif>


		</cfloop>


	</cfif>

	<cfif attributes.submit NEQ ''>
		<cfquery name="getfb" datasource="ahapdb">
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

			<!--- <cfloop list="tblBrokerageBills,tblFreightBills" item="table" index="idx"> --->
			<cfloop list="tblFreightBills" item="table" index="idx">
				<cfif idx NEQ 1>
					UNION ALL
				</cfif>
				SELECT <cfif attributes.format NEQ "csv">TOP 501</cfif> f.objID
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
					,f.Weight AS 'billedWeight'
					,f.Type
					,f.Service
					,f.NetCharge
					,f.Discount
					,f.Shipper1
					,f.Shipper2
					,f.estweight AS 'weight'
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
					,f.corrected
					,f.terms
					,f.checknumber
					,f.classification
					,CONVERT(VARCHAR(15), f.created, 110) AS 'created'
					,CONVERT(VARCHAR(15), f.modified, 110) AS 'modified'
					,f.modifiedby
					,f.modifiedby
					,f.POID
					,estship.[Estimated Shipping Cost] AS 'EstimatedAmount'
					,ROUND(f.amountbilled-estship.[Estimated Shipping Cost], 2) AS 'VarianceAmount'
					,NULLIF(f.amountbilled,0) + f.discount - accessorialTotal.total AS 'UndiscountedRate'
					,NULLIF(f.amountbilled,0) - accessorialTotal.total AS 'DiscountedRate'
					,ROUND((NULLIF(f.amountbilled,0) - accessorialTotal.total)/(ISNULL(NULLIF(f.Weight,0),1)/100),2) AS 'hundredweightrate'
					,CASE WHEN class.IsMinimumCharge = 1 THEN NULLIF(f.amountbilled,0) - accessorialTotal.total - ISNULL(pocr.minimum,rateBreakout.[minimum - current])
						  ELSE ROUND((NULLIF(f.amountbilled,0) - accessorialTotal.total)/(ISNULL(NULLIF(f.Weight,0),1)/100),2)
							- CASE WHEN f.Weight BETWEEN 0 AND 500 THEN ISNULL(pocr.lt500,rateBreakout.[lt500 - current])
		  						   WHEN f.Weight BETWEEN 500 AND 1000 THEN ISNULL(pocr.gt500, rateBreakout.[gt500 - current])
		  						   WHEN f.Weight BETWEEN 1000 AND 2000 THEN ISNULL(pocr.gt1k, rateBreakout.[gt1k - current])
		  						   WHEN f.Weight BETWEEN 2000 AND 5000 THEN ISNULL(pocr.gt2k, rateBreakout.[gt2k - current])
		  						   WHEN f.Weight > 5000 THEN ISNULL(pocr.gt5k, rateBreakout.[gt5k - current]) END END
						AS 'hundredweightvariance'
					,class.MaxClass AS 'class'
					,CASE WHEN class.Classes > 1 THEN 'Y' ELSE 'N' END AS 'Multiclass'
					,CASE WHEN class.IsMinimumCharge = 1 THEN 'Y' ELSE 'N' END AS 'IsMinimumCharge'
					,pocr.minimum AS 'minimum - historical'
					,pocr.lt500 AS 'lt500 - historical'
					,pocr.gt500 AS 'gt500 - historical'
					,pocr.gt1k AS 'gt1k - historical'
					,pocr.gt2k AS 'gt2k - historical'
					,pocr.gt5k AS 'gt5k - historical'
					,pocr.ShippingSurcharges AS 'ShippingSurcharges - historical'
					,pocr.FuelSurchargeRate AS 'FuelSurchargeRate - historical'
					,accessorial.[Accessorial 1 Code]
					,accessorial.[Accessorial 1 Amount]
					,accessorial.[Accessorial 2 Code]
					,accessorial.[Accessorial 2 Amount]
					,accessorial.[Accessorial 3 Code]
					,accessorial.[Accessorial 3 Amount]
					,accessorial.[Accessorial 4 Code]
					,accessorial.[Accessorial 4 Amount]
					,accessorial.[Accessorial 5 Code]
					,accessorial.[Accessorial 5 Amount]
					,accessorial.[Accessorial 6 Code]
					,accessorial.[Accessorial 6 Amount]
					,rateBreakout.[minimum - current]
					,rateBreakout.[lt500 - current]
					,rateBreakout.[gt500 - current]
					,rateBreakout.[gt1k - current]
					,rateBreakout.[gt2k - current]
					,rateBreakout.[gt5k - current]
					,rateBreakout.[ShippingSurcharges - current]
					,rateBreakout.[FuelSurchargeRate - current]
					,f.Weight - f.estweight AS 'Weight Variance'
					,CASE WHEN LEFT(poh.shippingoptions, 3) = 'COM' THEN 'N' ELSE 'Y' END AS 'Had Residential'
					,CASE WHEN (SELECT COUNT(*) FROM orders WHERE productnumber = 453054793 AND sessionid = f.orderID) = 1 THEN 'Y' ELSE 'N' END AS 'Had Liftgate'
					,CASE
						WHEN poh.locationTypeID = 1 AND poh.locationID = 9 THEN 'Kentucky'
						WHEN poh.locationTypeID = 1 AND poh.locationID = 10 THEN 'Pennsylvania'
						WHEN poh.locationTypeID = 1 AND poh.locationID = 11 THEN 'Nevada'
						ELSE '' END AS 'ShipPoint'
				FROM #table# f
				LEFT JOIN tblVendorPOHeader poh ON f.POID = poh.POID
				LEFT JOIN tblVendorPOCarrierRates pocr ON poh.POID = pocr.POID
				CROSS APPLY (
						SELECT MAX([Accessorial 1 Code]) AS 'Accessorial 1 Code'
							, MAX([Accessorial 1 Amount]) AS 'Accessorial 1 Amount'
							, MAX([Accessorial 2 Code]) AS 'Accessorial 2 Code'
							, MAX([Accessorial 2 Amount]) AS 'Accessorial 2 Amount'
							, MAX([Accessorial 3 Code]) AS 'Accessorial 3 Code'
							, MAX([Accessorial 3 Amount]) AS 'Accessorial 3 Amount'
							, MAX([Accessorial 4 Code]) AS 'Accessorial 4 Code'
							, MAX([Accessorial 4 Amount]) AS 'Accessorial 4 Amount'
							, MAX([Accessorial 5 Code]) AS 'Accessorial 5 Code'
							, MAX([Accessorial 5 Amount]) AS 'Accessorial 5 Amount'
							, MAX([Accessorial 6 Code]) AS 'Accessorial 6 Code'
							, MAX([Accessorial 6 Amount]) AS 'Accessorial 6 Amount'
						FROM (SELECT TOP 5
								  a.code
								, CONCAT('Accessorial '
										,CAST(CASE a.code WHEN 'FUE' THEN 1
														WHEN 'LIFP' THEN 2
														WHEN 'LFT' THEN 2
														WHEN 'RES' THEN 3
														WHEN 'RESD' THEN 3
														ELSE 3 - fixed.total + ROW_NUMBER() OVER(ORDER BY CASE WHEN a.code IN ('FUE','RES','RESD','LIFP','LFT') THEN 0 ELSE 1 END, a.cost DESC) END AS NVARCHAR)
										,' Code') AS 'codePivot'
								, a.cost
								, CONCAT('Accessorial '
										,CAST(CASE a.code WHEN 'FUE' THEN 1
														WHEN 'LIFP' THEN 2
														WHEN 'LFT' THEN 2
														WHEN 'RES' THEN 3
														WHEN 'RESD' THEN 3
														ELSE 3 - fixed.total + ROW_NUMBER() OVER(ORDER BY CASE WHEN a.code IN ('FUE','RES','RESD','LIFP','LFT') THEN 0 ELSE 1 END, a.cost DESC) END AS NVARCHAR)
										,' Amount') AS 'costPivot'
								FROM tblFreightBillAccessorials a
								CROSS APPLY (SELECT COUNT(*) AS 'total' FROM tblFreightBillAccessorials WHERE [objID] = a.[objID] AND code IN ('FUE','RES','RESD','LIFP','LFT')) fixed
								WHERE a.[objID] = f.[objID]) AS source
						PIVOT(MAX(code) FOR codePivot IN ([Accessorial 1 Code],[Accessorial 2 Code],[Accessorial 3 Code],[Accessorial 4 Code],[Accessorial 5 Code],[Accessorial 6 Code])) AS Pivot1
						PIVOT(MAX(cost) FOR costPivot IN ([Accessorial 1 Amount],[Accessorial 2 Amount],[Accessorial 3 Amount],[Accessorial 4 Amount],[Accessorial 5 Amount],[Accessorial 6 Amount])) AS Pivot2
					) accessorial
				CROSS APPLY ( SELECT ISNULL(SUM(cost),0) AS 'total' FROM tblFreightBillAccessorials WHERE [objID] = f.[objID]) accessorialTotal
				CROSS APPLY ( SELECT SUM(Amount) AS 'Estimated Shipping Cost' FROM tblVendorPOShippingEstimates WHERE POID = f.POID) estship
				CROSS APPLY ( SELECT ISNULL(SUM(Charge),0) AS 'BaseRate', MAX(Class) AS 'MaxClass', COUNT(DISTINCT Class) AS 'Classes', ISNULL(MAX(CONVERT(INT,IsMinimumCharge)),0) AS 'IsMinimumCharge' FROM tblFreightBillRates WHERE [objID] = f.[objID]) class
				OUTER APPLY ( SELECT minimum AS 'minimum - current'
									, lt500 AS 'lt500 - current'
									, gt500 AS 'gt500 - current'
									, gt1k AS 'gt1k - current'
									, gt2k AS 'gt2k - current'
									, gt5k AS 'gt5k - current'
									, ISNULL(stf.shippingtypefee,0) + ISNULL(sc.cost,0) AS 'ShippingSurcharges - current'
									,c.fuelsurcharge AS 'FuelSurchargeRate - current'
							  FROM tblVendorCarrierServiceDays vs
							  RIGHT JOIN tblVendorCarrierShipping vr ON vs.vendorID = vr.vendorID AND vs.carrierID = vr.carrierID AND vs.zip = vr.zip
							  INNER JOIN tblCarriers c ON c.carrierID = vr.carrierID AND CONVERT(VARCHAR,c.CarrierID) = f.freightcompany
							  INNER JOIN tblCarrierShippingTypeFees stf ON stf.carrierID = c.carrierID
							  INNER JOIN tblCarrierShippingTypeLookup stl ON typeID = stf.shippingtypeID and stl.queryflags = poh.shippingoptions
							  LEFT JOIN tblVendorCarrierSurcharges sc ON sc.carrierID = c.CarrierID AND vr.zip BETWEEN lozip AND hizip AND sc.surcharge = stl.typeID
							  WHERE vr.zip = f.ConsigneeZip) rateBreakout
				WHERE
					<cfswitch expression="#trim(attributes.specialReport)#">
						<cfcase value="duplicatebol">
							EXISTS
								(SELECT 1
								FROM #table# f2 WITH (NOLOCK)
								WHERE f2.ProNumber = f.ProNumber
								GROUP BY f2.ProNumber
								HAVING COUNT(*) > 1)
						</cfcase>
						<cfcase value="bolordermismatch">
							NOT EXISTS (SELECT 1 FROM checkouts WITH (NOLOCK) WHERE checkouts.sessionID = f.bolnumber)
							AND ISNULL(f.orderID,'') = ''
						</cfcase>
						<cfcase value="partialpay">
							f.amountpaid < f.amountbilled
							AND f.disputestatus IN ('Ready to Pay','Sent to Accounting','Paid')
						</cfcase>
						<cfcase value="blankbol">
							ISNULL(f.bolnumber,'') = ''
						</cfcase>
						<cfcase value="blankorder">
							ISNULL(f.orderID,'') = ''
						</cfcase>
						<cfdefaultcase>
							<cfif len(trim(attributes.criteria))>
								<cfqueryparam sqltype="VARCHAR" value="#attributes.criteria#"> IN (f.paymentnumber,f.checknumber,f.pronumber,f.BOLNumber,f.orderID)
								OR f.consigneename LIKE <cfqueryparam sqltype="VARCHAR" value="%#attributes.criteria#%">
								OR f.consigneezip LIKE <cfqueryparam sqltype="VARCHAR" value="%#attributes.criteria#%">
								OR f.statementnumber LIKE <cfqueryparam sqltype="VARCHAR" value="%#attributes.criteria#%">
								OR f.shippername LIKE <cfqueryparam sqltype="VARCHAR" value="%#attributes.criteria#%">
							<cfelse>
								1=1
								<cfif NOT len(trim(attributes.paymentnumber)) AND NOT len(trim(attributes.checknumber))>
									<cfif attributes.fbstatus IS "All Unpaid">
										AND f.disputestatus <> 'Paid'
									<cfelse>
										AND f.disputestatus IN (<cfqueryparam sqltype="VARCHAR" list=true value="#attributes.fbstatus#">)
									</cfif>
								</cfif>
								<cfif len(trim(attributes.paidDateFilter))>
									AND f.datepaid >= <cfqueryparam sqltype="VARCHAR" value="#minpaiddate#">
									AND f.datepaid <= <cfqueryparam sqltype="VARCHAR" value="#maxpaiddate#">
								</cfif>
								<cfif len(trim(attributes.shipDateFilter))>
									AND f.pickupdatetime >= <cfqueryparam sqltype="VARCHAR" value="#minshipdate#">
									AND f.pickupdatetime <= <cfqueryparam sqltype="VARCHAR" value="#maxshipdate#">
								</cfif>
								<cfif len(trim(attributes.freightcompany))>
									AND f.freightcompany IN (<cfqueryparam sqltype="VARCHAR" list=true value="#attributes.freightcompany#">)
								</cfif>
							</cfif>
						</cfdefaultcase>
					</cfswitch>
			</cfloop>
			ORDER BY f.ProNumber ASC
		</cfquery>
	</cfif>

	<div class="">
		<form name="updateform" method="post" action="<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>">
			<div class="row">
				<div class="col-md-5">
					<div class="form-group">
						<label>Status</label>
						<select class='form-control' multiple name="fbstatus" size='5'>
							<cfoutput query="uniquedisputestatus">
								<option value="#uniquedisputestatus.disputestatus#" <cfif listContains(attributes.fbstatus, uniquedisputestatus.disputestatus) >SELECTED</cfif>>#uniquedisputestatus.disputestatus# (#uniquedisputestatus.records#)</option>
							</cfoutput>
						</select>
					</div>
					<div class="form-group">
						<label>Criteria</label><!---  <font class="tiny"><a onclick="javascript:">what's this?</a></font> --->:</td>
						<input class='form-control' type="text" name="criteria" width="40" value="<cfoutput>#attributes.criteria#</cfoutput>">
					</div>
					<div class="form-group">
						<label>
							<input type="checkbox" name='shipDateFilter' <cfif attributes.shipDateFilter EQ 'on'>checked</cfif>>
							Ship Date Range
						</label><br>
						<div class='input-group'>
							<span class='input-group-addon'><i class='fa fa-calendar'></i></span>
							<cfoutput><input class='form-control dateFilter' type='text' name='shipDateRange'  id='shipDateRange' value='#MinShipDate# - #MaxShipDate#' /></cfoutput>
						</div>
					</div>
					<div class="form-group">
						<label>
							<input type="checkbox" name='paidDateFilter' <cfif attributes.paidDateFilter EQ 'on'>checked</cfif>>
							Date Paid Range
						</label><br>
						<div class='input-group'>
							<span class='input-group-addon'><i class='fa fa-calendar'></i></span>
							<cfoutput><input class='form-control dateFilter' type='text' name='paidDateRange' id='paidDateRange' value='#MinPaidDate# - #MaxPaidDate#' /></cfoutput>
						</div>
					</div>
				</div>
				<div class="col-md-7">
					<div class="form-group">
						<label>Company</label>
						<select class='form-control' multiple name="freightcompany" size='18'>
							<cfoutput query="uniquefreightcompany">
								<option value="#uniquefreightcompany.freightcompany#" <cfif ListFind(attributes.freightcompany, uniquefreightcompany.freightcompany)>SELECTED</cfif> <cfif !uniquefreightcompany.active>class="inactive"</cfif>><cfif Len(uniquefreightcompany.carrierLongName)>#uniquefreightcompany.carrierLongName# / #uniquefreightcompany.carrierName# / </cfif>#uniquefreightcompany.freightcompany# (#uniquefreightcompany.records#)</option>
							</cfoutput>
						</select>
					</div>
				</div>
			</div>
			<hr>
			<div class="row">
				<div class="col-md-5">
					<div class="form-group">
						<label><em>OR</em> Select Special Report:</label>
						<select class='form-control' name="specialReport">
							<option value="" <cfif attributes.specialReport IS "">SELECTED</cfif>>Use basic report above</option>
							<option value="bolordermismatch" <cfif attributes.specialReport IS "bolordermismatch">SELECTED</cfif>>BOL Number does not match order number (and is not blank)</option>
							<option value="partialpay" <cfif attributes.specialReport IS "partialpay">SELECTED</cfif>>Paid amount less than billed amount</option>
							<option value="blankorder" <cfif attributes.specialReport IS "blankorder">SELECTED</cfif>>Order Number is blank</option>
							<option value="blankbol" <cfif attributes.specialReport IS "blankbol">SELECTED</cfif>>BOL Number is blank</option>
							<option value="duplicatebol" <cfif attributes.specialReport IS "duplicatebol">SELECTED</cfif>>Duplicate BOL Numbers</option>
						</select>
					</div>
				</div>
				<div class="col-md-1"></div>
				<div class="col-md-6">
					<div class="form-group">
						<br>
						<label>Format</label>
						<div class="radio-inline">
							<label><input type='radio' name="format" value="HTML"<cfif attributes.format EQ "html"> CHECKED</cfif>>HTML</label>
						</div>
						<div class="radio-inline"  style='padding-right: 30px;'>
							<label><input type='radio' name="format" value="CSV"<cfif attributes.format EQ "CSV"> CHECKED</cfif>>CSV</label>
						</div>

						<button class='btn btn-primary' type="submit" value="Search" name="submit">Search</button>
					</div>
				</div>
			</div>
	</div>

	<cfif attributes.submit IS NOT "" AND attributes.format EQ "html">

		<cfoutput>
			<cfif attributes.submit IS NOT "">
					<cfset showupdate = 0>
				<div id="report">
					<table cellpadding="3" cellspacing="0" border="2">
						<tr>
							<td colspan="17">

								<strong><cfoutput>#getfb.recordcount#</cfoutput> records returned.</strong>
								<cfif getfb.recordcount GT 500>
								 <font color="red">Your query was truncated - maximum query display size is 500 rows. Please refine your criteria and try again.</font>
								</cfif>
							</td>
						</tr>
						<tr>
							<th>&nbsp;</th>
							<th><strong>Status</strong></th>
							<th><strong>Pickup Date</strong></th>
							<th><strong>Delivery Date</strong></th>
							<th><strong>Pro Number</strong></th>
							<th><strong>PO Number</strong></th>
							<th><strong>Order ID</strong></th>
							<th><strong>Ship-point</strong></th>
							<th><strong>Amount Billed</strong></th>
							<th><strong>Amount Paid</strong></th>
							<th><strong>Date Paid</strong></th>
							<th><strong>Consignee</strong></th>
							<th><strong>Payment No.</strong></th>
							<th><strong>Check No.</strong></th>
							<th><strong>Audit Recommendations</strong></th>
							<th><strong>Notes</strong></th>
							<th><strong>Zip Code</strong></th>
							<th><strong>Weight</strong></th>
						</tr>
						<cfset objCarrier = createObject("component","alpine-objects.carrier")>
						<cfset receivable = createObject("component","alpine-objects.receivable")>
						<cfloop query="getfb">
							<cfset highlight = "hiLite">
							<cfset showupdate = 1>
							<tr id="row#getfb.currentrow#" onmouseover="hiLite(this, j$('##row#getfb.currentrow#-2')[0]);" bordercolor="white">
								<td class="tiny" valign="top"><a href="javascript:openwin('/templates/object.cfm?objecttype=freightbill&objID=#getfb.objID#&action=edit','','850','800');" title="Open Freight Bill">open</a> &nbsp; <a href="javascript:preview('#getfb.objID#','freightbill');" title="Preview Freight Bill">preview</a></td>
								<td valign="top">#getfb.Disputestatus#&nbsp;</td>
								<td valign="top">#DateFormat(getfb.PickupDateTime,"mm/dd/yyyy")#&nbsp;</td>
								<td valign="top">#DateFormat(getfb.DeliveryDateTime,"mm/dd/yyyy")#&nbsp;</td>
								<td valign="top">#getfb.ProNumber#&nbsp;</td>
								<td valign="top">#getfb.PONumber#&nbsp;</td>
								<td valign="top"><a href="javascript:preview('#getfb.orderID#','order&showmessages=1&showinvoices=1');" title="Preview Order">#getfb.orderID#</a>&nbsp;</td>
								<td valign="top">#getfb.ShipPoint#&nbsp;</td>
								<td valign="top">#Dollarformat(getfb.amountbilled)#&nbsp;</td>
								<cfif getfb.disputestatus EQ "Failed Audit">
									<td valign="top"><input name="amountpaid#getfb.currentrow#" type="text" value="#getfb.amountpaid#" size="5"></td>
								<cfelse>
									<td valign="top">#Dollarformat(amountpaid)# <cfif amountpaid GT 0 AND val(amountpaid)-val(amountbilled) NEQ 0>#Dollarformat(val(amountpaid)-val(amountbilled))#</cfif>&nbsp;</td>
								</cfif>
								<td valign="top">#DateFormat(getfb.datepaid,"mm/dd/yyyy")#&nbsp;</td>
								<td valign="top">#getfb.Consigneename#&nbsp;</td>
								<td valign="top">#getfb.paymentnumber#&nbsp;</td>
								<td valign="top">#getfb.checknumber#&nbsp;</td>
								<td valign="top">
									<cfloop list="#getfb.auditrecommendations#" index="l">
										<cfoutput>#l#<br></cfoutput>
									</cfloop>&nbsp;
								</td>
								<td valign="top">#getfb.notes#&nbsp;</td>
								<td valign="top">#getfb.consigneezip#&nbsp;</td>
								<td valign="top">#getfb.billedWeight#&nbsp;</td>
							</tr>

							<cfif getfb.disputestatus EQ "Failed Audit">
								<tr id="row#getfb.currentrow#-2" onmouseover="hiLite(this, j$('##row#getfb.currentrow#')[0]);" bordercolor="white">
									<td colspan="5">&nbsp;</td>
									<td colspan="2">

										<cfquery name="getthePOHeader" datasource="#DSN#">
										SELECT c.vendorID, h.shippingoptions
										FROM tblCarriers c WITH (NOLOCK)
										LEFT OUTER JOIN tblVendorPOHeader h WITH (NOLOCK) ON h.carrierID = c.carrierID AND h.POID = <cfqueryparam sqltype="VARCHAR" value="#getfb.POID#">
										WHERE CAST(c.carrierID AS VARCHAR) = <cfqueryparam sqltype="VARCHAR" value="#getfb.freightcompany#">
										</cfquery>

										<cfif getthePOHeader.recordcount>
											<cfset attributes.POVendorID = getthePOHeader.vendorID>
											<cfset attributes.queryflags = getthePOHeader.shippingoptions>
										<cfelse>
											<cfset attributes.POVendorID = "">
											<cfset attributes.queryflags = "">
										</cfif>

										<cfset getRate = objCarrier.getshippingrate(vendorID=val(attributes.POVendorID),carrierID=val(getfb.freightcompany),postalcode=getfb.consigneezip,weight=val(getfb.billedWeight),shippingoptions=attributes.queryflags)>

										<cfset attributes.POVendorID = "">
										<cfset attributes.queryflags = "">
										<cfset local.guaranteedSurcharge = val(queryExecute("SELECT price FROM orders WHERE SessionID = :orderID AND productNumber = 453071037",{orderID:{sqltype:"VARCHAR",value:getfb.orderID}},{datasource:DSN}).price)>


										Shipping Estimate with Billed Weight: #dollarFormat(getRate.rate + local.guaranteedSurcharge)#


									</td>
									<td colspan="2" valign="top">
										<input name="objID#getfb.currentrow#" value="#getfb.objID#" type="hidden">
										<input name="amountbilled#getfb.currentrow#" type="hidden" value="#getfb.amountbilled#" size="7">
										<a href style="cursor: pointer" onclick="javascript:document.updateform.amountpaid#getfb.currentrow#.value = document.updateform.amountbilled#getfb.currentrow#.value;return false;">Approve as billed</a><br>
										<a href style="cursor: pointer" onclick="javascript:document.updateform.amountpaid#getfb.currentrow#.value = '0';return false;">UnApprove as billed</a>
											<br>
										<a href="/templates/object.cfm?objecttype=freightbill&action=openreceivable&objID=#getfb.objID#" target="_blank"><div class="tiny" id="dispute#getfb.objID#">open receivable</div></a>
									</td>
									<td colspan="8" bordercolor="white" valign="top">
										&nbsp; Billing Notes: <textarea name="notes#getfb.currentrow#" cols="50" rows="1">#getfb.notes#</textarea><br>
										Re-Audit: <input name="reaudit#getfb.currentrow#" type="radio" value="1"> Yes or <input name="reaudit#getfb.currentrow#" type="radio" value="0" checked> No
									</td>
								</tr>
							<cfelse>
								<tr id="row#getfb.currentrow#-2" onmouseover="hiLite(this, j$('##row#getfb.currentrow#')[0])" bordercolor="white">
									<td colspan="7">&nbsp;</td>
									<td colspan="2" valign="top">
										<a href="/templates/object.cfm?objecttype=freightbill&action=openreceivable&objID=#getfb.objID#" target="_blank"><div class="tiny" id="dispute#getfb.objID#">open receivable</div></a>
									</td>
									<td colspan="8" bordercolor="white" valign="top">&nbsp;</td>
								</tr>

							</cfif>

							<cfquery name="getreceivable" datasource="#DSN#">
							SELECT objID
							FROM tblReceivables
							WHERE creatorobjID = <cfqueryparam sqltype="VARCHAR" value="#getfb.objID#">
							</cfquery>

							<cfif getreceivable.recordcount>
								<tr>
									<td colspan="7">&nbsp;</td>
									<td colspan="2">
										<cfloop query="getreceivable">
											<cfset result = receivable.get(objID=getreceivable.objID)>
											<cfif result.errorcode>
												Error getting object
											</cfif>

											<cfset receivable.display(format="link")>
										</cfloop>
									</td>
								</tr>
							</cfif>

							<tr bordercolor="white"><td colspan="17">&nbsp;</td></tr>
						</cfloop>

						<cfif showupdate>
							<tr>
								<td colspan="7">&nbsp;</td>
								<td colspan="10">

									<button class='btn btn-primary btn-primary' name="submit" value="Update All Items" type="submit">Update All Items</button>
									<input  type="hidden" value="#getfb.recordcount#" name="records">
								</td>
							</tr>
						</cfif>
					</table>
				</form>
				</div>
			</cfif>
		</cfoutput>

		<DIV ID='previewdiv' STYLE="position:absolute;top:100;left:50;background:white;overflow:scroll;height:600" onclick="closediv();"></DIV>

		<script type="text/javascript">
		closediv();

		</script>

	<cfelseif attributes.submit IS NOT "" AND attributes.format EQ "csv">

		<cfset colorder="Disputestatus,PickupDateTime,DeliveryDateTime,ProNumber,PONumber,orderID,ShipPoint,datepaid,Consigneename,paymentnumber,checknumber,auditrecommendations,notes,consigneezip,amountbilled,amountpaid,EstimatedAmount,VarianceAmount,UndiscountedRate,DiscountedRate,IsMinimumCharge,hundredweightrate,hundredweightvariance,discount,class,Multiclass,weight,billedWeight,Weight Variance,Accessorial 1 Code,Accessorial 1 Amount,Accessorial 2 Code,Accessorial 2 Amount,Had Liftgate,Accessorial 3 Code,Accessorial 3 Amount,Had Residential,Accessorial 4 Code,Accessorial 4 Amount,Accessorial 5 Code,Accessorial 5 Amount,Accessorial 6 Code,Accessorial 6 Amount,minimum - historical,lt500 - historical,gt500 - historical,gt1k - historical,gt2k - historical,gt5k - historical,ShippingSurcharges - historical,FuelSurchargeRate - historical,minimum - current,lt500 - current,gt500 - current,gt1k - current,gt2k - current,gt5k - current,ShippingSurcharges - current,FuelSurchargeRate - current">
		<cfinvoke component="alpine-objects.report" method="display" recordset="#getfb#" columnorder="#colorder#" returnvariable="result" format="#attributes.format#">

	</cfif>
	<script>
		j$(function(){
			var now = new Date();
			var lastSunday = now.getDay() + 7;
			var thisSunday = now.getDay();
			var definedRanges =  {
				'This Week': [moment().subtract(thisSunday, 'days'), moment()],
				'Last Week': [moment().subtract(lastSunday, 'days'), moment().subtract(thisSunday, 'days')],
				'This Month': [moment().subtract(now.getDate() -1, 'days'), moment()]
			};

			j$('#shipDateRange').daterangepicker({
				'dateLimit': { 'years': 1 },
				ranges: definedRanges
			});

			j$('#paidDateRange').daterangepicker({
				ranges: definedRanges
			});
		});
	</script>
</cfsavecontent>


<cfinclude template='/partnernet/shared/layouts/basic.cfm'>
