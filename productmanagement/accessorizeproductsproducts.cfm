<cfsetting showdebugoutput="no">
<!--- select a given product category to apply accessories to --->
<!--- then select another product category to get the accessories from --->
<!--- grid is displayed with the product's accessories --->

<cfset screenID = 240>
<cfset recordhistory = 0>
<cfinclude template="/partnernet/shared/_header.cfm">

<cfparam name="attributes.categoryID" default="">
<cfparam name="attributes.accessorycategoryID" default = "">
<cfparam name="attributes.productList" default="">
<cfparam name="attributes.accessoryList" default="">
<cfparam name="attributes.isactive" default = "1">
<cfparam name="attributes.isobsolete" default = "0">

<cfif attributes.productID NEQ "">
	<cfparam name="attributes.objID" default="#attributes.productID#">
<cfelse>
	<cfparam name="attributes.objID" default="#attributes.objID#">
</cfif>

<cfset selectedCatName = "">
<cfset selectedAccCatName = "">

<cfif attributes.productList NEQ "">
	<cfset attributes.categoryID = "">
</cfif>

<cfif attributes.accessoryList NEQ "">
	<cfset attributes.accessorycategoryID = "">
</cfif>

<cfif attributes.productList EQ "">

	<cfif isdefined("attributes.productID") AND attributes.categoryID IS "">

		<cfquery name="getcategoryID" datasource="#DSN#">
			SELECT category
			FROM Products
			WHERE ID = <cfqueryparam sqltype="INT" value="#attributes.productID#">
			ORDER BY name
		</cfquery>

		<cfif getcategoryID.recordCount>
			<cfset attributes.categoryID = getcategoryID.category>
		</cfif>

	</cfif>

	<cfquery name="getcategory" datasource="#DSN#">
		SELECT ID, listname
		FROM Productcategories
		WHERE ID = <cfqueryparam sqltype="INT" value="#lenTrim(attributes.categoryID) ? attributes.categoryID : 10000#">
	</cfquery>

	<cfif getcategory.recordcount>
		<cfset selectedCatName = getcategory.listName>
	</cfif>

</cfif>

<cfif attributes.accessoryList EQ "">

	<cfquery name="getaccessorycategory" datasource="#DSN#">
		SELECT ID, listname
		FROM Productcategories
		WHERE ID = <cfqueryparam sqltype="INT" value="#lenTrim(attributes.accessorycategoryID) ? attributes.accessorycategoryID : 10000#">
	</cfquery>

	<cfif getaccessorycategory.recordcount>
		<cfset selectedAccCatName = getaccessorycategory.listName>
	</cfif>

</cfif>

<cfif attributes.productList NEQ "">

	<cfquery name="getcategoryproducts" datasource="#DSN#">
		SELECT ID, manufacturer, modelNumber, isNull(active,0) as active , prdisObsolete as isObsolete, listdescription
		FROM Products
		WHERE ID IN (<cfqueryparam sqltype="INT" list=true value="#attributes.productList#">)
			AND active IN (1,<cfqueryparam sqltype="BIT" value="#attributes.isactive#">)
			AND prdisobsolete = <cfqueryparam sqltype="BIT" value="#attributes.isobsolete#">
		ORDER BY active DESC, prdisobsolete, category, priority, manufacturer, modelnumber
	</cfquery>

	<cfset selectedCatName = "Products">

