<!DOCTYPE html>
<cfset screenID = 1105>
<cfif CGI.REQUEST_METHOD EQ "POST" AND  isDefined("priceChangeValueBox")>
	<cfinvoke component="alpine-objects.DynamicPricingResource"
		method="updateUserSettings"
		userID="#session.user.ID#"
		priceChgAmt="#priceChangeValueBox#"
		priceChgPct="#priceChangeDecimalBox#"
		filterByPrice="#IsDefined('filterPriceBox')#"
		filterByMargin="#isDefined('filterMarginBox')#"
		marginChgPct="#marginChangeDecimalBox#"
		filterByTurns="#IsDefined('filterTurnsBox')#"
		usePrefCosts="#IsDefined('filterCostBox')#"
		filterByCosts="#IsDefined('filterCostBox')#"
		costChgAmt="#costChangeValueBox#"
		costChgPct="#costChangeDecimalBox#"
	/>
</cfif>
<cfinvoke
	component="alpine-objects.DynamicPricingResource"
	method="getUserSettings"
	userID="#session.user.ID#"
	returnVariable="userSettings"
/>

<cfinvoke component="alpine-objects.DynamicPricingResource"
	method="getSettings"
	returnvariable="adminSettings"
/>
<cfif StructKeyExists(ATTRIBUTES, "showtable")>
	<cfif isDefined("URL.req")>
		<cfinvoke
			component="alpine-objects.DynamicPricingResource"
			method="buildDiscountList"
			reqjson="#URL.req#"
			returnvariable="userUpdates"
		/>
		<cfelse>
			<cfinvoke
				component="alpine-objects.DynamicPricingResource"
				method="getUserUpdates"
				userID="#session.user.ID#"
				returnvariable="userUpdates"
			/>
	</cfif>
	<cfinvoke
		component="alpine-objects.DynamicPricingResource"
		method="getNumberMasterCategoryUpdates"
		masterCatNameList="Furnaces/Heaters,Cooling,IAQ,Air Handlers and Electric Furnaces,Water Heaters,Replacement Parts,Ducting/Sheet Metal,Zone Control Systems,Chimney Relining Kits,Thermostats,Tools" <!--- ,Tools --->
		masterCatIDList="67,92,405,132,386,88,45,162,12,14,25" <!--- ,25 --->
		inputQuery="#userUpdates#"
		returnVariable="numProd"
	/>
	<cfinvoke
		component="alpine-objects.DynamicPricingResource"
		method="getNumberUpdatedProducts"
		userID="#session.user.ID#"
		masterQry="#userUpdates#"
		returnvariable="allupdates"
	/>
</cfif>
<cfset fieldlength=6>

