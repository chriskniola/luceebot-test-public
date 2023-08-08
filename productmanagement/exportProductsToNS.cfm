<cfsetting requesttimeout="360" showdebugoutput="false">

<cfparam name="attributes.submit" default="">
<cfparam name="attributes.date" default="">
<cfparam name="attributes.active" default=0>
<cfparam name="attributes.ProductID" default=0>
<cfparam name="attributes.Mfg" default="">
<cfset screenid = "1090">

<cfinclude template="/partnernet/shared/_header.cfm">
<script language="javascript" src="/partnernet/shared/javascripts/productSearch.js"></script>
<script language="javascript">

function addValues(values){
	var notFound;
	var myOptions = $('products').options;
	for(var x=0;x<values.length;x++){
		notFound = 1;
		for(var y=0;y<myOptions.length;y++){
			if(myOptions[y].value == values[x].data.id){
				notFound = 0;
			}
		}
		if(notFound){
			var optionName = values[x].data.category;
			if (values[x].data.manufacturer.length) optionName += ' ' + values[x].data.manufacturer + ' - ';
			optionName += ' ' + values[x].data.model;
			myOptions[myOptions.length] = new Option(optionName, values[x].data.id);
		}
	}
};


function removeValues(values){
	var notFound;
	var myOptions = $('products').options;
	for(var y=0;y<myOptions.length;y++){
		if(myOptions[y].selected){
			myOptions[y] = null;
			y--;
		}
	}
};


function selectAll(){
	var myOptions = $('products').options;
	for(var y=0;y<myOptions.length;y++){
		myOptions[y].selected = true;
	}
}


</script>
<script src="/partnernet/shared/javascripts/calendar.js"></script>
<!--- <cfif attributes.date IS "" AND attributes.submit NEQ "submit">
	<cfset attributes.date = DateFormat(DateAdd("m",-1,Now()),"mm/dd/yyyy")>
</cfif> --->
<cfoutput>
<H1>Generate File for NetSuite Product Import</H1><br>

<form name="form1" method="post" action="##winky" onsubmit="selectAll();">
<cfquery name="listProducts" datasource="#DSN#" cachedwithin="#createtimespan(0, 1, 0, 0)#">
SELECT p.ID, manufacturer, modelNumber, p.active, pc.listName
FROM products p WITH (NOLOCK)
Left Join productCategories pc WITH (NOLOCK)
	ON p.Category = pc.ID
WHERE p.ID IN (<cfqueryparam cfsqltype="CF_SQL_INTEGER" list=true value="#ATTRIBUTES.ProductID#">)
</cfquery>

<cfquery name="getMfgs" datasource="#DSN#" cachedwithin="#createtimespan(0, 4, 0, 0)#">
SELECT manufacturer AS Mfg, count(id) as prodCount
FROM products WITH (NOLOCK)
GROUP BY manufacturer
ORDER BY manufacturer
</cfquery>

<a name="winky"></a>
<div class="options">
	<div class="tabHeader">
		<div class="tabContent">
			<div class="tabTitle">Search By Product</div>
			<table>
				<tr>
					<td>
						<select name="ProductID" size="20" id='products' style="width:500px; height:300px;" multiple>
						 	<cfloop query="listProducts">
					 			<cfoutput><option value="#listProducts.ID#" SELECTED>#listProducts.ListName# - #listProducts.Manufacturer#<cfif Len(listProducts.Manufacturer)> - </cfif>#listProducts.ModelNumber# <cfif NOT val(listproducts.active)>(inactive)</cfif> </option></cfoutput>
							</cfloop>
						 </select>
					</td>
					<td>
						<input type="button" onClick="ProductSearch.show(addValues);" value="Select Products" style="width:150px;"/><br>
						<input type="button" onClick="removeValues();" value="Remove Products" style="width:150px;"/><br />
						<span class="tiny bold">(hold down ctrl-key to select multiple)</span><br />
					</td>
				</tr>
			</table>
		</div>
		<div class="tabContent<cfif attributes.productID EQ '0'> tabSelected</cfif>">
			<div class="tabTitle">Search By Mfg</div>
			<select name="Mfg" id="mfgs">
			 	<cfloop query="getMfgs">
		 			<cfoutput><option value="#getMfgs.Mfg#"<cfif attributes.mfg EQ getMfgs.Mfg> selected="true"</cfif>>#getMfgs.Mfg# (#getMfgs.prodCount#)</option>
					</cfoutput>
				</cfloop>
			 </select>
		</div>
	</div>