<cfelseif isDefined("getcategory") AND getcategory.recordcount GT 0>

	<cfquery name="getcategoryproducts" datasource="#DSN#">
		SELECT ID, manufacturer, modelNumber, isNull(active,0) as active , prdisObsolete as isObsolete, listdescription
		FROM Products
		WHERE category = <cfqueryparam sqltype="INT" value="#getcategory.ID#">
			AND active IN (1,<cfqueryparam sqltype="BIT" value="#attributes.isactive#">)
			AND prdisobsolete = <cfqueryparam sqltype="BIT" value="#attributes.isobsolete#">
		ORDER BY active DESC, prdisobsolete, category, priority, manufacturer, modelnumber
	</cfquery>

	<cfquery name="setproductList" datasource="#DSN#">
		SELECT ID, manufacturer, modelNumber, isNull(active,0) as active , prdisObsolete as isObsolete, listdescription
		FROM Products
		WHERE category = <cfqueryparam sqltype="INT" value="#getcategory.ID#">
		ORDER BY active DESC, prdisobsolete, category, priority, manufacturer, modelnumber
	</cfquery>

	<cfset attributes.productList = ValueList(setproductList.ID, ",")>

</cfif>

<cfif isDefined("attributes.accessoryList") AND attributes.accessoryList NEQ "">

	<cfquery name="getaccessorycategoryproducts" datasource="#DSN#">
		SELECT ID, listdescription, alpinePrice, manufacturer, modelNumber, isNull(active,0) as active, prdIsObsolete as isObsolete
		FROM Products
		WHERE ID IN (<cfqueryparam sqltype="INT" list=true value="#attributes.accessoryList#">)
			AND active IN (1,<cfqueryparam sqltype="BIT" value="#attributes.isactive#">)
			AND prdisobsolete = <cfqueryparam sqltype="BIT" value="#attributes.isobsolete#">
		ORDER BY active DESC, prdisobsolete, category, priority, manufacturer, modelnumber
	</cfquery>

	<cfset selectedAccCatName = "Products">

<cfelseif isDefined("getaccessorycategory") AND getaccessorycategory.recordcount GT 0>

	<cfquery name="getaccessorycategoryproducts" datasource="#DSN#">
		SELECT ID, listdescription, alpinePrice, manufacturer, modelNumber, isNull(active,0) as active, prdIsObsolete as isObsolete
		FROM Products
		WHERE category = <cfqueryparam sqltype="INT" value="#getaccessorycategory.ID#">
			AND active IN (1,<cfqueryparam sqltype="BIT" value="#attributes.isactive#">)
			AND prdisobsolete = <cfqueryparam sqltype="BIT" value="#attributes.isobsolete#">
		ORDER BY active DESC, prdisobsolete, category, priority, manufacturer, modelnumber
	</cfquery>

</cfif>

<cfif isDefined("getcategoryproducts") AND getcategoryproducts.recordcount GT 0 AND attributes.productList EQ "">

	<cfset attributes.productList = ValueList(getcategoryproducts.ID, ",")>

</cfif>

<cfif isDefined("getaccessorycategoryproducts") AND getaccessorycategoryproducts.recordcount GT 0 AND attributes.accessoryList EQ "">

	<cfset attributes.accessoryList = ValueList(getaccessorycategoryproducts.ID, ",")>

</cfif>

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

function hig(therowID){
		document.getElementById(therowID).style.backgroundColor = "#FFA1A1";
}

function unhig(therowID){
		document.getElementById(therowID).style.backgroundColor = "#FFFFFF";
}
function unhig2(therowID){
		document.getElementById(therowID).style.backgroundColor = "#66CCFF";
}

</script>

<cfinvoke component="ajax.sessionless.lock" method="putlock" userID="#getCurrentUser()#" objID="#attributes.productID#" returnvariable="lockresult"/>
<cfoutput>#lockresult.js#</cfoutput>

<cfset columns = 2>
<cfif isDefined("getcategoryproducts") AND getcategoryproducts.recordcount GT 0 AND isDefined("getaccessorycategoryproducts") AND getaccessorycategoryproducts.recordcount GT 0>
	<!--- accessory category recordcount determines the number of columns (in addition to the standard) we will have --->
	<!--- we begin with active, manufacturer & model, list description --->
	<cfset columns = columns + getaccessorycategoryproducts.recordcount + (ceiling(getaccessorycategoryproducts.recordcount/10) )-1>
