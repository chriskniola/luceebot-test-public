<!DOCTYPE html>
<cfsetting showdebugoutput='no'>
<cfset screenID = 1110>
<cfset showjquery=1 >
<cfset showSideNav=0>
<cfinclude template="/partnernet/shared/_header.cfm">
<cfset MAX_DISCOUNT_HISTORY_RECORDS = 5>
<!--- Get Settings for user and repricer --->
<cfinvoke component="objects.DynamicPricingResource"
	method="getUserSettings"
	userID="#session.user.ID#"
	returnvariable="userSettings"
/>
<cfinvoke component="objects.DynamicPricingResource"
	method="getSettings"
	returnvariable="adminSettings"
/>
<!------------------------------------------------------>
<!--- Determine Access Level --->
<cfinvoke component="objects.DynamicPricingResource"
	method="isUserAdmin"
	userID="#session.user.ID#"
	returnvariable="isAdmin"
/>
<!------------------------------------------>
<!--- Hide products if necessary. --->
<cfif isDefined("URL.hideProd")>
	<cfquery name="hideProduct" datasource="#DSN#">
		INSERT INTO tblRepriceUserHiddenItems
		(userID, prodID, hideDate)
		VALUES
		(<cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
		, <cfqueryparam cfsqltype="cf_sql_integer" value="#URLDecode(URL.hideProd)#">
		, CURRENT_TIMESTAMP)
	</cfquery>
</cfif>
<cfif IsDefined("URL.custom")>
	<cfset queryMethod = (IsDefined("URL.showAll") OR IsDefined("ATTRIBUTES.discountReq")) ? 'getAllUpdates' : 'getUserUpdates'>
	<cfinvoke component="Objects.DynamicPricingResource"
		method="#queryMethod#"
		userID="#session.user.ID#"
		usePrefCosts="#userSettings.usePrefCosts#"
		returnvariable="getUpdatedProducts">
	<cfif IsDefined('ATTRIBUTES.discountReq')>
		<cfinvoke component="objects.DynamicPricingResource"
			baseQry="#getUpdatedProducts#"
			method="buildDiscountList"
			reqJSON = "#ATTRIBUTES.discountReq#"
			returnVariable="getUpdatedProducts"
		/>
	</cfif>


	<cfinvoke component="Objects.DynamicPricingResource"
		method="narrowResults"
		inputquery="#getUpdatedProducts#"
		categoryOrList="#URL.categoryList#"
		returnvariable="getUpdatedProducts">
