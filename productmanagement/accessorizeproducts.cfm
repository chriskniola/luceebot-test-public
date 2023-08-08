<cfsetting showdebugoutput="true">
<!--- select a given product category to apply accessories to --->
<!--- then select another product category to get the accessories from --->
<!--- grid is displayed with the product's accessories --->

<cfparam name="attributes.categoryID" default="">
<cfparam name="attributes.accessorycategoryID" default = "">
<cfparam name="attributes.showInactiveProducts" default = "0">
<cfparam name="attributes.showInactiveAccessories" default = "0">
<cfparam name="attributes.isobsolete" default = "0">
<cfset showSideNav=0>

<cfif isdefined("attributes.productID") AND attributes.categoryID IS "">
	<cfquery name="getcategoryID" datasource="#DSN#">
		SELECT category
		FROM Products
			WHERE ID = '#attributes.productID#'
		ORDER BY name;
	</cfquery>
	<cfif getcategoryID.recordCount>
		<cfset attributes.categoryID = getcategoryID.category>
	</cfif>
</cfif>

<cfquery name="getcategory" datasource="#DSN#">
	SELECT ID, listname
	FROM Productcategories
	WHERE ID = <cfif attributes.categoryID IS NOT "">#attributes.categoryID#<cfelse>10000</cfif>
</cfquery>
<cfset selectedCatName = "">
<cfif getcategory.recordcount>
	<cfset selectedCatName = getcategory.listName>
</cfif>
<cfquery name="getaccessorycategory" datasource="#DSN#">
	SELECT ID, listname
	FROM Productcategories
	WHERE ID = <cfif attributes.accessorycategoryID IS NOT "">#attributes.accessorycategoryID#<cfelse>10000</cfif>
</cfquery>
<cfset selectedAccCatName = "">
<cfif getaccessorycategory.recordcount>
	<cfset selectedAccCatName = getaccessorycategory.listName>
</cfif>

<cfquery name="relatedCats" datasource="#DSN#">
	SELECT pc.Name, pc.ID
	FROM Products p WITH (NOLOCK)
	INNER JOIN tblProductAssociations a WITH (NOLOCK) ON a.prdID = p.ID
	INNER JOIN products p2 WITH (NOLOCK) ON p2.ID = a.prdRelative
	INNER JOIN ProductCategories pc (NOLOCK) ON pc.ID = p2.category
	WHERE a.ascType = 'R'
	AND pc.active = 1
	AND p.category = <cfif attributes.categoryID NEQ "">#attributes.categoryID#<cfelse>10000</cfif>
	GROUP BY pc.Name, pc.ID
	ORDER BY COUNT(*) DESC
</cfquery>

<cfset screenID = 240>
<cfset recordhistory = 0>
<cfinclude template="/partnernet/shared/_header.cfm">
<style>

	.box{
		border: 1px solid silver;
		padding: 4px;
		margin: 2px;
	}

	.closeBox{
		font-size: 8px;
		line-height: 7px;
		border: 1px solid;
		position: absolute;
		top: 1px;
		right: 1px;
		padding: 1px;
		cursor: hand;
	}

	.thism4{
		margin: 4px;
	}

	.title{
		font-weight: bold;
		padding: 4px;
		background-color: #efefff;
		margin-bottom: 8px;
	}

	#popup{
		position: absolute;
		background-color: white;
		width: 600px;
	}

	#popup select{
		width: 590px;
		height: 400px;
	}

	#criteria{
		width: 310px;
	}

	#catTo, #catFrom{
		width: 55%;
		padding: 4px;
	}
	#catToShell, #catFromShell{
		width: 300px;
		float: left;
		margin: 0px 10px 10px 0px;
	}
</style>

