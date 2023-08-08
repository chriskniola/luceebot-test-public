<cfsetting showdebugoutput="No">
<cfset screenID = "300">

<cfscript>
	var finalPath = "";
	var isKit = queryExecute("
			SELECT * FROM tblproductkits
			WHERE kitmasterprodID = :productID
		", {
			productID: { value: url.productID, sqltype: "INT"}
		}, {datasource = DSN}).recordcount;

	var inventoryItemFromProductID = queryExecute("
		SELECT ii.id FROM InventoryItems ii
		INNER JOIN InventoryItemLink iil on iil.InventoryItemID = ii.ID
		WHERE iil.ProductID = :productID
	", {
		productID: { value: url.productID, sqltype: "INT"}
	}, {datasource = DSN});

	if (inventoryItemFromProductID.recordCount) {
		endpoint = CreateObject("java", "java.lang.System").getEnv('imsEndpoint');
		urlPath = 'item/#inventoryItemFromProductID.rowData(1).id#';
		finalPath = "#endpoint#/#urlPath#";
	}
</cfscript>
<cfoutput>
	<div class="wrap">
		<cfif isKit>
			<h2 style="text-align: center;">This product is a kit.</h2>
			<p style="text-align: center;">Edit the kit items to change inventory item data.</p>
		<cfelseif !finalPath.len()>
			<h2 style="text-align: center;">This product is not linked to an inventory Item.</h2>
		<cfelse>
			<iframe id="ims" class="child" src="#finalPath#" frameborder="0" style="width: 100%;height: 100%"></iframe>
		</cfif>
	</div>
</cfoutput>
