<!---
name: buildkit.cfm
Created By: Jason Todd
Created On: 12-1-2005
Notes:


Modified By:
Modified On:
Notes:

--->

<cfset screenID = "240">
<cfset recordhistory = 0>
<cfset popup=1>

<cfinclude template="/partnernet/shared/_header.cfm">

<!--- the master kit product that we're building --->
<cfparam name="attributes.step" default="1">
<cfparam name="attributes.prodID" default="">
<cfparam name="attributes.kitprodID" default="">
<cfparam name="attributes.quantity" default="1">
<cfparam name="attributes.showincart" default="1">

<!--- todo: call CFC to get product --->

<cfif IsDefined("attributes.remove")>
	<cfquery name="removeproduct" datasource="#DSN#">
		DELETE
		FROM tblProductKits
		WHERE kitmasterprodID = <cfqueryparam sqltype="INT" value="#attributes.prodID#">
			AND kitprodID = <cfqueryparam sqltype="INT" value="#attributes.kitprodID#">

		DELETE FROM InventoryItemLink 
		WHERE ProductID = <cfqueryparam sqltype="INT" value="#attributes.prodID#">
		AND EXISTS (
			SELECT TOP 1 InventoryItemID
			FROM InventoryItemLink iil
			WHERE ProductID = <cfqueryparam sqltype="INT" value="#attributes.kitprodID#">
				AND iil.InventoryItemID = InventoryItemLink.InventoryItemID
		)
	</cfquery>

	<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.prodID#" value="Kitted item #attributes.kitprodID# removed.">
</cfif>

<cfif IsDefined("attributes.add") AND attributes.prodID IS NOT attributes.kitprodID AND attributes.kitprodID IS NOT "">
	<cfif IsDefined("attributes.quantity") AND attributes.quantity GT 0>
		<cfquery name="insertkit" datasource="#DSN#">
			INSERT INTO tblProductKits (kitmasterprodID,kitprodID,kitprodqty,showincart)
			VALUES (#attributes.prodID#,#attributes.kitprodID#,#attributes.quantity#,#attributes.showincart#)

			INSERT INTO InventoryItemLink (ProductID, InventoryItemID, Quantity)
				SELECT 
					<cfqueryparam sqltype="INT" value="#attributes.prodID#">,
					InventoryItemID,
					<cfqueryparam sqltype="INT" value="#attributes.quantity#"> * Quantity
				FROM InventoryItemLink 
				WHERE ProductID = <cfqueryparam sqltype="INT" value="#attributes.kitprodID#">
		</cfquery>
	</cfif>

	<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.prodID#" value="Kitted item #attributes.kitprodID# added in qty #attributes.quantity#.">
</cfif>

<!-- update the average weight of the product including kit members -->
<cfquery name="updateavgweight" datasource="#DSN#">
	DECLARE @productID int
	SELECT @productID = <cfqueryparam sqltype="INT" value="#attributes.prodID#">

	UPDATE Products
	SET [weight] = ISNULL((
		SELECT SUM(pil.Quantity * ii.[Weight])
		FROM InventoryItemLink pil
		INNER JOIN InventoryItems ii ON ii.ID = pil.InventoryItemID
		WHERE pil.ProductID = Products.ID), 0)
	WHERE ID = @productID
</cfquery>

<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
<cfset productUpdatedPublisher.publish({ 'id': attributes.prodID })>

<cfquery name="getproduct" datasource="#DSN#">
	SELECT *
	FROM Products
	WHERE ID = <cfqueryparam sqltype="INT" value="#attributes.prodID#">
</cfquery>

<cfstoredproc procedure="cfc_getAllproducts_GroupedBy_CategoryID" datasource="#DSN#">
<cfprocresult name="listProducts">
</cfstoredproc>


<!--- display current associations --->
<!--- prodID & details, number used in kit --->
<cfquery name="getkitproducts" datasource="#DSN#">
SELECT tblProductKits.*,products.manufacturer,products.modelnumber
FROM tblProductKits INNER JOIN products ON tblProductKits.kitprodID = products.ID
WHERE kitmasterprodID = <cfqueryparam sqltype="INT" value="#attributes.prodID#">
</cfquery>

<cfset ExcludeIDs = ValueList(getkitproducts.kitprodID, ",")>
<cfset ExcludeIDs = listappend(getkitproducts.kitprodID,attributes.prodID,",")>

<div class="large"><A href="javascript:closethiswin();">Click to Close</A></div>

<script language="javascript">
function closethiswin() {
	if (window.opener && !window.opener.closed)
			window.opener.location.reload();

		window.close();
}
</script>

<cfif attributes.step EQ 1>
	<cfoutput>
		<!--- products --->
		<form method="post" action="#cgi.script_name#" name="tmpForm">
		<input type="hidden" name="step" value="1" />
		<input type="hidden" name="prodID" value="#attributes.prodID#" />
			 <strong>You are editing kit items for #getproduct.manufacturer# #getproduct.modelnumber# (#getproduct.listdescription#)</strong><br><br>
			 <table cellpadding="2" cellspacing="0" border="0">
			 	<tr>
					<td class="normal"></td>
					<td class="normal">Product</td>
					<td class="normal">Quantity</td>
					<td class="normal">Display to user?</td>
				</tr>

				<cfloop query="getkitproducts">
				 	<tr>
						<td class="normal">
							<a href="?prodID=#attributes.prodID#&remove=1&kitprodID=#getkitproducts.kitprodID#">Remove</a>
						</td>
						<td class="normal">
							#getkitproducts.manufacturer# #getkitproducts.modelnumber#
						</td>
						<td class="normal">
							#getkitproducts.kitprodqty#
						</td>
						<td class="normal">
							#yesnoformat(getkitproducts.showincart)#
						</td>
					</tr>
				 </cfloop>

			 	<tr>
					<td class="normal">
						<!--- <input type="submit" name="add" value="#getassocproducts.ID#"> --->
					</td>
					<td class="normal">
						 <div id="productdescription"></div>
						 <a href="javascript:openwin('/templates/scanproduct.cfm?sendID=kitprodID&formname=tmpForm&ExcludeIDs=#ExcludeIDs#&senddescription=productdescription','');">Add product association</a>
						 <input type="hidden" name="kitprodID" id="kitprodID">
					</td>
					<td class="normal">
						 <input type="text" name="Quantity" size="5" maxlength="5" value="1">
					</td>
					<td class="normal">
						<select name="showincart">
							<option value="1">Yes</option>
							<option value="0">No</option>
						</select>
					</td>
				</tr>

			 	<tr>
					<td class="normal"></td>
					<td class="normal">
						<input type="submit" name="add" value="Update Kit Products"><br><br>

					</td>
					<td class="normal"></td>
				</tr>

			 </table>
		</form>
	</cfoutput>
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">





