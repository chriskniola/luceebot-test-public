<cfsetting showdebugoutput="yes">

<cfset screenID = "240">

<cfparam name="attributes.objID" default="">
<cfparam name="attributes.manufacturer" default="">
<cfparam name="attributes.manufacturer2" default="">
<cfparam name="attributes.modelnumber" default="">
<cfparam name="attributes.listdescription" default="">
<cfparam name="attributes.unitcost" default="0">
<cfparam name="attributes.alpineprice" default="0">
<cfparam name="attributes.prdpackheight" default="5">
<cfparam name="attributes.prdpackwidth" default="5">
<cfparam name="attributes.prdpackdepth" default="5">
<cfparam name="attributes.weight" default="5">
<cfparam name="attributes.purchasingStatusID" default="4">
<cfparam name="attributes.submit" default="">

<cfif NOT isDefined("session.message")>
	<cfset session.message = "">
</cfif>

<cfif attributes.manufacturer2 NEQ "">
	<cfset attributes.manufacturer = attributes.manufacturer2>
</cfif>

<cfset attributes.alpineprice = Int(attributes.alpineprice) + 0.99>

<cfset addingsuccess = 0>

<cfinclude template="/partnernet/shared/_header.cfm">

<cfobject component="objects.product" name="product">
<cfif attributes.objID NEQ "">
	<cfinvoke component="#product#" method="get" objID="#attributes.objID#">
</cfif>