</cfif>


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
				path = 'ajax_getProducts.cfm?criteria=' + criteria.value;
			}else{
				path = 'ajax_getProducts.cfm?criteria=' + criteria;
			}
		}else{
			path = 'ajax_getProducts.cfm?criteria=' + document.getElementById('criteria').value
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
				if((values[x].n.length > 1) && (values[x].t == 'p')) selectedValues.options[selectedValues.options.length] = new Option(values[x].n, values[x].i);
			}
			if(values.length < 1 || (values.length == 1 && values[0].n.length < 1)){
				selectedValues.options[0] = new Option('None Found',0);
				selectedValues.focus();
			}
		});
	}

	function displayValue(ObjID){
		var theDiv, theInput, selectedValues, selectedOption, i
		selectedValues = document.getElementById('selectedValues');
		selectedOption = '';

		for (i = 0; i < selectedValues.options.length; i++) {
			if (selectedValues.options[i].selected) {
				selectedOption = selectedOption + selectedValues.options[i].value + ',';
			}
		}

		if (selectedOption.length != 0) {
			selectedOption = selectedOption.substring(0, selectedOption.length - 1);
		}

		if(confirm("This page will be refreshed.\nWould you like to continue?")){
			if(selectedOption.text != 'None Found'){
				theDiv = document.getElementById(ObjID);
				theInput = document.getElementById(ObjID+'Id');
				theDiv.innerHTML = 'Products';
				if (theInput != null) {
					if (theInput.value.length > 0) {
						theInput.value = theInput.value + ',' + selectedOption;
					} else {
						theInput.value = selectedOption;
					}
				}
				hideShowSearch(0,0,1);
				document.forms['accForm'].submit();
			}
		} else {
			hideShowSearch(0,0,1);
			return false;
		}
	}

	function clearProducts(ObjID) {
		if(confirm("This page will be refreshed.\nWould you like to continue?")){
			var theInput, theInput2
			theInput = document.getElementById(ObjID);
			theInput.value = '';

			if (ObjID == 'catToId') {
				theInput2 = document.getElementById('theproduct');
				theInput2.value = '';
				document.forms['accForm'].action = '/partnernet/productmanagement/accessorizeproductsproducts.cfm'
				document.forms['accForm'].submit();
			}
			document.forms['accForm'].submit();
		} else {
			return false;
		}
	}

	j$(function() {
		j$('.accessorize').on('change',function() {
			let method = j$(this).prop("checked") ? 'post' : 'delete';
			j$.ajax({
				url: '/partnernet/product/accessory',
				method: method,
				data: j$(this).data(),
				error: function(e) {
					alert(e.responseJSON.errors[0].message);
				}
			});
			
		});
	});

</script>

<cfoutput>
<div class="options">
	<ul class="horiz">
		<li class="horiz"><a href="/partnernet/productmanagement/accessorizeProducts.cfm?productID=#attributes.objID#">Accessorize Products by Category</a></li>
		<li class="horiz"><strong>Accessorize Products by Product</strong></li>
		<li class="horiz"><a href="/partnernet/productmanagement/accessoryReport.cfm?productID=#attributes.objID#">View Product Accessorizations</a></li>
	</ul>
</div>
</cfoutput>

<div id="popup" style="display: none;" class="box">
	<div class="title"><div class="floatRight"><a class="closeBox" href="javascript:void(0);" onclick="hideShowSearch(0,0,1)">X</a></div>Find Products</div>
	<form onsubmit="getValues(); return false;"><input id="criteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="submit" value="GO" onclick="getValues();"></form>
	<a href="javascript:getValues('last7days');" class="tiny m5">last 7 days</a><br>
	<select id="selectedValues" name="values" ondblclick="displayValue(this.parentNode.updateId);" size="30" multiple="multiple"></select><br>
	<input type="button" value="Add" onclick="displayValue(this.parentNode.updateId);">
</div>

