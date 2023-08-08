<cfcomponent displayname="orders">
	<cfset this.DSN = "ahapdb">

	<cffunction name="userCanReleaseOrder" access="public" returntype="boolean">
		<cfreturn APPLICATION.user.returnpermission(1030)>
	</cffunction>

	<cffunction name="updateProcessNumber" access="public" returntype="void">
	<cfargument type="string" required="true" name="orderID">
	<cfargument type="numeric" required="true" name="processNumber">
		<cfset queryExecute("
			UPDATE checkouts SET process = :processNum
			WHERE SESSIONID= :orderID"
		, {	orderID 	= {sqltype="VARCHAR", value=arguments.orderID},
			processNum 	= {sqltype="INT", value=arguments.processNumber}}
		, { datasource	= 'ahapdb'})>

		<cfif listFind('90,99', arguments.processNumber)>
			<cfset application.cbController.runEvent( event="checkout.TaxJar.DeleteTaxJarOrderTransactionHandler.handle", eventArguments={rc.orderID: arguments.orderID})>
		</cfif>
	</cffunction>

	<cffunction name="getShippingInfo" access="public" returntype="any">
	<cfargument type="string" required="true" name="orderID">
		<cfset results = queryExecute("
			SELECT
				  c.sessionID AS orderID
				, c.shipname
				, c.shipcompany
				, c.shipaddress1
				, c.shipaddress2
				, c.shipcity
				, c.shipstate
				, UPPER(dbo.reAlphaNumeric(c.shipzip)) AS 'shippostalcode'
				, c.shipcountry
				, c.tel AS 'shiptelephone'
				, ISNULL(c.delayreporteddate,GETDATE()) AS 'requestedShipDate'
			FROM checkouts c WITH (NOLOCK)
			WHERE c.sessionID = :orderID
				AND c.process = 20
		"
		,{orderID={sqltype="VARCHAR",value=arguments.orderID}}
		,{datasource=THIS.DSN})>

		<cfif results.recordCount>
			<cfreturn results.rowData(1)>
		</cfif>
	</cffunction>

	<cffunction name="getOrderLock" access="public" returntype="boolean">
	<cfargument type="string" required="true" name="orderID">
		<cfset getLock = StructKeyExists(SESSION, 'user') ? SESSION.user.ID : 0>
		<cfstoredproc procedure="objects_lock_put" datasource="#this.DSN#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#arguments.orderID#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#getlock#">
			<cfprocparam type="OUT" sqltype="BIT" variable="lockgranted">
			<cfprocparam type="OUT" sqltype="VARCHAR" variable="lockedby">
			<cfprocresult name="orderLock">
		</cfstoredproc>
		<cfreturn lockgranted>
	</cffunction>

	<cffunction name="SiftScienceLabelOrderGood" access="public" hint="This will label a user as good in Sift Science">
	<cfargument name="orderID" required="Yes" type="string">
		<cftry>
			<cfquery datasource="#THIS.DSN#" name="orderInfo">
				SELECT TOP 1 cea.Email
				FROM CustomerOrders co
				INNER JOIN CustomerEmailLink cel ON co.CustomerContactID = cel.CustomerContactID
				INNER JOIN CustomerEmailAddresses cea ON cea.ID = cel.EmailID
				WHERE co.OrderID = <cfqueryparam sqltype="VARCHAR" value="#ARGUMENTS.orderID#">
			</cfquery>
			
			<cfif orderInfo.recordCount>
				<cfset sift = new objects.SiftScience.SiftClient()>
				<cfset sift.label(orderInfo.email, {'$is_bad': false})>
			</cfif>
			
			<cfcatch>
				<cfmail from="system@alpinehomeair.com" to="technical@alpinehomeair.com" type="html" subject="Sift Science Error!">
					Error sending the Label API Request
					<cfdump var="#orderInfo#">
					<cfdump var="#CFCATCH#">
				</cfmail>
			</cfcatch>

		</cftry>
	</cffunction>

	<cffunction name="SiftScienceCreateOrder" access="public" hint="This will create an order with Sift Science">
	<cfargument name="orderID" required="Yes" type="string">

		<cftry>

			<cfset orderDetails = getOrderDetails(ARGUMENTS.orderID)>
			<cfset itemsArray = ArrayNew()>

			<cfloop query="#orderDetails.orderQuery#">
				<cfset ArrayAppend(itemsArray, {
					'$item_id'			: ProductNumber,
					'$product_title'	: Description,
					'$price'			: Price,
					'quanity'			: Quantity
				})>
			</cfloop>

			<cfset createOrderStruct = {
				'$user_id'			: orderDetails.Email,
				'$user_email'		: orderDetails.Email,
				'$amount'			: orderDetails.orderTotal,
				'$currency_code'	: 'USD',
				'$billing_address'	: {
					'$name'			: orderDetails.Name,
					'$phone'		: orderDetails.Tel,
					'$address_1'	: orderDetails.Address1,
					'$address_2'	: orderDetails.Address2,
					'$city'			: orderDetails.City,
					'$region'		: orderDetails.State,
					'$country'		: orderDetails.Country,
					'$zipcode'		: orderDetails.Zip
				},

				'$shipping_address'	: {
					'$name'			: orderDetails.ShipName,
					'$address_1'	: orderDetails.ShipAddress1,
					'$address_2'	: orderDetails.ShipAddress2,
					'$city'			: orderDetails.ShipCity,
					'$region'		: orderDetails.ShipState,
					'$country'		: orderDetails.ShipCountry,
					'$zipcode'		: orderDetails.ShipZip
				},
				'$items'			: itemsArray
			}>

			<cfset sift = new objects.SiftScience.SiftClient()>
			<cfset siftResponse = sift.track(event='$create_order', properties=createOrderStruct)>

			<cfcatch>
				<cfmail from="errors@alpinehomeair.com" to="technical@alpinehomeair.com" type="html" subject="Sift Science Error">
					Error sending the Create Order API request
					<cfdump var="#orderDetails#">
					<cfdump var="#CFCATCH#">
				</cfmail>
			</cfcatch>
		</cftry>
	</cffunction>

	<!---
	FUNCTION: getOrderDetailsHTML
	ARG(S): sessionID
	THIS FUNCTION IS ONLY CALLED AT THE CHECKOUT WHICH IS AFTER THE ORDER IS PLACED
	INSIDE OF THE CHECKOUT TABLE, AND WILL BE IN THE ORDER TABLE PRIOR TO CHECKOUT
	SINCE THE USER WENT THROUGH THE CHECKOUT PROCESS
	--->
	<cffunction name="getOrderDetailsHTML" access="public" hint="This will draw out the html for each item's cost, shipping total, and total tax">
	<cfargument name="sessionID" required="Yes">
		<cfset total = 0>
		<cfset OrderTotal = 0>

		<!--- THIS STORED PROC RETURNS ITEM LEVEL INFORMATION --->
		<!--- RETURNS Weight,ID,productNumber,description,Price,quanity,lineTotalPrice,DistributorID --->
		<cfstoredproc procedure="sp_web_getcart_by_sessionID" datasource="#this.DSN#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#sessionID#">
			<cfprocparam type="IN" sqltype="BIT" value="1">
			<cfprocresult name="getcart">
		</cfstoredproc>

		<cfstoredproc procedure="sp_web_getorderheader_by_sessionID" datasource="#this.DSN#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#sessionID#">
			<cfprocresult name="getOrderTotals">
		</cfstoredproc>

		<!-- open item order table //-->
		<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
			<td><img src="/images/shim.gif" height="1" width="200" border="0"></td>
			<td><img src="/images/shim.gif" height="1" width="50" border="0"></td>
			<td><img src="/images/shim.gif" height="1" width="50" border="0"></td>
			<td><img src="/images/shim.gif" height="1" width="50" border="0"></td>
		</tr>
		<tr style="font-size: 11px;">
			<td class="specificationsheader"><span class="normal"><strong>Product Description</strong></span></td>
			<td class="specificationsheader"><span class="normal"><strong>Quantity</strong></span></td>
			<td class="specificationsheader"><span class="normal"><strong>Unit Price</strong></span></td>
			<td class="specificationsheader"><span class="normal"><strong>Line Total Price</strong></span></td>
		</tr>

		<cfset OrderTotal = 0>
		<cfoutput query="getcart">
			<cfstoredproc procedure="sp_getproduct_byproductID" datasource="#this.DSN#">
			<cfprocparam type="IN" sqltype="INT" value="#getcart.ProductNumber#">
			<cfprocresult name="getproduct">
			</cfstoredproc>

			<cfif getcart.subitemof EQ 0 AND getcart.hideFromUser NEQ 1>
				<tr>
					<td class="grayboxbody" valign="top"><span class="normal">#description#<br>#getproduct.listdescription#</span>
						<cfquery name="getsubitems" dbtype="query">
						SELECT description,quantity
						FROM getcart
						WHERE subitemof = #getcart.ID# AND hidefromuser = 0
						</cfquery>

						<cfif getsubitems.recordcount GT 0>
							<br><strong>Ships with:</strong><br>
							<cfloop query="getsubitems">
								Qty #quantity#: #description#<br>

							</cfloop>

						</cfif>
					</td>
					<td class="grayboxbody" valign="top"><span class="normal">#Quantity#</span></td>
					<td class="grayboxbody" valign="top"><span class="normal">#Dollarformat(Price)#</span></td>
					<td class="grayboxbody" valign="top"><span class="normal">#Dollarformat(lineTotalPrice)#</span></td>
				</tr>
				<cfset OrderTotal = #lineTotalPrice# + #OrderTotal#>
			</cfif>
		</cfoutput>
		<cfset total = val(OrderTotal) + val(getOrderTotals.taxCost) + val(getOrderTotals.Sbipcost)>
		<cfif val(getOrderTotals.taxCost) GT 0 OR val(getOrderTotals.Sbipcost GT 0)>
		<tr>
			<td colspan="2"></td>
			<td class="grayboxbody" align="right"><span class="normal"><strong>Subtotal: </strong></span></td>
			<td class="grayboxbody" align="left"><span class="normal"><strong><cfoutput>#Dollarformat(OrderTotal)#</cfoutput></strong></span></td>
		</tr>
		</cfif>
		<cfif val(getOrderTotals.taxCost) GT 0>
		<tr>
			<td colspan="2"></td>
			<td class="grayboxbody" align="right"><span class="normal"><strong>Tax: </strong></span></td>
			<td class="grayboxbody" align="left"><span class="normal"><strong><cfoutput>#Dollarformat(getOrderTotals.taxCost)#</cfoutput></strong></span></td>
		</tr>
		</cfif>
		<cfif val(getOrderTotals.Sbipcost) GT 0>
		<tr>
			<td colspan="2"></td>
			<td class="grayboxbody" align="right"><span class="normal"><strong>Shipping: </strong></span></td>
			<td class="grayboxbody" align="left"><span class="normal"><strong><cfoutput>#Dollarformat(getOrderTotals.Sbipcost)#</cfoutput></strong></span></td>
		</tr>
		</cfif>
		<tr style="font-size: 11px;">
			<td colspan="2"></td>
			<td class="grayboxbody" align="right" style="font-size: 1.3em;"><span class="normal"><strong>Order Total: </strong></span></td>
			<td class="grayboxbody" align="left" style="font-size: 1.3em;"><span class="normal"><strong><cfoutput>#Dollarformat(total)#</cfoutput></strong></span></td>
		</tr>
		</table>
	</cffunction>

	<cffunction name="getDetailedOrderInformation" returntype="query" access="public">
	<cfargument name="orderID" type="string" required="true">
		<cfreturn queryExecute("
			SELECT DISTINCT c.sessionID AS 'orderID', c.shipname, c.shipcompany, c.shipaddress1, c.shipaddress2, c.shipcity, c.shipstate, UPPER(dbo.reAlphaNumeric(c.shipzip)) AS 'shippostalcode'
			, c.shipcountry, c.tel AS 'shiptelephone', o.distributorID AS 'vendorID', o.carrierID, t.typeID AS 'shipTypeID'
			, ISNULL(NULLIF(c.delayreporteddate,''),GETDATE()) AS 'requestedShipDate'
			, CASE WHEN o.carrierID = 0
				THEN '[{''productID'':453071040, ''orderlineID'':' + (SELECT CONVERT(VARCHAR,ID) FROM orders WHERE SessionID = o.sessionID AND ProductNumber = 453071040) +' }]'
				ELSE '[' + (SELECT CASE WHEN ROW_NUMBER() OVER(ORDER BY o1.productnumber) > 1 THEN ',' ELSE '' END + '{''productID'':' + CAST(o1.productnumber AS VARCHAR) + ',''quantity'':' + CAST(SUM(o1.quantity) AS VARCHAR) + ', ''vendorProduct'':''' + v.SKU + ''', ''manufacturer'':''' + p.manufacturer + '''}'
						FROM orders o1
						INNER JOIN InventoryItemLink va ON o1.productnumber = va.productID
						INNER JOIN InventoryItems v ON va.InventoryItemID = v.ID
						INNER JOIN Products p ON p.ID = va.productID
						CROSS APPLY(
						SELECT ISNULL(SUM(d.quantity),0) AS 'POqty'
						FROM tblVendorPOHeader h
						INNER JOIN tblVendorPODetail d ON h.orderID = o1.sessionID
							AND d.POID = h.POID
							AND d.InventoryItemID = v.ID
						WHERE h.statusID <> 100
						) x
						WHERE o1.sessionID = o.SessionID
						AND o1.distributorID = o.DistributorID
						AND o1.carrierID = o.carrierID
						GROUP BY o1.ProductNumber, v.SKU, p.manufacturer
						HAVING SUM(o1.quantity * o1.ordlinepackqty) - SUM(x.POqty) > 0
						FOR XML PATH ('')
						) + ']' END AS 'products'
			FROM checkouts c
			INNER JOIN orders o ON c.sessionID = o.sessionID AND o.quantity > 0
			LEFT JOIN tblCarriers car ON car.carrierID = o.carrierID
			LEFT OUTER JOIN orders o2 ON o2.sessionID = o.sessionID AND o2.productnumber = 453054793
			LEFT OUTER JOIN orders o3 ON o3.sessionID = o.sessionID AND o3.productnumber = 453066844
			OUTER APPLY (SELECT typeID
						FROM tblCarrierShippingTypeLookup
						WHERE queryflags = CASE WHEN c.isResidential = 0 THEN 'COM' ELSE 'RES' END +
										CASE WHEN o2.ID IS NOT NULL OR o3.ID IS NOT NULL THEN ',LIFTGATE' ELSE '' END +
										CASE WHEN o3.ID IS NOT NULL THEN ',INSIDE' ELSE '' END) t
			WHERE c.process = 20
			AND (o.carrierID <> 0 OR o.ProductNumber = 453071040)
			AND o.SessionID = :orderID
			order by o.distributorID desc
				--AND NOT EXISTS (SELECT 1 FROM tblVendorPOHeader WHERE orderID = o.SessionID AND CarrierID = o.carrierID AND statusID <> 100)"
		, {orderID = {type="VARCHAR", value=arguments.orderID}}
		, {datasource=THIS.DSN})>
	</cffunction>


	<cffunction name="getOrderDetails" returntype="struct" access="public">
	<cfargument name="sessionID" required="Yes">
		<cfset var orderTotal = 0>
		<cfset var subTotal = 0>
		<cfset var discountAmount = 0>
		<cfset var discountSubtotal = 0>
		<cfset var OrderInfo = StructNew()>
		<cfset OrderInfo.OrderNumber = sessionID>

		<cfstoredproc procedure="sp_web_getcart_by_sessionID" datasource="#this.DSN#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#sessionID#">
			<cfprocresult name="getOrderItems">
		</cfstoredproc>

		<cfstoredproc procedure="sp_web_getorderheader_by_sessionID" datasource="#this.DSN#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#sessionID#">
			<cfprocresult name="getOrderTotals">
		</cfstoredproc>
		
		<cfif getOrderItems.recordcount GT 0 and getOrderTotals.recordcount GT 0>
			<cfloop query="getOrderItems">
				<cfset subTotal = subTotal + getOrderItems.lineTotalPrice>
				<cfset discountAmount = discountAmount + getOrderItems.discount_amount>
				<cfset discountSubtotal = discountSubtotal + getOrderItems.ordlinerev>
			</cfloop>

			<cfset OrderInfo.subTotal = subTotal>
			<cfset OrderInfo.OrderQuery = getOrderItems>
			<cfset orderTotal = discountSubtotal + getOrderTotals.taxcost + getOrderTotals.sbipcost>
			<cfset OrderInfo.taxcost = getOrderTotals.taxcost>
			<cfset OrderInfo.shipcost = getOrderTotals.sbipcost>
			<cfset OrderInfo.orderTotal = orderTotal>
			<cfset OrderInfo.discountAmount = discountAmount>
			<cfset OrderInfo.DiscountSubtotal = discountSubtotal>
			<cfset OrderInfo.Name = getOrderTotals.Name>
			<cfset OrderInfo.billCompany = getOrderTotals.billCompany>
			<cfset OrderInfo.Address1 = getOrderTotals.Address1>
			<cfset OrderInfo.Address2 = getOrderTotals.Address2>
			<cfset OrderInfo.City = getOrderTotals.City>
			<cfset OrderInfo.State = getOrderTotals.State>
			<cfset OrderInfo.Zip = getOrderTotals.Zip>
			<cfset OrderInfo.Tel = getOrderTotals.Tel>
			<cfset OrderInfo.Email = getOrderTotals.Email>
			<cfset OrderInfo.shipCountry = getOrderTotals.shipCountry>
			<cfset OrderInfo.ShipName = getOrderTotals.ShipName>
			<cfset OrderInfo.shipCompany = getOrderTotals.shipCompany>
			<cfset OrderInfo.shipAddress1 = getOrderTotals.shipAddress1>
			<cfset OrderInfo.shipAddress2 = getOrderTotals.shipAddress2>
			<cfset OrderInfo.shipCity = getOrderTotals.shipCity>
			<cfset OrderInfo.shipState = getOrderTotals.shipState>
			<cfset OrderInfo.shipZip = getOrderTotals.shipZip>
			<cfset OrderInfo.Country = getOrderTotals.Country>
			<cfset OrderInfo.Email = getOrderTotals.Email>
			<cfset OrderInfo.Dt = getOrderTotals.Dt>
			<cfset OrderInfo.PayType = determinePayType(getOrderTotals.CCNum) />
			<cfset OrderInfo.Success = "YES">
			<cfset OrderInfo.MessageText = "Order confirmation email sent">
		<cfelse>
			<cfset OrderInfo.Success = "NO">
			<cfset OrderInfo.MessageText = "Error, order email not sent.">
		</cfif>

		<!--- RETURN VALUES --->
		<cfreturn OrderInfo>
	</cffunction>

	<cfscript>
		private string function determinePayType( required string ccnum ){
			if( arguments.ccnum CONTAINS "PAYPAL" ){ return 'PayPal'; }
			if( arguments.ccnum CONTAINS "AMAZON" ){ return 'Amazon'; }
			if( arguments.ccnum CONTAINS "AFFIRM" ){ return 'Affirm'; }
			if( arguments.ccnum CONTAINS "CHECK to be sent" ){ return 'Check'; }
			return 'Credit Card';
		}
	</cfscript>

	<cffunction name="sendOrderEmailHTML" access="public" hint="This will send out the order information to the customer">
	<cfargument name="sessionID" required="Yes">
	<cfargument name="displayMessage" required="Yes">

		<cftry>

			<cfset OrderInfo = getOrderDetails(ARGUMENTS.sessionID)>
			<cfif displayMessage EQ "Yes" AND OrderInfo.Success>
				<cfoutput>#OrderInfo.OrderNumber# - #OrderInfo.MessageText# to #OrderInfo.Email#</cfoutput>
			</cfif>
			<cfcatch type="Any">
				<cfmail to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" subject="sendOrderEmailHTML">
					error on order #sessionID#
				</cfmail>
			</cfcatch>
		</cftry>

		<cfif OrderInfo.Success EQ "NO">
			<cfmail to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" subject="sendOrderEmailHTML">
				no details found on order #sessionID#
			</cfmail>
		</cfif>
		<cfif OrderInfo.Success EQ "YES">
			<cfsavecontent variable="emailcontent">
				<cfif ListFind(ValueList(OrderInfo.OrderQuery.productnumber), '453071040')>
					<cfset emailType = 'HVAC' />
				</cfif>
				<cfinclude template="/massemail/_email_header.cfm">

				<tr id="body-row">
					<td>
						<table width="100%" cellpadding="30" cellspacing="0" border="0" bgcolor="#fcfcfc">
							<tr>
								<td class="text" style="color:#333333; font-family:Arial; font-size:13px; line-height:20px; text-align:left">
									<h1 style="font-size: 24px; line-height: 30px; font-weight: 600; color:#0061ae; margin-top: 15px;">
										Order Receipt
									</h1>
									<hr style=" border: 0; height: 1px; background: #cdcdcd;">
									<br>
									<br>

									<!--- Number Box --->
									<table width="100%" style="border-collapse: collapse; border:1px solid #d9d9d9; font-size:13px; line-height:16px; text-align: center; ">
										<tr>
											<td>
												<br>
												Order Number:
												<br>
												<br>
												<span style="color:#0061ae; font-size:35px; line-height:39px; font-weight:bold; text-transform:uppercase">
													<cfoutput>#OrderInfo.OrderNumber#</cfoutput>
												</span>
												<br>
												<br>
												Order date: <span style="font-weight:bold;"><cfoutput>#DateFormat(OrderInfo.dt,"mmmm dd, yyyy")#</cfoutput></span>
												<br>
												<br>
											</td>
										</tr>
									</table>
									<!--- End Number Box --->
									<br>

									<!--- Two Boxes --->
									<table width="100%" cellpadding="0" cellspacing="0" border="0">
										<tr>
											<td width="45%" valign="top">
												<!--- Billing Address --->
												<table width="100%" cellpadding="15" style="border-collapse: collapse; border:1px solid #d9d9d9;">
													<tr>
														<td class="text" style="font-size:13px; line-height:24px; text-align:left">
															<strong>Billing Address</strong>
															<hr style="border: 0; height: 1px; background: #cdcdcd;">
															<cfoutput>
																#OrderInfo.Name#
																<br>
																<cfif IsDefined("OrderInfo.billCompany") and Len("OrderInfo.billCompany") GT 0>
																	#OrderInfo.billCompany#
																	<br>
																</cfif>
																#OrderInfo.Address1#
																<br>
																<cfif IsDefined("OrderInfo.Address2") and Len("OrderInfo.Address2") GT 0>
																	#OrderInfo.Address2#
																	<br>
																</cfif>
																	#OrderInfo.City#, #OrderInfo.State# #OrderInfo.Zip#
																	<br>
																	<cfif IsDefined("OrderInfo.shipCountry") and OrderInfo.shipCountry EQ "CA">
																	Canada
																		<br>
																</cfif>
						  										<a style="color: ##333; text-decoration: none;">
																	#OrderInfo.Tel#
						  										</a>
																<br>
																<a style="color: ##333; text-decoration: none;">
																	#OrderInfo.Email#
																</a>
															</cfoutput>
															<br>
														</td>
													</tr>
												</table>
											</td>
											<td></td>
											<td width="45%">
												<!--- Shipping Address --->
												<table width="100%" cellpadding="15" style="border-collapse:collapse; border:1px solid #d9d9d9;">
													<tr>
														<td class="text" style="font-size:13px; line-height:24px; text-align:left">
															<strong>Shipping Address</strong>
															<hr style="border: 0; height: 1px; background: #cdcdcd;">
															<cfoutput>
																#OrderInfo.ShipName#
																<br>
																<cfif IsDefined("OrderInfo.shipCompany") and Len("OrderInfo.shipCompany") GT 0>
																	#OrderInfo.shipCompany#
																	<br>
																</cfif>
																#OrderInfo.shipAddress1#
																<br>
																<cfif IsDefined("OrderInfo.shipAddress2") and Len("OrderInfo.shipAddress2") GT 0>
																	#OrderInfo.shipAddress2#
																	<br>
																</cfif>
																#OrderInfo.shipCity#, #OrderInfo.shipState# #OrderInfo.shipZip#
																<br>
																<cfif IsDefined("OrderInfo.shipCountry") and OrderInfo.shipCountry EQ "CA">
																	Canada
																		<br>
																</cfif>
																#OrderInfo.Tel#
																<br>
																<a style="color: ##333; text-decoration: none;">
																	#OrderInfo.Email#
																</a>
															</cfoutput>
														<br>
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
								<!--- End Two Boxes --->
								<br>
								<!--- Total Table --->
								<table width="100%" cellpadding="15" style="border-collapse: collapse; border: 1px solid #d9d9d9; font-size:12px; line-height:16px; font-weight:bold; text-align: center;">
									<!--- Row --->
									<tr>
										<td style="border: 1px solid #d9d9d9;">
											Product <br>
											Description
									  	</td>
										<td style="border: 1px solid #d9d9d9;">
											QTY <br />
											Shipped
										</td>
										<td style="border: 1px solid #d9d9d9;">
											Total
										</td>
										<td style="border: 1px solid #d9d9d9;">
											Subtotal
										</td>
									</tr>
									<!--- End Row --->

									<cfloop query="OrderInfo.OrderQuery">
										<cfstoredproc procedure="sp_getproduct_byproductID" datasource="#this.DSN#">
											<cfprocparam type="IN" sqltype="INT" value="#ProductNumber#">
											<cfprocresult name="getproduct">
										</cfstoredproc>
											<cfset var productTitle = "#Description# <cfif OrderInfo.OrderQuery.productnumber IS 453071037> #OrderInfo.OrderQuery.GuaranteedDate# between #OrderInfo.OrderQuery.DeliveryWindow#</cfif>">

											<cfset productDescription = getproduct.listdescription>
											<cfif OrderInfo.OrderQuery.productnumber EQ 453071040>
												<cftry>
												<cfquery name="getSNetLaborInfo" datasource="#this.DSN#">
													SELECT
														s.name AS customerName
													  , c.companyName
													  , cr.cartID
													FROM tblSNetQuotes s WITH (NOLOCK)
													LEFT JOIN tblSNetMultiTabs mt WITH (NOLOCK) ON mt.cartID = s.cartID AND mt.selected = 1
													INNER JOIN tblSNetContractorResponses cr WITH (NOLOCK) ON cr.contractorID = <cfqueryparam sqltype="int" value="#OrderInfo.OrderQuery.Attribute3#">
													  AND s.cartID = cr.cartID
													INNER JOIN tblContractorsNew c WITH (NOLOCK) ON c.ID = cr.contractorID
													WHERE ISNULL(mt.quoteNumber,s.cartID) = <cfqueryparam sqltype="varchar" value="#OrderInfo.OrderQuery.quotenumber#" />
												  </cfquery>

												  <cfset productTitle = getSNetLaborInfo.companyName />
												  <cfset productDescription = "Installation quote for #getSNetLaborInfo.customername#" />
												  <cfset SNetObj = new objects.ServiceNet.SNetEmails() />
												  <cfset SNetObj.jobWon(cartID = getSNetLaborInfo.cartID, contractorID = OrderInfo.OrderQuery.Attribute3, orderID = arguments.sessionID ) />
												  <cfset SNetObj.openNewInstallationJob(cartID = getSNetLaborInfo.cartID, contractorID = OrderInfo.OrderQuery.Attribute3, orderID = arguments.sessionID) />
												  <cfcatch>
												  	<cfmail to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" subject="Error sending email to contractor" type="html">
														<cfdump var="#cfcatch#">
													</cfmail>
												  </cfcatch>
												</cftry>
											  </cfif>

											<!--- Row --->
											<tr>
												<td style="border: 1px solid #d9d9d9; text-align: left;">
													<div>
														<cfoutput>#productTitle#</cfoutput>
													</div>
													<span style="font-weight: 400;">
														<cfoutput>#productDescription#</cfoutput>
													</span>
												</td>
												<td style="border: 1px solid #d9d9d9;">
													<cfoutput>#Quantity#</cfoutput>
												</td>
												<td style="border: 1px solid #d9d9d9;">
													<cfoutput>#Dollarformat(Price)#</cfoutput>
												</td>
												<td style="border: 1px solid #d9d9d9;">
													<cfoutput>#Dollarformat(lineTotalPrice)#</cfoutput>
												</td>
											</tr>
											<!--- End Row --->
										</cfloop>
									</table>
									<table width="100%" cellpadding="0" cellspacing="0" border="0">
										<tr>
											<!--- Included With Your Order --->
											<td style="font-size:12px; line-height:20px; text-align:left; font-weight:bold" width="60%" valign="top">
						  						<br>
												Items Included With Your Order:
						  						<br>
						  						<br>
												<div style="text-align:left;">
													<a href="https://www.alpinehomeair.com/premium-guarantee" target="_blank" class="link" style="color:#025ba2; text-decoration:underline">Alpine's Premium Guarantee</a>
												</div>
											</td>
											<!--- End included with your order --->
											<td valign="top">
												<!--- Totals Table --->
												<table width="100%" cellpadding="15" cellspacing="0" style="border-collapse: collapse; border:1px solid #d9d9d9; font-size:12px; line-height:16px; font-weight:bold; border-top: 0px;">
													<tr>
														<td style="border: 1px solid #d9d9d9;">
															Subtotal:
														</td>
														<td style="border: 1px solid #d9d9d9;">
															<cfoutput>#Dollarformat(OrderInfo.subTotal)#</cfoutput>
														</td>
													</tr>
													<!--- End Row --->
												<cfif OrderInfo.discountAmount GT 0>
													<tr>
														<td style="border: 1px solid #d9d9d9;">
															Discount Amount:
														</td>
														<td style="border: 1px solid #d9d9d9; color: red; ">
															<cfoutput>#DollarFormat(OrderInfo.DiscountAmount)#</cfoutput>
														</td>
													</tr>
													<tr>
														<td style="border: 1px solid #d9d9d9;">
															Subtotal After Discount:
														</td>
														<td style="border: 1px solid #d9d9d9;">
															<cfoutput>#DollarFormat(OrderInfo.DiscountSubtotal)#</cfoutput>
														</td>
													</tr>
												</cfif>
												<cfif val(OrderInfo.taxCost) GT 0>
													<!--- Row --->
													<tr>
														<td style="border: 1px solid #d9d9d9;">
															Tax:
														</td>
														<td style="border: 1px solid #d9d9d9;">
															<cfoutput>#Dollarformat(OrderInfo.taxcost)#</cfoutput>
														</td>
													</tr>
													<!--- End Row --->
												</cfif>
													<!--- Row --->
													<tr>
														<td style="border: 1px solid #d9d9d9;">
															Shipping:
														</td>
														<td style="border: 1px solid #d9d9d9;">
															<cfoutput>#Dollarformat(OrderInfo.shipcost)#</cfoutput>
														</td>
													</tr>
													<!--- End Row --->
													<!--- Row --->
														<tr>
															<td style="border: 1px solid #d9d9d9;">
																Total:
															</td>
															<td style="border: 1px solid #d9d9d9;">
																<cfoutput>#Dollarformat(OrderInfo.orderTotal)#</cfoutput>
															</td>
														</tr>
														<tr>
							                          		<td colspan='2'><center>PAID<cfoutput> by #OrderInfo.PayType#</cfoutput></center></td>
							                          	</tr>
														<!--- End Row --->
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
								<!--- End Total Table --->

								<br>
								<hr style=" border: 0; height: 1px; background: #cdcdcd;">
								<br>
								Thanks for shopping at Alpine Home Air Products.
								<br>
								<br>
								To see the status of your order please
								<cfoutput>
									<a href="https://www.alpinehomeair.com/order-summary/#OrderInfo.OrderNumber#/#OrderInfo.Zip#" target="_blank" class="link" style="color:##025ba2; text-decoration:underline"><span class="link" style="color:##025ba2; text-decoration:underline">click here</span></a>.
								</cfoutput>
								<br>
								<br>
								If you have any questions or would like to add something to your order,
								<a href="https://www.alpinehomeair.com/contact-us" target="_blank" class="link" style="color:#025ba2; text-decoration:underline"><span class="link" style="color:#025ba2; text-decoration:underline">click here</span></a> and <br />we'll take care of it.
								<br>
								<br>
								If you have a moment we would appreciate some feedback on our website or on our company in general. Send us an email letting us know what you like and what could be improved upon.
								<br>
							</td>
						</tr>
					</table>
				</td>
			</tr> <!--- End "body-row" --->
			<!-- End Main -->

				<cfinclude template="/massemail/_email_footer.cfm">
			</cfsavecontent>

			<!--- BEGIN EMAIL PORTION --->
			<cfmail to="#OrderInfo.Email#" from="sales@alpinehomeair.com(Customer Service)" subject="Your order information from Alpine Home Air Products" type="HTML">
				<cfmailpart type="text">HTML is required to view this email. Please enable HTML and re-open the email.</cfmailpart>
				<cfmailpart type="html">#emailcontent#</cfmailpart>
			</cfmail>
			<cfset new objects.objectUtils().putlog('OrderEmail_#ARGUMENTS.sessionID#', 'Order Information Email Sent to #OrderInfo.Email#') />
		</cfif>
		<!--- END EMAIL PART HERE --->
	</cffunction>
</cfcomponent>
