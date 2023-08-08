<cfcomponent displayname="vendorPO" extends="simple_global" output="true" hint="Vendor Purchase Order, created from order shipping groups">

	<cffunction name="init" access="public" hint="Initializes an empty Vendor Purchase Order">
		<cfargument name="userId" type="numeric" required="false" default="#getcurrentuser()#">
		<cfargument name="wirebox" required="false" default="">

		<cfset variables.wirebox = arguments.wirebox>
		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cfset this.objID = this.carrierID = this.errorcode = this.canvoid = this.isComplete = this.NSync = this.statusID = 0>
		<cfset this.vendorID = 24>
		<cfset this.status = "new">
		<cfset this.nsStatus = "">
		<cfset this.POID = this.ordergroup = this.orderID = this.orderDate = this.lastPrinted = "">
		<cfset this.shipcompletePO = 1>
		<cfset this.shipname = this.shipcompany = this.shipaddress1 = this.shipaddress2 = this.shipcity = this.shipstate = this.shippostalcode = this.shipcountry = this.shiptelephone = this.email = "">
		<cfset this.shipinstructions = this.EDIResult = this.EDIDateTime = this.EDIConfirmed = this.requestedshipdate = this.shippingoptions = this.carriercode = this.errormessage = this.carrierName = this.carrierreturncode = this.vendorName = this.locationName = this.locationAddress1 = this.locationAddress2 = this.locationCity = this.locationState = this.locationPostalCode = this.vendorPOShipDate = "">
		<cfset this.estimatedshipdate = this.shipby = "">
		<cfset this.estimatedShippingDetails = []>
		<cfset this.lineItems = []>
		<cfset this.isFreight = 0>
		<cfset this.locationID = 1>
		<cfset this.locationTypeID = 1>
		<cfset this.rmas = []>
		<cfset this.runInventoryUpdate = false>

		<cfset this.createdby = this.modifiedby = arguments.userId>
		<cfset this.created = this.modified = Now()>
		<cfreturn result>
	</cffunction>

	<cffunction name="incrementbizdays" output="false" access="public" returntype="struct">
	<cfargument name="startdate" type="date" required="false" default="#now()#">
	<cfargument name="days" type="numeric">

		<cfset local.result = structnew()>
		<cfset local.result.dayincrement = 0>

		<cfif dayofweek(dateadd("d",arguments.days,arguments.startdate)) == 1>
			<cfset arguments.days = arguments.days + 1>
			<cfset local.result.dayincrement = 1>
		</cfif>

		<cfif dayofweek(dateadd("d",arguments.days,arguments.startdate)) == 7>
			<cfset arguments.days = arguments.days + 2>
			<cfset local.result.dayincrement = 2>
		</cfif>

		<cfset local.result.days = arguments.days>
		<cfreturn local.result>
	</cffunction>

	<cffunction name="get" access="public" returntype="boolean" hint="Retrieves the Vendor PO from the database">
		<cfargument name="objID" default="">
		<cfargument name="POID" required="Yes" default="">
		<cfset userId = this.modifiedBy>

		<cfquery name="local.getobj" datasource="#this.DSN#">
			SELECT
				h.*,
				c.Email,
				c.comments AS 'checkoutComments',
				ca.carrierlongname AS 'carrierName',
				c.shipby,
				c.DT AS 'orderDate',
				fs.srcCompanyName AS 'vendorName',
				ISNULL((
					SELECT
						ID,
						POID,
						Amount,
						Created,
						CreatedBy,
						Modified,
						ModifiedBy,
						Weight,
						Height,
						Width,
						Length,
						EstimatedShipDate
					FROM tblVendorPOShippingEstimates
					WHERE POID = h.POID
					FOR JSON AUTO
				),'[]') AS 'estimatedShippingDetails',
				l.[name] AS 'locationName',
				l.Address1 AS 'locationAddress1',
				l.City AS 'locationCity',
				l.Address2 AS 'locationAddress2',
				l.State AS 'locationState',
				l.PostalCode AS 'locationPostalCode',
				(SELECT Min(v.shipDate) FROM tblVendorPODetailShipments v WHERE v.POID = h.POID) AS 'vendorPOShipDate'
			FROM tblVendorPOHeader h WITH (NOLOCK)
			INNER JOIN v_locations l ON l.locationID = h.LocationID AND l.locationTypeId = h.LocationTypeID
			LEFT JOIN tblCarriers ca on h.carrierID = ca.carrierID
			INNER JOIN checkouts c ON c.sessionID = h.orderID
			LEFT JOIN tblProductFulfillmentSources fs ON fs.srcID = h.vendorID
			WHERE objID = <cfqueryparam sqltype="INT" value="#val(ARGUMENTS.objID)#">  OR POID = <cfqueryparam sqltype="VARCHAR" value="#ARGUMENTS.POID#"> OR POID = <cfqueryparam sqltype="VARCHAR" value="#ARGUMENTS.objID#">
		</cfquery>

		<cfif local.getobj.recordcount>
			<cfset local.columns = QueryColumnArray(local.getobj)>
			<cfloop array="#local.columns#" index="local.c">
				<cfset this[local.c] = local.getobj[local.c]>
			</cfloop>
			<cfset this.modifiedBy = userId>

			<cfif(isJSON(this.estimatedShippingDetails))>
				<cfset this.estimatedShippingDetails = deserializeJSON(this.estimatedShippingDetails)>
			</cfif>

			<cfquery name="local.getDetail" datasource="#this.DSN#">
				SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
				SELECT
					d.lineID,
					d.POID,
					d.orderID,
					d.orderlineID,
					d.vendorID,
					d.vendorprodnumber,
					d.quantity,
					d.UOM,
					d.unitprice,
					d.extprice,
					d.mfgpartnumber,
					d.UPC,
					d.description,
					d.created,
					d.createdby,
					d.modified,
					d.modifiedby,
					d.countryofmfg,
					d.weight,
					d.packheight,
					d.packwidth,
					d.packlength,
					d.estshipdate,
					d.status_shipped,
					d.deliverymethod,
					d.isfreight,
					d.producttype,
					d.overridevendorcost,
					d.extoverridevendorcost,
					d.perunitestshippingcostalloc,
					d.fifoCogs,
					d.nsLineID,
					d.qtyToNetsuite,
					d.qtyCommitted, --CASE WHEN si.ID IS NOT NULL THEN 1 ELSE 0 END AS 'qtyCommitted',
					d.qtyPickedPacked,
					d.qtyShipped,
					d.committedDate,
					d.pickedBy,
					d.expectedInStock,
					d.InventoryItemID,
					o.description AS 'orderdescription',
					o.productnumber AS 'productID',
					o.quantity AS 'orderedquantity',
					ii.picklistpartnumber AS 'pickTicket',
					o.price / ISNULL(NULLIF(o.ordlinepackqty,0),1) AS 'orderedPrice',
					ii.ShipFreight,
					ii.ShipInMfgBoxFreight AS 'shipinmfgboxfc',
					ii.ShipInMfgBoxSmallPack AS 'shipinmfgboxsc',
					ii.skid,
					'' AS 'packinbox',
					fc.Label AS 'freightClass',
					ISNULL(NULLIF(ii.nmfc, ''), 0) AS 'nmfc',
					COALESCE(gclp2.column1, gpg2.column1,gclp.column1, gpg.column1) AS 'FroogleLabel2',
					p.manufacturer,
					'/product/' + pr.[Route] AS 'alpineUrl',
					si.ID AS 'sublineItemId'
				FROM tblVendorPODetail d
				INNER JOIN InventoryItems ii ON ii.ID = d.InventoryItemId
				LEFT JOIN orders o ON o.ID = d.orderlineID
				LEFT JOIN FreightClasses fc ON fc.ID = ii.FreightClassID
				LEFT JOIN products p ON p.id = o.productnumber
				LEFT JOIN ProductRouting pr ON pr.ProductID = p.ID
					AND pr.RedirectID IS NULL
				LEFT JOIN tblGoogleProductGroups gpg ON gpg.categoryID = p.Category
				LEFT JOIN tblGoogleCustomLabel_Products gclp ON gclp.productID = p.id
				LEFT JOIN tblProductSerials s ON CONVERT(VARCHAR, s.numericID) = REPLACE(ii.SKU,'SND','')
				LEFT JOIN products p2 ON p2.id = s.productnumber
				LEFT JOIN tblGoogleProductGroups gpg2 ON gpg2.categoryID = p2.Category
				LEFT JOIN tblGoogleCustomLabel_Products gclp2 ON gclp2.productID = p2.id
				LEFT JOIN SublineItems si ON si.CustomerPoLineId = d.lineID
				WHERE d.POID = <cfqueryparam sqltype="VARCHAR" value="#getobj.POID#">
				ORDER BY ISNULL(ii.SmallPack, 1), ii.SmallPack DESC, p.manufacturer, d.mfgpartnumber
			</cfquery>

			<cfloop query="#local.getDetail#">
				<cfset ArrayAppend(this.lineItems,CreateObject("Component", "objects.vendorPOLineItem").init(queryrowdata(local.getDetail,querycurrentrow(local.getDetail)), userId))>
			</cfloop>

			<cfquery name="local.rmas" datasource="#this.DSN#" returntype="array">
				SELECT *
				FROM tblVendorPODetail pod
				INNER JOIN tblProductSerials ps ON ps.POLineID = pod.lineID
				WHERE pod.POID = <cfqueryparam sqltype="VARCHAR" value="#getobj.POID#">
				ORDER BY created DESC
			</cfquery>
			<cfset this.rmas = local.rmas>

			<cfset local.thisOrder = CreateObject("Component", "alpine-objects.order_new")>
			<cfset local.thisOrder.orderID = this.orderID>
			<cfset this.isPaidFor = local.thisOrder.getPaymentSummary().paidInFull>
			<cfreturn 1>
		</cfif>

		<cfreturn 0>
	</cffunction>

	<cffunction name="putInErrorStatus" returntype="void">
		<cfset this.status = "Error">
		<cfset this.statusID = 117>
		<cfset this.update()>
	</cffunction>

	<cffunction name="put" returntype="any" hint="Inserts or Updates Vendor PO & Line Items">
		<cfset var result = {errorcode: 0, errormessage:"" }>
		<cfset var oldStatusID = this.statusID>

		<cfif arrayLen(this.lineItems)>
			<cfif !listFindNoCase('Void,Ready to EDI',this.status)>
				<cfset businessrules()>
			</cfif>

			<cfquery name="getobj" datasource="#THIS.DSN#">
				SELECT 1
				FROM tblVendorPOHeader
				WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#this.objID#">
			</cfquery>

			<cfif this.errorcode>
				<cfset this.status = "Error">
				<cfset this.statusID = 117>
				<cfset result.errorcode = this.errorcode>
				<cfset result.errormessage = this.errormessage>
			</cfif>

			<cftransaction>
			<cftry>
				<cfif !getobj.recordcount> <!--- inserting --->
					<cfset this.insert()>

					<cfloop array="#this.lineItems#" index="i">
						<cfset i.insert(this.POID)>
					</cfloop>

					<cfquery name="updateRMAs" datasource="#this.DSN#">
						UPDATE s
						SET s.POLineID = d.lineID
						FROM tblProductSerials s
						INNER JOIN tblVendorPODetail d ON s.orderlineID = d.orderlineID
						WHERE d.POID = <cfqueryparam sqltype='VARCHAR' value='#this.POID#'>
							AND s.orderlineID <> 0
					</cfquery>

					<cfset var fulfillmentRepository = new contexts.Shipping.DataAccess.DatabaseFulfillmentRepository()>
					<cfif isDefined("this.liveRates.AccessorialCharges")>
						<cfloop collection="#this.liveRates.AccessorialCharges#" index="local.accessorialType" item="local.accessorialValue">
							<cfset fulfillmentRepository.storeAccessorialCharge(this.POID, local.accessorialType, val(local.accessorialValue))>
						</cfloop>
					</cfif>

					<cfif isDefined("this.liveRates.Terminals")>
						<cfloop collection="#this.liveRates.Terminals#" index="local.terminalType" item="local.terminal">
							<cfset var terminalID = fulfillmentRepository.storeTerminalInformation(local.terminal)>
							<cfset fulfillmentRepository.storeTerminalLink(this.POID, local.terminalType, terminalID)>
						</cfloop>
					</cfif>
				<cfelse> <!--- updating --->
					<cfset this.update()>

					<cfloop array="#this.lineItems#" index="i">
						<cfif !val(i.lineID)> <!---If a new line item snuck in, insert it--->
							<cfset i.insert(this.POID)>
						<cfelse>
							<cfset i.update()>
						</cfif>
					</cfloop>
				</cfif>

				<cfquery datasource="ahapdb">
					DECLARE @json VARCHAR(MAX) = <cfqueryparam sqltype="LONGVARCHAR" value="#serializeJSON(this.estimatedShippingDetails)#">
					DECLARE @user INT = <cfqueryparam sqltype="INT" value="#this.modifiedBy#">
					DECLARE @POID VARCHAR(20) = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">

					MERGE INTO tblVendorPOShippingEstimates AS Target
					USING (
						SELECT
							ID,
							POID,
							Amount,
							Weight,
							Height,
							Width,
							Length,
							EstimatedShipDate
						FROM OPENJSON(@json) WITH (
							ID INT '$.ID',
							POID VARCHAR(20) '$.POID',
							Amount MONEY '$.Amount',
							Weight NUMERIC(10,2) '$.Weight',
							Height NUMERIC(10,2) '$.Height',
							Width NUMERIC(10,2) '$.Width',
							Length NUMERIC(10,2) '$.Length',
							EstimatedShipDate Date '$.EstimatedShipDate'
						)
					) AS Source (ID, POID, Amount, Weight, Height, Width, Length, EstimatedShipDate)
					ON Target.POID = @POID
						AND Source.ID = Target.ID
					WHEN MATCHED THEN
						UPDATE SET
							Target.Amount = Source.Amount,
							Target.Weight = Source.Weight,
							Target.Height = Source.Height,
							Target.Length = Source.Length,
							Target.EstimatedShipDate = Source.EstimatedShipDate,
							Target.Modified = GETDATE(),
							Target.ModifiedBy = @user
					WHEN NOT MATCHED BY Target THEN
						INSERT (
							POID,
							Amount,
							Weight,
							Height,
							Width,
							Length,
							EstimatedShipDate,
							Created,
							CreatedBy,
							Modified,
							ModifiedBy
						)
						VALUES (
							@POID,
							Source.Amount,
							Source.Weight,
							Source.Height,
							Source.Width,
							Source.Length,
							Source.EstimatedShipDate,
							GETDATE(),
							@user,
							GETDATE(),
							@user
						);
				</cfquery>

				<cfif listFindNoCase('Fully Shipped,Void', this.status)>
					<cfobject component="alpine-objects.order" name="order">
					<cfset order.get(sessionID = this.orderID)>
					<cfset order.checkShipments()>
					<cfif this.status == 'Fully Shipped'>
						<cfset this.createOrderShipmentRecords()>
					</cfif>
				</cfif>

				<cfset result=this.sync()>
				<cfif oldStatusID != this.statusID>
					<cfset logPOStatusChange(oldStatusID)>
				</cfif>

				<!--- check that we have not exceeded our ordered quantity --->
				<cfif this.statusID != 100>
					<cfset result = checkbatchquantity()>
				</cfif>
				<cfif structKeyExists(variables, 'wirebox') && !isEmpty(variables.wirebox)>
					<cfset ProcessProjectWorkflowUseCase = variables.wirebox.getInstance('ProcessProjectWorkflowUseCase')>
				<cfelse>
					<cfset ProcessProjectWorkflowUseCase = application.wirebox.getInstance('ProcessProjectWorkflowUseCase')>
				</cfif>
				<cfquery name="projectIDs" datasource="ahapdb">
					SELECT cpol.CustomerProjectID
					FROM CustomerOrders co
					INNER JOIN CustomerProjectOrderLink cpol ON cpol.CustomerOrderID = co.ID
					INNER JOIN CustomerProjects cp ON cpol.CustomerProjectID = cp.ID
					WHERE co.OrderID = <cfqueryparam sqltype="VARCHAR" value="#this.orderID#">
				</cfquery>
				<cfloop query="#projectIDs#">
					<cfset ProcessProjectWorkflowUseCase.ProcessProjectWorkflow(projectIDs.CustomerProjectID)>
				</cfloop>

				<cfif result.errorcode>
					<cfset setErrorStatus("Status set to Error. #result.errormessage#")>
				</cfif>

				<cfif this.runInventoryUpdate>
					<cfset updateInventoryStock()>
				</cfif>

				<cfcatch>
					<cfscript>mail subject="error" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump(cfcatch); }</cfscript>
					<cftransaction action="rollback" />
					<cfset result.errorcode = 1>
					<cfset result.errormessage = "Vendor PO Put failed - #cfcatch.Message# #cfcatch.detail#">
					<cfset logonly = true>
   					<cfinclude template='/partnernet/irongate/irongate.cfm'>
				</cfcatch>
			</cftry>
			</cftransaction>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cfscript>
		function updateInventoryStock() {
			var items = this.lineItems.reduce((carry, acc) => {
				arguments.carry.append(arguments.acc.inventoryItemId);
				return arguments.carry;
			}, []);

			storedproc procedure="updateInventoryStock" datasource="ahapdb" {
				procparam type="IN" sqltype="VARCHAR" value=items.toList(',');
				procparam type="IN" sqltype="VARCHAR" value=this.locationID;
				procresult name="productIds" resultSet="1";
			}

			application.wirebox.getInstance('ProductInventoryUpdatedPublisher').publish({
				'ids': productIds.columnData('ProductID')
			});
		}
	</cfscript>

	<cffunction name="insert" access="private" returntype="any" hint="Inserts tblVendorPOHeader record">
		<cfquery name="putHeader" datasource="#this.DSN#">
			DECLARE @customerOrderID INT = (SELECT ID FROM CustomerOrders WHERE OrderID = <cfqueryparam sqltype="VARCHAR" value="#this.orderID#">)

			INSERT INTO tblVendorPOHeader
				(status, statusID, orderID, vendorID, shipcompletePO, shipname, shipcompany, shipaddress1, shipaddress2, shipcity, shipstate, shippostalcode, shipcountry,
					shiptelephone, requestedshipdate, created, modified, createdby, modifiedby, shippingoptions, shipinstructions, carrierID, carriercode, carrierreturncode, customerOrderID, locationID, locationTypeId
				)
			VALUES
			(	<cfqueryparam sqltype="VARCHAR" value="#this.status#">
				,<cfqueryparam sqltype="SMALLINT" value="#this.statusID#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.orderID#">
				,<cfqueryparam sqltype="INT" value="#this.vendorID#">
				,<cfqueryparam sqltype="BIT" value="#val(this.shipcompletePO)#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipname#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipcompany#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipaddress1#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipaddress2#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipcity#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipstate#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shippostalcode#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shipcountry#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shiptelephone#">
				<cfif isdate(this.requestedshipdate)>
					,<cfqueryparam sqltype="DATE" value="#this.requestedshipdate#">
				<cfelse>
					,([dbo].[func_expectedshipdate_mv](getdate(),<cfqueryparam sqltype="INT" value="#this.vendorID#">))
				</cfif>
				,getdate()
				,getdate()
				,<cfqueryparam sqltype="VARCHAR" value="#this.createdby#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.modifiedby#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.shippingoptions#">
				,<cfqueryparam sqltype="VARCHAR" value="#left(this.shipinstructions,255)#">
				,<cfqueryparam sqltype="INT" value="#this.carrierID#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.carriercode#">
				,<cfqueryparam sqltype="VARCHAR" value="#this.carrierreturncode#">
				,@customerOrderID
				,<cfqueryparam sqltype="INT" value="#this.locationId#">
				,<cfqueryparam sqltype="INT" value="#this.locationTypeId#">
			)

			--POID set in trigger, prevents OUTPUT clause above
			SELECT objID, POID
			FROM tblVendorPOHeader WHERE objID = SCOPE_IDENTITY()
		</cfquery>

		<cfset this.objID = putHeader.objID>
		<cfset this.POID = putHeader.POID>

		<cfquery datasource="#this.DSN#">
			INSERT INTO RecordLogs ([RecordTypeID],[RecordID],[Message],[User])
				SELECT (SELECT ID FROM RecordTypes WHERE Code = 'order')
					, co.ID
					,CONCAT('Purchase Order ',poh.POID,' was created.')
					,0
				FROM CustomerOrders co
				INNER JOIN tblVendorPOHeader poh ON poh.POID = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">
					AND poh.OrderID = co.OrderID
		</cfquery>

		<cftry>
			<cfquery datasource="#this.DSN#">
				INSERT INTO tblVendorPOCarrierRates (POID, minimum, LT500, GT500, GT1k, GT2k, GT5k, ShippingSurcharges, FuelSurchargeRate)
					SELECT  poh.POID, vr.minimum, vr.LT500, vr.GT500, GT1k, GT2k, GT5k, stf.shippingtypefee + ISNULL(sc.cost,0), c.fuelsurcharge
					FROM tblVendorPOHeader poh
					INNER JOIN tblVendorCarrierShipping vr ON poh.vendorID = vr.vendorID AND poh.carrierID = vr.carrierID AND poh.shippostalcode = vr.zip
					INNER JOIN tblCarriers c ON c.carrierID = vr.carrierID
					INNER JOIN tblCarrierShippingTypeFees stf ON stf.carrierID = c.carrierID
					INNER JOIN tblCarrierShippingTypeLookup stl ON stl.typeID = stf.shippingtypeID AND stl.queryflags = poh.shippingoptions
					LEFT JOIN tblVendorCarrierSurcharges sc ON sc.carrierID = c.CarrierID AND vr.zip BETWEEN lozip AND hizip AND sc.surcharge = stl.typeID
					WHERE poh.POID = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">
			</cfquery>
			<cfcatch></cfcatch>
		</cftry>

		<cfreturn>
	</cffunction>

	<cffunction name="update" access="private" returntype="any" hint="Updates tblVendorPOHeader record">
		<cfquery name="putPO" datasource="#this.DSN#">
			UPDATE tblVendorPOHeader
			SET status = <cfqueryparam sqltype="VARCHAR" value="#this.status#">
				,orderID = <cfqueryparam sqltype="VARCHAR" value="#this.orderID#">
				,vendorID = <cfqueryparam sqltype="INT" value="#this.vendorID#">
				,shipcompletePO = <cfqueryparam sqltype="BIT" value="#val(this.shipcompletePO)#">
				,shipname = <cfqueryparam sqltype="VARCHAR" value="#this.shipname#">
				,shipcompany = <cfqueryparam sqltype="VARCHAR" value="#this.shipcompany#">
				,shipaddress1 = <cfqueryparam sqltype="VARCHAR" value="#this.shipaddress1#">
				,shipaddress2 = <cfqueryparam sqltype="VARCHAR" value="#this.shipaddress2#">
				,shipcity = <cfqueryparam sqltype="VARCHAR" value="#this.shipcity#">
				,shipstate = <cfqueryparam sqltype="VARCHAR" value="#this.shipstate#">
				,shippostalcode = <cfqueryparam sqltype="VARCHAR" value="#this.shippostalcode#">
				,shipcountry = <cfqueryparam sqltype="VARCHAR" value="#this.shipcountry#">
				,shiptelephone = <cfqueryparam sqltype="VARCHAR" value="#this.shiptelephone#">
				<cfif isdate(this.requestedshipdate)>,requestedshipdate = <cfqueryparam sqltype="DATE" value="#this.requestedshipdate#"></cfif>
				,modified = getdate()
				,modifiedby = <cfqueryparam sqltype="VARCHAR" value="#this.modifiedby#">
				,shippingoptions = <cfqueryparam sqltype="VARCHAR" value="#this.shippingoptions#">
				,shipinstructions = <cfqueryparam sqltype="VARCHAR" value="#left(this.shipinstructions,255)#">
				,carrierID = <cfqueryparam sqltype="INT" value="#this.carrierID#">
				,carriercode = <cfqueryparam sqltype="VARCHAR" value="#this.carriercode#">
				,carrierreturncode = <cfqueryparam sqltype="VARCHAR" value="#this.carrierreturncode#">
				,lastPrinted = <cfqueryparam sqltype="TIMESTAMP" value="#this.lastPrinted#">
				,statusID = <cfqueryparam sqltype="SMALLINT" value="#this.statusID#">
				,nsStatus = <cfqueryparam sqltype="VARCHAR" value="#this.nsStatus#">
				,ediResult = <cfqueryparam sqltype="VARCHAR" value="#this.ediResult#" null="#isEmpty(this.ediResult)#">
				,ediDateTime = <cfqueryparam sqltype="TIMESTAMP" value="#this.ediDateTime#" null="#isEmpty(this.ediDateTime)#">
			WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#this.objID#">

		</cfquery>
		<cfreturn>
	</cffunction>

	<cffunction name="delete" access="public" hint="Deletes the Vendor PO Header & Line Items from the database">
		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cfset this.uncommitAllItemsAndReassignThem()>

		<cfquery name="getobj" datasource="#this.DSN#">
			DELETE FROM tblVendorPODetailShipments WHERE POID = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">

			DELETE FROM tblVendorPODetail WHERE POID = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">

			DELETE FROM tblVendorPOShippingEstimates WHERE POID = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">

			DELETE FROM tblVendorPOHeader
			WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#this.objID#">
		</cfquery>

		<cfset updateInventoryStock()>
		
		<cfinvoke component="alpine-objects.objectutils" method="clearlog" objID="#this.objID#"/>

		<cfset result = this.init()>

		<cfreturn result>
	</cffunction>

	<cffunction name="businessrules" returntype="any" hint="">
		<cfset var result = {errorcode: 0, errormessage:"" }>
		
		<cfif this.status == 'void'>
			<cfreturn result>
		</cfif>

		<cfif this.objID == 0 OR this.POID IS "" OR (this.EDIResult != "Success" && isDate(this.EDIConfirmed) == 0)>
			<cfset this.canvoid = 1>
			<cfset this.isComplete = 0>
		</cfif>

		<cfset totals = this.gettotalcosts()>

		<cfif (dateCompare(NOW(),this.requestedshipdate,'m') + dateCompare(NOW(),this.requestedshipdate,'d')) LT 0 && NOT isSnetLabor()>
			<cfset this.status = "On Hold">
			<cfset this.statusID = 110>
		<cfelseif
			(totals.totalShipped == totals.totalToShip && totals.totalToShip != 0)
			OR (year(this.created) LTE 2016 && this.lineItems.map((e) => arguments.e.deliverymethod == 's' && arguments.e.productType == 'p' ? arguments.e.quantity : 0).sum() == totals.totalShipped)
			OR isSnetLabor()
		>
			<cfif totals.hasEmptyTracking && NOT isSnetLabor()>
				<cfset this.status = "Needs Tracking">
				<cfset this.statusID = 108>
			<cfelse>
				<cfset this.status = "Fully Shipped">
				<cfset this.statusID = 109>
				<cfif isSnetLabor()>
					<cfset this.ediResult = 'Success'>
					<cfset this.ediDateTime = lenTrim(this.ediDateTime) ? this.ediDateTime : now()>
				</cfif>
				<cfset this.lineItems.each(function(item,index){if(item.deliverymethod == 's'){item.status_shipped = 'S';}})>
			</cfif>
		<cfelseif totals.totalShipped GT 0>
			<cfset this.status = "Partially Fulfilled">
			<cfset this.statusID = 112>
		<cfelseif totals.totalPickedPacked ==  totals.totalToShip  && totals.totalToShip != 0>
			<cfset this.status = "Fully Picked/Packed">
			<cfset this.statusID = 111>
		<cfelseif totals.totalPickedPacked GT 0>
			<cfset this.status = "Partially Picked/Packed">
			<cfset this.statusID = 107>
		<cfelseif isPrinted()>
			 <cfset this.status = "Printed">
			 <cfset this.statusID = 106>
		<cfelseif totals.totalCommitted == totals.totalToShip && totals.totalToShip != 0>
			<cfif this.isPaidFor == 1>
				<cfset this.status = "Ready to Print">
				<cfset this.statusID = 105>
				<!--- <cfset generateTrackingNumberIfNeeded(totals)> --->
			<cfelse>
				<cfset this.status = "Committed, Not Paid">
				<cfset this.statusID = 104>
			</cfif>
		<cfelse>
			<cfset this.status = "Backordered">
			<cfset this.statusID = 103>
		</cfif>
		<cfreturn result>
	</cffunction>

	<cfscript>
	function addMiscellaneous(struct miscLineItems) {
		for(var item in arguments.miscLineItems.miscellaneous) {
			addMiscellaneousProduct(item.productId);
		}
		for(var item in arguments.miscLineItems.shipping) {
			ArrayAppend(this.estimatedShippingDetails, {
				'POID': this.POID,
				'Amount': item.unitprice,
				'Weight': item.weight,
				'Height': item.packheight,
				'Width': item.packwidth,
				'Length': item.packlength,
			});
		}
	}
	</cfscript>

	<cffunction name="getMiscellaneous" access="public" returntype="struct" hint="Adds extra items needed to complete shipments">
		<cfset var equipmentitems = "">
		<cfset var result = { shipping:[], miscellaneous:[] }>

		<cfif arrayLen(this.lineItems)>
			<cfif isSnetLabor()>
				<cfreturn result>
			</cfif>

			<cfset productList = this.lineItems.Reduce(reduceLineItems)>
			<cfset this.isFreight = productList.some((product) => arguments.product.shipFreight) || this.isFreight>
			<cfif this.isFreight>
				<cfset productList.first().shipFreight = 1>
			</cfif>

			<cfset packageProductsService = application.wirebox.getInstance('packageProductsService')>
			<cfset boxes = packageProductsService.packageProducts(productList)>

			<!--- add shipping costs to PO --->
			<cfset estimatedshipping = calculateshipping(packages = boxes)>

			<cfloop array="#estimatedshipping#" item="x" index="i">
				<cfset ArrayAppend(result.shipping, {
					  POID: this.POID,
					  OrderID: this.orderID,
					  vendorprodnumber: "Shipping",
					  unitprice: x.unitprice,
					  extprice: x.unitprice,
					  description: "Shipment Cost Allocation",
					  weight: val(x.weight),
					  packheight: val(x.height),
					  packwidth: val(x.width),
					  packlength: val(x.length),
					  deliverymethod: "X",
					  producttype: "S"
				})>
			</cfloop>

			<cfif isdefined("boxes.unloaded") && boxes.unloaded.count() GT 0>
				<cfset this.errorcode = 1>
				<cfset this.errormessage = "Some items were unable to be boxed. #boxes.unloaded.keyList()#">
			</cfif>

			<cfset hasEquipment = this.lineItems.Reduce(function(qty,item){ return qty += item.isFreight; },0)>

			<cfif hasEquipment && boxes.skids.len() == 0>
				<cfset this.errormessage = "Equipment on order, but no skids.">
			</cfif>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="reduceLineItems" returnType="any">
		<cfargument name="products" default="#[]#">
		<cfargument name="item">
		<cfscript>
			if(item.orderlineID GT 0) {
				arguments.products.append({
					'productID': arguments.item.productID,
					'quantity': arguments.item.quantity,
					'orderedQuantity': arguments.item.orderedQuantity,
					'weight': arguments.item.weight,
					'height': arguments.item.packHeight,
					'length': arguments.item.packLength,
					'width': arguments.item.packWidth,
					'shipinmfgboxsc': arguments.item.shipinmfgboxsc,
					'shipinmfgboxfc': arguments.item.shipinmfgboxfc,
					'packinbox': arguments.item.packinbox,
					'shipfreight': arguments.item.shipFreight,
					'skid': arguments.item.skid,
					'freightClass': arguments.item.freightClass,
					'nmfc': arguments.item.nmfc
				});
			}
			return arguments.products;
		</cfscript>
	</cffunction>

	<cffunction name="additem" returntype="any" hint="">
		<cfargument name="orderlineID" type="Numeric" required="false"> <!--- order line ID will override the other settings --->
		<cfargument name="inventoryItemID" type="Numeric" required="false">
		<cfargument name="quantity" type="Numeric" required="false">

		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cfquery name='getproduct' datasource='ahapdb'>
			SELECT
				o.sessionID AS 'orderId',
				ii.sku AS 'vendorprodnumber',
				o.quantity * iil.quantity AS 'orderedQuantity',
				ii.unitOfMeasure AS 'uom',
				ii.unitCost AS 'unitprice',
				ii.model AS 'mfgpartnumber',
				ii.upc,
				ii.weight,
				ii.width AS 'packwidth',
				ii.height AS 'packheight',
				ii.length AS 'packlength',
				ii.shortdescription AS 'description',
				ii.countryofmfr AS 'countryofmfg',
				CASE WHEN ii.shippable = 1 THEN 'S' ELSE 'X' END AS 'deliverymethod',
				c.expectedshipdate AS 'estshipdate',
				o.productNumber AS 'productID',
				p.category AS 'categoryID',
				ii.shipfreight AS 'isFreight',
				p.productType,
				ii.shipinmfgboxsmallpack AS 'shipinmfgboxsc',
				ii.shipinmfgboxfreight AS 'shipinmfgboxfc',
				ii.skid,
				ii.shipFreight,
				p.overridevendorcosts,
				fc.label AS 'freightclass',
				gpg.column1 AS 'froogleLabel2',
				ii.nmfc,
				p.manufacturer,
				iil.inventoryItemID,
				ii.shippable,
				ISNULL((
					SELECT si.ID
					FROM SublineItems si
					INNER JOIN Bins b ON b.ID = si.BinId
						AND b.Orderable = 1
					INNER JOIN BinSections bs ON bs.ID = b.BinSectionId
						AND bs.WarehouseId = ins.LocationID
					WHERE si.InventoryItemID = iil.InventoryItemID
						AND si.Active = 1
						AND si.Closed = 0
						AND (
							si.CustomerPoLineId IS NULL
							OR
							(
								SELECT checkouts.DT
								FROM tblVendorPODetail pod
								INNER JOIN tblVendorPOHeader poh ON poh.POID = pod.POID
									AND poh.statusID NOT IN (106,107,108,109,111,112)
								INNER JOIN checkouts ON checkouts.SessionID = pod.OrderID
								WHERE pod.lineID = si.CustomerPoLineId
							) > c.DT --Committed PO is for a newer order
						)
						AND si.LocationTransferItemId IS NULL
					ORDER BY si.CustomerPoLineId, ISNULL(si.PalletId,0), b.Priority, bs.[Name], b.[Name]
					FOR JSON AUTO
				),'[]') AS 'availableSublineItems',
				ISNULL(ins.QtyBackOrdered,0) AS 'qtyBackOrdered',
				ISNULL((
					SELECT TOP(CONVERT(INT,o.quantity * iil.quantity) + ISNULL(ins.QtyBackOrdered,0))
						COALESCE(CONVERT(DATETIME,s.ScheduledDeliveryDate) + CONVERT(DATETIME,s.ScheduledDeliveryTime),s.ExpectedDeliveryDate,vpoi.ExpectedReceiptDate) AS 'ETA'
					FROM VendorPurchaseOrders vpo
					INNER JOIN Warehouses w ON w.ID = vpo.WarehouseId AND w.ID = ins.LocationID
					INNER JOIN VendorPurchaseOrderItems vpoi ON vpoi.PurchaseOrderId = vpo.ID
					INNER JOIN SublineItems si ON si.ID = vpoi.SublineItemId
						AND si.InventoryItemID = iil.InventoryItemID
						AND si.Active = 1 
						AND si.Closed = 0 
						AND si.CustomerPoLineId IS NULL 
						AND si.LocationTransferItemId IS NULL
						AND si.BinId IS NULL
					LEFT JOIN ShipmentSublineItemLink ssil ON ssil.SublineItemId = si.ID
					LEFT JOIN Shipments s ON s.ID = ssil.ShipmentId
					ORDER BY COALESCE(CONVERT(DATETIME,s.ScheduledDeliveryDate) + CONVERT(DATETIME,s.ScheduledDeliveryTime),s.ExpectedDeliveryDate,vpoi.ExpectedReceiptDate)
					FOR JSON AUTO
				),'[]') AS 'onOrderDetails'
			FROM orders o
			INNER JOIN InventoryItemLink iil ON iil.productID = o.productNumber
			INNER JOIN InventoryItems ii ON ii.ID = iil.inventoryItemID
			INNER JOIN checkouts c ON c.sessionID = o.sessionID
			INNER JOIN products p ON p.id = o.productNumber
			INNER JOIN FreightClasses fc ON fc.id = ii.freightClassID
			LEFT JOIN tblGoogleProductGroups gpg ON gpg.categoryID = p.category
			LEFT JOIN InventoryStock ins ON ins.InventoryItemID = ii.ID
				AND ins.LocationTypeID = <cfqueryparam sqltype="INT" value="#this.locationTypeId#">
				AND ins.LocationID = <cfqueryparam sqltype="INT" value="#this.locationId#">
			WHERE o.id = <cfqueryparam sqltype='INT' value='#arguments.orderLineID#'>
		</cfquery>

		<cfif getproduct.recordcount GT 0>
			<cfscript>
				var firstRow = getproduct.rowData(1);
				firstRow.append({
					'poid': this.POID,
					'orderLineID': arguments.orderLineID,
					'vendorID': 24,
					'quantity': 1,
				});
				onOrderDates = deserializeJSON(firstRow.onOrderDetails);
				onOrderDates = onOrderDates.len() > firstRow.qtyBackordered ? onOrderDates.slice(firstRow.qtyBackordered + 1).map((e) => arguments.e.ETA) : [];
				
				loop from='1' to='#arguments.quantity#' index='local.idx' {
					var itemToAdd = duplicate(firstRow);
					if(itemToAdd.shippable && itemToAdd.productType == 'p') {
						var previouslyAllocatedSublineItems = this.lineItems.filter((e) => arguments.e.inventoryItemID == firstRow.inventoryItemID).map((e) => arguments.e.sublineItemID);
						var availableSublineItems = deserializeJSON(itemToAdd.availableSublineItems).filter((e) => !previouslyAllocatedSublineItems.find(arguments.e.ID));
						if(availableSublineItems.len()) {
							itemToAdd.sublineItemID = availableSublineItems.first().ID;
							itemToAdd.qtyCommitted = itemToAdd.quantity;
							this.runInventoryUpdate = true;
						} else {
							itemToAdd.estshipdate = onOrderDates.shift(itemToAdd.estshipdate);
						}
					}
					ArrayAppend(this.lineItems, new objects.vendorPOLineItem(itemToAdd));
				}
			</cfscript>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cfscript>
		function addMiscellaneousProduct(required productId) {
			var product = QueryExecute("
				SELECT
					ii.sku AS 'vendorprodnumber',
					ii.unitOfMeasure AS 'uom',
					ii.unitCost AS 'unitprice',
					ii.model AS 'mfgpartnumber',
					ii.upc,
					ii.weight,
					ii.width AS 'packwidth',
					ii.height AS 'packheight',
					ii.length AS 'packlength',
					ii.shortdescription AS 'description',
					ii.countryofmfr AS 'countryofmfg',
					CASE WHEN ii.shippable = 1 THEN 'S' ELSE 'X' END AS 'deliverymethod',
					ISNULL(p.category, 265) AS 'categoryID',
					ii.shipfreight AS 'isFreight',
					ISNULL(p.productType, 'K') AS 'productType',
					ii.shipinmfgboxsmallpack AS 'shipinmfgboxsc',
					ii.shipinmfgboxfreight AS 'shipinmfgboxfc',
					ii.skid,
					ii.shipFreight,
					ISNULL(p.overridevendorcosts, 0) AS 'overridevendorcosts',
					fc.label AS 'freightclass',
					gpg.column1 AS 'froogleLabel2',
					ii.nmfc,
					ii.id AS 'inventoryItemID'
				FROM InventoryItems ii
				LEFT JOIN products p ON CONVERT(VARCHAR, p.id) = ii.sku
				INNER JOIN FreightClasses fc ON fc.id = ii.freightClassID
				LEFT JOIN tblGoogleProductGroups gpg ON gpg.categoryID = p.category
				WHERE ii.sku = :productId
			", {
				productId: { sqltype: 'VARCHAR', value: arguments.productID }
			}, { datasource: 'ahapdb' });

			if(product.recordcount GT 0) {
				var firstRow = product.rowData(1);
				firstRow.append({
					'poid': this.POID,
					'orderId': this.orderId,
					'orderLineID': 0,
					'vendorID': 24,
					'quantity': 1,
				});

				ArrayAppend(this.lineItems, new objects.vendorPOLineItem(firstRow));
			}
		}
	</cfscript>

	<cffunction name="checkorderline" returntype="struct" hint="">
		<cfargument name="orderlineID" type="Numeric" required="true">
		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cfquery name="checkline" datasource="#this.DSN#">
			SELECT h.status,d.status_shipped,h.EDIResult
			FROM tblVendorPODetail d WITH (NOLOCK)
			INNER JOIN tblVendorPOHeader h ON d.status_shipped NOT LIKE 'V'
				AND d.orderlineID = <cfqueryparam sqltype="INT" value="#orderlineID#">
				AND (h.statusid <> 100)
				AND h.POID = d.POID
		</cfquery>
		<cfif checkline.recordcount>
			<cfset result.errorcode = 1>
			<cfset result.errormessage = "Line cannot be added/modified">
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="sync" returntype="struct" access="private" hint="">
		<cfargument name="POID" type="String" required="false" default="#this.POID#">
		<cfset var result = {errorcode: 0, errormessage:"" }>

			<cfif len(trim(POID))>
				<!--- this does not update the line for a kit master item --->
				<cfquery name="updateorderline" datasource="#this.DSN#">
					UPDATE orders
					SET productcost = unitprice
						,dprodnumber = vendorprodnumber
						,distributorID = vendorID
					FROM orders
					INNER JOIN tblvendorPODetail ON orders.ID = tblvendorPODetail.orderlineID
					WHERE tblvendorPODetail.POID = <cfqueryparam sqltype="VARCHAR" value="#POID#">
				</cfquery>

				<!--- this updates the line for the kit master items --->
				<cfquery name="updatekitmaster" datasource="#this.DSN#">
					DECLARE @POID varchar(25)
					SET @POID=<cfqueryparam sqltype="VARCHAR" value="#POID#">

					DECLARE @session varchar(25)
					SELECT @session= orderID FROM tblVendorPODetail WHERE POID=@POID

					SELECT orders.ID
						, orders.ProductNumber
						, CAST(SUM(ii.unitCost * iil.Quantity * pk.kitprodqty) AS MONEY) AS kitprice
					FROM orders WITH (NOLOCK)
					INNER JOIN tblproductkits pk (NOLOCK) ON pk.kitmasterprodID=orders.ProductNumber
					INNER JOIN InventoryItemLink iil (NOLOCK) ON iil.productID = pk.kitprodID
					INNER JOIN InventoryItems ii (NOLOCK) ON ii.ID=iil.InventoryItemID
					WHERE orders.ID IN
						(SELECT ID FROM orders WITH (NOLOCK) WHERE ProductNumber = pk.kitmasterprodID AND SessionID=@session)
					GROUP BY orders.ID, orders.ProductNumber
				</cfquery>

				<cfif updatekitmaster.recordcount LT 10> <!--- a little insurance - don't update more than 10 lines --->
					<cfloop query="updatekitmaster">
						<cfquery name="updateorderline" datasource="#this.DSN#">
							UPDATE orders
							SET productcost = <cfqueryparam sqltype="MONEY" value="#kitprice#">
							WHERE ID = <cfqueryparam sqltype="INT" value="#ID#">
						</cfquery>
					</cfloop>
				</cfif>

			<cfelse>
				<cfset result.errorcode=1>
				<cfset result.errormessage = "POID cannot be blank. Sync failed.">
			</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="setErrorStatus" access="private" returntype="void" hint="">
		<cfargument name="message" required="false" default="">
		<cfset this.status = "Error">
		<cfset this.statusID = 117>
		<!--- update this PO --->
		<cfquery name="updatestatus" datasource="#this.DSN#">
			UPDATE tblVendorPOHeader
			SET status = <cfqueryparam sqltype="VARCHAR" value="#this.status#">
			WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#this.objID#">
				AND status IN ('New','Ready to EDI')
		</cfquery>

		<cfquery name="insertlog" datasource="#this.DSN#">
			INSERT INTO tblObjectLog(objID,value,createdby,oktoarchive)
			VALUES (<cfqueryparam sqltype="VARCHAR" value="#this.objID#">,<cfqueryparam sqltype="VARCHAR" value="#ARGUMENTS.message#">,<cfqueryparam sqltype="VARCHAR" value="#getCurrentUser()#">,0)
		</cfquery>

		<cfmail to="csm@alpinehomeair.com;technical@alpinehomeair.com" from="system@alpinehomeair.com" subject="Error creating PO #this.POID#">#ARGUMENTS.message#</cfmail>
	</cffunction>

	<cffunction name="checkbatchquantity" access="public" returntype="struct" hint="">
		<cfargument name="orderID" required="false" default="#this.orderID#">
		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cfquery name="checkqty" datasource="#this.DSN#">
			DECLARE @orderID VARCHAR(10) = <cfqueryparam sqltype="VARCHAR" value="#this.orderID#">

			DECLARE @orddetail TABLE (productnumber VARCHAR(20), quantity int)
			INSERT INTO @orddetail
			SELECT ii.SKU AS 'vendorpartnumber', SUM(o.Quantity * o.ordlinepackqty)
				FROM orders o
				INNER JOIN Products p ON o.ProductNumber = p.ID
				INNER JOIN InventoryItemLink iil ON p.ID = iil.productID
				INNER JOIN InventoryItems ii ON iil.InventoryItemID = ii.ID AND ii.Shippable = 1
				WHERE sessionid = @orderID
				GROUP BY ii.SKU

			SELECT od.productnumber
			FROM @orddetail od
			LEFT JOIN (
				SELECT pod.vendorprodnumber, SUM(pod.quantity) AS quantity
				FROM tblVendorPODetail pod
				INNER JOIN tblVendorPOHeader poh ON poh.statusID NOT IN (100) AND pod.POID = poh.POID
				WHERE pod.orderID = @orderID
					AND pod.producttype = 'p'
					AND pod.deliverymethod = 's'
				GROUP BY pod.vendorprodnumber
				) x ON x.vendorprodnumber = CAST(od.productnumber AS VARCHAR)
			WHERE ISNULL(x.quantity,0) > od.quantity
		</cfquery>

		<cfif checkqty.recordcount>
			<cfset result.errorcode = 1>
			<cfset result.errormessage = "Total batched quantities greater than total ordered quantities.">
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="isPrinted" returntype="boolean">
		<cfreturn len(this.lastPrinted) ? true : false>
	</cffunction>

	<cffunction name="isSnetLabor" returntype="boolean">
		<cfreturn arrayLen(this.lineItems) IS 1 && this.lineItems[1].productID IS 453071040>
	</cffunction>

	<cffunction name="isShipped" returntype="boolean">
		<cfreturn this.statusid == 108 OR this.statusid == 109>
	</cffunction>

	<cffunction name="isVoided" returntype="boolean">
		<cfreturn this.statusID == 100>
	</cffunction>

	<cffunction name="cancelPO" access="public" returntype="struct" hint="Cancels the PO">
		<cfset progress = new objects.progress()>

		<cftry>
			<cfset progress.setProgress(40, 'Voiding PO in PNet. Please Wait...')>

			<cfquery name="getdistributors" datasource="#this.DSN#">
				SELECT DISTINCT srcID, srcUOREmail
				FROM tblProductFulfillmentSources WITH (NOLOCK)
				WHERE srcID = <cfqueryparam sqltype="INT" value="#this.vendorID#">
					AND srcUOREmail <> '' AND srcUOREmail IS NOT NULL
			</cfquery>

			<cfobject component="alpine-objects.orderchange" name="orderchange">
			<cfset orderchange.changeoptions = "cancelentireorderresend">
			<cfset orderchange.orderID = this.POID>
			<cfset orderchange.changedby = "#SESSION.user.firstname# #SESSION.user.lastname#">

			<cfloop query="getdistributors">
				<cfset orderchange.distributorID = getdistributors.srcID>
				<cfset orderchange.changesendto = getdistributors.srcUOREmail>
				<cfset orderchange.send()>
				<cfset orderchange.save()>
			</cfloop>

			<cfquery datasource="#this.DSN#">
				UPDATE checkouts
				SET process = 25
				WHERE sessionID = <cfqueryparam sqltype="VARCHAR" value="#this.orderID#">
			</cfquery>

			<cfset this.uncommitAllItemsAndReassignThem()>

			<cfcatch>
				<cfset logonly = true>
				<cfinclude template="/partnernet/irongate/irongate.cfm">
				<cfset progress.setProgress(100, 'You done goofed', true)>
				<cfreturn { errorcode:1, errormessage: "You done goofed" }>
			</cfcatch>
		</cftry>

		<cfset oldStatusID = this.statusID>
		<cfset this.status = "Void">
		<cfset this.statusID = 100>
		<cfset this.runInventoryUpdate = true>
		<cfset logPOStatusChange(oldStatusID)>
		<cfinvoke component="objects.objectutils" method="putlog" objID="#this.objID#" value="Voided"/>
		<cfset results = put()>
		<cfset progress.setProgress(100, 'Voided PO!')>
		
		<cfreturn results>
	</cffunction>

	<cffunction name="uncommitAllItemsAndReassignThem" access="private" returntype="void">
		<cfset this.lineItems.each((ele) => {
			arguments.ele.sublineItemID = '';
			arguments.ele.qtyCommitted = 0;
		})>
		<cfquery name="newlyAvailableSublineItems" datasource="#this.DSN#">
			UPDATE si
			SET si.CustomerPoLineId = NULL
			OUTPUT inserted.ID
			FROM tblVendorPODetail pod
			INNER JOIN SublineItems si ON si.CustomerPoLineId = pod.lineID
			WHERE pod.POID = <cfqueryparam sqltype="VARCHAR" value="#this.POID#">
		</cfquery>
		<cfif newlyAvailableSublineItems.recordCount>
			<cfquery datasource="ahapdb" name="sndsOnPO">
				SELECT
					ps.tagServiceId
				FROM SublineItems si
				INNER JOIN InventoryItems ii ON ii.ID = si.InventoryItemID
				INNER JOIN ProductTypes pt ON pt.ID = ii.ItemTypeID
					AND pt.Code = 'snd'
				LEFT JOIN SublineItemLink sil ON sil.newSublineItemId = si.ID
				INNER JOIN tblProductSerials ps ON ps.numericId = ISNULL(sil.tagNum, CASE WHEN ii.SKU LIKE 'SND%' THEN SUBSTRING(ii.SKU,4,LEN(ii.SKU)-3) END)
				WHERE si.ID IN (<cfqueryparam sqltype="INT" list="true" value="#newlyAvailableSublineItems.columnData('ID')#">)
			</cfquery>

			<cfif sndsOnPO.recordCount>
				<cfloop query="#sndsOnPO#">
					<cfset application.wirebox.getInstance('SNDItemUnCommittedPublisher').publish({
						'id': sndsOnPO.tagServiceId,
						'userId': getCurrentUser()
					})>
				</cfloop>
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="getEstimatedShipping" access="public" returntype="struct" hint="">
		<cfargument name="POID" required="false" default="#this.POID#">
		<cfargument name="orderID" required="false" default="">
		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cfif orderID == "" && POID IS NOT "">

			<cfquery name="getvalues" datasource="#this.DSN#">
				SELECT
					COUNT(*) AS 'estimatedshipments',
					SUM(se.Amount) AS 'estimatedshippingcost',
					SUM(se.Weight) AS 'estimatedWeight',
					h.shippingoptions,
					h.carriercode,
					h.carrierreturncode,
					h.carrierID
				FROM tblVendorPOShippingEstimates se WITH (NOLOCK)
				INNER JOIN tblvendorpoHeader h WITH (NOLOCK) ON se.POID = h.POID
				WHERE se.POID = <cfqueryparam sqltype="VARCHAR" value="#POID#">
				GROUP BY h.shippingoptions, h.carriercode, h.carrierreturncode, h.carrierID
			</cfquery>

			<cfset result.carrierID = getvalues.carrierID>
			<cfset result.shippingoptions = getvalues.shippingoptions>
			<cfset result.carriercode = getvalues.carriercode>
			<cfset result.carrierreturncode = getvalues.carrierreturncode>
			<cfset result.estimatedshipments = val(getvalues.estimatedshipments)>
			<cfset result.estimatedshippingcost = val(getvalues.estimatedshippingcost)>
			<cfset result.estimatedWeight = val(getvalues.estimatedWeight)>

		<cfelseif orderID IS NOT "" && POID IS "">

			<cfquery name="getvalues" datasource="#this.DSN#">
				SELECT COUNT(*) AS 'estimatedshipments', SUM(se.Amount) AS 'estimatedshippingcost'
				FROM tblVendorPOShippingEstimates se WITH (NOLOCK)
				INNER JOIN tblvendorpoHeader h WITH (NOLOCK) ON se.POID = h.POID
					AND h.orderID = <cfqueryparam sqltype="VARCHAR" value="#orderID#">
			</cfquery>

			<cfset result.carrierID = "">
			<cfset result.shippingoptions = "">
			<cfset result.carriercode = "">
			<cfset result.carrierreturncode = "">
			<cfset result.estimatedshipments = val(getvalues.estimatedshipments)>
			<cfset result.estimatedshippingcost = val(getvalues.estimatedshippingcost)>

		<cfelseif POID IS "">
			<cfset lineTotals = gettotalcosts()>

			<cfset result.carrierID = this.carrierID>
			<cfset result.shippingoptions = this.shippingoptions>
			<cfset result.carriercode = this.carriercode>
			<cfset result.carrierreturncode = this.carrierreturncode>
			<cfset result.estimatedshipments = val(lineTotals.totalQuantity)>
			<cfset result.estimatedshippingcost = val(lineTotals.totalExtcost)>

		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="getestimatedshipdate" returntype="struct" hint="">
		<cfset var result = {errorcode: 0, errormessage:"" }>

		<cftry>
			<cfif arrayLen(this.lineItems)>
				<cfset this.estimatedshipdate = this.lineItems.Reduce(function(estShipDate,item){
					return (dateCompare(arguments.item.estshipdate,arguments.estShipDate) == 1) ? arguments.item.estshipdate : arguments.estShipDate
				},now() )>

				<cfif isdate(this.estimatedshipdate) && isdate(this.requestedshipdate) && datecompare(this.requestedshipdate,this.estimatedshipdate,"d") == 1>
					<cfset this.estimatedshipdate = this.requestedshipdate>
				</cfif>

				<cfset this.shippingmsg = "">

				<cfif isdate(this.estimatedshipdate) && datecompare(now(),this.estimatedshipdate,"d") == 0 && datediff("n",now(),this.estimatedshipdate) GT 0>
					<cfset tzs = "s">
					<cfif datediff("h",now(),this.estimatedshipdate) GTE 1>
						<cfset this.shippingmsg="Ships today if ordered in the next #datediff('h',now(),this.estimatedshipdate)# hour#IIF(datediff('h',now(),this.estimatedshipdate) GT 1,'tzs','')# #datediff('n',now(),this.estimatedshipdate)-(datediff('h',now(),this.estimatedshipdate)*60)# minute#IIF(datediff('n',now(),this.estimatedshipdate)-(datediff('h',now(),this.estimatedshipdate)*60) GT 1,'tzs','')#">
					<cfelse>
						<cfset this.shippingmsg="Ships today if ordered in the next #datediff('n',now(),this.estimatedshipdate)# minute#IIF(datediff('n',now(),this.estimatedshipdate) GT 1,'tzs','')#">
					</cfif>
				</cfif>

				<cfset local.carrier = createObject("component","alpine-objects.carrier")>
				<cfset local.carrier.get(objID=this.carrierID)>
				<cfset this.daysintransit = val(local.carrier.getshippingspeed(postalcode=this.shippostalcode).servicedays)>

				<cfset this.estimateddeliverydate = parsedatetime(Dateadd("d",incrementbizdays(days=this.daysintransit,startdate=this.estimatedshipdate).days,this.estimatedshipdate))>

				<cfset this.notavailable = 0>
				<cfloop array=#this.LineItems# item="local.lineItem">
					<cfset local.lineItem.estshipdate = this.estimatedshipdate>
				</cfloop>
			<cfelse>
				<cfset this.notavailable = 1>
				<cfset this.estimatedshipdate = "">
			</cfif>

		<cfcatch>
			<cfset result.errorcode = 1>
			<cfset result.errormessage = "#cfcatch.Detail# #cfcatch.Message#">
			<cfset this.notavailable = 1>
		</cfcatch>
		</cftry>

		<cfreturn result>
	</cffunction>

	<cffunction name="gettotalcosts" returntype="struct" hint="Calculates all total costs from PO Line Items">
		<cfset var result = {
			'errorcode': 0,
			'errormessage': '',
			'totalUnitCost': 0,
			'totalExtcost': 0,
			'totalFifoCogs': 0,
			'totalExtFifoCogs': 0,
			'totalQuantity': 0,
			'totalCommitted': 0,
			'totalPickedPacked': 0,
			'totalShipped': 0,
			'totalToShip': 0,
			'hasEmptyTracking': 0,
			'isFreight': 0
		}>
		<cfset var trackingArray = []>

		<cfset this.lineItems.each(function(item,index){
			if(item.orderlineID || item.vendorprodnumber == 453075476){
				result.shipDetails = item.getCombinedShipmentDetails();
				result.totalShipped += result.shipDetails.qtyShipped;
				result.hasEmptyTracking += result.shipDetails.hasEmptyTracking;
				trackingArray.append(result.shipDetails.trackingNums);
				result.totalToShip += item.quantity;
			}
			result.totalQuantity += item.quantity;
			result.totalCommitted += item.qtyCommitted;
			result.totalPickedPacked += item.qtyPickedPacked;
			result.totalUnitCost += item.unitprice;
			result.totalExtcost  += item.unitprice * item.quantity;
			result.totalFifoCogs += item.fifocogs;
			result.totalExtFifoCogs += item.fifocogs * item.quantity;
			result.isFreight += item.isFreight;
		})>

		<cfset this.estimatedShippingDetails.each(function(e){
			result.totalUnitCost += arguments.e.Amount;
			result.totalExtcost  += arguments.e.Amount;
		})>
		<cfset result.trackingNums = arrayToList(createObject('java','java.util.HashSet').init(trackingArray))>
		<cfreturn result>
	</cffunction>

	<cffunction name="createOrderShipmentRecords" returntype="void" hint="">
		<cfset totals = this.gettotalcosts()>

		<cfquery name="makeShipments" datasource="#this.DSN#">
			DECLARE @orderID varchar(20) = <cfqueryparam sqltype="VARCHAR" value="#this.orderID#">
			DECLARE @carrierID varchar(15) = <cfqueryparam sqltype="VARCHAR" value="#this.carrierID#">

			<cfloop list="#totals.trackingNums#" index="i">
				IF NOT EXISTS (SELECT * FROM tblShipments
					WHERE sessionID = @orderID
					AND trackingnumber = <cfqueryparam sqltype="VARCHAR" value="#trim(i)#">)
				BEGIN
					INSERT INTO tblshipments (sessionID,trackingnumber,shipdate,servicetype,company,billedweight)
					VALUES (@orderID ,<cfqueryparam sqltype="VARCHAR" value="#trim(i)#">, getDate(), @carrierID ,@carrierID, 0)
				END
			</cfloop>
		</cfquery>

		<cfloop array="#this.lineitems#" item="i">
			<cfif i.vendorprodnumber.startsWith('SND')>
				<cfset numericID = REREPLACE(i.vendorprodnumber, "[^0-9]+", "", "all")>

				<cfquery name="getitem" datasource="#this.DSN#">
					INSERT INTO tblProductLocation (productID,locationID,sublocationID,condition,createdby,notes,[grouping],disposition)
						SELECT s.[objID], 'SND Sale', l.sublocationID, l.condition, <cfqueryparam sqltype="INT" value="#getcurrentuser()#">, <cfqueryparam sqltype="VARCHAR" value="#this.POID#">, l.[grouping], l.disposition
						FROM tblProductSerials s WITH (NOLOCK)
						CROSS APPLY (SELECT TOP 1 l.* FROM tblProductLocation l WHERE l.productID = s.[objID] ORDER BY l.created DESC) l
						WHERE s.numericID = <cfqueryparam sqltype="INT" value="#val(numericID)#">
							AND l.notes <> <cfqueryparam sqltype="VARCHAR" value="#this.POID#">
				</cfquery>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="logPOStatusChange" returntype="void">
		<cfargument name="oldStatusID" type="numeric" required=true>
		<cftry>
			<cfquery datasource="#this.DSN#">
				INSERT INTO tblPOStatusLog (POID,fk_prev_statusID,fk_curr_statusID)
				VALUES (
					<cfqueryparam sqltype="VARCHAR" value="#this.POID#">,
					<cfqueryparam sqltype="SMALLINT" value="#ARGUMENTS.oldStatusID#">,
					<cfqueryparam sqltype="SMALLINT" value="#this.statusID#">
					)
			</cfquery>
			<cfcatch></cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="calculateshipping" access="private" returntype="array">
		<cfargument name="packages" type="struct" required=true>
		<cfargument name="carrierID" type="numeric" required=false default="#this.carrierID#">
		<cfargument name="vendorID" type="numeric" required=false default="#this.vendorID#">
		<cfargument name="orderID" type="String" required=false default="#this.orderID#">
		<cfargument name="postalcode" type="String" required=false default="#this.shippostalcode#">
		<cfargument name="shippingoptions" type="String" required=false default="#this.shippingoptions#">
		<cfargument name="isfreight" type="boolean" required=false default="#this.isfreight#">
		<cfargument name="locationID" type="boolean" required=false default="#this.locationID#">
		<cfargument name="locationTypeID" type="boolean" required=false default="#this.locationTypeID#">

		<cfset var LOCAL = {}>
		<cfset var estimatedshipping = []>

		<cftry>
			<cfset estimatedshipping.append(getLiveShippingRate(argumentCollection = arguments))>

			<cfcatch>
				<cfset LOCAL.objCarrier = createObject("objects.carrier")>

				<cfif NOT ARGUMENTS.isfreight>
					<cfloop collection="#ARGUMENTS.packages.packages#" index="local.ID" item="local.package">
						<cfset LOCAL.dimsurcharge = LOCAL.dimweight1 = LOCAL.dimweight2 = 0>
						<cfset LOCAL.dimlist = "">
						<cfset LOCAL.dimlist = LOCAL.dimlist.listAppend(ceiling(local.package.length)).listAppend(ceiling(local.package.width)).listAppend(ceiling(local.package.height)).listSort("numeric")>

						<cfif (listFirst(LOCAL.dimlist) * 2) + (listGetAt(LOCAL.dimlist,2) * 2) + listLast(LOCAL.dimlist) GTE 130>
							<cfset LOCAL.dimweight2 = 90>
							<cfset LOCAL.dimsurcharge = 40>
						</cfif>

						<cfif NOT listFind("453057440,453056876,453056908",local.package.productID)>
							<cfset LOCAL.args = {
								  carrierID = ARGUMENTS.carrierID
								, vendorID = ARGUMENTS.vendorID
								, postalcode = ARGUMENTS.postalcode
								, length = ceiling(local.package.length)
								, width = ceiling(local.package.width)
								, height = ceiling(local.package.height)
								, weight = MAX(MAX(LOCAL.dimweight1,LOCAL.dimweight2),ceiling(local.package.weight))
								, shippingoptions = ARGUMENTS.shippingoptions
							}>
							<cfset LOCAL.estshipping = objCarrier.getshippingrate(argumentCollection=LOCAL.args)>

							<cfloop from="1" to="#local.package.quantity#" index="i">
								<cfset estimatedshipping.append({
								  weight:ceiling(LOCAL.args.weight)
								, height:ceiling(local.package.height)
								, length: ceiling(local.package.length)
								, width: ceiling(local.package.width)
								, unitprice:val(LOCAL.estshipping.rate) + LOCAL.dimsurcharge
								})>
							</cfloop>
						</cfif>
					</cfloop>
				<cfelse>
					<cfset ARGUMENTS.weight = ARGUMENTS.packages.skids.reduce(function(totalweight,ele){ return arguments.totalweight += arguments.ele.weight; },0)>
					<cfset LOCAL.estshipping = objCarrier.getshippingrate(argumentCollection=ARGUMENTS)>
					<cfset LOCAL.guaranteedSurcharge = val(queryExecute("SELECT price FROM orders WHERE SessionID = :orderID AND productNumber = 453071037",{orderID:{sqltype:"VARCHAR",value:ARGUMENTS.orderID}},{datasource:this.DSN}).price)>
					<cfset estimatedshipping.append({
						  weight:val(ARGUMENTS.weight)
						, height:ceiling(ARGUMENTS.packages.skids.first().height)
						, length: ceiling(ARGUMENTS.packages.skids.first().length)
						, width: ceiling(ARGUMENTS.packages.skids.first().width)
						, unitprice:val(LOCAL.estshipping.rate + LOCAL.guaranteedSurcharge)
					})>
				</cfif>
				<cfset logonly = true>
				<cfinclude template="/partnernet/irongate/irongate.cfm">
			</cfcatch>
		</cftry>

		<cfreturn estimatedshipping>
	</cffunction>

	<cffunction name="getLiveShippingRate" access="private" returntype="struct">
		<cfargument name="packages" type="struct" required=true>
		<cfargument name="orderID" type="String" required=true>
		<cfargument name="vendorID" type="numeric" required=true>
		<cfargument name="carrierID" type="numeric" required=true>
		<cfargument name="shippingoptions" type="String" required=true>
		<cfargument name="locationID" type="boolean" required=true>
		<cfargument name="locationTypeID" type="boolean" required=true>

		<cfset var fulfillmentRepository = new contexts.Shipping.DataAccess.DatabaseFulfillmentRepository()>
		<cfset var orderRepository = new contexts.Order.DataAccess.DatabaseOrderRepository()>
		<cfset var checkoutDetails = orderRepository.getCheckoutDetails(arguments.orderID)>
		<cfset var isFreight = arguments.packages.isFreight>
		<cfset var shipDate = dateCompare(checkoutDetails.requestedShipDate,now(),'d') == -1 ? dateFormat(now(), 'yyyy-mm-dd') : checkoutDetails.requestedShipDate>
		<cfset var args = {
			'origin': fulfillmentRepository.getFulfillmentOrigin3(arguments.locationTypeID, arguments.locationID).origin,
			'destination': deserializeJSON(checkoutDetails.destination),
			'carriers': fulfillmentRepository.getCarrierNames(arguments.carrierID),
			'boxingResult': arguments.packages,
			'shipdate': shipDate,
			'accessorials': listToArray(arguments.shippingoptions).map(function(e) {
				if(arguments.e == 'RES') {
					return 'residential';
				}
				if(arguments.e == 'INSIDE') {
					return 'insidedelivery';
				}
				return lCase(arguments.e);
			})
		}>
		<cfif isEmpty(args.accessorials)>
			<cfset args.accessorials = ['notify']>
		</cfif>
		<cfset var rateService = application.wirebox.getInstance('CarrierRateRequestService')>
		<cfset var rates = rateService.getRates(args.carriers.first().carrierName, args)>

		<cfset var rateName = isFreight ? 'Standard' : 'Ground Shipping'>
		<cfif isFreight && checkoutDetails.hasGuaranteed>
			<cfset rateName = checkoutDetails.shipby == 'Express Delivery AM' ? 'GuaranteedAM' : 'Guaranteed'>
		</cfif>
		<cfif !isFreight && checkoutDetails.shipby == 'Two Day/Express'>
			<cfset rateName = '2 Day Air'>
		</cfif>
		<cfif !isFreight && checkoutDetails.shipby == 'One Day/Expedited'>
			<cfset rateName = 'Overnight'>
		</cfif>
		<cfif arguments.carrierID == 195>
			<cfset rateName = 'Guaranteed'>
		</cfif>
		<cfset this.liveRates = rates>
		<cfset var selectedRate = isFreight ? rates.Rates[rateName].first() : rates.Rates.Standard.filter((e) => arguments.e.Name == rateName).first()>

		<cfif checkoutDetails.hasGuaranteed && dateCompare(checkoutDetails.GuaranteedDate, selectedRate.EstimatedDate, 'd') == 1>
			<cfset shippingHelper = application.wirebox.getInstance('ShippingHelper')>
			<!--- <cfset this.requestedshipdate = shippingHelper.calculateGuaranteedShipDate(checkoutDetails.GuaranteedDate,selectedRate.ServiceDays)> --->
		</cfif>

		<cfreturn {
				  weight:ceiling(arguments.packages.weight)
				, height:''
				, length:''
				, width: ''
				, unitprice: selectedRate.Total
		}>
	</cffunction>

	<cffunction name="generateTrackingNumberIfNeeded" returntype="void">
		<cfargument name="totals" type="struct" default="#this.gettotalcosts()#">

		<cfif !arguments.totals.hasEmptyTracking && !len(arguments.totals.trackingNums)>
			<cfset var newNum = "">
			<cfset freightCarriers = QueryExecute("SELECT CarrierID FROM tblCarriers WHERE isfreight = 1 AND active = 1", {}, { datasource: 'ahapdb', cachedWithin: CreateTimespan(0,1,0,0)})>
			<cfif arguments.totals.isFreight || listFind(freightCarriers.valueList('carrierID'), this.carrierID)>
				<cfstoredproc procedure="getNewTrackingID" datasource="#this.DSN#">
					<cfprocparam type="IN" sqltype="INTEGER" value="#this.carrierID#">
					<cfprocparam type="IN" sqltype="INTEGER" value="#this.locationID#">
					<cfprocparam type="OUT" sqltype="VARCHAR" variable="newNum">
				</cfstoredproc>
			</cfif>
			<cfset this.lineItems.each(function(item,index){
				if(item.orderLineID || item.vendorprodnumber == 453075476){
					item.insertLineItemShipment(tracking = newNum, carrierID = this.carrierID);
				}
			})>
		</cfif>
	</cffunction>

	<cffunction name="getShippingTerminals" returntype="array">
		<cfreturn queryExecute("
				SELECT tt.Label, ct.Address, ct.City, ct.State, ct.PostalCode, ct.Telephone
				FROM tblVendorPOTerminals pot
				INNER JOIN tblVendorPOTerminalTypes tt ON pot.TerminalTypeID = tt.ID
				INNER JOIN CarrierTerminals ct ON pot.TerminalID = ct.ID
				WHERE pot.POID = :POID
				ORDER BY tt.Label DESC
			", {
				POID: {sqltype: 'VARCHAR', value: this.POID}
			}, {datasource: 'ahapdb', returnType: 'array'})>
	</cffunction>

	<cffunction name="getFulfillments" returntype="array">
		<cfreturn queryExecute("
			SELECT ID
			FROM CustomerPOFulfillments
			WHERE CustomerPONumericId = :POID AND Active = 1
		", {
			POID: {sqltype: 'VARCHAR', value: this.objID}
		}, {datasource: 'ahapdb', returnType: 'array'})>
	</cffunction>

	<cffunction name="getShippingChargeByPOID" returntype="any">
		<cfreturn queryExecute("
			SELECT top 1 t.amountbilled, t.ProNumber
			FROM tblFreightBills t
			WHERE t.POID = :POID
		", {
			POID: {sqltype: 'VARCHAR', value: this.POID}
		}, {datasource: 'ahapdb', returnType='array'})>
	</cffunction>

</cfcomponent>