<cfif attributes.submit NEQ "" AND attributes.submit EQ "Submit">

	<!--- start product addition --->
	<cfscript>
		product.category = attributes.category;
		product.manufacturer = attributes.manufacturer;
		product.modelnumber = attributes.modelnumber;
		product.name = attributes.manufacturer & ' ' & attributes.modelnumber;
		product.listdescription = Left(attributes.listdescription, 255);
		product.prdpackheight = attributes.prdpackheight;
		product.prdpackwidth = attributes.prdpackwidth;
		product.prdpackdepth = attributes.prdpackdepth;
		product.weight = attributes.weight;
		product.includespremiumguarantee = 1;
		product.purchasingStatusID = attributes.purchasingStatusID;
		product.alpineprice = attributes.alpineprice;
		product.alpinesaleprice = 0;
		product.weight = attributes.weight;
	</cfscript>

	<cfset product.put()>

	<cfset attributes.objID = product.objID>

	<cfif attributes.objID NEQ "">
		<cfset addingsuccess = 1>
	</cfif>
	<!--- end product addition --->

	<!--- start inventory item record addition --->
	<cfquery name="exists" datasource="#DSN#">
		SELECT SKU
		FROM InventoryItems
		WHERE SKU = <cfqueryparam sqltype="VARCHAR" value="#attributes.objID#">
	</cfquery>

	<cfif exists.recordcount EQ 0>
		<cfscript>
			queryExecute("
				DECLARE @manufacturerId INT = (SELECT ID FROM Manufacturers WHERE Name = :manufacturer)

				MERGE INTO InventoryItems AS TARGET
				USING (VALUES
				(
				:id,
				:sku,
				@manufacturerId,
				:model,
				:shortDescription,
				:itemTypeID,
				:purchasingStatusID,
				:smallPack,
				:serialized,
				:shipFreight,
				:pickListPartNumber,
				NULL,
				:unitCost,
				:weight,
				:height,
				:width,
				:length,
				:createdBy,
				:packQuantity,
				:unitOfMeasure,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				:shipInMfgBoxSmallPack,
				:shipInMfgBoxFreight,
				:shipVerticalRotation,
				:shippable,
				NULL,
				NULL,
				:freightClassID,
				NULL,
				NULL,
				NULL
				)) AS SOURCE
				(
				ID,
					SKU,
					ManufacturerId,
					Model,
					ShortDescription,
					ItemTypeID,
					PurchasingStatusID,
					SmallPack,
					Serialized,
					ShipFreight,
					PickListPartNumber,
					UPC,
					UnitCost,
					Weight,
					Height,
					Width,
					Length,
					CreatedBy,
					PackQuantity,
					UnitOfMeasure,
					MfgBoxQuantity,
					MfgBoxWeight,
					MfgBoxHeight,
					MfgBoxWidth,
					MfgBoxLength,
					ShipInMfgBoxSmallPack,
					ShipInMfgBoxFreight,
					ShipVerticalRotation,
					Shippable,
					Skid,
					Nafta,
					FreightClassID,
					Nmfc,
					CustomsDescription,
					CountryOfMfr
				)
				ON Target.ID = Source.ID
				WHEN MATCHED THEN UPDATE
				SET
					Target.ManufacturerId = Source.ManufacturerId,
					Target.Model = Source.Model,
					Target.ShortDescription = Source.ShortDescription,
					Target.ItemTypeID = Source.ItemTypeID,
					Target.PurchasingStatusID = Source.PurchasingStatusID,
					Target.SmallPack = Source.SmallPack,
					Target.Serialized = Source.Serialized,
					Target.ShipFreight = Source.ShipFreight,
					Target.PickListPartNumber = Source.PickListPartNumber,
					Target.UPC = Source.UPC,
					Target.UnitCost = Source.UnitCost,
					Target.Weight = Source.Weight,
					Target.Height = Source.Height,
					Target.Width = Source.Width,
					Target.Length = Source.Length,
					Target.CreatedBy = Source.CreatedBy,
					Target.PackQuantity = Source.PackQuantity,
					Target.UnitOfMeasure = Source.UnitOfMeasure,
					Target.MfgBoxQuantity = Source.MfgBoxQuantity,
					Target.MfgBoxWeight = Source.MfgBoxWeight,
					Target.MfgBoxHeight = Source.MfgBoxHeight,
					Target.MfgBoxWidth = Source.MfgBoxWidth,
					Target.MfgBoxLength = Source.MfgBoxLength,
					Target.ShipInMfgBoxSmallPack = Source.ShipInMfgBoxSmallPack,
					Target.ShipInMfgBoxFreight = Source.ShipInMfgBoxFreight,
					Target.ShipVerticalRotation = Source.ShipVerticalRotation,
					Target.Shippable = Source.Shippable,
					Target.Skid = Source.Skid,
					Target.Nafta = Source.Nafta,
					Target.FreightClassID = Source.FreightClassID,
					Target.Nmfc = Source.Nmfc,
					Target.CustomsDescription = Source.CustomsDescription,
					Target.CountryOfMfr = Source.CountryOfMfr

				WHEN NOT MATCHED THEN INSERT
				(SKU,
					ManufacturerId,
					Model,
					ShortDescription,
					ItemTypeID,
					PurchasingStatusID,
					SmallPack,
					Serialized,
					ShipFreight,
					PickListPartNumber,
					UPC,
					UnitCost,
					Weight,
					Height,
					Width,
					Length,
					CreatedBy,
					PackQuantity,
					UnitOfMeasure,
					MfgBoxQuantity,
					MfgBoxWeight,
					MfgBoxHeight,
					MfgBoxWidth,
					MfgBoxLength,
					ShipInMfgBoxSmallPack,
					ShipInMfgBoxFreight,
					ShipVerticalRotation,
					Shippable,
					Skid,
					Nafta,
					FreightClassID,
					Nmfc,
					CustomsDescription,
					CountryOfMfr
				) VALUES (
					Source.SKU,
					Source.ManufacturerId,
					Source.Model,
					Source.ShortDescription,
					Source.ItemTypeID,
					Source.PurchasingStatusID,
					Source.SmallPack,
					Source.Serialized,
					Source.ShipFreight,
					Source.PickListPartNumber,
					Source.UPC,
					Source.UnitCost,
					Source.Weight,
					Source.Height,
					Source.Width,
					Source.Length,
					Source.CreatedBy,
					Source.PackQuantity,
					Source.UnitOfMeasure,
					Source.MfgBoxQuantity,
					Source.MfgBoxWeight,
					Source.MfgBoxHeight,
					Source.MfgBoxWidth,
					Source.MfgBoxLength,
					Source.ShipInMfgBoxSmallPack,
					Source.ShipInMfgBoxFreight,
					Source.ShipVerticalRotation,
					Source.Shippable,
					Source.Skid,
					Source.Nafta,
					Source.FreightClassID,
					Source.Nmfc,
					Source.CustomsDescription,
					Source.CountryOfMfr
				);
			",{
				id: { sqltype:'INT', value: attributes.objID },
				sku: { sqltype: 'VARCHAR', value: attributes.objID },
				manufacturer: { sqltype: 'VARCHAR', value: attributes.manufacturer },
				model: { sqltype: 'VARCHAR', value: attributes.modelnumber },
				shortDescription: { sqltype: 'VARCHAR', value: attributes.listdescription },
				itemTypeID: { sqltype: 'TINYINT', value: 10 },
				purchasingStatusID: { sqltype: 'VARCHAR', value: attributes.purchasingStatusID },
				smallPack: { sqltype: 'BIT', value: 0 },
				serialized: { sqltype: 'BIT', value: 0 },
				shipFreight: { sqltype: 'BIT', value: 0 },
				pickListPartNumber: { sqltype: 'VARCHAR', value: attributes.objID },
				unitCost: { sqltype: 'DECIMAL', value: attributes.unitcost },
				weight: { sqltype: 'DECIMAL', value: attributes.weight },
				width: { sqltype: 'DECIMAL', value: attributes.prdpackwidth },
				height: { sqltype: 'DECIMAL', value: attributes.prdpackheight },
				length: { sqltype: 'DECIMAL', value: attributes.prdpackdepth },
				createdBy: { sqltype: 'INT', value: session.user.ID },
				packQuantity: { sqltype: 'INT', value: 1 },
				unitOfMeasure: { sqltype: 'INT', value: 1 },
				shipInMfgBoxSmallPack: { sqltype: 'BIT', value: 0 },
				shipInMfgBoxFreight: { sqltype: 'BIT', value: 0 },
				shipVerticalRotation: { sqltype: 'BIT', value: 1 },
				shippable: { sqltype: 'BIT', value: 1 },
				freightClassID: { sqltype: 'TINYINT', value: 5 }
			}, { datasource:'ahapdb' });
		</cfscript>
	<cfelse>
		<cfset session.message = session.message & "An inventory item record already exists for this product.\n">
	</cfif>

	<cfquery name="update" datasource="#DSN#">
		IF NOT EXISTS (SELECT ProductID FROM InventoryItemLink WHERE ProductID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.objID#">)
		BEGIN
			DECLARE @inventoryItemId INT = (SELECT ID FROM InventoryItems WHERE SKU = convert(varchar(20), <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.objID#">))
			INSERT INTO InventoryItemLink (ProductID, InventoryItemID, Quantity)
			VALUES (<cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.objID#">, @inventoryItemId, 1)

			EXEC UpdateInventoryStock @inventoryItemId
		END
	</cfquery>

	<cfscript>
		if(update.recordCount) {
			application.wirebox.getInstance('ProductInventoryUpdatedPublisher').publish({
				'ids': update.columnData('ProductID')
			});
		}
	</cfscript>

	<cfinvoke component="objects.objectutils" method="putlog" objID="#product.objID#" value="#attributes.objID# association add/update">
</cfif>

<script type="text/javascript">
	function checkForm() {
		var frmWp = document.forms['warrantyproduct'];

		if (frmWp.manufacturer.value == '' && frmWp.manufacturer2.value == '') {
			alert( "A manufacturer is required.");
			frmWp.manufacturer.focus();
		return false ;
		}

		if (frmWp.modelnumber.value == '') {
			alert( "A model number is required.");
			frmWp.manufacturer.focus();
		return false ;
		}

		if (frmWp.listdescription.value == '') {
			alert( "A list description is required.");
			frmWp.listdescription.focus();
		return false ;
		}

		if (frmWp.unitcost.value == '') {
			alert( "A cost is required.");
			frmWp.unitcost.focus();
		return false ;
		}

		if (frmWp.alpineprice.value == '') {
			alert( "A price is required.");
			frmWp.alpineprice.focus();
		return false ;
		}

		if (frmWp.prdpackheight.value == '' || frmWp.prdpackheight.value == '0') {
			alert( "The product height is required.");
			frmWp.prdpackheight.focus();
		return false ;
		}

		if (frmWp.prdpackwidth.value == '' || frmWp.prdpackwidth.value == '0') {
			alert( "The product width is required.");
			frmWp.prdpackwidth.focus();
		return false ;
		}

		if (frmWp.prdpackdepth.value == '' || frmWp.prdpackdepth.value == '0') {
			alert( "The product depth is required.");
			frmWp.prdpackdepth.focus();
		return false ;
		}

		if (frmWp.weight.value == '' || frmWp.weight.value == '0') {
			alert( "The product weight is required.");
			frmWp.weight.focus();
		return false ;
		}

		return true;
	}

	function clearForm() {
		document.warrantyproduct.manufacturer.value = '';
		document.warrantyproduct.manufacturer2.value = '';
		document.warrantyproduct.modelnumber.value = '';
		document.warrantyproduct.listdescription.value = '';
		document.warrantyproduct.unitcost.value = '0';
		document.warrantyproduct.alpineprice.value = '0';
		document.warrantyproduct.prdpackheight.value = '5';
		document.warrantyproduct.prdpackwidth.value = '5';
		document.warrantyproduct.prdpackdepth.value = '5';
		document.warrantyproduct.weight.value = '5';
		document.warrantyproduct.vendor.value = '';
		document.warrantyproduct.objID.value = '';

		var div = document.getElementById('idsuccess');
		if (div != null) {
			div.parentNode.removeChild(div);
		}
		div = document.getElementById('clearlink');
		if (div != null) {
			div.parentNode.removeChild(div);
		}
	}

	function getRecommended() {
		var frmWp = document.forms['warrantyproduct'];
		var theid = '<cfoutput>#attributes.objID#</cfoutput>';
		var myTotal = 0;
		var sCost = parseFloat(frmWp.unitcost.value);

		var path = 'editFrame/ajax_getretail.cfm?productID=' + theid + '&cost=' + sCost;
		j$.ajax(path,{
			method: 'get',
			onSuccess: function(transport) {
				myTotal = parseInt(transport.responseText);
				frmWp.alpineprice.value = myTotal;
			}
		});
	}
</script>

<cfquery name="mfglist" datasource="#DSN#">
	SELECT manufacturer
	FROM Products WITH (NOLOCK)
	GROUP BY manufacturer
	ORDER BY manufacturer
</cfquery>

<cfscript>
	var purchasingStatuses = QueryExecute("SELECT * FROM PurchasingStatus", {}, {datasource: 'ahapdb'});
</cfscript>

<cfoutput>
	<div class="options">
		<form name="warrantyproduct" method="post" onsubmit="return checkForm();">
			<table align="center">
				<cfif isDefined("addingsuccess") AND addingsuccess EQ 1>
					<tr>
						<td colspan="2">
						<div class="successbox" id="idsuccess">
							Successfully added as #attributes.objID#!<br>
							<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#attributes.objID#','',800,1100);">Edit</a> #attributes.manufacturer# #attributes.modelnumber# in the product wizard.
						</div>
						</td>
					</tr>
				</cfif>
				<tr>
					<th colspan="2" style="text-align: center;"><h2>Basic Warranty Part Info</h2></th>
				</tr>
				<tr>
					<td colspan="2">
						Product will be placed in the "Miscellaneous" category under "Replacement Parts".<br>
						Product price will be applied the regular price (not the sale price).<br>
						Product will not include free shipping.<br>
						<br>
					</td>
				</tr>
				<tr>
					<td>Manufacturer:</td>
					<td>
						<select name="manufacturer" tabindex=1>
						<option value=""></option>
						<cfloop query="mfglist">
						<option value="#manufacturer#"<cfif manufacturer EQ attributes.manufacturer> SELECTED</cfif>>#manufacturer#</option>
						</cfloop>
						</select>
						or <input type="text" name="manufacturer2" size="26" tabindex=13></input>
					</td>
				</tr>
				<tr>
					<td>Model Number:</td>
					<td><input type="text" name="modelnumber" value="#attributes.modelnumber#" tabindex=2></input></td>
				</tr>
				<tr>
					<td>List Description:</td>
					<td><input type="text" name="listdescription" size="70%" value="#attributes.listdescription#" tabindex=3></input></td>
				</tr>
				<tr>
					<td>Cost:</td>
					<td><input type="text" name="unitcost" size="5" value="#attributes.unitcost#" tabindex=4></input></td>
				</tr>
				<tr>
					<td>Price:</td>
					<td><input type="text" name="alpineprice" size="2" value="#Int(attributes.alpineprice)#" tabindex=5></input>.99 - <a href="javascript:getRecommended();">Get Recommended</a></td>
				</tr>
				<tr>
					<td>Height:</td>
					<td><input type="text" name="prdpackheight" size="2" value="#attributes.prdpackheight#" tabindex=6></input> Inches</td>
				</tr>
				<tr>
					<td>Width:</td>
					<td><input type="text" name="prdpackwidth" size="2" value="#attributes.prdpackwidth#" tabindex=7></input> Inches</td>
				</tr>
				<tr>
					<td>Depth:</td>
					<td><input type="text" name="prdpackdepth" size="2" value="#attributes.prdpackdepth#" tabindex=8></input> Inches</td>
				</tr>
				<tr>
					<td>Weight:</td>
					<td><input type="text" name="weight" size="2" value="#attributes.weight#" tabindex=9></input> Pounds</td>
				</tr>
				<tr>
					<td>Purchasing Status:</td>
					<td>
						<select id="purchasingStatusID" name="purchasingStatusID" tabindex=10>
							<option value="">Please select a purchasing status</option>
							<cfloop query="#purchasingStatuses#">
								<option value="#ESAPIEncode('html_attr', purchasingStatuses.ID)#" <cfif purchasingStatuses.ID == attributes.purchasingStatusID>SELECTED</cfif>>#ESAPIEncode('html', purchasingStatuses.Label)#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td>
						<input name="submit" type="submit" value="Submit" tabindex=12>
					</td>
					<td style="vertical-align:middle;">
						<cfif isDefined("addingsuccess") AND addingsuccess EQ 1>
							<div id="clearlink"><a href="##" onClick="javascript:clearForm();" style="font-size: 16px; font-weight: bold;">Clear Form</a></div>
						</cfif>
					</td>
				</tr>
			</table>
			<input type="hidden" name="category" value="476"></input>
			<input type="hidden" name="objID" value="#attributes.objID#"></input>
		</form>
	</div>
</cfoutput>

<cfinclude template="/partnernet/shared/_footer.cfm">
