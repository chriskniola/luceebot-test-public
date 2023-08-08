<cfset screenID = "240">

<cfinclude template="/partnernet/shared/_header.cfm">

<cfparam name="attributes.submit" default="">
<cfparam name="attributes.format" default="html">

<cfoutput>
<form method="post" action="#CGI.script_Name#" name="searchform">
<div class="options">
<table>
	<tbody>
		<tr>
			<th colspan="2">Download all Alpine Products with Associated Vendor Products</th>
		</tr>
		<tr>
			<th>Includes basic shipping attributes.</th>
			
		</tr>					
		
		<tr>
			<th>&nbsp;</th>
			<td><input type="submit" value="Create Report" name="submit"></td>
		</tr>
	</tbody>
</table>
</div>			
</form>

</cfoutput>		

<cfif Isdefined("attributes.submit") AND attributes.submit IS NOT "">
	
	<cfquery name="getproducts" datasource="#DSN#">
	SELECT p.active
		,p.ID AS 'productID'
		,p.manufacturer
		,p.modelnumber
		,p.isgeneric
		,p.prdincludes_freeshipping
		,p.prdincludes_contractorassist
		,p.prdincludes_freevideo
		,p.prdincludes_premiumguarantee
		,p.naftacertlink
		,v.NAFTA AS 'overridenafta'
		,'' AS 'vendorID'
		,'' as 'vendorname'
		,v.SKU AS 'prodnumber'
		,v.ShipInMfgBoxSmallPack AS 'shipinmfgboxsc'
		,v.ShipInMfgBoxFreight AS 'shipinmfgboxfc'
		,v.ShipFreight AS 'shipfreight'
		,'' AS 'stockflag'
		,p.prdmodified
		,u.firstname + ' ' + left(lastname,1) + '.' AS 'createdby'
		,v.UnitOfMeasure AS 'vendorRoundBy'
		,va.Quantity AS 'VAPackQty'
		,v.Height AS 'height'
		,v.Width AS 'width'
		,v.Length AS 'length'
		,v.Weight AS 'weight'
		,1 AS 'associated'
	FROM products p WITH (NOLOCK)
		INNER JOIN InventoryItemLink va WITH (NOLOCK) ON p.ID = va.productID
		INNER JOIN InventoryItems v WITH (NOLOCK) ON va.InventoryItemID = v.ID
		LEFT JOIN tblSecurity_Users u WITH (NOLOCK) ON p.prdcreatedby = u.ID
	</cfquery>
	
	<cfset columnorder = "active,createdby,isgeneric,productID,manufacturer,modelnumber,naftacertlink,overridenafta,prdincludes_contractorassist,prdincludes_Freeshipping,prdincludes_freevideo,prdincludes_premiumguarantee,prdmodified,prodnumber,shipfreight,shipinmfgboxfc,shipinmfgboxsc,stockflag,associated,vendorID,vendorname,VAPackQty,vendorRoundBy,weight,height,width,length">
	
	<cfinvoke component="alpine-objects.report" method="display" columnorder="#columnorder#" recordset="#getproducts#" format="CSV" returnvariable="result"></cfinvoke>

</cfif>



<cfinclude template="/partnernet/shared/_footer.cfm">