<script language="JavaScript">

	function hic(thecolID,thisCol){
		var topCol, nextCol, headerRows
		topCol = document.getElementById(thecolID);
		topCol.style.backgroundColor = "#FFA1A1";
		if(!topCol.onmouseout) topCol.onmouseout = function(){unhic(thecolID)};
		if(thisCol && !thisCol.onmouseout) thisCol.onmouseout = function(){unhic(thecolID)};
		headerRows = document.getElementById('bigOtable').getElementsByTagName('tr');
		headerRows = (headerRows.length-2) / 21;
		for (i = 1; i < headerRows; i++){
			nextCol = document.getElementById(thecolID + i);
			nextCol.style.backgroundColor = "#FFA1A1";
			if(!nextCol.onmouseout)nextCol.onmouseout = function(){unhic(thecolID)};
		}
	}

	function unhic(thecolID){
		var headerRows = document.getElementById('bigOtable').getElementsByTagName('tr');
		headerRows = (headerRows.length-2) / 21;
		document.getElementById(thecolID).style.backgroundColor = "#FFFFFF";
		for (i = 1; i < headerRows; i++)
			document.getElementById(thecolID + i).style.backgroundColor = "#FFFFFF";
	}

	function hic2(thecolID,thisCol){
		var topCol, nextCol, headerRows
		topCol = document.getElementById(thecolID);
		topCol.style.backgroundColor = "#FFA1A1";
		if(!topCol.onmouseout) topCol.onmouseout = function(){unhic2(thecolID)};
		if(thisCol && !thisCol.onmouseout) thisCol.onmouseout = function(){unhic2(thecolID)};
		headerRows = document.getElementById('bigOtable').getElementsByTagName('tr');
		headerRows = (headerRows.length-2) / 21;
		for (i = 1; i < headerRows; i++){
			nextCol = document.getElementById(thecolID + i);
			nextCol.style.backgroundColor = "#FFA1A1";
			if(!nextCol.onmouseout)nextCol.onmouseout = function(){unhic2(thecolID)};
		}
	}

	function unhic2(thecolID){
		var headerRows = document.getElementById('bigOtable').getElementsByTagName('tr');
		headerRows = (headerRows.length-2) / 21;
		document.getElementById(thecolID).style.backgroundColor = "#66CCFF";
		for (i = 1; i < headerRows; i++)
			document.getElementById(thecolID + i).style.backgroundColor = "#66CCFF";
	}

	function hideShowSearch(updateObjId,evt,closePopUp,criteria){
		var type, popup, criteria, closePopUp, evt
		document.getElementById('popup').style.display = 'none';
		document.getElementById('selectedValues').options.length = 0;
		popup = document.getElementById('popup');
		popup.updateId = updateObjId;

		if(popup.style.display == 'none' && !closePopUp){
			setPosition(evt,popup);
			document.getElementById('criteria').value = '';
			if(criteria){
				document.getElementById('criteria').value = (criteria.value)?criteria.value:criteria;
				getValues(criteria);
				document.getElementById('selectedValues').focus();
			}else{
				document.getElementById('criteria').focus();
			}
		}else{
			popup.style.display = 'none';
		}
	}


	function getValues(criteria){
		var criteria, path, selectedResources
		if(criteria){
			if(criteria.value){
				path = 'ajax_getCategories.cfm?criteria=' + criteria.value;
			}else{
				path = 'ajax_getCategories.cfm?criteria=' + criteria;
			}
		}else{
			path = 'ajax_getCategories.cfm?criteria=' + document.getElementById('criteria').value
		}
		selectedResources = document.getElementById('selectedValues');
		selectedResources.options.length = 0;
		selectedResources.options[0] = new Option('Loading...', 0);
		j$.ajax(path,{
			method: 'get'
		})
		.success(function(transport) {
			var selectedValues, values
			selectedValues = document.getElementById('selectedValues');
			values = eval(transport);
			selectedValues.options.length = 0;
			for(var x=0; x < values.length; x++){
				if(values[x].n.length > 1) selectedValues.options[selectedValues.options.length] = new Option(values[x].n, values[x].i);
			}
			if(values.length < 1 || (values.length == 1 && values[0].n.length < 1)){
				selectedValues.options[0] = new Option('None Found',0);
				selectedValues.focus();
			}
		});
	}

	function displayValue(ObjID){
		var theDiv, theInput, selectedValues, selectedOption
		selectedValues = document.getElementById('selectedValues');
		selectedOption = selectedValues.options[selectedValues.options.selectedIndex];
		if(selectedOption.text != 'None Found'){
			theDiv = document.getElementById(ObjID);
			theInput = document.getElementById(ObjID+'Id');
			theDiv.innerHTML = selectedOption.text;
			theInput.value = selectedOption.value;
			hideShowSearch(0,0,1);
			document.forms['accForm'].submit();
		}
	}

	function hig(therowID){
			document.getElementById(therowID).style.backgroundColor = "#FFA1A1";
	}

	function unhig(therowID){
			document.getElementById(therowID).style.backgroundColor = "#FFFFFF";
	}
	function unhig2(therowID){
			document.getElementById(therowID).style.backgroundColor = "#66CCFF";
	}
	
	function toggleAccessory(selection){
		let method = j$(selection).prop("checked") ? 'post' : 'delete';
		j$.ajax({
			url: '/partnernet/product/accessory',
			method: method,
			data: j$(selection).data(),
			error: function(e) {
				alert(e.responseJSON.errors[0].message);
			}
		});
	}

