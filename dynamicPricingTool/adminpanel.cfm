<cfset screenID = 1100>
<cfinclude template="/partnernet/shared/_header.cfm">
<cffunction name="getSettings" returntype="query">
	<cfinvoke 
		component="alpine-objects.DynamicPricingResource"
		method="getSettings"
		returnvariable="retstruct"
	/>
	<cfreturn retStruct>
</cffunction>

<cffunction name="updateSettings">
	<cfargument name="oneCentMargin" required="true" type="numeric">
	<cfargument name="fiveKMargin" required="true" type="numeric">
	<cfargument name="stockMarginFloor" required="true" type="numeric">
	<cfargument name="dropMarginFloor" required="true" type="numeric">
	<cfargument name="stockThresholdLevel" required="true" type="numeric">
	<cfinvoke
		component="alpine-objects.DynamicPricingResource"
		method="updatesettings"
		oneCent="#oneCentMargin#"
		fiveK="#fiveKMargin#"
		stockMargin="#stockMarginFloor#"
		dropMargin="#dropMarginFloor#"
		stockThreshold="#stockThresholdLevel#"
	/>
</cffunction>

<cffunction name="getSampleMargin" returntype="any">
	<cfargument name="lowMar" required="true" type="numeric">
	<cfargument name="highMar" required="true" type="numeric">
	<cfargument name="dollars" required="true" type="numeric">
	<cfinvoke 
		component="alpine-objects.DynamicPricingResource"
		method="getCeilingMargin"
		lowMargin="#lowMar#"
		highMargin="#highMar#"
		dollarAmount="#dollars#"
		returnvariable="margin"		
	/>
	<cfreturn margin>
</cffunction>
<!--- Handle Updating --->
<cfif isDefined("oneCentMarginBox")>
	<cfinvoke component="alpine-objects.DynamicPricingResource"
		method="updateSettings"
		oneCent="#oneCentMarginBox#"
		fiveK="#fiveKMarginBox#"
		stockMargin="#stockedFloorBox#"
		dropMargin="0"
		stockThreshold="0"
		turnThreshold="#turnThresholdBox#"
		costOfStockLimit="#costStockLimitBox#"
		minimumActiveDays="#minActiveDaysBox#"
		minimumDaysSinceDisc="#minDaysSinceBox#"
		kitPriceRecommendation="#kitPriceBox#"
	/>	
</cfif>

<cfquery name="getAnticipatedRebates" datasource="#DSN#">
	DECLARE @temp TABLE(mfr varchar(50))
	INSERT INTO @temp
	SELECT DISTINCT 
		CASE WHEN p.isconcealed=1
			THEN p.cmfg
			ELSE p.Manufacturer
		END as 'mfr'
	FROM Products p	
	WHERE p.producttype='p'
		AND p.prdDeliveryMethod='s'
	
	SELECT t.mfr
		, ISNULL(ar.rebatePct, 0) as 'rebatePercent'
	FROM @temp t
	LEFT OUTER JOIN tblRepriceAnticipatedRebates ar on ar.manufacturer=t.mfr 
	ORDER BY t.mfr ASC