<cfsetting showDebugOutput="No">
<cfinclude template="/partnernet/shared/_header.cfm">
<link rel="stylesheet" href="//code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css">
<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min.js"></script>
<script>
var j$ = jQuery.noConflict();
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.28.0/js/jquery.tablesorter.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.28.0/js/extras/jquery.tablesorter.pager.min.js"></script>
<script>
	function addToolTips()
	{
		j$("#marginChangeMO").tooltip({content: "Show products for which the margin at the recommended price differs from the margin at the current price by more than a given percentage."});
		j$("#includeAllMO").tooltip({content:"Show all products in the selected category, whether they fit the search criteria or not."});
		j$(".ui-icon-triangle-2-n-s").tooltip({content: "Sortable"});
		j$("#priceChangeMO").tooltip({content: "Show products for which the difference between the recommended price and the current price differs by a percentage of the current price or a flat amount, whichever is greater."});
		j$("#costChangeMO").tooltip({content: "Show products for which the vendor cost differs from the average vendor cost by a given percentage or a flat amount, whichever is greater."});
		j$( "#currentCostExpMO" ).tooltip({content: "If selected, all margin calculations and price floors are set relative to the current vendor costs of a product, if available.  Otherwise, average costs are used."});
		j$( "#includeCategoryMO" ).tooltip({content: "Select checkboxes to include selected categories in a custom category summary."});
	}
	function hideSpecs(e)
	{
		j$( "#settingsinput" ).toggle();
		e.preventDefault();
	}
	function okGo()
	{
		j$(".dt").datepicker({
			autoSize:true
		});
		//check if showAll checkbox is checked, if so, change the href attribute of the link element for the category.
<!--- 		j$( "input.showAll" ).click(function(){
			tempLink = j$( this ).attr( "href" );
			if( j$( this ).parents("tr").find( "input.showAll" ).is(":checked") ){
				tempLink += "&showAll=true";
			}
			j$( this ).attr("href", tempLink);
		}); --->
		j$( "#categorytable" ).tablesorter({
										widgets:["zebra"]	}
									);//.tablesorterPager({container:j$("#pager"), positionFixed:false, seperator: " of ", size: parseInt( j$(".pagesize").val())});

		addToolTips();
		j$( "#hidelink" ).click(hideSpecs);
		j$(".tabHeader").click(function(){
						if( j$("#settingsinput").is(":visible") )
						{
							j$("#searchRestrictionSubmission").css("display", "none");
						}else{
							j$("#searchRestrictionSubmission").css("display", "block");
						}
				});
		j$(".tabHeader").click();
		<cfif isDefined("URL.req")>
			<cfset tDiscReq = JSStringFormat(URL.req)>
			j$( "a.listLink" ).each(function(){
						var tempLinkVal = j$( this ).attr("href");
			<cfoutput>queryStringAdd = "&discountReq=#tDiscReq#";</cfoutput>
						j$( this ).attr("href", tempLinkVal + queryStringAdd);
			});

		</cfif>
		j$(".catList").click(function(){
			var numChecked = j$( ".catList:checked" ).get().length;
			if(numChecked > 0){
				j$( "#rollupSettings" ).css("display", "block");
			}else{
				j$( "#rollupSettings" ).css("display", "none");
			}
		});
	}
	function updateUserSettings()
	{
		var updateObj = {};
		updateObj.userID = <cfoutput>#session.user.ID#</cfoutput>;
		updateObj.priceChgAmt = j$( "#priceChangeValueBox" ).val();
		updateObj.priceChgPct = j$( "#priceChangeDecimalBox" ).val();
		updateObj.filterByPrice = (j$( "#filterPriceBox" ).is(":checked")) * 1;
		updateObj.filterByMargin = (j$( "#filterMarginBox" ).is(":checked")) * 1;
		updateObj.marginChgPct = j$( "#marginChangeDecimalBox" ).val();
		updateObj.filterByTurns = (j$( "#filterTurnsBox" ).is(":checked")) * 1;
		updateObj.usePrefCosts = (j$( "#usePrefCosts" ).is(":checked")) * 1;
		updateObj.filterByCosts = (j$( "#filterCostBox" ).is(":checked")) * 1;
		updateObj.costChgAmt = j$( "#costChangeValueBox" ).val();
		updateObj.costChgPct = j$( "#costChangeDecimalBox" ).val();
		updateObj.filterByDate = (j$( "#filterByDate" ).is(":checked")) * 1;
		updateObj.dateIsBetween = j$("#dateIsBetween").val();
		updateObj.dateBegin = j$("#lastChangeBeginning").val();
		updateObj.dateEnd = j$( "#lastChangeEnding" ).val();
		updateObj.filterByActivationDate = (j$( "#filterByActivationDate" ).is(":checked")) * 1;
		updateObj.activationDateBegin = j$( "#activationBeginning" ).val();
		updateObj.activationDateEnd = j$( "#activationEnding" ).val();

		<cfajaxproxy cfc="alpine-objects.DynamicPricingResource" jsclassname="jsDRP">
		var updater = new jsDRP();
		//set method to POST to allow for larger sets of products
		updater.setHTTPMethod("POST");
		var response = updater.ajaxUpdateUserSettings(JSON.stringify(updateObj));
		var respObj = JSON.parse(response.replace("//", ""));

		if(!respObj.SUCCESS)
		{
			alert("Update failed: " + respObj.failDetail);
			return;
		}

		location.reload();
	}

	function loadCustomRollUp(){
		var catsAry = [];
		j$( ".catList:checked" ).each(function(){
			catsAry.push( j$( this ).val()	);
		});
		var catListStr = "acceptancepanel.cfm?custom=1&categoryList=" + catsAry.join();
		catListStr += (j$( "#showAllCustom" ).is(":checked")) ? "&showAll=true" : "";
		<cfif StructKeyExists(URL, "req")>
		catListStr += <cfoutput>'&discountreq=#JSStringFormat(URL.req)#';</cfoutput>
		</cfif>
		window.location=(catListStr);
	}

	j$( okGo );