</script>

<cfinvoke component="ajax.sessionless.lock" method="putlock" userID="#getCurrentUser()#" objID="#attributes.productID#" returnvariable="lockresult"/>
<cfoutput>#lockresult.js#</cfoutput>

<cfset columns = 2>
<cfif getcategory.recordcount GT 0 AND getaccessorycategory.recordcount GT 0>
	<!--- first get the products for the category --->
	<cfquery name="getcategoryproducts" datasource="#DSN#">
		SELECT ID, manufacturer, modelNumber, active , prdisObsolete AS 'isObsolete'
		FROM Products
		WHERE category = <cfqueryparam sqltype="INT" value="#getcategory.ID#">
			AND CASE WHEN <cfqueryparam sqltype="BIT" value="#attributes.showInactiveProducts#"> = 0 AND Active = 0 THEN 0 ELSE 1 END = 1
			AND prdisobsolete = <cfqueryparam sqltype="BIT" value="#attributes.isobsolete#">
		ORDER BY active DESC, prdisobsolete, manufacturer, modelnumber
	</cfquery>

	<!--- then get the products for the accessory category --->
	<cfquery name="getaccessorycategoryproducts" datasource="#DSN#">
		SELECT ID, listdescription, alpinePrice,  manufacturer, modelNumber, active, prdIsObsolete AS 'isObsolete'
		FROM Products
		WHERE category = <cfqueryparam sqltype="INT" value="#getaccessorycategory.ID#">
			AND CASE WHEN <cfqueryparam sqltype="BIT" value="#attributes.showInactiveAccessories#"> = 0 AND Active = 0 THEN 0 ELSE 1 END = 1
			AND prdisobsolete = <cfqueryparam sqltype="BIT" value="#attributes.isobsolete#">
		ORDER BY active DESC, prdisobsolete, manufacturer, modelnumber
	</cfquery>

	<!--- accessory category recordcount determines the number of columns (in addition to the standard) we will have --->
	<!--- we begin with active, manufacturer & model, list description --->
	<cfset columns = columns + getaccessorycategoryproducts.recordcount + (ceiling(getaccessorycategoryproducts.recordcount/10) )-1>
</cfif>



<cfoutput>
<div class="options">
	<ul class="horiz">
		<li class="horiz"><strong>Accessorize Products by Category</strong></li>
		<li class="horiz"><a href="/partnernet/productmanagement/accessorizeproductsproducts.cfm?productID=#attributes.productID#">Accessorize Products by Product</a></li>
		<li class="horiz"><a href="/partnernet/productmanagement/accessoryReport.cfm?productID=#attributes.productID#">View Product Accessorizations</a></li>
	</ul>
</div>
</cfoutput>

<div id="popup" style="display: none;" class="box">
	<div class="title"><div class="floatRight"><a class="closeBox" href="javascript:void(0);" onclick="hideShowSearch(0,0,1)">X</a></div>Find Category</div>
	<form onsubmit="getValues(); return false;"><input id="criteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="submit" value="GO" onclick="getValues();"></form>
	<a href="javascript:getValues('last7days');" class="tiny m5">last 7 days</a><br>
	<select id="selectedValues" name="values" ondblclick="displayValue(this.parentNode.updateId);" size="30"></select><br>
	<input type="button" value="Add" onclick="displayValue(this.parentNode.updateId);">
</div>