</cfquery>
<!--- Begin Rendering Page --->
<link rel="stylesheet" href="//code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css">
<link rel="stylesheet" href="dynamicPricing.css">
<script>
	function addToolTips()	{
		j$( "#stockedFloorMO" ).tooltip({content: "The minimum profit margin for recommended prices.", tooltipClass:"ui-tooltip"});
		j$( "#dropFloorMO" ).tooltip({content: "The minimum profit margin that will be recommended for drop-shipped products.", tooltipClass:"ui-tooltip"});
		j$( "#stockThresholdMO" ).tooltip({content: "The percentage of fulfillment from YS at which a product is considered stocked.", tooltipClass:"ui-tooltip"});
		j$( "#idealMarginMO" ).tooltip({content: "Ideal margins are calculated from a linear graph from the margin at a cost of one cent to the margin at a cost of $5,000 or more.", tooltipClass:"ui-tooltip"});
		j$("#anticipatedRebateMO").tooltip({content: "The anticipated percentage of cost per item to receive as a rebate from a given manufacturer.", tooltipClass:"ui-tooltip"});
		j$( "#discountSettingsMO" ).tooltip({content: "Save these settings to determine what products are flagged as needing discounts, or use them to search.", tooltipClass:"ui-tooltip"});
		j$( "#savebuttonMO" ).tooltip({content:"Save all discount search and global price tool settings.", tooltipClass:"ui-tooltip"});
		j$( "#kitMarkMO" ).tooltip({content:"When kits are repriced, the prices of all the products in the kit are added together and then a price is recommended by subtracting this percentage."});
	}
	
	function setAnticipatedRebate()	{
		var requestObj = {};
		requestObj.mfr = j$("#mfrs").children("option:selected").text();
		requestObj.pct = parseFloat ( j$("#rebatePct").val() );
		
		<cfajaxproxy cfc="alpine-objects.DynamicPricingResource" jsclassname="jsDRP">
		var reqHandler = new jsDRP();
		reqHandler.setHTTPMethod("POST");
		var requestStr = JSON.stringify(requestObj);
		var responseStr = reqHandler.ajaxUpdateAnticipatedRebates(requestStr);
		
		var responseObj = JSON.parse( responseStr.replace("//", "") );
		var replyStr = "Anticipated rebate of " +responseObj.PCT +"% for manufacturer " + responseObj.MFR + " has ";
		replyStr += (responseObj.ACCEPTED) ? "been submitted successfully." : ("failed. Reason: " + responseObj.FAILUREDEF);
		alert(replyStr);
		j$("#rebateul").append("<li class='rebate'>Manufacturer: " +requestObj.mfr + " - Anticipated Rebate: " + requestObj.pct +"</li>" );
	}

	function getDiscountSearchResults(e) {
		e.preventDefault();
		var searchObj = {};
		searchObj.costLimit = parseFloat( j$( "input[name='costStockLimitBox']" ).val() );
		searchObj.turnThresh = parseFloat( j$( "input[name='turnThresholdBox']" ).val() );
		searchObj.comparator = j$( "#comparisonType" ).val();
		searchObj.marginComp = parseFloat( j$( "#marginComp" ).val() );
		searchObj.minDaysActive = parseInt( j$( "input[name='minActiveDaysBox']" ).val() );
		searchObj.minDaysSince = parseInt( j$( "input[name='minDaysSinceBox']" ).val() );
		searchObj.useMrgn = j$( "#useMargin" ).is(":checked");
		searchObj.useTrn = j$( "#useTurns" ).is(":checked");
		searchObj.useCost = j$( "#useCostLimit" ).is(":checked");
		searchObj.useAD = j$( "#useMinimumActive" ).is(":checked");
		searchObj.useDS = j$( "#useDaysSinceLastDiscount" ).is( ":checked" );
		
		<cfajaxproxy cfc="alpine-objects.DynamicPricingResource" jsclassname="jsDRP">
		var reqHandler = new jsDRP();
		reqHandler.setHTTPMethod("POST");
		var linkText = reqHandler.ajaxGetDiscountInfo(JSON.stringify(searchObj));
		j$("#discResultLink").attr("href", "/partnernet/dynamicPricingTool/listpage.cfm?req="+encodeURI(JSON.stringify(searchObj))).text(linkText);
		
		j$("#discountResult").css("display", "block");
	}
	
</script>

<cfset priceSettings = getsettings()>
<cfset inputWidth = 6>
<h1 align="center" id="drapHeader">Dynamic Reprice Admin Panel</h1><br /><br />