</script>
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

<link rel="stylesheet" href="dynamicPricing.css">

<cfparam name="attributes.ProductID" default=0>
<cfparam name="attributes.Mfg" default="">
<cfparam name="attributes.activecbx" default="">

<cfquery name="listProducts" datasource="#DSN#" cachedwithin="#createtimespan(0, 1, 0, 0)#">
	SELECT p.ID, manufacturer, modelNumber, p.active, pc.listName
	FROM products p WITH (NOLOCK)
	LEFT JOIN productCategories pc WITH (NOLOCK)
		ON p.Category = pc.ID
	WHERE p.ID IN ('#Replace(attributes.ProductID,",","','","all")#')
</cfquery>
<cfquery name="getMfgs" datasource="#DSN#" cachedwithin="#createtimespan(0, 4, 0, 0)#">
	SELECT manufacturer AS Mfg, COUNT(id) as prodCount, SUM(CAST(active AS INT)) AS numActives
	FROM products WITH (NOLOCK)
	WHERE (prdcreated > dateadd("m", -3, getdate())
	OR active = 1)
	AND isorderable = 1
	AND prdisobsolete = 0
	AND category NOT IN (96,231)
	AND Len(LTRIM(RTRIM(manufacturer))) > 0
	GROUP BY manufacturer
	ORDER BY CASE WHEN SUM(CAST(active AS INT)) > 0 THEN 1 ELSE 0 END DESC, manufacturer ASC
</cfquery>

<h1>Dynamic Pricing List Page</h1>
<cfif NOT StructKeyExists(ATTRIBUTES, "showTable")>
	<a href="listpage.cfm?showtable=1" class="button green">Show Category List Table</a>
</cfif>
<cfoutput>
<form name="form1" method="post" action="acceptancepanel.cfm" onsubmit="selectAll();">
<br>
<cfif isDefined('URL.req')>
	<input type="hidden" name="discountReq" value="#URL.req#">