<div class="clear"></div>
<form id="accForm" name="accForm" action="<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>" method="POST">
<input type="hidden" name="productID" value="<cfoutput>#attributes.productID#</cfoutput>">
<cfoutput>
	<div id="catToShell">
		<div class="grayBoxHeader">Category to accessorize products TO:</div>
		<div class="grayBoxBody">
			<div id="catTo" class="floatLeft">#selectedCatName#</div>
			<div class="floatLeft"><input class="tiny" type="button" name="addUpdate" value="Add/Update" onclick="hideShowSearch('catTo',event);"></div>
			<input type="hidden" name="categoryID" ID="catToId" value="#attributes.categoryID#"><div class="clear"></div>
		</div>
	</div>

	<div id="catFromShell">
		<div class="grayBoxHeader">Category to accessorize products FROM:</div>
		<div class="grayBoxBody">
			<div id="catFrom" class="floatLeft">#selectedAccCatName#</div>
			<div class="floatLeft"><input class="tiny" type="button" name="addUpdate" value="Add/Update" onclick="hideShowSearch('catFrom',event);"></div>
			<input type="hidden" name="accessorycategoryID" id='catFromId' value="#attributes.accessorycategoryID#"><div class="clear"></div>
		</div>
	</div>

	<strong>Related Accessory Categories:</strong>
	<div id="relatedCats" style="height: 60px; overflow-y: scroll; overflow-x: hidden;">
		<cfloop query="relatedCats">
		<a id="relatedcatlink#attributes.accessorycategoryID#" href="javascript: void(0);" onclick="javascript: document.accForm.accessorycategoryID.value = #relatedCats.ID#; document.forms['accForm'].submit();">#relatedCats.Name#</a><br>
		</cfloop>
	</div>
</cfoutput>