<cfelse>
	<cfset searchDept = (isDefined("URL.deptID")) ? URLDecode(URL.deptID) : 0>
	<cfif ISDefined("ATTRIBUTES.showAll")>
		<cfset showAll = ATTRIBUTES.showAll>
		<cfelse>
			<cfset showAll = false>
	</cfif>
	<cfset masterID = ( isDefined("URL.masterID") ) ? URLDecode(URL.masterID) : 0>
	<cfif structkeyexists(ATTRIBUTES, "categoryID")>
		<cfquery name="checkDeptType" datasource="#DSN#">
			SELECT * FROM dbo.hierarchy_getChildren(<cfqueryparam cfsqltype="cf_sql_integer" value="#ATTRIBUTES.categoryID#">)
		</cfquery>
		<cfif checkDeptType.recordCount GT 0>
			<cfset masterID = ATTRIBUTES.categoryID>
			<cfelse>
				<cfset searchDept = ATTRIBUTES.categoryID>
		</cfif>
		<cfset showAll = true>
	</cfif>

	<cfif isDefined("URL.usePref")>
		<cfset usePref = URLDecode(URL.usePref)>
		<cfelse>
			<cfset usePref = 1>
	</cfif>

	<cfif (CGI.REQUEST_METHOD EQ "GET" OR IsDefined("ATTRIBUTES.useFilters") ) AND (showAll EQ False)>

		<cfinvoke
			component="objects.DynamicPricingResource"
			method="getUserUpdates"
			catID="#searchDept#"
			userID="#session.user.ID#"
			masterCatID="#masterID#"
			returnvariable="getUpdatedProducts"
		/>
		<cfelse>
			<cfinvoke
				component="objects.DynamicPricingResource"
				method="getAllUpdates"
				userID="#session.user.ID#"
				usePrefCosts="#userSettings.usePrefCosts#"
				returnvariable="getUpdatedProducts"
			/>
	</cfif>

	<cfif IsDefined('ATTRIBUTES.discountReq')>
		<cfinvoke component="objects.DynamicPricingResource"
			method="buildDiscountList"
			reqJSON = "#ATTRIBUTES.discountReq#"
			returnVariable="getUpdatedProducts"
		/>
	</cfif>

	<cfif IsDefined('ATTRIBUTES.discountReq') OR showAll>
		<cfset categoryOrList = "">
		<cfset narrowProd = 0>
		<cfif structkeyexists(URL, "editP")> <cfset narrowProd = ATTRIBUTES.productID></cfif>
		<cfset mustNarrow = false>
		<cfif masterID NEQ 0>
			<cfquery name="getCatList" datasource="#DSN#">
				SELECT categoryID FROM dbo.hierarchy_getChildren(<cfqueryparam cfsqltype="cf_sql_integer" value="#masterID#">)
			</cfquery>
			<cfset categoryOrList = ValueList(getCatList.categoryID)>
			<cfset mustNarrow = true>
			<cfelseif searchDept NEQ 0>
				<cfset categoryOrList = searchDept>
				<cfset mustNarrow = true>
		</cfif>
		<cfif mustNarrow OR showAll>
			<cfinvoke component="objects.DynamicPricingResource"
				method="narrowResults"
				inputQuery="#getUpdatedProducts#"
				categoryOrList="#categoryOrList#"
				productID = "#narrowProd#"
				returnvariable="getUpdatedProducts"
			/>
		</cfif>
	</cfif>
	<cfif CGI.REQUEST_METHOD EQ "POST" OR structKeyExists(ATTRIBUTES, "productID")>
			<cfquery name="temp" dbtype="query">
				SELECT * FROM getUpdatedProducts
				WHERE  <cfif structkeyexists(ATTRIBUTES, "mfg")><cfif ATTRIBUTES.mfg NEQ "">
					(lower(Manufacturer) LIKE<cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(ATTRIBUTES.mfg)#%">
						OR lower(cmfg) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#lcase(ATTRIBUTES.mfg)#%">)
						</cfif></cfif>
				<cfif IsDefined("ATTRIBUTES.productID")>
					<cfif structkeyexists(ATTRIBUTES, "mfg")><cfif ATTRIBUTES.mfg NEQ "">OR</cfif></cfif>  prodID IN (<cfqueryparam cfsqltype="cf_sql_integer" value="0,#ATTRIBUTES.productID#" list="true" separator=",">)
				</cfif>
			</cfquery>
			<cfset getUpdatedProducts = temp>
	</cfif>
	<cfif structkeyexists(URL, "editP") AND getUpdatedProducts.recordCount EQ 0>
		<cflocation url="/partnernet/productmanagement/editframe/editpricingp.cfm?productID=#ATTRIBUTES.productID#" addtoken="no">
		<cfabort>
	</cfif>
</cfif>
<cfinvoke component="objects.DynamicPricingResource"
	method="makeUnique"
	queryIn="#getUpdatedProducts#"
	returnvariable="getUpdatedProducts"
/>
<cfquery name="getChangeHistories" datasource="#DSN#">
	SELECT ol.objid
		, value
		, created
		, createdby
		, su.firstName + ' ' + su.lastname AS 'NAME'
	FROM tblObjectLog ol WITH (noLock)
	INNER JOIN tblSecurity_Users su ON su.ID=ol.createdby_int
	WHERE (value LIKE '(DR)%' OR value LIKE 'New retail%')
</cfquery>
<cffunction name="sortCompetitors">
	<cfargument name="CompList" default="">
	<cfargument name="priceList" default="">
	<cfargument name="shipList" default="">

	<cfif ListLen(compList) NEQ ListLen(priceList) OR ListLen(compList) NEQ ListLen(shipList) OR compList EQ ''>
		<cfreturn [[' ', 0, 0]]>
	</cfif>

	<cfset compArray = ArrayNew(2)>
	<cfloop from=1 to="#ListLen(compList)#" index="i">
		<cfset ArrayAppend( compArray, [ListGetAt(compList, i), ListGetAt(priceList, i), ListGetAt(shipList, i)])>
	</cfloop>

	<cfloop index="outer" from="1" to="#arrayLen(compArray)#">
		<cfloop index="inner" from="1" to="#arrayLen(compArray)-1#">
			<cfif compArray[inner][2] + compArray[inner][3] gt compArray[outer][2]+ compArray[outer][3]>
				<cfset arraySwap(compArray,outer,inner)>
			</cfif>
		</cfloop>
	</cfloop>
	<cfreturn compArray>
</cffunction>

<cfquery name="scheduledResetAlerts" datasource="#DSN#">
	SELECT rs.*
		, su.FirstName + ' ' + su.LastName AS 'userName'
	FROM tblRepriceScheduledResets rs WITH(NOLOCK)
	INNER JOIN tblSecurity_Users su on su.ID=rs.userID
</cfquery>

<cfset futureResetsList = ValueList(scheduledResetAlerts.prodID, ",")>
<html>

	<head>
		<link rel="stylesheet" href="//code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.5/jquery.fancybox.min.css" />
		<link rel="stylesheet" href="adminpanel.css?v=23">
		<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min.js"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.28.0/js/jquery.tablesorter.min.js"></script>
		<script src="/js/numeral.min.js"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.5/jquery.fancybox.pack.js"></script>
		<script>
			<cfajaxproxy cfc="objects.DynamicPricingResource" jsclassname="jsDRP">
			var j$ = jQuery.noConflict();
			var settings = {};
			settings.isSlider = false;
			function getCosmeticPrice(uglyPrice)
			{
					var price = Math.floor(uglyPrice) + .99;
					return price;
			}
			function numberWithCommas(x) {
			    var numWith = x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
			    if(numWith.indexOf(".") == -1){
			    	numWith += ".";
		    	}
			    while( numWith.split(".")[1].length < 2 ){
			    	numWith += "0";
			    }
			    return numWith;
			}
			function setOldValues()
			{
				j$( ".newmargins" ).each(function(){
					j$( this ).data("oldVal", j$( this ).val());
				});
			}

			function setScaleSlider()
			{
				setOldValues();
				var sl = j$( "#slider" ).slider( {value: 0});
				//set appropriate slider scale/steps
				sl.slider( "option", "min", -100 );
				sl.slider( "option", "max", 100 );
				sl.slider( "option", "step", .01 );
				//bind proper event handler
				sl.on( "slidechange", function(event, ui) {
					if( j$( ".select:checked").toArray().length > 0){
						scaleValues(ui.value);
						j$( "#slidervalue" ).text( ui. value + "%");
						settings.isSlider = true;
					}
				});
				j$( ".selected .newmargins").each(function(){
					j$( this ).val( j$( this ).data( "oldVal" ) );
					j$( this ).change();
				})
				j$("#slidervalue").text( "  ");
			}

			function setSetSlider()
			{
				var sl = j$( "#slider" ).slider();
				//set appropriate slider scale/steps
				sl.slider( "option", "min", 0 );
				sl.slider( "option", "max", 100 );
				sl.slider( "option", "step", .01 );
				//bind proper event handler
				sl.on( "slidechange", function(event, ui) {
					if( j$( ".select:checked").toArray().length > 0){
						setValues(ui.value);
						j$( "#slidervalue" ).text( ui. value + "%");
						settings.isSlider = true;
					}
				});
				j$("#slidervalue").text("  ");

			}

			function setValues( value )
			{
				<cfif !isAdmin>
					if( value < 0)
					{
						value = 0;
					}
				</cfif>
				if(value > 99.99)
				{
					value = 99.99;
				}
				j$( ".selected .newmargins" ).each(
					function()
					{
						j$( this ).val( value );
						//trigger change event to update price box
						j$( this ).change();
				});
			}

			function scaleValues( value )
			{
				j$( ".selected .newmargins" ).each(
					function()
					{
						var oldVal = parseFloat( j$( this).data("oldVal") );
						var newVal = oldVal + ((value / 100) * oldVal);

						<cfif !isAdmin>
							if( newVal < 0 )
							{
								newVal = 0;
							}
						</cfif>
						if( newVal > 99.99 )
						{
							newVal = 99.99;
						}
						j$( this ).val( newVal );
						//be sure to trigger change event to update price box
						j$( this ).change();
				});
			}

			function marginBoxChangeHandler( e )
			{

				var product = j$( this ).parents("tr").data("product");
				var cost = parseFloat( j$( "#" + product +"cost").text().replace("$", "").replace(",", "")  );
				var rawPrice = cost/ (1 - ( parseFloat( j$( this ).val() ) / 100));
				var newPrice = getCosmeticPrice(rawPrice);
				if( newPrice < 0 )
				{
					newPrice = 0;
				}

				j$( "#newprice" + product).val( newPrice );
				if(!settings.isSlider){
					j$("#slidervalue").text("  ");
				}
				settings.isSlider = false;
			}

			function priceBoxChangeHandler( e )
			{
				var price= parseFloat( j$( this ).val() );
				var product = j$( this ).parent().data("product");
				var cost = parseFloat( j$( "#" + product +"cost").text().replace("$", "").replace(",", "") );
				//Stop non admins from going outside proper ranges
				<cfif NOT isAdmin>
					//remove illgalChange class if necessary
					j$( this ).parent().removeClass("illegalChange");
					if( price < cost)
					{
						price = getCosmeticPrice( cost );
						j$( this ).val( price );
						//style for illegalChange
						j$( this ).parent().addClass("illegalChange");
						//j$( this ).change();
					}
				</cfif>
				var newMargin = 100 * (price - cost) / price;
				//round new margin to 4 spots after decimal
				newMargin = Math.ceil( newMargin * 10000) / 10000;
				j$("#newmargin" + product).val( newMargin );
				if(!settings.isSlider){
					j$("#slidervalue").text("  ");
				}
				settings.isSlider = false;

			}

			function addToolTips()
			{
					j$( ".currentPriceLink" ).each(function(){
						j$( this ).tooltip( {content:function(){
							var pID = j$( this ).parents( "tr" ).data( "product");
							return j$( "#retailPriceTooltip" + pID ).html();
						}, tooltipClass:"ui-tooltip"} );
					});
					j$( ".netCosts" ).each(function(){
						j$( this ).tooltip( {content: function(){
							return j$( "#costTooltip" + j$( this ).parent().data("product") ).html();
						}, tooltipClass:"ui-tooltip-wide"}  );
					});
					j$( ".recPrices" ).each(function(){
						j$( this ).tooltip( {content: function(){
							return j$( "#recTooltip" + j$( this ).parent().data("product") ).html();
						}} );
					});
					j$( ".stock" ).each(function(){
						j$( this ).tooltip( {content: function(){
							return j$( "#turnTooltip" + j$( this ).parent().data("product") ).html();
						}} );
					});
					j$( "#compChangeMO" ).tooltip( {content:function(){
						return "Change the prices of the selected products relative to the lowest priced competitor down to the price floor, which is the price of the product at the margin floor, currently <cfoutput> #adminSettings.stockedMarginFloor#</cfoutput>%.  If you select \"with shipping\", the price will match on the competitor's price plus their shipping price, add or subtract your amount from that total, and then subtract our average customer-paid shipping.  If you choose \"without shipping\", it will suggest a price based on the competitor's price without shipping and add or subtract your amount without subtracting our average customer paid shipping.";
					}} );
					<!--- j$( ".discountInfo" ).each(function(){
						j$( this ).tooltip( {content: function(){
							return j$( "#discountTooltip" + j$( this ).parent().data("product") ).html();
						}} );
					});	 --->
					j$( ".changeInfo" ).each(function(){
						j$( this ).tooltip({content:function(){
							return j$( "#changeHistory" + j$( this ).parent().data("product") ).html();
						}});
					});
					j$( ".resetAlertIcon" ).each(function(){
						j$( this ).tooltip({ content:function(){
							return j$( "#resetAlert" + j$( this ).data("product") ).html();
						}});
					});
					j$(".hideproduct").each(function(){
						j$( this ).tooltip();
					});
					j$(".markproducterror").each(function(){
						j$( this ).tooltip();
					});
					j$("#legendlink").tooltip({content:function(){
						return j$( "#legendwrapper" ).html();
					}, tooltipClass:"legendtip"
					 , position:{
					 	my:"top",
					 	at:"bottom +50"
					 } });
					 j$("#productlisting th").tooltip();
					 j$( ".removeSchedule" ).tooltip();
					 j$("a.iframe").tooltip();
			}

			function handleSelectionBoxes()
			{
					j$( ".select" ).change(function(){
						j$( this ).parent().parent().toggleClass("selected");
					});
			}
			function selectAll()
			{
					j$( "#selectAll" ).click(function(e){
						e.preventDefault();
						j$( "input.select" ).each(function(){
							j$( this ).prop("checked", true);
							j$( this ).parent().parent().addClass("selected")	;
						});
					});
			}
			function selectNone()
			{
					j$( "#selectNone" ).click(function(e){
						e.preventDefault();
						j$( "input.select" ).each( function(){
							j$( this ).prop("checked", false);
							j$( this ).parent().parent().removeClass("selected")	;
						});
					});
			}

			function sort()
			{
					j$("#productlisting").tablesorter({
										headers:{ 0:{sorter:false}, 11:{sorter:false}, 10:{sorter:'shortDate'}, 5:{sorter:'currency'}, 6:{sorter:'currency'},  9:{sorter:'currency'}},
										widgets:["zebra"],
										dateFormat : "mmddyyyy"}
									);//.tablesorterPager({container:j$("#pager"), positionFixed:false, seperator: " of ", size: parseInt( j$(".pagesize").val())});
			}

			function updateProducts()
			{
				var updateObj = {};
				updateObj.userID = <cfoutput>#session.user.ID#</cfoutput>
				updateObj.type = j$("[name='setType']:checked").val();
				updateObj.products = [];
				//initialize advanced update values
				updateObj.resetStock = 0;
				updateObj.resetStockLevel ='';
				updateObj.resetAt = 0;
				updateObj.resetAtDate = '';
				updateObj.useAdv = false;
				if( j$("#useAdv").attr("checked") == "checked" ){
					updateObj.useAdv = true;
					if( j$("#advType:checked").val() == 'D' ){
						updateObj.resetAt = 1;
						updateObj.resetAtDate =  j$( "#resetDate" ).val();
					}
					else{
						updateObj.resetStock = 1;
						updateObj.resetStockLevel = parseInt( j$( "#resetStock" ).val() );
					}
				}
				updateObj.priceType = j$( "#priceType").val();
				j$( "tr.selected").each(function(){
					var tempProd = {};
					tempProd.prodID= j$( this ).data("product");
					tempProd.isonsale=j$( this ).data("isonsale");
					tempProd.newPrice = parseFloat( j$( this ).find( ".newprices" ).val().replace("$", "").replace(",", "") );
					tempProd.newMargin = parseFloat( j$( this ).find( ".newmargins" ).val() );
					tempProd.newCompare = parseFloat( j$( this ).find( ".newcompares" ).val() );
					tempProd.newIsInCartPrice = (j$(this).find('.newincartprices:checked').length) ? 1:0;
					tempProd.currentPrice = parseFloat( j$( this ).find( ".currentPrice" ).text().replace("$", "").replace(",", "") );
					tempProd.isKit = j$( this ).is(".kit") ? 1 : 0;

					tempProd.isRepriceAutomatic = (j$(this).find('#toggleRepriceAutomatic:checked').length) ? 1:0;
					tempProd.setByAmount = parseFloat(j$(this).find('#setByAmount').val());
					tempProd.setByPercent = parseFloat(j$(this).find('#setByPercent').val());
					tempProd.setByCompare = parseFloat(j$(this).find('#setByCompare').val());
					if(isNaN(tempProd.setByPercent)){
						tempProd.setByPercent = 0.0;
					}
					if(isNaN(tempProd.setByAmount)){
						tempProd.setByAmount = 0.0;
					}
					tempProd.repriceByPercent = j$(this).find('#setByPercent').hasClass('driving') ? 1:0;

					if(tempProd.isRepriceAutomatic){
						var originalPriceChecker = new jsDRP();
						originalPriceChecker.setHTTPMethod('POST');
						var originalPriceDiv = j$(this).find('.recPrices');
						originalID = originalPriceDiv.attr('originalID');

						if(originalID){
							//DATA returns 2 rows as an array: [ORIGINAL PRODUCT PRICE, ORIGINAL PRODUCT ID]
							//ORIGINAL PRODUCT PRICE is accessed by array index '0'
							//ORIGINAL PRODUCT ID is accessed by array index '1'
							var response = originalPriceChecker.affirmOriginalProductPricing(originalID);
							var pArray = JSON.parse(response).DATA;
							var changedPrice = parseFloat(pArray[0]);
							if(changedPrice != parseFloat(j$(this).find('.recPrices').html().replace("$", "").replace(",", ""))) {
								if(tempProd.repriceByPercent){
									tempProd.newPrice = changedPrice * (1.0 - (tempProd.setByPercent / 100.00));
								}
								else{
									tempProd.newPrice = changedPrice - tempProd.setByAmount;
								}
								var formattedNew = numeral(changedPrice).format('$0.00');
								j$('.currentPriceLink').html(formattedNew);
								alert('The pricing of the original product has changed since the page was last loaded, \n\nThe old price was: ' + j$(this).find('.recPrices').html() + '\n\nThe new price is: ' + formattedNew);
								originalPriceDiv.html(formattedNew);
								originalPriceDiv.attr('originalprice', changedPrice);
							}
						}
					}
					updateObj.products.push( tempProd );
				});
				var updater = new jsDRP();
				//set method to POST to allow for larger sets of products
				updater.setHTTPMethod("POST");
				var response = updater.ajaxUpdateProducts(JSON.stringify(updateObj));
				var respObj = JSON.parse(response.replace("//", ""));
				alert(respObj.NUMSUCCESS + " of " + respObj.NUMREQUESTS + " successfully updated.");
				if(respObj.FAILDETAIL != '')
				{
					alert("ERROR: " + respObj.FAILDETAIL);
				}
				j$("tr.selected").each(function(){
					var tempProductID = j$( this ).data("product");
					var tempNewPrice = 0;
					var tempNewMargin = 0;

					var tempNew_setByAmount = 0;
					var tempNew_setByPercent = 0;
					var tempNew_repriceByPercent = 0;
					if( respObj.SUCCESSPRODS.indexOf( tempProductID ) != -1){
						for( var i =0; i < updateObj.products.length; i++ ){
							var tProd = updateObj.products[i];
							if( tProd.prodID ==  tempProductID){
								tempNewPrice = tProd.newPrice;
								tempNewMargin = tProd.newMargin;
								tempNewCompare = tProd.newCompare;
								tempNewIsInCartPrice = tProd.newIsInCartPrice;
								tempNew_setByAmount = tProd.setByAmount;
								tempNew_setByPercent = tProd.setByPercent;
								tempNew_repriceByPercent = tProd.repriceByPercent;
								break;
							}
						}
						j$( this ).addClass("successful");
						if(updateObj.type == 'P' || updateObj.type=='B'){
							j$( this ).find( ".currentPriceLink" ).text("$" + numberWithCommas(tempNewPrice) );
							j$( "#productlisting" ).trigger("updateCell", j$( this ).find(".currentPriceLink").parents("td").get(), false);
							j$( this ).find( ".currentMargin" ).text( tempNewMargin.toString().substring(0,6) + "%");
							j$( "#productlisting" ).trigger("updateCell", j$( this ).find( ".currentMargin" ).get(), false);
							var tShipCost = parseFloat( j$( "#tooltipCustomerShipping" + tempProductID ).text().replace("$","").replace(",","") );
							j$( ".tooltipCurrentPrice" + tempProductID).text( "$" + numberWithCommas( tempNewPrice ) );
							j$( ".tooltipCustomerCurrentTotal" + tempProductID ).text( "$" + numberWithCommas( tempNewPrice + tShipCost ) );

							j$( "#setByAmount").val(parseFloat(tempNew_setByAmount).toFixed(2));
							j$( "#setByPercent").val(parseFloat(tempNew_setByPercent).toFixed(2));
							if(tempNew_repriceByPercent){
								if(j$('.automaticAdjust').find( '.percent-disabled').length){
									changeHeaderToPercentEnabled();
								}
							}
							else{
								if(j$('.automaticAdjust').find('.amount-disabled').length){
									changeHeaderToAmountEnabled();
								}
							}
						}
						if(updateObj.type == 'B' || updateObj.type=='M'){
							j$( "#savedMarginCell" + tempProductID ).text( tempNewMargin.toString().substring(0,6) + "%" );
							j$( "#savedMarginPriceCell" + tempProductID ).text( "$" + numberWithCommas(tempNewPrice) );
							j$( this ).find(".newmargins").attr("targetmargin", tempNewMargin);
						}
						var tempDate = new Date();
						var tempMonth = (tempDate.getMonth() + 1);
						tempMonth = (tempMonth < 10) ? '0' + tempMonth.toString() : tempMonth;
						j$( "#changes" + tempProductID ).text( tempMonth + "/" + tempDate.getDate() + "/" + tempDate.getFullYear() );
						j$( "#changeNA" + tempProductID ).remove();
						j$( "#productlisting" ).trigger("updateCell", j$( "#changes" + tempProductID ).parents("td").get() );
					}
					else{
						if( respObj.FAILPRODS.indexOf( j$( this ).data("product") ) != -1){
							j$( this )	.addClass("failure");
						}
					}
				});
			}

			function confirmation() {
				j$( "#dialog-confirm" ).dialog({
					resizable: false,
					height:225,
					modal: true,
					buttons: {
						"Yes": function() {
							j$( this ).dialog( "close" );
							updateProducts();
					},
						Cancel: function() {
							j$( this ).dialog( "close" );
						}
					}
				});
			}

			function resetToRecPrices()
			{
				j$( ".newprices" ).each(function(){
					var recPrice = getCosmeticPrice( parseFloat( j$( this ).attr("recPrice") ) - .99 );
					var floor = getCosmeticPrice( parseFloat (j$( this ).data( "floor" )));
					var newPrice = ( floor > recPrice ) ? floor : recPrice;
					j$( this ).val( newPrice );
					j$( this ).change();
				});
				setOldValues();
			}

			function resetToTargetMargins()
			{
				j$( ".newmargins" ).each(function(){
					var tmpMrgn = parseFloat( j$( this ).attr("targetmargin") );

					if( tmpMrgn != 0 )
					{
						j$( this ).val( tmpMrgn );
						j$( this ).change();
					}
				});
				setOldValues();
			}

			function toggleAdmin( e )
			{
				j$( "#advancedSettings" ).toggle();
				e.preventDefault();
			}

			function hideProduct( productNumber )
			{
				var handler = new jsDRP();
				handler.setHTTPMethod("POST");
				var reqObj = {};
				reqObj.userID = <cfoutput>#session.user.ID#</cfoutput>;
				reqObj.prodID = productNumber;
				var respStr = handler.ajaxHideProduct(JSON.stringify(reqObj));
				if( respStr.indexOf("success") != -1 ){
					j$( "tr[data-product=" + productNumber +"]" ).remove();
					sort();
				}else{
					alert("Error occured.");
				}

			}
			function markProductError( productNumber )
			{
				var handler = new jsDRP();
				handler.setHTTPMethod("POST");
				var reqObj = {};
				reqObj.prodID = productNumber;
				var respStr = handler.ajaxMarkPossibleError(JSON.stringify(reqObj));
				j$("#mfrmdl" + productNumber).addClass("possibleerror");
			}
			function rowLevelControlHandling()
			{
				j$( "a.hideproduct" ).click(function(){
					hideProduct( j$( this ).data("product") );
				});
				j$( "a.markproducterror" ).click(function(){
					markProductError( j$( this ).data("product") );
				});
			}
			function refreshDisplay()
			{
				if( j$( "input[name='refreshtype']:checked" ).is( "#resetPrices" ) ){
					resetToRecPrices();
				}else{
					resetToTargetMargins();
				}
			}

			function selectCorrectRows()
			{
				var matchType = j$( "#theSelector" ).val();
				var secondaryMatchType = j$( "#costTypeSelector" ).val();
				secondaryMatchType = ( secondaryMatchType == "" ) ? secondaryMatchType : "." + secondaryMatchType
				var shipType = j$( "#theShippingTypeSelector" ).val();
				shipType = ( shipType == 'either' ) ? '' : '.' + shipType;
				var packQty = j$( "#packQuantitySelector" ).val();
				packQty = ( packQty == '' ) ? '' : '.' + packQty;
				j$( "input.select" ).each( function(){
					j$( this ).prop("checked", false);
					j$( this ).parent().parent().removeClass("selected");
				});
				if( matchType == "none" ){ return false;}
				if( matchType == "all" ){
					j$(" input.select" ).each(function(){
						j$( this ).prop("checked", true);
						j$( this ).parent().parent().addClass("selected");
					});
					return false;
				}
				matchType = ( matchType =="" ) ? matchType : "." + matchType;
				var selector =  matchType + secondaryMatchType + shipType + packQty + " input.select";

				j$( selector ).each(function(){
					j$( this ).prop("checked", true);
					j$( this ).parent().parent().addClass("selected");
				});

				return false;
			}

			function competitorPriceScaling()
			{
				var matchPlusShip = (  j$( "#compMatchShip" ).val() == "ship"  );
				var markDown = (  j$( "#compChangeOperator" ).val() == '-'  );
				var matchDollars = (  j$( "#compChangeUnit" ).val() == 'D'  );
				var matchDiff = parseFloat( j$( "#compChangeBy" ).val() );
				//alert(matchDiff);
				j$( "tr.selected .newprices" ).each(function(){
					var compPrice = (matchPlusShip) ? parseFloat( j$( this ).data( "compship" ) ) : parseFloat( j$( this ).data("compprice") );
					//ensure when price is made cosmetic, that the price will still be lower than the competitor
					compPrice -= .99;
					var diff = ( matchDollars ) ? matchDiff : matchDiff * compPrice / 100;
					//alert(diff);
					var newPrice = ( markDown ) ? compPrice - diff : compPrice + diff;
					newPrice -= ( matchPlusShip ) ? parseFloat( j$( this ).data("custship") ) : 0;
					//alert(newPrice);
					if( j$( "#useIdealPriceFailover" ).is(":checked") ){
						var idealGreater = ( j$( "#idealPriceComparator" ).val() == 'GT' );
						var idealPrice = parseFloat( j$( this ).data("idealprice"));
						if( idealGreater && idealPrice > newPrice ){
							newPrice = idealPrice;
						}else if( (!idealGreater) && idealPrice < newPrice ){
							newPrice = idealPrice;
						}
					}
					var floor = parseFloat( j$( this ).data( "floor" ) );
					if( newPrice < floor ){
						newPrice = floor;
					}
					j$( this ).val( getCosmeticPrice(newPrice) );
					j$( this ).change();
				});
				j$("#slidervalue").text("  ");
				setOldValues();
			}

			function okGo()
			{
				j$.tablesorter.addParser({
						id:'customDate',
						is:function(s){return false;},
						format:function(s){
							/*if(s == 'N/A'){
								return j$.tablesorter.formatFloat( new Date('09/03/1988') );
							} */

							return j$.tablesorter.formatFloat( new Date(s).getTime() );
						},
						type:'numeric'
					});
				j$.tablesorter.addParser({
					id:'moneyWithSymbols',
					is:function(s){return false;},
					format:function(s){
						return j$.tablesorter.formatFloat( parseFloat(s.toString().replace("$", "").replace(",","") ) );
					}
				})
				//radio buttons start on "set all"
				setSetSlider();
				setOldValues();
				j$("#slider").slider("option", "value", 0);
				j$( ".newmargins" ).change( marginBoxChangeHandler );
				j$( ".newprices" ).change( priceBoxChangeHandler );
				j$( ".newprices" ).keyup(function(){
					settings.isSlider = false;
				});
				j$( ".newmargins" ).keyup(function(){
					settings.isSlider = false;
				});
				j$("input[name='radio']").change( function()
					{
						if(this.value == 1) //value is 1 on set all button
						{
							setSetSlider();
						}
						else
						{
							setScaleSlider();
						}
				});
				//Add product data attribute to each td element for ease of access.
				j$( "tr[data-product]" ).each(function(){
					j$( this ).children().attr("data-product", j$( this ).data("product"));
				});
				//Trigger price box changes to set margin boxes
				resetToRecPrices();
				addToolTips();
				handleSelectionBoxes();
				selectAll();
				selectNone();
				sort();
				j$( "span#rCount" ).text( j$( ".newprices" ).toArray().length );
				//turn off clicks on mouseover links
				j$("tbody a[href='#']").click(function(e){e.preventDefault();});
				j$( "#toggleAdminSettings" ).click(toggleAdmin);
				j$("input[name='setType']").change(function(){
					if( j$( this ).val() == 'M' ){
						j$('#priceType').prop("disabled", true);
					}else{
						j$("#priceType").prop("disabled", false);
					}
				});
				j$( "[name='advType']" ).change(function(){
					j$(".advInput").prop("disabled", true);
					if( j$("#useAdv" ).is(":checked") ){
						j$( "." + j$( this ).val()  ).prop("disabled", false);
					}
				});
				j$("#useAdv").change( function(){
					if( j$( this ).is(":checked") ){
						j$( "[name='advType']:checked" ).change();
					}else{
						j$(".advInput").prop("disabled", true);
					}
				} );
				j$("#useAdv").change();
				j$('.dt').datepicker({
					autoSize: true
				});
				j$( ".removeSchedule" ).click(function(){
					var schedHandler = new jsDRP();
					schedHandler.setHTTPMethod("POST");
					var tID = j$( this ).data( "product" );
					var resp = schedHandler.ajaxUnSchedule( tID );
					if( resp == "SUCCESS"){
						j$( "#removeShedule" + tID ).remove();
						j$( "#resetAlertIcon" + tID ).remove();
					}
				});
				j$( "a.prodLightBox" ).fancybox({'type':'iframe', 'width':'75%'});
				j$("#slidervalue").text("  ");

				selectCorrectRows();
				if(j$('.automaticAdjust').length > 0)
				{
					initializeAutoRepriceRows();
				}

			}
			function updateFroogleFeed(){
				j$( "#uploadFroogleFeedButton" ).attr("disabled", "disabled");
				j$( "#uploadFroogleFeedButton" ).removeClass("green");
				j$( "#uploadFroogleFeedButton" ).addClass("gray");
				j$( "#uploadFroogleFeedButton" ).val( "Please wait..." );
				j$.ajax({
					url: 'ajax_uploadFroogleFeed.cfm',
					success:function(r){
						alert("Froogle Feed Uploaded");
						j$( "#uploadFroogleFeedButton" ).removeAttr("disabled");
						j$( "#uploadFroogleFeedButton" ).removeClass("gray");
						j$( "#uploadFroogleFeedButton" ).addClass("green");
						j$( "#uploadFroogleFeedButton" ).val("UPLOAD PRODUCT FEED TO GOOGLE");
					}
				});
			}


			function updatePriceFields()
			{
				var original = parseFloat(j$('.recPrices').attr('originalPrice'));


				var drivingResult = original;

				if(j$(this).parent().hasClass('priceCell'))
				{
					var adjustment = parseFloat(j$(this).val());
					drivingResult -= adjustment;
					var passengerTerm = (original == 0)?0.0:(adjustment / original) * 100.0;
					j$('#setByPercent').val(passengerTerm);

					j$('#setByPercent').removeClass('driving');
					j$('#setByAmount').addClass('driving');

					if(j$('.automaticAdjust').find('.amount-disabled').length)
					{
						changeHeaderToAmountEnabled();
					}
				}
				if(j$(this).parent().parent().parent().hasClass('marginCell'))
				{
					var adjustment = parseFloat(j$(this).val())/100.0;
					var passengerTerm = drivingResult*adjustment;
					drivingResult -= drivingResult*adjustment;
					j$('#setByAmount').val(passengerTerm);

					j$('#setByAmount').removeClass('driving');
					j$('#setByPercent').addClass('driving');

					if(j$('.automaticAdjust').find('.percent-disabled').length)
					{
						changeHeaderToPercentEnabled();
					}
				}
				//trigger runs and updates so send original price?
				j$('.priceCell .newprices').val(drivingResult.toFixed(2));
			}

			function initializeAutoRepriceRows()
			{
				j$('.automaticAdjust').each(function(){
					var enabledSpan = j$(this).find('.amount-enabled');
					var disabledSpan = j$(this).find('.percent-disabled');
					if(j$(this).find('.amount-enabled').length)
					{
						j$(this).find('input[type=radio]').prop('checked',true);
						j$('.automaticAdjust .percent-disabled').find('input[type=radio]').prop('checked',false);
						j$('#setByAmount').attr('value',parseFloat(j$('#setByAmount').parent().attr('value')).toFixed(2));
						j$('#setByPercent').prop('disabled', true);
					}
					if(j$(this).find('.percent-enabled').length)
					{
						j$(this).find('input[type=radio]').prop('checked',true);
						j$('.automaticAdjust .amount-disabled').find('input[type=radio]').prop('checked',false);
						j$('#setByPercent').attr('value',parseFloat(j$('#setByPercent').parent().parent().parent().attr('value')));
						j$('#setByAmount').prop('disabled', true);
					}
				});
				if(j$('#toggleRepriceAutomatic:checked').length)
				{
					j$('.manualAdjust').each(function(){
						j$(this).css("display","none");
					});
				}
				else
				{
					j$('.automaticAdjust').each(function(){
						j$(this).css("display","none");
					});
				}

				j$('#toggleRepriceAutomatic').click(toggleAutomatic);

				j$('.automaticAdjust span').each(function(){
					j$(this).click(toggleRadioButtons);
				});

				j$('#setByPercent').change(updatePriceFields);
				j$('#setByAmount').change(updatePriceFields);
				j$('.newprices').val(numeral(j$('.currentPriceLink').html()).format('0.00'));
			}

			function changeHeaderToPercentEnabled()
			{
				j$('.automaticAdjust').find('.percent-disabled').removeClass('percent-disabled').addClass('percent-enabled').find('input[type=radio]').prop('checked', true);
				j$('.automaticAdjust').find('.amount-enabled').removeClass('amount-enabled').addClass('amount-disabled').prop('disabled',true).find('input[type=radio]').prop('checked', false);

				if(j$('#setByPercent').val() && !j$('#setByPercent').hasClass('driving'))
				{
					j$('#setByPercent').addClass('driving').prop('disabled',false);
					j$('#setByAmount').removeClass('driving').prop('disabled',true);
				}

				j$('#setByPercent').prop('disabled',false);
				j$('#setByAmount').prop('disabled',true);
			}
			function changeHeaderToAmountEnabled()
			{
				j$('.automaticAdjust').find('.amount-disabled').removeClass('amount-disabled').addClass('amount-enabled').prop('disabled',false).find('input[type=radio]').prop('checked', true);
				j$('.automaticAdjust').find('.percent-enabled').removeClass('percent-enabled').addClass('percent-disabled').prop('disabled',true).find('input[type=radio]').prop('checked', false);

				if(j$('#setByAmount').val() && !j$('#setByAmount').hasClass('driving'))
				{
					j$('#setByAmount').addClass('driving').prop('disabled',false);
					j$('#setByPercent').removeClass('driving').prop('disabled',true);
				}
				j$('#setByAmount').prop('disabled',false);
				j$('#setByPercent').prop('disabled',true);
			}

			function toggleRadioButtons()
			{
				if(j$(this).hasClass('amount-disabled'))
				{
					changeHeaderToAmountEnabled();
				}
				if(j$(this).hasClass('percent-disabled'))
				{
					changeHeaderToPercentEnabled();
				}
			}
			function toggleAutomatic()
			{
				if(j$('#toggleRepriceAutomatic:checked').length)
				{
					j$('.manualAdjust').each(function(){
						j$(this).css("display","none");
					});
					j$('.automaticAdjust').each(function(){
						j$(this).css("display","table-cell");
					});
					j$('.automatic span').html('YES');
					j$('.snd-choice .tablesorter-header-inner').html(j$('.snd-choice .tablesorter-header-inner').html().replace('?',''));
				}
				else
				{
					j$('.manualAdjust').each(function(){
						j$(this).css("display","table-cell");
					});
					j$('.automaticAdjust').each(function(){
						j$(this).css("display","none");
					});
					j$('.automatic span').html('NO');
					j$('.snd-choice .tablesorter-header-inner').append('?');
				}
			}
			j$( okGo );

		</script>
	</head>
	<body>
		<h1>Dynamic Pricing Acceptance Panel</h1>
		<div id="topWrapper">
		<cfif !ISDEFINED("ATTRIBUTES.categoryID") AND !STRUCTKEYEXISTS(URL, "editP")>
			<div id="backLinksDiv"><a target="_top" href="/partnernet/dynamicPricingTool/listpage.cfm"><strong>Back to list page</strong></a>
			<cfif isAdmin>&nbsp;&nbsp;<a target="_top" href="/partnernet/dynamicPricingTool/adminpanel.cfm"><strong>Back to Admin Panel</strong></a></cfif></div>
		</cfif>
		<cfif getUpdatedProducts.RecordCount EQ 0>
			</div>
			No records to display.
			<cfelse>
				<div id="recordCount">
					<cfset rCount = getUpdatedProducts.RecordCount>
					<strong><cfoutput>#rCount# Product<cfif rCount GT 1>s</cfif> Displayed</cfoutput></strong>
				</div>
				<div id="updateOnSite">
					<div id="tablecontrols">
						<div id="radiogroup">
				   			<input type="radio" id="updatePrices" name ="setType" checked="checked" value="P"/><label for="updatePrices">Set Prices</label><br />
				   			<input type="radio" id="updateMargins" name ="setType" value="M"/><label for="updateMargins">Set Margins</label><br />
				   			<input type="radio" id="updateBoth" name ="setType" value="B"/><label for="updateBoth">Set Both</label>
			   			</div>
		   				<div id="dropDownControl"><span id="priceChangeTypeTitle">Change Which Price:</span><br />
			   				<select id="priceType">
				   				<option value="A" selected>Automatic</option>
				   				<option value="R">Regular Price</option>
				   				<option value="S">Sale Price</option>
			   				</select>
						</div>
		   			</div>
		   			<div id="buttongroup">
			   			<input type="button" class="button red" id="updaterButton" value="UPDATE ON ALPINE SITE" onClick="confirmation()">
			   			<div style="float: right;width: 225px;font-size: xx-small;margin-left: 25px; margin-top:-42px">Partnernet updates the Google feed hourly from 05:47 until 23:47 each day.  Reprice during these hours to avoid getting out of synch with Google and having products removed from PLAs.</div>
			   			<!--- <input type="button" class="button green" id="uploadFroogleFeedButton" onClick="updateFroogleFeed()" value="UPLOAD PRODUCT FEED TO GOOGLE" disabled style="opacity:.4;"> --->
		   			</div>
					<div id="advancedSettings">
						<form>
							<input type="checkbox" id="useAdv" name="useAdv"><label for="useAdv">Revert to Current Retail Price</label><br />
							<input type="radio" name="advType" value="D" checked="true">On Date: <input class="D advInput dt" type="date" name="resetDate"><br />
							<input type="radio" name="advType" value="S">When stock is equal to or below: <input class="S advInput" type="number" name="resetStock">
						</form>
					</div>
				</div>
				</div>
				<form name="updateProductPrices" action="acceptancepanel.cfm">
					<div id="acceptancelist">
						<div id="legendbox">
							<a id="legendlink" href="#" title="">Hover for Legend</a>
						</div>
						<div id="controlswrapper">
							<div id="rightControlShell">
								<div id="rightControls">
									<h3>Change Prices On Grid Display for Selected Rows</h3>
									<div id="sliderbox">
										<div id="slider"></div><div id="slidervaluebox"><span id="slidervalue"></span></div><br /><br />
										<div id="sliderRadios"><input type="radio" id="radio1" name="radio" value="1" checked="checked" /><label for="radio1">Set Selected</label>
								   		<input type="radio" id="radio2" name="radio" value="2" /><label for="radio2">Scale Selected</label></div>
									</div>
									<div id="topCompPriceChange">
									Set selected prices relative to lowest competitor price<span id="compChangeMO" class="ui-icon ui-icon-info" title=""></span>
										<div class="rightControlBox">
											<select id="compMatchShip">
												<option value="ship">With Shipping</option>
												<option value="noship">Without Shipping</option>
											</select>
											<select id="compChangeOperator">
												<option value="-" SELECTED>Minus</option>
												<option value="+">Plus</option>
											</select>
											<input type="text" validate="float" name="compChangeBy" id="compChangeBy">
											<select id="compChangeUnit">
												<option value="D" SELECTED>Dollars</option>
												<option value="P">Percent</option>
											</select><br />
											<label><input type="checkbox" checked="checked" id="useIdealPriceFailover" />Or Ideal Price, whichever is</label>
											<select id="idealPriceComparator">
												<option value="LT">Lesser</option>
												<option value="GT">Greater</option>
											</select>
											<input type="button" onclick="competitorPriceScaling()" value="Go" />
										</div>
									</div>
				   				</div>
			   				</div>
							<div id="notslider">
								<label><input type="radio" name="refreshtype" id="resetPrices" checked="checked">Display Recommended Retail Prices (and margin)</label><br />
				   				<label><input type="radio" name="refreshtype" id="resetMargins">Display Saved Margins</label><br />
				   				<input type="button" id="refreshdisplay" value="Refresh Grid Display" onclick="refreshDisplay();">
			   				</div>
			   				<div id="rowSelector">
								<select id="theSelector">
									<option value="all">*All Products*</option>
									<option value="none">*No Products*</option>
									<option value="">Either Matched or Unmatched</option>
									<option value="matched">Products Matched by Wisepricer</option>
									<option value="unmatched">Products Unmatched by Wisepricer</option>
								</select><br />
								<select id ="costTypeSelector">
									<option value="">Either with or without Current Pricing</option>
									<option value="current">Products with Current Vendor Pricing</option>
									<option value="nocurrent">Products without Current Vendor Pricing</option>
								</select><br />
								<select id="theShippingTypeSelector">
									<option value="either">Freight And Small Pack Products</option>
									<option value="freeship">Freight Products</option>
									<option value="paidship">Small Pack Products</option>
								</select><br />
								<select id="packQuantitySelector">
									<option value="">Single Or Multi Pack</option>
									<option value="single">Single Pack Products Only</option>
									<option value="multi">Multi Pack Products Only</option>
								</select><br />
								Select Rows <input type="button" onclick=" selectCorrectRows();" value="Go" />
							</div>
						</div>
						<table id="productlisting">
							<thead>
								<tr id="productlistingheaders">
									<th>Selected?</th>
									<th>Manufacturer<br />& Model</th>
									<th>Stock</th>
									<th>Active</th>
									<th>Free<br />Ship?</th>
									<th title="The cost of the product plus shipping and less any anticipated rebates. Average costs are historical averages from netsuite and current vendor costs are current pricing from vendors and should reflect new price lists.">Net<br />Cost<span class="ui-icon ui-icon-info"></span></th>
									<th>Current<br />Retail Price</th>
									<th>Current<br />Margin</th>
									<cfif getUpdatedProducts.Category NEQ 96>
										<th title="The ideal profit margin as calculated by the formula set on the admin panel.">Ideal<br />Margin<span class="ui-icon ui-icon-info"></span></th>
									</cfif>
									<cfif getUpdatedProducts.Category EQ 96>
										<th title="Recommended prices for SND products are the price of the new product in our inventory.">Original Model<br />Retail Price<span class="ui-icon ui-icon-info"></span></th>
									<cfelse>
										<th title="Recommended prices received from wisepricer are based on the lowest price of our competitors minus $1 down to a minimum price. Unless the product is a kit, then the recommended price is based on the total retail of all of the products in the kit minus the Kit Markdown recommendation on the admin panel, currently <cfoutput>#NumberFormat(adminSettings.kitPriceRecommendation, '.99')#</cfoutput>%.">Recommended<br />Retail Price<span class="ui-icon ui-icon-info"></span></th>
									</cfif>
									<th title="The date of the last time this product was repriced.">Last<br />Price Change<span class="ui-icon ui-icon-info"></span></th>
									<!---<th>Apply<br />Discount</th> --->
									<cfif getUpdatedProducts.Category EQ 96>
										<th class="snd-choice">Automatic Retail<br /> Based on original<cfif !getUpdatedProducts.isRepriceAutomatic>?</cfif></th>
									</cfif>
									<th class="manualAdjust">New Price</th>
									<th class="manualAdjust">New<br />Margin</th>
									<th class="manualAdjust">MAP/Compare<br />Price</th>
									<cfif getUpdatedProducts.Category EQ 96>
										<form>
											<th class="automaticAdjust" >Discount Off<br />Original
												<span class=<cfif !#getUpdatedProducts.repriceByPercent#>"amount-enabled"<cfelse>"amount-disabled"</cfif>>
													<input type="radio">
												</span>
											</th>
											<th class="automaticAdjust" >Percent Off<br />Original
												<span class=<cfif#getUpdatedProducts.repriceByPercent#>"percent-enabled"<cfelse>"percent-disabled"</cfif>>
													<input type="radio">
												</span>
											</th>
										</form>
									</cfif>
									<th class="manualAdjust">Hide Price<br />Until Cart</th>
								</tr>
							</thead>
		 				<cfloop query="getUpdatedProducts">
							<tbody>
			 				<cfset cList ="">
			 				<cfset pList ="">
			 				<cfset sList ="">
			 				<cfif comp1 NEQ ""><cfset cList &= Replace(comp1, ',' ,'')> <cfset pList &= comp1Price> <cfset sList &= comp1Ship> </cfif>
			 				<cfif comp2 NEQ ""><cfset cList &=  ("," & Replace(comp2, ',', ''))> <cfset pList &=  ("," & comp2Price)> <cfset sList &=  ("," & comp2Ship)> </cfif>
			 				<cfif comp3 NEQ ""><cfset cList &=  ("," & Replace(comp3, ',', ''))><cfset pList &=  ("," & comp3Price)> <cfset sList &=  ("," & comp3Ship)> </cfif>
			 				<cfif comp4 NEQ ""><cfset cList &=  ("," & Replace(comp4, ',', ''))><cfset pList &=  ("," & comp4Price)> <cfset sList &=  ("," & comp4Ship)> </cfif>
			 				<cfif comp5 NEQ ""><cfset cList &=  ("," & Replace(comp5, ',', ''))><cfset pList &=  ("," & comp5Price)> <cfset sList &=  ("," & comp5Ship)> </cfif>
			 				<cfset rankedComp = sortcompetitors(cList, pList, sList)>
			 				<cfset hasPendingReset = (ListContainsNoCase(futureResetsList, prodID, ",") NEQ 0)>
								<cfoutput>
									<cftry>
										<cfset netCost=nominalCost + shipCost - anticipatedRebate>
										<cfcatch>
											<cfset netCost = 0><!--- TODO: --->
										</cfcatch>
									</cftry>
									<cfinvoke component="objects.DynamicPricingResource"
										method="getCeilingMargin"
										lowMargin="#adminSettings.oneCentMargin#"
										highMargin="#adminSettings.fiveKMargin#"
										dollarAmount=	"#netCost#"
										returnvariable="idealMargin"/>
									<cfinvoke component="objects.DynamicPricingResource"
										method="getSNDPriceComparison"
										prodID="#prodID#"
										returnvariable="priceComparison"/>

									<cfset idealPrice = netCost/  ( (100 - idealMargin)/100 )>
									<tr data-idealprice="#idealPrice#" data-idealmargin="#idealMargin#" data-product="#prodID#" data-isonsale="#isonsale#" data-smoothedprice="#smoothedPrice#" data-issmoothable="#isSmoothable#" class="<cfif packQty GT 1> multi<cfelse> single</cfif><cfif comp1 EQ ''> unmatched<cfelse> matched</cfif><cfif isPref EQ 0> nocurrent<cfelse> current</cfif><cfif freeship EQ 1> freeship<cfelse> paidship</cfif><cfif isKit EQ 1> kit</cfif>">

										<td class="ch"> <input type="checkbox" name="set#prodID#" class="select"><cfif hasPendingReset> <span title="" class="ui-icon ui-icon-notice resetAlertIcon" id="resetAlertIcon#prodID#" data-product="#prodID#"></span><a href="##" id="removeShedule#prodID#" data-product="#prodID#" class="removeSchedule"><span class="ui-icon ui-icon-closethick unschedule" title="Remove Scheduled Reset?"></span></a></cfif></td>
										<td id="mfrmdl#prodID#" <!--- <cfif isPossibleError EQ 1> class="possibleerror"</cfif> --->><a class="iframe prodLightBox" href="#getUpdatedProducts.url#" title="Click to view live product page.">#Manufacturer# #ModelNumber#</a><cfif isKit EQ 1> <span class="kitspan">KIT</span></cfif></td>

										<td><a href="##" class="stock <cfif turnoverRate LT adminSettings.turnThreshold AND turnoverRate NEQ -1 >lowturns</cfif><cfif turnoverRate EQ -1> turnsMissing</cfif>" title="">#stockOnHand#</a></td>
										<td>#Active EQ 1#</td>
										<td>#freeShip EQ 1#</td>
										<td class="currency" id="#prodID#cost" ><a href="##"class="netCosts <cfif <!--- usePrefCosts EQ 1 AND ---> isPref EQ 0>notpref</cfif> " title="">#NumberFormat(netCost, "$,.99")#</td>
										<cfif Category EQ 96>
											<td class="currentPrice currency"><a href="##" class="currentPriceLink <cfif isonsale EQ 1> onSale</cfif>" title="" originalPrice="#priceComparison.ActualSNDPrice#">#NumberFormat(priceComparison.ActualSNDPrice, "$,.99")#</a></td>
										<cfelse>
											<td class="currentPrice currency"><a href="##" class="currentPriceLink <cfif isonsale EQ 1> onSale</cfif>" title="">#NumberFormat(currentPrice, "$,.99")#</a></td>
										</cfif>
										<td class="decimal currentMargin">#NumberFormat((currentPrice - netCost)/currentPrice * 100, ".99")#%</td>
										<cfif getUpdatedProducts.Category NEQ 96>
											<td class="decimal">
												#NumberFormat( idealMargin, ".99")#%
											</td>
										</cfif>
										<cfif Category EQ 96>
											<td class="currency"><a class="recPrices <cfif comp1 EQ ''> noComp</cfif>" href="##" title="" originalID="#priceComparison.originalID#"originalPrice="#priceComparison.normalProduct#">#DollarFormat(priceComparison.normalProduct)#</a></td>
										<cfelse>
											<td class="currency"><a class="recPrices <cfif comp1 EQ ''> noComp</cfif>" href="##" title="" >#NumberFormat((recommendedPrice NEQ -1) ? recommendedPrice : idealPrice, '$,.99')#</a></td>
										</cfif>
										<cfset changeDate = DateFormat(lastChange, 'mm/dd/yyyy')>
										<cfset changeDate = (changeDate EQ '09/03/1988') ? '' : changeDate>
										<td><a href="##" class="changeInfo" id="changes#prodID#" title="" >#changeDate# </a>#(changeDate EQ '') ? '<span id="changeNA#prodID#">N/A </span>' : ''#</td>

										<cfif Category EQ 96>
											<td class="automatic"><input id="toggleRepriceAutomatic" type="checkbox" name="autoreprice_#prodID#"<cfif #int(isRepriceAutomatic)# >checked="checked"</cfif></input> <span><cfif isRepriceAutomatic>YES<cfelse>NO</cfif></span></td>
										</cfif>

										<td class="priceCell manualAdjust">$<input id="newprice#prodID#" type="text" validate="float" name="newprice#prodID#" class="newprices" recPrice="#NumberFormat((recommendedPrice NEQ -1) ? recommendedPrice : idealPrice, '.99')#" size="6" data-compprice="#comp1price#" data-compship="#rankedComp[1][2] + rankedComp[1][3]#" data-custship="#customerShipping#" data-floor="#netCost/(1 - (adminSettings.stockedMarginFloor/100))#" data-idealprice="#idealPrice#"></td>

										<td class="marginCell manualAdjust">
											<div class="lastcellWrapper" style="position:relative;">
												<div class="marginWrapper">
													<input id="newmargin#prodID#" type="text" validate="float" name="newmargin#prodID#" class="newmargins" targetmargin="#targetmargin#" size="6" maxlength="8">%</div>
											</div>
										</td>
										<cfif Category EQ 96>
											<td class="priceCell automaticAdjust" value="#setByAmount#" byAmount=<cfif#repriceByPercent#>0<cfelse>1</cfif>>$
														<input id="setByAmount" type="text" validate="fixed" size="6" maxlength="8">
											</td>

											<td class="marginCell automaticAdjust" value="#setByPercent#" byPercent=<cfif#repriceByPercent#>1<cfelse>0</cfif>>
												<div class="lastcellWrapper" style="position:relative;">
													<div class="marginWrapper">
														<input id="setByPercent" type="text" validate="float" size="6" maxlength="8">%
													</div>
												</div>
											</td>
											<td>
										</cfif>
										<td style="white-space: nowrap;">
											$<input style="width:75px" name="newCompare#prodID#" class="newcompares" value="#val(getUpdatedProducts.ComparePrice) ? getUpdatedProducts.ComparePrice : round(getUpdatedProducts.CURRENTPRICE  * 1.31) + 0.99#">
										</td>
										<td>
											<input type="checkbox" name="newIsInCartPrice#prodID#" class="newincartprices" value="1" <cfif getUpdatedProducts.isInCartPrice>checked</cfif>>
										</td>
									</tr>
								</cfoutput>
							</cfloop>
							</tbody>
						</table>
					</div>
				</form>
				<cfloop query="getUpdatedProducts">
					<cftry>
						<cfset netCost=nominalCost + shipCost - anticipatedRebate>
						<cfcatch>
							<cfset netCost = 0><!--- TODO: --->
						</cfcatch>
					</cftry>
					<cfinvoke component="objects.DynamicPricingResource"
						method="getCeilingMargin"
						lowMargin="#adminSettings.oneCentMargin#"
						highMargin="#adminSettings.fiveKMargin#"
						dollarAmount=	"#netCost#"
						returnvariable="idealMargin"
					/>
					<cfset idealPrice = netCost/  ( (100 - idealMargin)/100 )>
					<cfoutput>
						<div style="display:none;" id="retailPriceTooltip#prodID#">
							<div>
								<table>
									<tr>
										<th>Current Retail</th>
										<th>Customer Shipping Cost</th>
										<th>Total Price with Shipping</th>
									</tr>
									<tr>
										<td class="tooltipCurrentPrice#prodID#">#NumberFormat( currentPrice, "$,.99" )#</td>
										<td id="tooltipCustomerShipping#prodID#">#NumberFormat( customerShipping, "$,.99" )#</td>
										<td class="tooltipCustomerCurrentTotal#prodID#">#NumberFormat( currentPrice + customerShipping, "$,.99" )#</td>
									</tr>
								</table>
							</div>
						</div>
						<cfquery name="getThisProdHistory" dbtype="query" maxrows="20">
							SELECT * FROM getChangeHistories
							WHERE objID = <cfqueryParam cfsqltype="cf_sql_varchar" value="#prodID#">
							ORDER BY created DESC
						</cfquery>
					<div id="changeHistory#prodID#" style="display:none;">
						<div>
							<table>
								<tr>
									<th>Date</th>
									<th>User</th>
									<th>Log Entry</th>
								</tr>
								<cfloop query="getThisProdHistory">
									<tr>
										<td>
											#DateFormat(created,  'mm/dd/yyyy')#
										</td>
										<td>
											#Name#
										</td>
										<td>
											#value#
										</td>
									</tr>
								</cfloop>
							</table>
						</div>
					</div>
					<cfset hasPref = ( currentVendorCost NEQ 0 )>
						<div style="display:none;" id="costTooltip#prodID#">
							<div>
								<table style="text-align:center;">
									<tr>
										<th>Average Cost</th>
										<th>Current Vendor Cost</th>
										<th>Shipping Cost</th>
										<th>Average Expected Rebate</th>
										<th>Current Expected Rebate</th>
										<th>Average Net Cost</th>
										<th>Current Net Cost</th>
									</tr>
									<tr>
										<td>#NumberFormat(averageCost, "$,.99")#</td>
										<td>
												<cfif hasPref>#NumberFormat(currentVendorCost, "$,.99")#<cfelse>N/A</cfif>
										</td>
										<td>
											#NumberFormat(shipCost, "$,.99")#
										</td>
										<cfset avgRebate = rebatePct * averageCost>
										<cfset currentRebate = rebatePct * currentVendorCost>
										<td> #NumberFormat(avgRebate, "$,.99")# (#NumberFormat(rebatePct * 100, ".99")#%) </td>
										<td><cfif hasPref>#NumberFormat(currentRebate, "$,.99")# (#NumberFormat(rebatePct * 100, ".99")#%)<cfelse>N/A</cfif> </td>
										<td>
												#NumberFormat(shipCost + averageCost - avgRebate, "$,.99")#
										</td>
										<td><cfif hasPref>#NumberFormat(shipCost + currentVendorCost - currentRebate, "$,.99")#<cfelse>N/A</cfif></td>
									</tr>
								</table>
							</div>
						</div>
						<cfset cList ="">
			 				<cfset pList ="">
			 				<cfset sList ="">
			 				<cfif comp1 NEQ ""><cfset cList &= Replace(comp1, ',' ,'')> <cfset pList &= comp1Price> <cfset sList &= comp1Ship> </cfif>
			 				<cfif comp2 NEQ ""><cfset cList &=  ("," & Replace(comp2, ',', ''))> <cfset pList &=  ("," & comp2Price)> <cfset sList &=  ("," & comp2Ship)> </cfif>
			 				<cfif comp3 NEQ ""><cfset cList &=  ("," & Replace(comp3, ',', ''))><cfset pList &=  ("," & comp3Price)> <cfset sList &=  ("," & comp3Ship)> </cfif>
			 				<cfif comp4 NEQ ""><cfset cList &=  ("," & Replace(comp4, ',', ''))><cfset pList &=  ("," & comp4Price)> <cfset sList &=  ("," & comp4Ship)> </cfif>
			 				<cfif comp5 NEQ ""><cfset cList &=  ("," & Replace(comp5, ',', ''))><cfset pList &=  ("," & comp5Price)> <cfset sList &=  ("," & comp5Ship)> </cfif>
		 				<cfset rankedComp = sortcompetitors(cList, pList, sList)>
		 				<cfset numComp = ArrayLen(rankedComp)>
						<div style="display:none;" id="recTooltip#prodID#">
							<div>
								<cfif isKit EQ 0>
									<cfset dataPullDate = DateFormat(lastDataPull,'mm/dd/yyyy')>
									<cfif dataPullDate NEQ '09/03/1988'>
										<strong>Last Wisepricer Update: #dataPullDate#</strong>
										<cfelse>
											<strong>Data not received from Wisepricer</strong>
									</cfif>
									<table>
										<cfif numComp GTE 1 AND rankedComp[1][2] NEQ 0>
										<tr>
											<th>Competitors</th>
											<th>Price</th>
											<th>Shipping Price</th>
											<th>Total</th>
										</tr>
										<tr>
											<td>#rankedComp[1][1]#</td>
											<td class="currency">#NumberFormat(rankedComp[1][2], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[1][3], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[1][2] + rankedComp[1][3], "$,.99")#</td>
										</tr>
										<cfif numComp GTE 2>
										<tr>
											<td>#rankedComp[2][1]#</td>
											<td class="currency">#NumberFormat(rankedComp[2][2], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[2][3], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[2][2] + rankedComp[2][3], "$,.99")#</td>
										</tr>
										</cfif>
										<cfif numComp GTE 3>
										<tr>
											<td>#rankedComp[3][1]#</td>
											<td class="currency">#NumberFormat(rankedComp[3][2], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[3][3], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[3][2] + rankedComp[3][3], "$,.99")#</td>
										</tr>
										</cfif>
										<cfif numComp GTE 4>
										<tr>
											<td>#rankedComp[4][1]#</td>
											<td class="currency">#NumberFormat(rankedComp[4][2], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[4][3], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[4][2] + rankedComp[4][3], "$,.99")#</td>
										</tr>
										</cfif>
											<cfif numComp GTE 5>
										<tr>
											<td>#rankedComp[5][1]#</td>
											<td class="currency">#NumberFormat(rankedComp[5][2], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[5][3], "$,.99")#</td>
											<td class="currency">#NumberFormat(rankedComp[5][2] + rankedComp[5][3], "$,.99")#</td>
										</tr>
										</cfif>
										<tr>
											<td>Alpine Home Air</td>
											<td class="currency tooltipCurrentPrice#prodID#">#NumberFormat(currentPrice, "$,.99")#</td>
											<td class="currency tooltipCustomerShipping#prodID#">#NumberFormat(customerShipping, "$,.99")#</td>
											<td class="currency tooltipCustomerCurrentTotal#prodID#">#NumberFormat(currentPrice + customerShipping, "$,.99")#</td>
										</tr>
										<cfelse>
											<tr><td>No competitors found</td></tr>
										</cfif>
									</table>
									<cfelse>
										<cfquery name="getSubProducts" datasource="#DSN#">
											SELECT p.ID
												, CASE WHEN p.isConcealed=1
													THEN p.cmfg
													ELSE p.Manufacturer
												END AS 'tempMfr'
												, CASE WHEN p.isConcealed=1
													THEN p.cmodel
													ELSE p.ModelNumber
												END AS 'tempModel'
												, p.retailPrice AS 'tempPrice'
												, pk.kitprodqty AS 'tempQty'
											FROM Products p WITH(NOLOCK)
											INNER JOIN tblproductkits pk on pk.kitprodID = p.ID
											WHERE pk.kitmasterprodID=<cfqueryparam cfsqltype="cf_sql_integer" value="#prodID#">
										</cfquery>
										<table>
											<tr><th colspan="4">Kitted Products</th></tr>
											<tr>
												<th>Product ID</th>
												<th>Manufacturer and <br />Model Number</th>
												<th>Current Price</th>
												<th>Quantity<br />In Kit</th>
											</tr>
											<cfset tPriceTotal = 0>
											<cfset tQtyTotal = 0>
										<cfloop query="getSubProducts">
											<tr>
												<td>#ID#</td>
												<td>#tempMfr# #tempModel#</td>
												<td>#NumberFormat(tempPrice, "$,.99")#</td>
												<td>#tempQty#</td>
											</tr>
											<cfset tQtyTotal += tempQty>
											<cfset tPriceTotal += tempPrice>
										</cfloop>
											<tr>
												<th colspan="2">Totals</th>
												<td>#NumberFormat(tPriceTotal, "$,.99")#</td>
												<td>#tQtyTotal#</td>
											</tr>
										</table>
								</cfif>
								<br />
								<table>
									<tr>
										<th>Saved Margin</th>
										<th>Price At Saved Margin</th>
									</tr>
									<tr>
										<cfif targetmargin NEQ 0>
											<td id="savedMarginCell#prodID#">#NumberFormat(targetmargin, ".999")#</td>
											<cfset tempCost =  (nominalCost + shipCost)>
											<cfset tempCost = tempCost - anticipatedRebate>
											<td id="savedMarginPriceCell#prodID#">#NumberFormat(tempCost / ( 1 - (targetmargin /100) ), "$,.99")#</td>
											<cfelse>
												<td id="savedMarginCell#prodID#">N/A</td>
												<td id="savedMarginPriceCell#prodID#">N/A</td>
										</cfif>
									</tr>
								</table>
								<br />
								<table>
									<tr>
										<th>Ideal Margin</th>
										<th>Ideal Price</th>
									</tr>
									<tr>
										<td>#NumberFormat(idealMargin, ".99")#%</td>
										<td>#NumberFormat(idealPrice, "$,.99")#</td>
									</tr>
								</table>
								<br />
								<table>
									<tr>
										<th>Margin Floor</th>
										<th>Retail Price at Margin Floor</th>
									</tr>
									<tr>
										<td>#NumberFormat(adminSettings.stockedMarginFloor, ".99")#%</td>
										<cfset tempPrice = (nominalCost + shipCost - anticipatedRebate) / (1 - (adminSettings.stockedMarginFloor / 100))>
										<td>#NumberFormat(tempPrice, "$,.99")#</td>
									</tr>
								</table>
								<cfif isSmoothable EQ 1>
									<br />
									<table>
										<tr>
											<th>Smoothed Price</th>
										</tr>
										<tr>
											<td>#NumberFormat(smoothedPrice, "$,.99")#</td>
										</tr>
									</table>
								</cfif>
							</div>
						</div>
						<div id="turnTooltip#prodID#" style="display:none;">
							<div>
								<table>
									<tr>
										<th>Inventory Turns</th>
									</tr>
									<tr>
										<td>&nbsp;
											<cfif turnoverRate NEQ -1>
												#turnoverRate#
												<cfelse>
												Data Missing
											</cfif>
											&nbsp;</td>
									</tr>
								</table>
							</div>
						</div>
					</cfoutput>
				</cfloop>
			<cfloop query="scheduledResetAlerts">
				<cfoutput>
					<div id="resetAlert#prodID#" style="display:none;">
						<p class="resetAlertInfo">#userName# scheduled an automatic price reset for this product.  The <cfif salePrice EQ 1>sale </cfif>price will be set to #NumberFormat(oldPrice, "$,.99")#<cfif resetAt EQ 1> on #resetAtDate#<cfelse> when stock reaches #resetStockLevel#</cfif>.</p>
					</div>
				</cfoutput>
			</cfloop>
		</cfif>
	<!--- LEGEND --->
		<div style="display:none;">
			<div id="legendwrapper">
				<table id="legend">
					<thead>
						<tr>
							<th>Set?</th>
							<th>Stock</th>
							<th>Net<br />Cost</th>
							<th>Current<br />Retail Price</th>
							<th>Rec. Retail</th>
						</tr>
					</thead>
					<tbody>
						<tr class="odd">
							<td> <span class="ui-icon ui-icon-notice"></span> Scheduled Reprice Pending</td>
							<td><a class="missingTurns" href="#">Turns Missing</a></td>
							<td><a class="notpref" href="#">Using Average Cost</a></td>
							<td><a class="netCosts" href="#">Regular Price</a></td>
							<td><a class="noComp" href="#">No Competitors</a></td>
						</tr>
						<tr class="even">
							<td>&nbsp;</td>
							<td><a class="lowturns" href="#">Low Turns</a></td>
							<td><a class="netCosts"href="#">Uses Current Cost</a></td>
							<td ><a class="onSale" href="#">Sale Price</a></td>
							<td><a class="recPrices" href="#">Has Competitors Listed</a></td>
						</tr>
						<tr class="odd">
							<td>&nbsp;</td>
							<td><a class="recPrices" href="#">Turns Acceptable</a></td>
							<td>&nbsp;</td>
							<td>&nbsp;</td>
							<td>&nbsp;</td>
						</tr>
					</tbody>
					<caption>Bold items on the listing table have mouse-overs</caption>
				</table>
			</div>
		</div>

		<div id="hideDialog" style="display:none;">
			<div id="dialog-confirm" title="Update Immediately?">
				<p><span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 20px 0;"></span>These changes will go live on the site immediately. Are you sure?</p>
			</div>
		</div>
	</body>
</html>
<cfinclude template="/partnernet/shared/_footer.cfm">