</cfif>
<div class="options">
	<div class="tabHeader">
		<div class="tabContent">
			<div class="tabTitle">Search By Product</div>
			<table>
				<tr>
					<td>
						<select name="ProductID" size="20" id="products" style="width:500px; height:300px;" multiple>
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
		<div class="tabContent" >
			<div class="tabTitle">Search By Mfg</div>
			<select name="Mfg" id="mfgs">
			 	<cfloop query="getMfgs">
		 			<cfoutput><option value="#getMfgs.Mfg#"<cfif attributes.mfg EQ getMfgs.Mfg> selected="true"</cfif>>#getMfgs.Mfg# (#getMFGs.numActives#)</option>
					</cfoutput>
				</cfloop>
			 </select>
		</div>
		<div class="tabContent tabSelected">
			<div class="tabTitle" >Search By Specifications</div>
			<form action="listpage.cfm">
				<cfset priceFilter= userSettings.filterByPrice EQ 1>
				<cfset marginFilter= userSettings.filterByMargin EQ 1>
				<cfset costFilter = userSettings.filterByCost EQ 1>
				<cfset filterByDate = userSettings.filterByDate EQ 1>
				<cfset dateIsBetween = userSettings.dateIsBetween EQ 1>
				<cfset dateBegin = DateFormat(userSettings.dateBegin, "MM/DD/YYYY")>
				<cfset dateEnd = DateFormat(userSettings.dateEnd, "MM/DD/YYYY")>
				<cfset activationBegin = DateFormat(userSettings.activationDateBegin, "MM/DD/YYYY")>
				<cfset activationEnd = DateFormat(userSettings.activationDateEnd, "MM/DD/YYYY")>
				<cfset filterByActivationDate = (userSettings.filterByActivationDate EQ 1)>
				<div id="searchspecwrapper">
					<div id="searchspec">
						<table id="settingsinput">
							<tr><td class="filterbox">
									Filter <input name="filterPriceBox" type="checkbox" checked="#priceFilter#">
								</td><td class="filterbox">
									Filter	<input name="filterMarginBox" type="checkbox" checked="#marginFilter#">
								</td>	<td class="filterbox">
									Filter <input name="filterCostBox" type="checkbox" checked="#costFilter#">
								</td></tr>
							<tr>
								<td id="pricechanges" class="settingcell">
									<div id="pricechangetable" class="settingsbox">
										<span class="settingchangeheader">Prices Changed By<span title="" id="priceChangeMO" class="ui-icon ui-icon-info"></span>:</span><br /><br />
										<span class="settingsboxes">
											$<input type="text" name="priceChangeValueBox" validate="float" size="#fieldlength#" value="#userSettings.priceChangeAmt#" required="true">
											  - or -
											<input type="text" name="priceChangeDecimalBox" validate="float" size="#fieldlength#" value="#userSettings.priceChangePct#" required="true"> %
										</span><br />
										<p>Whichever is greater</p>
									</div>
								</td>
								<td id="marginchanges" class="settingcell">
									<div id="marginchangetable" class="settingsbox">
										<span class="settingchangeheader">Margin Changed By More Than <span title="" id="marginChangeMO" class="ui-icon ui-icon-info"></span>:</span><br /><br />
										<span class="settingsboxes">
											<input type="text" name="marginChangeDecimalBox" validate="float" size="#fieldlength#" value="#userSettings.marginChangePct#"> %
										</span><br />
									</div>
								</td>
								<td id="costchanges" class="settingcell">
									<div id="costchangetable" class="settingsbox">
										<span class="settingchangeheader">Cost Changed By <span title="" id="costChangeMO" class="ui-icon ui-icon-info"></span>:</span><br /><br />
										<span class="settingsboxes">
											$<input type="text" name="costChangeValueBox" validate="float" size="#fieldlength#" value="#userSettings.costChangeAmt#"> - or -
											<input type="text" name="costChangeDecimalBox" validate="float" size="#fieldlength#" value="#userSettings.costChangePct#"> % <br /><br />
											Whichever is greater
										</span>
									</div>
								</td>
							</tr>
							<tr><td colspan="3" id="datespecrow" class="settingcell">
							<cfoutput>
								<div id="datespecinputwrap" class="settingsbox">
									<label><input id="filterByDate" type="checkbox" <cfif filterByDate>checked="checked"</cfif>>Only show Products where prices/margins</label>
									<select id="dateIsBetween">
										<option value="1" <cfif dateIsBetween> SELECTED</cfif>>Were updated</option>
										<option value="0" <cfif NOT dateIsBetween>SELECTED</cfif>>Were not updated</option>
									</select>
									<label>From:  <input id="lastChangeBeginning" type="date" value="#dateFormat(dateBegin,'yyyy-mm-dd')#"/></label><label>To:  <input id="lastChangeEnding" type="date" value="#dateFormat(dateEnd,'yyyy-mm-dd')#"></label>
								</div>
							</cfoutput>
							</td></tr>
							<tr><td colspan="3" id="activedaterow" class="settingcell">
								<div class="settingsbox"><cfoutput>
									<label><input type="checkbox" id="filterByActivationDate" <cfif filterByActivationDate> checked="checked"</cfif>> Only show new products activated</label>
									<label>From:  <input id="activationBeginning" type="date" value="#dateFormat(activationBegin,'yyyy-mm-dd')#"></label><label>To:  <input id="activationEnding" type="date" value="#dateFormat(activationEnd,'yyyy-mm-dd')#"></label></>
								</cfoutput></div>
							</td></tr>
							<tr><td colspan="2" id="turncell">
								<cfset turnFilter=userSettings.filterByTurns EQ 1>
								<label><input type="checkbox" name="filterTurnsBox" checked="#turnFilter#">
								Show products with unacceptable turns (<cfoutput>#NumberFormat(adminSettings.turnThreshold, ".99")#</cfoutput>)</label></td><td><label><input type="checkbox" name="usePrefCosts" checked="#userSettings.usePrefCosts EQ 1#">&nbsp;Use Current Costs</label><span id="currentCostExpMO" class="ui-icon ui-icon-info" title=""></span></td></tr>
								<tr>
									<td colspan="3" id="updatecell">
										<input name="update" type="button" value="Update" onclick="updateUserSettings();">
									</td>
								</tr>
							</table>
						</div>
				</div>
			</form>
		</div>
	</div>
	<div id="searchRestrictionSubmission">
		<div><input type="submit" value="Submit" name="submit"></div>
		<div><input type="checkbox" name="useFilters">Use Filter Specifications</div>
	</div>
</div>
</form>
</cfoutput>
<br><br>

<cfset productList = attributes.productID>

<cfif attributes.productID EQ "0">
	<cfquery name="getProdIds" datasource="#dsn#">
		SELECT ID, manufacturer, modelNumber
		FROM products
		WHERE manufacturer = <cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.mfg#">
		AND isorderable = 1
		AND prdisobsolete = 0
		AND category NOT IN (96,231)
		ORDER BY modelNumber
	</cfquery>
	<cfset productList = valueList(getProdIds.Id)>
<cfelse>
	<cfset getProdIds = listProducts>
</cfif>

<!---  --->

<cfif StructKeyExists(ATTRIBUTES, "showtable")>
	<cfoutput>
		<div id="categorieslist">
			<div id="rollupSettings">
				<button class="button green" onclick="loadCustomRollUp();">Load Custom Category Summary</button>
				<label><input id="showAllCustom" type="checkbox"> Show all products in custom summary?</label>
			</div>
			<table id="categorytable">
			<thead><tr>
				<th>Category <span title="" class="ui-icon ui-icon-triangle-2-n-s"></span></th>
				<th>Number of Products <span title="" class="ui-icon ui-icon-triangle-2-n-s"></span></th>
				<th>Include All Products? <span title="" id="includeAllMO" class="ui-icon ui-icon-info"></span></th>
				<th>Include This Category? <span title="" id="includeCategoryMO" class="ui-icon ui-icon-info"></span></th>
			</tr></thead>
			<tbody>
			<cfloop query="numProd">
				<tr id="masterCat#masterID#" class="masterCategory" value="#NumberFormat(numProducts, '9')#">
					<td><a id="#masterID#link" class="listLink" href="#masterLink#">#ListName# (Master Category)</a></td>
					<td>#NumberFormat(numProducts, "9")#</td>
					<td><a class="showAll" href="#masterLink#&showAll=true">Show All</a></td>
					<td><input class="catList" type="checkbox" value="#IDList#"></td>
				</tr>
			</cfloop>
			<cfloop query="allupdates">
			<tr class="regularCategory" value="#NumberFormat(numProducts, '9')#">
				<td><a id="#catID#link" class="listLink" href="acceptancepanel.cfm?deptID=#catID#" >#ListName#</a></td>
				<td>#NumberFormat(numProducts, "9")#</td>
				<td><a class="showAll" href="acceptancepanel.cfm?deptID=#catID#&showAll=true">Show All</a></td>
				<td><input class="catList" type="checkbox" value="#catID#"></td>
			</tr>
			</cfloop></tbody>
			</table>
		<!--- 	<div id="pager" class="pager">
				<form>
					<span style="display:inline-block;" class="ui-icon ui-icon-arrowthickstop-1-w first"></span>
					<span style="display:inline-block;" class="ui-icon ui-icon-arrowthick-1-w prev"></span>
					<input type="text" disabled="disabled" class="pagedisplay"/>
					<span style="display:inline-block;" class="ui-icon ui-icon-arrowthick-1-e next"></span>
					<span style="display:inline-block;" class="ui-icon ui-icon-arrowthickstop-1-e last"></span>
					<select class="pagesize">
						<option  value="10">10</option>
						<option value="20">20</option>
						<option  selected="selected" value="30">30</option>
						<option  value="40">40</option>
						<option value="50">50</option>
					</select>
				</form>
			</div> --->
		</div>
	</cfoutput>
</cfif>
<cfinclude template="/partnernet/shared/_footer.cfm">