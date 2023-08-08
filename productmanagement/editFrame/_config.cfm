<cfparam name="attributes.tree" default="">

<cfset addNewPage = "/partnernet/productmanagement/addproduct_new.cfm">

<cffunction name="addpage" returntype="any">
<cfargument name="yourarray" type="array">
<cfargument name="menutext" type="string">
<cfargument name="URL" type="string">

	<cfset var newstruct= structnew()>

	<cfset newstruct.menutext = arguments.menutext>
	<cfset newstruct.URL = arguments.URL>

	<cfset ArrayAppend(yourarray,newstruct)>

	<cfreturn yourarray>
</cffunction>

<cffunction name="writeJS" returntype="any">
<cfargument name="yourarray" type="array">

	var iframeSrc = [];
	<cfloop from="1" to="#arraylen(yourarray)#" index="x">
	<cfoutput>iframeSrc[#x#] = '#iframeSrc[x].URL#';</cfoutput>
	</cfloop>


</cffunction>

<cffunction name="writemenuHTML" returntype="any">
<cfargument name="yourarray" type="array">

	<div id="thisTable">
		<cfloop from="1" to="#arraylen(yourarray)#" index=i>
		<cfoutput><a id="step#i#" target="_parent" href="default.cfm?currentStep=#i#">#yourarray[i].menutext#</a></cfoutput>
		</cfloop>
		<div id="tree" style="margin-right: 10px; margin-top: 5px; float: right;">
			<cfoutput>
			<form method="post" name="tree">
				<select name="tree" class="normal" onchange="changetree(this)">
					<option value="1" <cfif #attributes.tree# EQ 1>SELECTED</cfif>>Product Settings</option>
					<option value="3" <cfif #attributes.tree# EQ 3>SELECTED</cfif>>Extra Functions</option>
				</select>
			</form>
			</cfoutput>
		</div><div class="clear"></div>
	</div>
</cffunction>

<cffunction name="getProductUrl" returntype="string">
	<cfargument name="objID">
	<cfquery name="getUrl" datasource="#DSN#">
		SELECT '/product/' + [Route] AS 'url'
		FROM ProductRouting
		WHERE ProductID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#val(arguments.objID)#">
			AND RedirectID IS NULL
	</cfquery>

	<cfreturn '#application.responsiveEndpoint##getUrl.url#'>
</cffunction>

<cffunction name="getProduct" returntype="string">
	<cfargument name="objID">
	<cfquery name="get" datasource="#DSN#">
		SELECT manufacturer, modelNumber
		FROM Products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#val(arguments.objID)#">
	</cfquery>

	<cfreturn "#get.manufacturer# #get.modelnumber#">
</cffunction>

<cfset iframeSrc = ArrayNew(1)>

<cfif attributes.tree EQ 1>
	<cfset iframeSrc = addpage(iframeSrc,"Edit<br>Product","/templates/object.cfm?objecttype=product&action=edit&objID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Associate to <br>Inventory Item","/partnernet/productmanagement/listVendors.cfm?productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Inventory<br>Item","/partnernet/productmanagement/viewvendorproducts.cfm?productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Edit<br>Price","/partnernet/dynamicPricingTool/acceptancepanel.cfm?editP=1&showAll=true&productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Associate<br>Resources","/partnernet/productmanagement/editFrame/associateResources.cfm?productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Associate<br>Photos","/partnernet/productmanagement/editFrame/associatePhotos.cfm?productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Edit<br>Attributes","/partnernet/productmanagement/editFrame/editAttributes.cfm?productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Accessorize<br>Product","/partnernet/productManagement/accessorizeproducts.cfm?productID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Preview","productUrl")>
<cfelseif attributes.tree EQ 3>
	<cfset iframeSrc = addpage(iframeSrc,"Add<br>Categories","/partnernet/productmanagement/editFrame/add2ndcategory.cfm?objID=")>
	<cfset iframeSrc = addpage(iframeSrc,"Edit<br>Descriptions","/templates/object.cfm?objecttype=product&action=editdescriptions&objID=")>
</cfif>