<form id="accForm" name="accForm" action="<cfoutput>#CGI.SCRIPT_NAME#</cfoutput>" method="POST">
<input type="hidden" name="productID" id="theproduct" value="<cfoutput>#attributes.productID#</cfoutput>">
<input type="hidden" name="objID" value="<cfoutput>#attributes.objID#</cfoutput>">
<cfoutput>
	<div id="catToShell">
		<div class="grayBoxHeader">Products to accessorize products TO:</div>
		<div class="grayBoxBody">
			<div id="catTo" class="floatLeft">#selectedCatName#</div>
			<div class="floatLeft">
				<input class="tiny" type="button" name="addUpdate" value="Add" onclick="hideShowSearch('catTo',event);">
				<input class="tiny" type="button" name="clear" value="Clear" onclick="clearProducts('catToId');">
			</div>
			<input type="hidden" name="productList" ID="catToId" value="#attributes.productList#"><div class="clear"></div>
		</div>
	</div>

	<div id="catFromShell">
		<div class="grayBoxHeader">Products to accessorize products FROM:</div>
		<div class="grayBoxBody">
			<div id="catFrom" class="floatLeft">#selectedAccCatName#</div>
			<div class="floatLeft">
				<input class="tiny" type="button" name="addUpdate" value="Add" onclick="hideShowSearch('catFrom',event);">
				<input class="tiny" type="button" name="clear" value="Clear" onclick="clearProducts('catFromId');">
			</div>
			<input type="hidden" name="accessoryList" id="catFromId" value="#attributes.accessoryList#"><div class="clear"></div>
		</div>
	</div>
</cfoutput>

<div class="clear"></div>
	<cfif isDefined("attributes.productList") AND attributes.productList NEQ "" AND isDefined("attributes.accessoryList") AND attributes.accessoryList NEQ "">
		Display Options: 
			<input id="isactive" name="isactive" value="0" type="checkbox" <cfif attributes.isactive EQ 0>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();">
			<label for="isactive">Display Inactive Products</label> &nbsp; 
			<input type="checkbox" id="isobsolete" name="isobsolete" <cfif attributes.isobsolete>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();" value="1">
			<label for="isobsolete">Display Obsolete Products</label>
	<cfelseif isDefined("getcategoryproducts") AND getcategoryproducts.recordcount GT 0 AND isDefined("getaccessorycategoryproducts") AND getaccessorycategoryproducts.recordcount GT 0>
		Display Options: 
			<input id="isactive" name="isactive" value="0" type="checkbox" <cfif attributes.isactive EQ 0>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();">
			<label for="isactive">Display Inactive Products</label> &nbsp; 
			<input type="checkbox" id="isobsolete" name="isobsolete" <cfif attributes.isobsolete>CHECKED="true"</cfif> onclick="document.forms['accForm'].submit();" value="1">
			<label for="isobsolete">Display Obsolete Products</label>
	<cfelse>
		<input type="hidden" name="isactive" value="<cfoutput>#attributes.isactive#</cfoutput>">
		<input type="hidden" name="isobsolete" value="<cfoutput>#attributes.isobsolete#</cfoutput>">
	</cfif>
	<cfif isDefined("getcategoryproducts") AND getcategoryproducts.recordcount GT 0 AND isDefined("getaccessorycategoryproducts") AND getaccessorycategoryproducts.recordcount GT 0>
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
							<cfdump var="#attributes.productID#" >
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

				<cfset insidelist = queryExecute("SELECT prdRelative FROM tblProductAssociations WHERE prdID = :ID AND ascType = 'R'",{ID:{sqltype:"INT",value:getcategoryproducts.ID}},{datasource:DSN}).reduce(function(k,i){return listAppend(k,i.prdRelative);},'')>
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
							<input class="accessorize" type="checkbox" #checked# name="row#productID#" value="#getaccessorycategoryproducts.ID#" data-productID="#esapiEncode('html_attr',productID)#" data-accessoryID="#esapiEncode('html_attr',getaccessorycategoryproducts.ID)#">
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