<br>
	<table cellspacing="15">
		<tr>
			<td valign="bottom">
				<label for="date">Created On/After:</label><br><input type="text" name="date" VALUE="#attributes.date#" class="dateField">
			</td>
			<td valign="bottom" align="center">
				<label for="active">Only Active Products:</label><br><input type="checkbox" name="active" VALUE="1" <cfif attributes.active>CHECKED</cfif>>
			</td>
			<td valign="bottom">
				<input type="submit" name="submit" value="Submit" style="margin-bottom:0;">
			</td>
		</tr>
	</table>
	<br>
</form>
</cfoutput>

<cfif Isdefined("attributes.submit") AND attributes.submit EQ "submit">
	<cfquery name="getproducts" datasource="#DSN#">
	SELECT DISTINCT p.ID as AlpineID
		,p.Manufacturer + ' ' + p.ModelNumber AS AlpineDisplayName
		,CASE WHEN p.isconcealed = 1 THEN p.cmfg ELSE p.Manufacturer END AS ActualManufacturer
		,CASE WHEN p.isconcealed = 1 THEN p.cmodel ELSE p.ModelNumber END AS ActualModelNumber
		,CASE WHEN p.isconcealed = 1 THEN p.cmfg + ' ' + p.cmodel ELSE p.Manufacturer + ' ' + p.ModelNumber END AS AlpineDisplayNameUnconcealed
		,RTRIM(v.manufacturer) + ' ' + v.mfgnumber as YellowDisplayName
		,RTRIM(v.manufacturer) + ' ' + v.mfgnumber as PurchaseDescription
		,p.listdescription as SalesDescription
		,v.picklistpartnumber as PickTicketCode
		,v.packHeight as Height
		,v.packLength as Length
		,v.packWidth as Width
		,v.weight as Weight
		,v.packquantity AS PackQty
		,v.PUOM as UnitOfMeasure
		,v.isSerialized
	FROM Products p WITH (NOLOCK)
	LEFT OUTER JOIN tblVendorAlpineProducts a WITH (NOLOCK) ON p.ID = a.productID AND a.vendorID =24
	LEFT OUTER JOIN tblVendorProducts v WITH (NOLOCK) ON a.vendorpartnumber = v.prodnumber AND v.vendorID = 24
	INNER JOIN ProductCategories c WITH (NOLOCK) ON p.category = c.ID
	WHERE p.category <> 96
	<cfif attributes.productid NEQ "" AND attributes.productID NEQ 0>
	 	AND p.id IN (<cfqueryparam cfsqltype="CF_SQL_INTEGER" list="true" value="#attributes.productid#">)
	<cfelseif attributes.mfg NEQ "">
		AND p.manufacturer = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attributes.mfg#">
	</cfif>
	<cfif attributes.date NEQ "">
		AND p.prdCreated > '#dateformat(attributes.date,"mm/dd/yyyy")#'
	</cfif>
	<cfif attributes.active>
		AND p.active = 1
	</cfif>

	</cfquery>

	<cfif getproducts.recordcount GT 0>
		<cfinvoke component="alpine-objects.report" method="display" recordset="#getproducts#" format="CSV" title="NetSuiteProducts#dateformat(now(),'yyyymmdd')#_#timeformat(now(),'HHmmss')#"
					savetopath="#session.user.userfolderpath#"
					columnorder="AlpineID,AlpineDisplayName,ActualManufacturer,ActualModelNumber,AlpineDisplayNameUnconcealed,YellowDisplayName,PurchaseDescription,SalesDescription,PickTicketCode,Height,Length,Width,Weight,PackQty,UnitOfMeasure,isSerialized"
					outputtobrowser="false"
					returnvariable="productresults"/>


		<cfoutput><li><a href="#session.user.userfolderpathURL##productresults.filename#">Netsuite Products Import File</a></li></cfoutput>

	</cfif>
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">