<div class="clear"></div>
	<cfif getcategory.recordcount GT 0 AND getaccessorycategory.recordcount GT 0>
		Display Options: 
			<input id="showInactiveProducts" name="showInactiveProducts" value="1" type="checkbox" <cfif attributes.showInactiveProducts>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();">
			<label for="showInactiveProducts">Display Inactive Products</label> &nbsp;
			<input id="showInactiveAccessories" name="showInactiveAccessories" value="1" type="checkbox" <cfif attributes.showInactiveAccessories>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();">
			<label for="showInactiveAccessories">Display Inactive Accessories</label> &nbsp;
			<input type="checkbox" id="isobsolete" name="isobsolete" <cfif attributes.isobsolete>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();" value="1">
			<label for="isobsolete">Display Obsolete Products</label>
		<table id="bigOtable" width="100%" cellspacing="1" cellpadding="1" border="1" class="clear">
			<cfoutput>
				<tr class="grayboxheader2">
					<td colspan="2"></td>
					<td colspan="#columns-2#">Accessories >>></td>
					<td></td>
				</tr>
				<tr>
					<td colspan="#columns#" height="2" bgcolor="gray"></td>
					<td></td>
				</tr>
			</cfoutput>

			<!--- loop out the header --->
			<tr class="normal">
				<td colspan="2"><strong>Products</strong><br>
					<span class="green">A: active</span><br>
					<span class="red">O: Obsolete</span>
				</td>

				<cfoutput query="getaccessorycategoryproducts">
					<cfif getaccessorycategoryproducts.currentrow MOD 10 EQ 0>
						<td>&nbsp;</td>
					</cfif>
					<cfif attributes.productID EQ getaccessorycategoryproducts.ID>
						<td  style="background:##66CCFF" id="col#getaccessorycategoryproducts.ID#" onmouseover="hic2('col#getaccessorycategoryproducts.ID#')"><cfif getaccessorycategoryproducts.active><span class="green">A</span></cfif><cfif getaccessorycategoryproducts.isObsolete><span class="red">O</span></cfif><br><a title="#getaccessorycategoryproducts.listdescription# #chr(13)#Retail: #Dollarformat(getaccessorycategoryproducts.alpineprice)#">#getaccessorycategoryproducts.manufacturer# #getaccessorycategoryproducts.modelnumber#</a></td>
					<cfelse>
						<td id="col#getaccessorycategoryproducts.ID#" onmouseover="hic('col#getaccessorycategoryproducts.ID#')"><cfif getaccessorycategoryproducts.active><span class="green">A</span></cfif><cfif getaccessorycategoryproducts.isObsolete><span class="red">O</span></cfif><br><a title="#getaccessorycategoryproducts.listdescription# #chr(13)#Retail: #Dollarformat(getaccessorycategoryproducts.alpineprice)#">#getaccessorycategoryproducts.manufacturer# #getaccessorycategoryproducts.modelnumber#</a></td>
					</cfif>
				</cfoutput>

			</tr>

			<cfset looper = 1>
			<cfoutput query="getcategoryproducts">
				<cfif getcategoryproducts.currentrow MOD 20 EQ 0>
					<tr class="columnNames">
						<td colspan="2"><strong>Products</strong></td>

						<cfloop query="getaccessorycategoryproducts">
							<cfif getaccessorycategoryproducts.currentrow MOD 10 EQ 0>
								<td>&nbsp;</td>
							</cfif>
							<cfif attributes.productID EQ getaccessorycategoryproducts.ID>
								<td id='col#getaccessorycategoryproducts.ID##looper#' onmouseover="hic2('col#getaccessorycategoryproducts.ID#')"><cfif getaccessorycategoryproducts.active><span class="green">A</span></cfif><cfif getaccessorycategoryproducts.isObsolete><span class="red">O</span></cfif><br><a title="#getaccessorycategoryproducts.listdescription# #chr(13)#Retail: #Dollarformat(getaccessorycategoryproducts.alpineprice)#">#getaccessorycategoryproducts.manufacturer# #getaccessorycategoryproducts.modelnumber#</a></td>
							<cfelse>
								<td id='col#getaccessorycategoryproducts.ID##looper#' onmouseover="hic('col#getaccessorycategoryproducts.ID#')"><cfif getaccessorycategoryproducts.active><span class="green">A</span></cfif><cfif getaccessorycategoryproducts.isObsolete><span class="red">O</span></cfif><br><a title="#getaccessorycategoryproducts.listdescription# #chr(13)#Retail: #Dollarformat(getaccessorycategoryproducts.alpineprice)#">#getaccessorycategoryproducts.manufacturer# #getaccessorycategoryproducts.modelnumber#</a></td>
							</cfif>
						</cfloop>
						<cfset looper = looper + 1>
						<td>&nbsp;</td>
					</tr>
				</cfif>
				<cfquery name="getaccessories" datasource="#DSN#">
					SELECT prdRelative
					FROM tblProductAssociations
					WHERE prdID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#getcategoryproducts.ID#">
					AND ascType = 'R'
				</cfquery>

				<cfset insidelist = valueList(getaccessories.prdRelative)>
				<cfset productID = getcategoryproducts.ID>

				<cfif attributes.productID EQ getcategoryproducts.ID>
					<tr style="background:##66CCFF" class="normal" id="row#getcategoryproducts.ID#" onmouseover="hig('row#getcategoryproducts.ID#');" onmouseout="unhig2('row#getcategoryproducts.ID#');">
				<cfelse>
					<tr class="normal" id="row#getcategoryproducts.ID#" onmouseover="hig('row#getcategoryproducts.ID#');" onmouseout="unhig('row#getcategoryproducts.ID#');">
				</cfif>
					<td><cfif val(getcategoryproducts.active)><span class="green">A</span></cfif><cfif val(getcategoryproducts.isObsolete)><span class="red">O</span></cfif></td>
					<td>#getcategoryproducts.manufacturer# #getcategoryproducts.modelnumber#</td>

					<cfloop query="getaccessorycategoryproducts">
						<cfif getaccessorycategoryproducts.currentrow MOD 10 EQ 0>
							<td>#getcategoryproducts.manufacturer# #getcategoryproducts.modelnumber#</td>
						</cfif>

						<cfif ListFindNoCase("#insidelist#","#getaccessorycategoryproducts.ID#")>
							<cfset checked = "checked">
						<cfelse>
							<cfset checked = "">
						</cfif>
						<cfif attributes.productID EQ getaccessorycategoryproducts.ID>
							<td onmouseover="hic2('col#getaccessorycategoryproducts.ID#',this)">
						<cfelse>
							<td onmouseover="hic('col#getaccessorycategoryproducts.ID#',this)">
						</cfif>
							<input class="accessorize" type="checkbox" #checked# name="row#productID#" value="#getaccessorycategoryproducts.ID#" data-productID="#esapiEncode('html_attr',productID)#" data-accessoryID="#esapiEncode('html_attr',getaccessorycategoryproducts.ID)#" onclick="toggleAccessory(this)">
						</td>

					</cfloop>

				</tr>
			</cfoutput>

		</table>
	<cfelse>
		<div style="height:500px;"></div>
	</cfif>
</form>

<cfinclude template="/partnernet/shared/_footer.cfm">