<form name="adminPanelForm" action="adminPanel.cfm">
	<div id="admin_panel">
		<div id="maintable">
			<div id="topRow">
				<div id="floors">
					<table id="floortable">
						<tr><th align="left" class="admin_panel_header">
							Margin Floors:
						</th></tr>
						<tr><td>
							All Items <span title="" id="stockedFloorMO" class="ui-icon ui-icon-info" ></span>
						</td><td>&nbsp;</td></tr>
						<tr><td>
							<input name="stockedFloorBox" type="text" value="#priceSettings.stockedMarginFloor#" size="#inputWidth#" required="true"> %
						</td><td>&nbsp;</td></tr>
					</table>
				</div>
				<div id="marginformula">
					<table id="marginformulatable">
						<tr><th id="idealMarginFormula" align="left" class="admin_panel_header" colspan="12">
							Ideal Margin Formula <span title="" id="idealMarginMO" class="ui-icon ui-icon-info"></span>
						</th></tr>
						<!--- solve for calculated margins --->
						<cfset l = priceSettings.oneCentMargin>
						<cfset h = priceSettings.fiveKMargin>
						<tr id="adminmargins"><th class="admin_panel_table_row_header"><span>Margins %</span></th>
							<td><input name="oneCentMarginBox" type="text" value="#priceSettings.oneCentMargin#" size="#inputWidth#" required="true">%</td>
							<cfoutput><td>#getSampleMargin(l, h, 25)#</td><td>#getSampleMargin(l, h, 100)#</td>	<td>#getSampleMargin(l, h, 250)#</td>
							<td>#getSampleMargin(l, h, 500)#</td><td>#getSampleMargin(l, h, 1000)#</td>	<td>#getSampleMargin(l, h, 1500)#</td>
							<td>#getSampleMargin(l, h, 2000)#</td><td>#getSampleMargin(l, h, 2500)#</td>	<td>#getSampleMargin(l, h, 3500)#</td></cfoutput>
							<td><input name="fiveKMarginBox" type="text" value="#priceSettings.fiveKMargin#" size="#inputWidth#" required="true">%</td>
						</tr>
						<tr id="admincosts"><th class="admin_panel_table_row_header"><span>Costs</span></th>
						<td>$0.01</td><td>$25</td><td>$100</td><td>$250</td><td>$500</td><td>$1,000</td>
						<td>$1,500</td><td>$2,000</td><td>$2,500</td><td>$3,500</td><td>$5,000</td>
					</table>
				</div>
			</div>
			<div id="middleRow">
				<div id="kittable">
					<table>
						<tr><th class="admin_panel_header">Kit Markdown<br />Recommendation<span title="" id="kitMarkMO" class="ui-icon ui-icon-info"></span></th></tr>
						<tr><td><input name="kitPriceBox" type="text" validate="float" required="true" size="#inputWidth#" value="#priceSettings.kitPriceRecommendation#">%</td></tr>
					</table>
				</div>
				<div  id="discountinfo">
					<table id="discounttable">
						<tr><th id="discountsettings" align="left" class="admin_panel_header" colspan="4">
							Discount Settings <span title="" id="discountSettingsMO" class="ui-icon ui-icon-info" ></span>
						</th></tr>
						<tr><td><label for="useTurns">Turnover threshold<input id="useTurns" type="checkbox" checked="checked"></label></td>
						<td><label for="useCostLimit">Max. Cost of Stock<input id="useCostLimit" type="checkbox" checked="checked"></label></td>
						<td><label for="useMinimumActive">Min. Active Days<input id="useMinimumActive" type="checkbox" checked="checked"></label></td>
						<td><label for="useDaysSinceLastDiscount">Min. Days Since Discount<input id="useDaysSinceLastDiscount" type="checkbox" checked="checked"></label></td></tr>
						<td><input name="turnThresholdBox" type="text" size="#inputWidth#" value="#priceSettings.turnThreshold#"></td>
						<td><input name="costStockLimitBox" type="text" size="#inputWidth#" value="#NumberFormat(priceSettings.costOfStockLimit, '.99')#"></td>
						<td><input name="minActiveDaysBox" type="number" size="#inputWidth#" value="#priceSettings.minimumActiveDays#"></td>
						<td><input name="minDaysSinceBox" type="number" size="#inputWidth#" value="#priceSettings.minimumDaysSinceDisc#"></td>
					</table>
					<div id="discountSearchCriteria">
						<label for="useMargin">Check Margins<input id="useMargin" type="checkbox"></label><select id="comparisonType"><option value="LT">Less Than</option><option value="GT">Greater Than</option></select><input id="marginComp" type="text">	<br />
						<button id="discountSearch">Search For Products</button>
						<div id="discountResult" style="display:none;"><a id="discResultLink" href="#"></a></div>
					</div>
				</div>
			</div>
			<div id="bottomRow">
				<div align ="center" ><input name="update" value="Save Settings" type="submit"> <span id="savebuttonMO" class="ui-icon ui-icon-info" title=""></span></div>
			</div>
		</div>
		<div>
			<div  id="rebateRow">
				<div id="rebateFirst">
					<table id="anticipatedRebates">
						<thead>
							<tr>
								<th class="admin_panel_header" colspan="4">Anticipated Rebates<span title="" id="anticipatedRebateMO" class="ui-icon ui-icon-info"></th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td colspan="3">Manufacturer</td>
								<td>Anticipated Rebate</td>
							</tr>
							<tr>
								<td colspan="3">
									<select id="mfrs" name="mfrs">
										<option value="" selected>Select a Manufacturer</option>
										<cfoutput query="getAnticipatedRebates">
											<option value="#getAnticipatedRebates.rebatePercent#">#getAnticipatedRebates.mfr#</option>
										</cfoutput>
									</select>
								</td>
								<td>
									<input id="rebatePct" name="rebate" type="text" validate="float">
								</td>
							</tr>
							<tr>
								<td align="center" colspan="4">
									<input type="button" id="setRebate" value="Set Anticipated Rebate"/>
								</td>
							</tr>
						</tbody>
					</table>
				</div>
				<div id="rebateslistcell">
					<a href="#" id="rebatelisttoggle">Show anticipated rebates</a>
					<div id="rebateslist">
						<ul id="rebateul">
							<cfoutput query="getAnticipatedRebates">
								<cfif getAnticipatedRebates.rebatePercent NEQ 0>
								<li class="rebate">
									Manufacturer: #getAnticipatedRebates.mfr# - Anticipated Rebate: #getAnticipatedRebates.rebatePercent#
								</li>
								</cfif>
							</cfoutput>
						</ul>
					</div>
				</div>
			</div>
		</div>
		<br /><br />
	</div>
</form>
<script>
	j$( "#rebateslist" ).hide();		
	addToolTips();
	j$("#mfrs").change(function(){
	    j$("#rebatePct").val( j$( this ).val());
	});
	j$("#setRebate").click(setAnticipatedRebate);
	j$("#discountSearch").click(getDiscountSearchResults);
	j$("#rebatelisttoggle").click( function(){
			j$( "#rebateslist" ).toggle();			
	});
</script>
<cfinclude template="/partnernet/shared/_footer.cfm">