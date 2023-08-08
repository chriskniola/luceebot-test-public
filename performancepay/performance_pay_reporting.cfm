
<cfsetting requesttimeout="3000" showdebugoutput='yes'>
<cfset screenID = 920>

<cfquery name="check" datasource="#DSN#">
	SELECT COUNT(UserID) AS 'isAdmin'
	FROM tblSecurity_Usergroups WITH(NOLOCK)
	WHERE UserID = <cfqueryparam sqltype="INTEGER" value="#SESSION.user.ID#">
		AND GroupID IN (6,36)
</cfquery>

<cfquery name="consultantList" datasource="#DSN#">
	SELECT FirstName + ' ' + LastName AS consultantName, ID
	FROM tblSecurity_Users WITH (NOLOCK)
	WHERE isConsultant = 1
		AND isActive=1
	ORDER BY ID
</cfquery>

<cfquery name="creditTypeList" datasource="#DSN#">
	SELECT * FROM tblPerformanceCreditTypes
</cfquery>

<cfquery name="perfSettings" datasource="#DSN#">
	SELECT * FROM tblPerformanceSettings
</cfquery>

<cfobject component="alpine-objects.perfpaycredit" name="perfPayComponent">

<cfset nonSalePcts = perfPayComponent.getCreditPercentagesByCreditType(3)>
<cfset liveChatPcts = perfPayComponent.getCreditPercentagesByCreditType(2)>

<cfset showPrototype = 0>
<cfinclude template="/partnernet/shared/_header.cfm">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.5/jquery.fancybox.min.css" />
<link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/themes/smoothness/jquery-ui.css" />
<link rel="stylesheet" type="text/css" href="perfpay.css?v=10">
<script src="https://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.5/jquery.fancybox.pack.js"></script>

<script>
	<cfajaxproxy cfc="objects.perfpaycredit" jsclassname="PerfCredit">
	perf = new PerfCredit();
	perf.setHTTPMethod("POST");
	var j$=jQuery.noConflict();
	//Toggle Pane plugin
	j$.fn.togglepanels = function(){
	  return this.each(function(){
		j$(this).addClass("ui-accordion ui-accordion-icons ui-widget ui-helper-reset")
	  .find("> h3")
		.addClass("ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
		.hover(function() { j$(this).toggleClass("ui-state-hover"); })
		.append('<span class="ui-icon ui-icon-triangle-1-e ui-togglepane-arrow"></span>')
		.click(function() {
		  j$(this)
			.toggleClass("ui-accordion-header-active ui-state-active ui-state-default ui-corner-bottom")
			.find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s").end()
			.next().slideToggle();
		  return false;
		})
		.next()
		  .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
		  .hide();
	  });
	};//end toggle pane

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

	function openDialog(titleIn, messageIn){
		j$("#dialog-status-response").attr("title", titleIn);
		j$("#status-message").text(messageIn);
		j$("#dialog-status-response").dialog();
	}

	function showCreditLog(objID){
		var logTable = perf.ajax_creditLogTable(objID);
		j$("#creditLogOuter").attr("title", "Log for credit " + objID);
		j$( "#creditLogInner" ).html(logTable);
		j$("#creditLogOuter").dialog();
	}

	<cfif check.isAdmin>
		<cfoutput>
			#toScript(JSStringFormat(SESSION.user.ID), 'userID')#
		</cfoutput>

		function confirmation(objID, days, pct, hours, comment) {
			j$( "#modal-objID" ).val(objID);
			j$( "#modal-days" ).val(days);
			j$( "#modal-pct" ).val(pct);
			j$( "#modal-hours" ).val(hours);
			j$( "#modal-comment" ).val(comment);
			j$( "#dialog-confirm" ).dialog({
				resizable: false,
				height:300,
				width:450,
				modal: true,
				buttons: {
					"Save": function() {
						var tempReq = {};
						tempReq.objID = j$( "#modal-objID" ).val();
						tempReq.comment = j$( "#modal-comment" ).val();
						tempReq.hours = j$( "#modal-hours" ).val();
						tempReq.pct = j$( "#modal-pct" ).val();
						tempReq.days = j$( "#modal-days" ).val();
						tempReq.changedBy = userID;
						alert( JSON.parse(perf.ajax_editCredit(JSON.stringify(tempReq)).replace("//", "") ).STATUS );
						j$("#changeAlert").show();
						j$( this ).dialog( "close" );
					},
					"Void This Credit": function() {
						var tempReq = {};
						tempReq.objID = j$( "#modal-objID" ).val();
						tempReq.changedBy = userID;
						alert( JSON.parse(perf.ajax_voidCredit(JSON.stringify(tempReq)).replace("//", "") ).DETAIL );
						j$("#changeAlert").show();
						j$( this ).dialog( "close" );
					}
				}
			});
		}

		function addCredit(){
			var reqObj = {};
			reqObj.consultantID = j$("#credit-consultant-select").val();
			reqObj.validFor = j$("#credit-date").val();
			reqObj.creditType = j$("#credit-type-select").val();
			reqObj.hours = j$("#credit-hours").val();
			reqObj.createdBy = userID;
			reqObj.comment = j$("#credit-comment").val();
			var addResponse = perf.ajax_addCredit(JSON.stringify(reqObj));
			var addRespObj = JSON.parse(addResponse.replace("//", ""));
								alert(addRespObj.STATUS);
			if(addRespObj.STATUS == 'Success'){
				openDialog("Credit Added!", "Credit Added Successfully.");
				j$("#changeAlert").show();
			}else{
				openDialog("Credit Add Failed", addRespObj.DETAIL);
			}
		}

		function updateCreditTypes(){
			var updateCreditObj = {};
			updateCreditObj.types = [];
			j$(".consultant-credit-type").each(function(){
				var tempCred = {};
				tempCred.type=j$( this ).data("type");
				tempCred.consultant=j$( this ).data("consultant");
				tempCred.value = j$( this ).val();
				updateCreditObj.types.push( tempCred );
			});
			updateCreditObj.days = j$( "#agp-days" ).val();

			var result = perf.ajax_editCreditSettings(JSON.stringify(updateCreditObj));
			var resultObj = JSON.parse(result.replace("//", ""));

			if(resultObj.STATUS == 'Success'){
				openDialog("Credit Types Edited", "Credit Types saved successfully");
			}else{
				openDialog("Credit Type Edit Failed", resultObj.DETAIL)	;
			}
		}

	</cfif>

	function togglePerHourCharts(){
		var t = j$( ".hourChart:not(.active)" ).attr("id");
		j$( ".hourChart.active" ).removeClass("active");
		j$( "#" + t ).addClass("active");
	}

	function calculatePayouts(rankingChart){
		if( rankingChart[0].AGP < rankingChart[1].AGP ){
			rankingChart.reverse();
		}
		var minDate = Date.parse(j$('#startdt').val());
		var maxDate = Date.parse(j$('#enddt').val());
		var diffDays = Math.round((maxDate - minDate)/(24*3600*1000))
		var potSize = parseFloat(j$("#potSize").val());
		var medArr = rankingChart[0].Median;
		var tableStr;

		<!--- set table columns --->
		if (potSize) {

			tableStr = "<table align=center class='consultant-summary' id='calcTable'><thead><tr><th colspan=100%>Median AGP: $" + numberWithCommas(Math.round(medArr)) + "</th></tr><tr><th>Consultant Name</th><th>Pool Payout</th><th>Monthly<br />Breakout Bonus</th><th>AGP</th><th>$ Above Median</th><th>% Above Median</th><th>Approved<br />Time Off Hours</th></tr></thead><tbody></tbody></table>";

		} else {

			tableStr = "<table align=center class='consultant-summary' id='calcTable'><thead><tr><th colspan=100%>Enter A Pool Size Greater Than 0.<br />Numbers only, please.</th></tr></thead><tbody></tbody></table>";
		}

		j$("#calculatorResultsWrapper").html(tableStr);

		if ( potSize ) {
			if ( rankingChart.length > 0 ) {
				var tbl = j$( "#calcTable tbody" );
				var tblhead = j$("#calcTable thead" );

				for ( var i = 0; i < rankingChart.length ; i++ ) {
					var consultant 	= rankingChart[i];
					var potPayout 	= parseFloat(consultant.potPayout).toFixed(2);
					var bonusCredit = Math.round(parseFloat(consultant.bonusCredit).toFixed(2));

					if ( diffDays >= 28 ) {

						tbl.append("<tr><td align=center>" + consultant.consultantName + "</td><td align=center>$" + potPayout + "</td><td align=center>$" + numberWithCommas(bonusCredit) + "</td><td align=center>$" + numberWithCommas(consultant.AGP) + "</td><td align=center>$" + numberWithCommas(Math.round(consultant.amountAboveMedian)) + "</td><td align=center>" + Math.round(consultant.percentAboveMedian) + "%</td><td align=center>" + consultant.vacationHours + "</td></tr>");

					} else {
						tbl.append("<tr><td align=center>" + consultant.consultantName + "</td><td align=center>$" + potPayout + "</td><td align=center>N/A</td><td align=center>$" + numberWithCommas(consultant.AGP) + "</td><td align=center>$" + numberWithCommas(Math.round(consultant.amountAboveMedian)) + "</td><td align=center>" + Math.round(consultant.percentAboveMedian) + "%</td><td align=center>" + consultant.vacationHours + "</td></tr>");
					}
				}
			}

			j$('#canvas4').remove();
			j$('#curveChart').append('<canvas id="canvas4" height="200" width="200"></canvas>');

			var ctx4 = document.getElementById("canvas4");
			var curvePoints = [];
			var chartData = [];

			for(i=0; i < 100; i = i + 0.25) {
				curvePoints.push({x:i, y:payCurve(i / 100, potSize)});
			}
			var consultants = [];

			for ( var i = 0; i < rankingChart.length ; i++ ) {
				var consultant = {
					name: rankingChart[i].consultantName,
					pay: rankingChart[i].potPayout,
					percent: rankingChart[i].potPercent
				}
				consultants.push(consultant)
			}

			function payCurve(value, max) {
				var pay = 2.08553 * Math.pow(value,3) - 1.00311 * Math.pow(value,2) + 0.07816 * value - 0.0729416;
				pay *= max;
				pay = (pay < 0) ? 0 : pay;
				pay = (pay > max) ? max : pay;
				return pay;
			}

			consultants.forEach(function(element, value) {
				chartData.push({
					borderColor: 'rgba(0,85,255,1)',
					fill: false,
					showLine: false,
					label: [element.name],
					data:[{y:element.pay, x:element.percent}]
				});
			});

			var curveData = {
				borderColor: 'rgba(223,255,193,1)',
				pointBorderColor: "rgba(255,255,255,1)",
				showLine: true,
				pointRadius: 0,
				pointHitRadius: 0,
				label: 'Scatter Dataset',
				fill: false,
				data: curvePoints
			};

			chartData.push(curveData);

			var scatterChart = new Chart(ctx4, {
				type: 'line',
				data: {
					datasets: chartData
				},
				options: {
					legend: {
						display: false
					},
					tooltips: {
						displayColors: true,
						mode: 'x-axis',
						callbacks: {
							title: function(tooltipItems, data){
								return tooltipItems[0].xLabel + '%'
							},
							label: function(tooltipItem, data){
								if(data.datasets[tooltipItem.datasetIndex].label[0] == "S"){return}
						 		return data.datasets[tooltipItem.datasetIndex].label[0] + ': $' + tooltipItem.yLabel.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, "$1,");
							}
						}
					},
					scales: {
						xAxes: [{
							type: 'linear',
							position: 'bottom'
						}]
					}
				}
			});
		}

	}

	function okGo() {
		//set datepickers on datefields
		j$(".dt").datepicker({autoSize:true});
		//add all mouse-over tooltips
		j$(".mo").tooltip( {track: true });
		//establish toggle-panes/accordions for the two separate groups
		j$("#chartcontainer").togglepanels();
		j$("#perfcontainer").togglepanels();
		j$(".orders-all").togglepanels();
		j$(".consultant-credit-detail").togglepanels();
		//fancybox in piecharts
		j$( ".order-gp-detail" ).fancybox({'type':'iframe', 'width':'20%', minHeight:300, autoSize:true, autoscale:true, maxHeight:"40%"});
		//expand chart on page load
		j$("#chart-header").click();
		j$( "#credit-consultant-select" ).change(function(){
			var consultantID = j$( this ).val();
			j$("#credit-table-container").html( j$( "#creditTbl" + consultantID ).clone().wrap('<p>').parent().html() );
		});
		j$("#credit-consultant-select").change();
		j$("#main").show();
	}//end ready
	j$( okGo );
</script>

<cfif check.isAdmin>
	<script>
	j$( ".edit-credit" ).click(confirmation);
	</script>
</cfif>

<div class="reporting">
	<div id="main" style="display:none;">
		<h2>Gross Profit Per Sales Consultant</h2>
		<cfset useSuppliedDates = (CGI.REQUEST_METHOD EQ 'POST')>
		<cfset minDate = (useSuppliedDates) ? ATTRIBUTES.startdt : DateFormat(DateAdd("d",-8,Now()), "mm/dd/yyyy")>
		<cfset maxDate = (useSuppliedDates) ? ATTRIBUTES.enddt : DateFormat(DateAdd("d",-1,Now()), "mm/dd/yyyy")>

		<cfset dateDif = ABS(DateDiff("d", maxDate, minDate))>
		<cfset ATTRIBUTES.summaryMode = ( dateDif GT 31 OR IsDefined("FORM.summaryMode")) ? 1 : 0>

		<cfquery name="consultants" datasource="#DSN#">
			DECLARE @minDate DATE = <cfqueryparam sqltype="DATE" value="#minDate#" />
			DECLARE @maxDate DATE = <cfqueryparam sqltype="DATE" value="#maxDate#" />

			SELECT su.ID AS 'userID', su.FirstName, su.LastName
			FROM tblOrderPerformancePay pp
			INNER JOIN tblSecurity_Users su ON su.ID = CASE WHEN ISNUMERIC(pp.userID) = 1 THEN pp.userID ELSE 0 END
				AND su.isactive = 1 AND su.isconsultant = 1
			WHERE CONVERT(DATE,pp.datetoapply) BETWEEN @minDate AND @maxDate
				AND pp.userID IS NOT NULL
				AND pp.datetoapply < '2019-04-01'
			UNION
			SELECT su.ID, su.FirstName, su.LastName
			FROM OrderAGP agp
			INNER JOIN tblSecurity_Users su ON su.ID = agp.UserID
				AND su.isactive = 1 AND su.isconsultant = 1
			WHERE agp.Created > '2019-04-01'
				AND CONVERT(DATE,agp.Created) BETWEEN @minDate AND @maxDate
			ORDER BY su.FirstName, su.LastName
		</cfquery>

		<cfif NOT IsDefined("FORM.summaryMode") AND ATTRIBUTES.summaryMode>
			<cfoutput><h3 style="color:red;">Summary Mode enabled due to long date range (#dateDif# days)</h3></cfoutput>
		</cfif>
		<div id="dateform">
			<span class="frmHeader">Order Date Range<span class="ui-icon ui-icon-info mo" title="Show the GP and order details for all orders in &quot;Sent To Distributor&quot; or &quot;Shipped&quot; status that were placed between these dates."></span></span>
			<form action="performance_pay_reporting.cfm" id="performancePayReporting" method="POST">
				<div class="inputwrap"><label>Start Date<br /><input name="startdt" id="startdt" class="dt" type="datefield" <cfoutput>value="#minDate#"</cfoutput> /></label></div>
				<div class="inputwrap"><label>End Date<br /><input name="enddt" id="enddt" class="dt" type="datefield" <cfoutput>value="#maxDate#"</cfoutput> /></label></div>
				<div class="inputwrap"><label>Summary Mode <span class="ui-icon ui-icon-info mo" title="Summary Mode shows only consultant GP/Credit totals over period rather than order details.  Date ranges greater than 31 days will be forced into summary mode for performance protection."></span>
					<br /><input type="checkbox" name="summaryMode" <cfif ATTRIBUTES.summaryMode OR NOT useSuppliedDates>checked="CHECKED"</cfif>></label></div>
				<input class="button secondary" type="Submit" value="Go" />
			</form>
		</div>
		<div class="consultants" style="text-align: center;">
			<cfif consultants.recordCount>
				<div class="selectAllCheckBox">
					<input type="checkbox" id="selectAllConsultant" checked /> <label for="selectAllConsultant">Select &#47; Deselect All</label>
				</div>
				<ul class="consultantList">
					<cfoutput query="#consultants#">
						<li><input type="checkbox" class="consultant" value="#consultants.userID#" id="c#consultants.userID#" checked /> <label for="c#consultants.userID#">#consultants.FirstName# #consultants.LastName#</label></li>
					</cfoutput>
				</ul>
				<input type="button" class="button secondary" id="update" value="Update"/>
				<script type="text/javascript">
					j$("#selectAllConsultant").click(function () {
					    j$('.consultant').prop('checked', this.checked);
					});
					j$(".consultant").click(function () {
					    j$('#selectAllConsultant').prop('checked', false);
					});
				</script>
			</cfif>
		</div>
		<div id="chartcontainer">
			<cfif check.isAdmin>
				<div id="hideCredits" style="display:none;">
					<cfloop list="#ValueList(consultantList.ID)#" index="consultantID">
						<cfset creditTable = perfPaycomponent.getConsultantCreditTable(consultantID="#consultantID#", minDate ="#minDate#", maxDate="#maxDate#", tableID="creditTbl#consultantID#", admin=1)>
						<cfoutput>#creditTable#</cfoutput>
					</cfloop>
				</div>
				<h3><span class="accordion-header-left">Admin Panel</span></h3>
				<div>
					<div id="admin-panel">
						<h4 id="changeAlert" style="display:none; color:red;">Credits have been added or edited, press "Go" to update charts and tables.</h4>
						<div class="top">
							<div id="top-header"><span>Set Credit Values</span><br />
							<span>Applied to all future credits added</span></div>
							<div class="col1">
								<p>Percentage of average gross profit per hour to be credited for <strong>post-sale call</strong> phone time</p>
								<table>
									<thead>
										<tr>
											<th>Consultant</th>
											<th>Percentage</th>
										</tr>
									</thead>
									<tbody>
										<cfoutput query="nonSalePcts">
										<tr>
											<td>#consultantName#</td>
											<td><input class="consultant-credit-type" data-consultant="#ID#" data-type="#typeID#" value = "#agpPct#"></td>
										</tr>
										</cfoutput>
									</tbody>
								</table>
							</div>
							<div class="col2">
								<p>Percentage of average gross profit per hour to be credited for <strong>LiveChat/Email</strong> time</p>
								<table>
									<thead>
										<tr>
											<th>Consultant</th>
											<th>Percentage</th>
										</tr>
									</thead>
									<tbody>
										<cfoutput query="liveChatPcts">
										<tr>
											<td>#consultantName#</td>
											<td><input class="consultant-credit-type" data-consultant="#ID#" data-type="#typeID#" value = "#agpPct#"></td>
										</tr>
										</cfoutput>
									</tbody>
								</table>	<br /><br />
								<button class="button secondary" id="apply-agp-changes" onClick="updateCreditTypes();">Set Values</button>
							</div>
							<div class="col3">
								<p>Gross Profit (GP) per work hour, averaged over number of days<span class="ui-icon ui-icon-info mo"
								title="All consultant credits have a number of days associated.  This is the number of days over which their GSD per work-hour is caclulated. This GSD per work hour times the number of hours and attributed gross profit percentage determines the dollar value of the credit."></span></p>
								<label>Days
									<select name = "agp-days" id="agp-days">
										<cfoutput>
											<cfloop from=7 to=56 step=7 index="i">
												<option value="#i#" <cfif "#perfSettings.agpDays#" EQ i>SELECTED</cfif>>#i#</option>
											</cfloop>
											<option value="365" <cfif "#perfSettings.agpDays#" EQ 365>SELECTED</cfif>>365</option>
										</cfoutput>
										</select>
								</label>
							</div>
							<div style="text-align:left;">
								<p>If sales consultants have Approved Time Off of 16 or more hours during a specified period of time and the highest AGP for this period, two pay calculators are run.</p>
								<p>For sales consultants</p>
								<ul>
									<li>with Approved Time Off of 16 hours or more</li>
									<li>with no Approved Time Off or Approved Time Off of less than 16 hours</li>
								</ul>
							</div>
						</div>
						<hr class="major">
						<div class="bottom-half">
							<div class="top">
								<span>Add Credit</span>
								<div class="col1">
									<label>Consultant    <select id="credit-consultant-select">
										<cfloop query="consultantList">
											<cfoutput><option value="#ID#">#consultantName#</option></cfoutput>
										</cfloop>
									</select></label><br /><br />
									<label>Credit Type   <select id="credit-type-select">
										<cfloop query="creditTypeList">
											<cfoutput><option value="#typeID#">#typeName#</option></cfoutput>
										</cfloop>
									</select></label><br /><br />
									<label>Hours   <span class="ui-icon ui-icon-info mo" title="Number of hours of per work-hour credit to apply"></span>   <input type="text" id="credit-hours"></label><br /><br />
									<label>Credit Date  <span class="ui-icon ui-icon-info mo" title="Day to which credit should be applied"></span>    <input id="credit-date" class="dt" type="datefield"><span class="ui-icon ui-icon-calendar"></span></label><br /><br />
								</div>
								<div class="col2">
									<label>Credit Comments (Optional)<br /><textarea name="credit-comment" id="credit-comment" rows="6" cols="60"></textarea></label><br />
									<button class="button green" onclick="addCredit();">Apply Credit</button>
								</div>
							</div>
							<hr class="minor" />
							<div class="bottom" id="credit-table-container">

							</div>
						</div>
					</div>
				</div>
			</cfif>
			<h3><span class="accordion-header-left">Information</span></h3>
			<div>
				<div class = "top">
					<div align ="left">
				   		<p>Sales consultant performance pay consists of the following components:</p>
					</div>
					<hr>
					<div align ="left">
						<h4>Lead Distribution</h4>
						<p>
							Looks at projects that were created 1-5 weeks ago. Each project calculates an Expected AGP value that is based on the AGP/Project for that Product Category since 9/1/18. That expected value is then adjusted based on the Lead Source and amount of Systems. These adjustment factors are calculated behind the scenes as a broad factor across all Product Categories.
						</p>
						<p>
							A consultant has a total Expected AGP for all projects assigned to them. 100% of the expected AGP goes to the Project assignee. Their Project GP is their AGP from all projects created in the 1-5 week range (including AGP on projects assigned to other consultants).  This Project GP is compared to the Total Expected AGP to calculate the Excess Value created by the Consultant.
						</p>
						<p>
							This will be evaluated weekly and create a ranking of the Sales Team. Team members with the highest Excess Value will be at the top of the ranking. The top half of the team will be put in the High Value Queue and the bottom half in the Low Value Queue. All Sales Team members will be in the Medium Value Queue. These queue labels are visible on the Expected Values tab of the New Sales Dashboard.
						</p>
					</div>
					<hr>
					<div align ="left">
						<h4>Bonus Pay</h4>
						<p>
							Each month the consultant’s Total AGP (including credits) slots into a given bonus level. These bonus levels are visible on the Bonus Levels tab on the New Sales Dashboard.  Sales Team members receive the percentage associated with that level of their Excess AGP. Excess AGP is Total AGP minus Level 1 AGP. This Bonus Amount is then multiplied by the Bonus Multiplier to result in the actual Payout for the month.
						</p>
					</div>
					<hr>
					<div align ="left">
						<h4>Bonus Multiplier</h4>
						<p>
							This is calculated using 12 weighted scores. The weighting is listed in the Multiplier Raw tab on the New Sales Dashboard.
						</p>
						<ul>
							<li><strong>Review Score:</strong> Average score from the Call Reviews Google Doc.</li>
							<li><strong>Survey Score:</strong> Average of survey score in PartnerNet multiplied by 20 to be out of 100.</li>
							<li><strong>Margin Score:</strong> Based on Product Category, each project has an expected Margin. This score looks at actual Margin vs expected Margin.</li>
							<li><strong>AGP/Sale Score:</strong> Same methodology as Margin Score except that it’s based on AGP/Sale.</li>
							<li><strong>Phone Time:</strong> Phone Time % is calculated as Queue Talk Time divided by Queue Logged in Time. This is divided by the goal amount set for that month which factors in seasonality.</li>
							<li><strong>Pause Time:</strong> If you are under 10% Pause Time, you get a score of 100.  If you are over 10%, you get a score of 0.</li>
							<li><strong>RNA:</strong> RNA/Hour is the metric.  If you are over 2, your score is 0.  If under 2, it is graded on a linear scale from 0-2 RNA/Hour.  Example: 0.5 RNA/Hour is 75% of the way towards 0 from 2, so the score is 75.</li>
							<li><strong>PLS and Time Infractions:</strong> Displayed on the Infractions tab of the New Sales Dashboard and score is 100 minus total infraction points.</li>
							<li><strong>Unscheduled Time Off:</strong> Score starts at 100 and is deducted 30 points for each day of Unscheduled Time Off.</li>
							<li><strong>Return Score:</strong> RMA % is calculated as total RMA’s divided by Total Vendor Qty sold by a Consultant. <1.5%=100, <2% = 90, <2.5% = 80, <3% = 70, <4% = 50, <5% = 30, >5% = 0</li>
						</ul>
					</div>
					<hr>
					<div align ="left">
						<h4>Gain Sharing</h4>
						<p>
							If total company revenue for the past three months exceeds our best same three months in prior years (usually last year), a bonus is paid. Bonus is based on percentage revenue growth average for the past three months of growth. <a href="/partnernet/reports/salesbybestmonths.cfm" target="_blank">You can view company revenue and growth rates here.</a> See your employment offer or manager for payout details.
						</p>
					</div>
					<hr>
					<div align ="left">
						<h4>Attributed Gross Profit (AGP) Breakdown</h4>
						<div style="margin-left: 22px;">
							<cfset AGPScenarios = new contexts.AGP.Dataaccess.DatabaseAGPRepository().getAGPScenarios()>
							<cfoutput query="#AGPScenarios#" group="scenarioLabel"><div>
								<p>
									<strong>#AGPScenarios.scenarioLabel#</strong>
									<ul>
										<cfoutput>
											<li>#AGPScenarios.percentageLabel# #AGPScenarios.percentage#%</li>
										</cfoutput>
									</ul>
								</p></div>
							</cfoutput>
						</div>
					</div>
					<hr>
					<div align = "left">
						<h4>Technical Notes:</h4>
						<ul>
							<li>Data is only accurate over periods of 1 or more weeks.</li>
							<li>Data is shown for active consultants only.</li>
							<li>Post sale call credits are run for the previous week Monday mornings, therefore credits will be most accurate for the prior period when the report is run after noon on Monday.</li>
							<li>Credits exist beginning 4/1/14 and new processing exists beginning 3/1/14.</li>
						</ul>
					</div>
				</div>
			</div>
		<cfif CGI.REQUEST_METHOD EQ "POST">


			<!--- POST Only Queries --->
			<cfset getRankingChart = CreateObject('component', 'alpine-objects.perfpaycredit').getPotPrc(returntype = 'query', minDate = minDate, maxDate = maxDate) />
			<cfif NOT ATTRIBUTES.summaryMode>
				<cfquery name="allgsddata" datasource="#DSN#">
					DECLARE @minDate DATE = <cfqueryparam sqltype="DATE" value="#minDate#">
					DECLARE @maxDate DATE = <cfqueryparam sqltype="DATE" value="#maxDate#">
					SELECT
						opp.ID,
						opp.created,
						opp.orderlineID,
						opp.[description],
						opp.GSD,
						opp.GSP,
						opp.userID,
						opp.locked,
						c.DT AS 'orderCreated',
						opp.payamount,
						o.sessionID,
						ISNULL(p.[Name], p.ModelNumber) AS 'Name',
						ISNULL(su.FullName, 'Customer') AS 'personName',
						o.Quantity AS 'orderQuantity'
					FROM tblOrderPerformancePay opp WITH(NOLOCK)
					INNER JOIN orders o ON o.ID = opp.orderlineID
					INNER JOIN checkouts c ON o.SessionID = c.SessionID
						AND CONVERT(DATE,c.DT) BETWEEN @mindate AND @maxdate
						AND c.DT < '2019-04-01'
					INNER JOIN Products p ON p.ID = o.ProductNumber
					LEFT OUTER JOIN tblSecurity_users su ON CAST(su.ID AS VARCHAR) = opp.userID

					UNION ALL

					SELECT
						agp.ID,
						agp.Created,
						agp.OrderLineID,
						pt.Label + CASE WHEN agp.[Description] IS NOT NULL THEN ' - ' + agp.[Description] ELSE '' END,
						agp.Amount,
						ROUND((agp.Amount / 10),2),
						CONVERT(VARCHAR,agp.UserID),
						0,
						c.DT,
						0,
						agp.OrderID,
						ISNULL(p.[Name], p.ModelNumber),
						ISNULL(su.FullName, 'Customer'),
						o.Quantity
					FROM OrderAGP agp
					INNER JOIN AGPPercentageTypes pt ON pt.ID = agp.AGPPercentageTypeID
					INNER JOIN orders o ON o.ID = agp.OrderLineID
					INNER JOIN checkouts c ON o.SessionID = c.SessionID
						AND CONVERT(DATE,c.DT) BETWEEN @mindate AND @maxdate
						AND c.DT >= '2019-04-01'
					INNER JOIN Products p ON p.ID = o.ProductNumber
					LEFT OUTER JOIN tblSecurity_users su ON su.ID = agp.UserID
				</cfquery>
			</cfif>



			<!--- End Queries --->
			<h3 id="chart-header"><span class="accordion-header-left">Ranking Charts</span></h3>
			<div>
				<div>
					<table id="graphs">
						<tr>
							<th><h4>GP Per Work Hour Over Last <cfoutput>#perfSettings.agpDays# Days</cfoutput><span class="ui-icon ui-icon-info mo" title="Used to calculate credit values"></span></h4></th>
							<th style="width: 30px;"></th>
							<th><h4>Period Attributed Gross Profit (AGP)</h4></th>
						</tr>
						<tr>
							<td id="td1"><canvas id="canvas1"></canvas></td>
							<td></td>
							<td id="td3"><canvas id="canvas3"></canvas></td>
						</tr>
						<tr>
							<td id="legend1"></td>
							<td></td>
							<td id="legend3"></td>
						</tr>
					</table>
				</div>
			</div>

			<script>
				j$(function() {
					createRanking('charts');

					j$('#update').click(function() {
						createRanking('charts');

						var id = j$(this).val();
						var checked = j$(this).prop('checked');
						if(checked) {
							j$('#perf-accordion-' + id).removeClass('ui-state-active').addClass('ui-state-default').fadeIn();
						} else {
							j$('#perf-accordion-' + id + ', #perf-accordion-' + id + ' + div').fadeOut();
						}
					});
				});

				function createRanking(callback) {
					var minDate = j$('#startdt').val();
					var maxDate = j$('#enddt').val();
					var poolSize = j$('#potSize').val();

					var list = [];
					j$('.consultant').each(function() {
						if(!j$(this).prop('checked')) list.push(j$(this).val());
					});

					var excludeUsers = list.join(',');
					var url = "/objects/perfpaycredit.cfc";
					var data = { method : 'getPotPrc', minDate : minDate, maxDate : maxDate, excludeUsers : excludeUsers, poolSize : poolSize, returnType:'array'};

					j$.post(url, data, function(result) {
						var result = JSON.parse(result);
						if(callback == 'charts') createCharts(result);
						if(callback == 'payouts') calculatePayouts(result);
					})
					.fail(function(e) {
						alert(e.responseText);
					});
				}

				function createCharts(rankingChart) {
					var rankingChart = rankingChart.sort(function(a,b){return a.AGP - b.AGP;});

					j$('.consultant').each(function() {
						var id = j$(this).val();
						if(!j$(this).prop('checked')) {
							for(var i in rankingChart)  {
								var consultant = rankingChart[i];
								if(consultant.userID == id) {
									delete rankingChart[i];
								}
							}
						}
					});

					var names = rankingChart.map(function(value, index) {
						return value.consultantName;
					});

					var userGSDs = rankingChart.map(function(value, index) {
						return value.userGSD;
					});

					var nscreditVals = rankingChart.map(function(value, index) {
						return value.nsCreditVal;
					});

					var screditVals = rankingChart.map(function(value, index) {
						return value.sCreditVal;
					});

					var GSDPerHours = rankingChart.map(function(value, index) {
						return value.GPperHourOverAGPDays;
					});

					var PWH = {
						labels : names,
						datasets : [{
							label: "Consultant Per Phone Hour GP",
							backgroundColor : "rgba(219,138,151,0.2)",
							borderColor : "rgba(219,138,151,1)",
							borderWidth : 1,
							data : GSDPerHours
							}]
						}

					var AGP = {
						labels : names,
						datasets : [{
							label: "Period GP",
							backgroundColor : "rgba(144,198,124,0.2)",
							borderColor : "rgba(144,198,124,1)",
							borderWidth : 1,
							data : userGSDs
							}
							,{
							label: "Manually Entered Credits",
							backgroundColor : "rgba(94,131,145,0.2)",
							borderColor : "rgba(94,131,145,1)",
							borderWidth : 1,
							data : nscreditVals
							}
							,{
							label: "Post Sales Call Time Credit",
							backgroundColor : "rgba(219,138,151,0.2)",
							borderColor : "rgba(219,138,151,1)",
							borderWidth : 1,
							data : screditVals
							}]
						}

					j$('#canvas1').remove();
					j$('#td1').append('<canvas id="canvas1" height="300" width="350"></canvas>');
					var ctx = document.getElementById("canvas1").getContext("2d");

					window.myBar = new Chart(ctx, {
						type: 'bar',
						data: PWH,
						options: {
							responsive: true,
							pointHitDetectionRadius : 20,
							scales: {
								yAxes: [{
									ticks: {
										beginAtZero: true,
										callback: function(value) { return '$' + value; }
									}
								}]
							},
							legend: {
								display: false,
							},
							scaleLabel: 5,
							tooltips: {
								callbacks: {
									label: function(tooltipItems, data) { return '$' + tooltipItems.yLabel}
								}
							}
						}
					});

					j$('#legend1').html(window.myBar.generateLegend());


					j$('#canvas3').remove();
					j$('#td3').append('<div style="width: 430px;"><canvas id="canvas3" height="210"></canvas></div>');
					var ctx3 = document.getElementById("canvas3").getContext("2d");

					window.myBar = new Chart(ctx3, {
						type: 'bar',
						data: AGP,
						options: {
							responsive: true,
							pointHitDetectionRadius : 20,
							scales: {
								yAxes: [{
									ticks: {
										beginAtZero: true,
										callback: function(value) { return '$' + value; }
									}
								}]
							},
							legend: {
								display: false
							},
							scaleLabel: "$<%=value%>",
							tooltips: {
								displayColors: true,
								mode: 'label',
								callbacks: {
									label: function(tooltipItem, data){
										return '$ ' + tooltipItem.yLabel.toFixed(2).replace(/(\d)(?=(\d{3})+\.)/g, "$1,");
									},
									labelColor: function(tooltipItem, chartInstance) {
										var item = chartInstance.tooltip._data.datasets[tooltipItem.datasetIndex];
										return {
											borderColor: item.borderColor,
											backgroundColor: item.backgroundColor
										}

									}
								}
							}
						}
					});

					j$('#legend3').html(window.myBar.generateLegend());

					if(j$('#potSize').val()) {
						calculatePayouts(rankingChart);
					}
				}
			</script>

			<h3><span class="accordion-header-left">Calculator</span></h3>
			<div>
				<div id="calculatorFormWrapper">

					<div align="center">
					<label>Enter <a href="https://docs.google.com/spreadsheets/d/1FjOPykG5y3HqDTx1P1QfQXiR58H1692B_cLggTbnU6o/edit?ts=56e6b935#gid=0"  target="_blank" style="color: rgb(0,255,0)"><font color="3300FF">pool size:</font></a></label>
					<input type="text" size="3" name="potSize" id="potSize" value="0" />
				   </div><br />
					 <div align="center"><button name="calculate" id="calculate" onclick="createRanking('payouts');">Calculate!</button> </div><br />
				</div>
				<center>
					<div id="curveChart" style="width: 450px; height: 500px; display: inline-block;"><canvas id="canvas4"></canvas></div>
				</center>
				<div id="calculatorResultsWrapper"></div>

				<p class="tableh">Consultants with less than 16 hours or no Approved Time Off</p>
				<div id="calculatorNonVacationResultsWrapper"></div>
				<div id="calculatorBreakoutResultsWrapper"></div>
			</div>
		</div>
		<div id="perfcontainer">
			<cfquery name="getConsultantRank" dbtype="query">
				SELECT consultantName, userID AS ID, userGSD + nsCreditVal + sCreditVal AS gsTotal FROM getRankingChart ORDER BY gsTotal DESC
			</cfquery>
			<cfloop query="getConsultantRank">
				<cfset currentConsultant = #getConsultantRank.consultantName#>
				<cfquery name="consultantGSDDetail" dbtype="query">
					SELECT * FROM getRankingChart WHERE consultantName = <cfqueryparam cfsqltype="cf_sql_varchar" value='#getConsultantRank.consultantName#'>
				</cfquery>
				<cfoutput><h3 id="perf-accordion-#ID#"><span class="accordion-header-left">#getConsultantRank.consultantName#</span><span class="accordion-header-right">#NumberFormat(val(consultantGSDDetail.userGSD) + val(consultantGSDDetail.nscreditVal) + val(consultantGSDDetail.screditVal), "$,.99")#</span></h3>
				<!--- Use consultant ID for ID here so user's ID can be expanded by default' --->
				<div>
					<table class="consultant-summary">
						<thead>
							<tr>
								<th>Sales Gross Profit</th>
								<th>Credits</th>
								<th>Total Attributed Gross Profit</th>
							</tr>
						</thead>
						<tbody>
							<tr>
								<td>#NumberFormat(val(consultantGSDDetail.userGSD), "$,.99")#</td>
								<td>#NumberFormat(val(consultantGSDDetail.nscreditVal) + val(consultantGSDDetail.screditVal), "$,.99")#</td>
								<td>#NumberFormat(val(consultantGSDDetail.userGSD) + val(consultantGSDDetail.screditVal) + val(consultantGSDDetail.nscreditVal), "$,.99")#</td>
							</tr>
						</tbody>
					</table>
					<br />
					<cfif NOT ATTRIBUTES.summaryMode><br />
						<div class="consultant-credit-detail">
							<h3><span class="accordion-header-left">Credit Details</span></h3>
							<div>
								<cfset creditTable = perfPaycomponent.getConsultantCreditTable(consultantID="#getConsultantRank.ID#", minDate ="#minDate#", maxDate="#maxDate#", tableID="credit2Tbl#ID#")>
								#creditTable#
							</div>
						</div>
					</cfif>
				</cfoutput>
					<cfif NOT ATTRIBUTES.summaryMode>
						<div class="orders-all">
							<table class="orders-all-header"><thead><tr><th>Order Date</th><th>Order Number</th><th>Total GP</th><th>User GP</th></tr></thead></table>
							<cfquery name="VARIABLES.orderDetails" dbtype="query">
								SELECT sessionID,orderCreated,Name,orderQuantity,description,gsd,personName
								FROM  VARIABLES.allgsddata
								WHERE sessionID IN (SELECT DISTINCT sessionID
													FROM VARIABLES.allgsddata
													WHERE userID = <cfqueryparam sqltype="int" value='#VARIABLES.getConsultantRank.ID#'>)
								ORDER BY sessionID, userID
							</cfquery>
							<!--- Start Order Loop Here --->
							<cfoutput query="VARIABLES.orderDetails" group="sessionID">
								<cfquery name="VARIABLES.orderSum" dbtype="query">
									SELECT SUM(GSD) AS orderSum, 0.00 AS userSum
									FROM VARIABLES.allgsddata
									WHERE sessionID = <cfqueryparam cfsqltype="cf_sql_varchar" value='#VARIABLES.orderDetails.sessionID#'>

									UNION

									SELECT 0.00, SUM(GSD)
									FROM VARIABLES.allgsddata
									WHERE sessionID = <cfqueryparam cfsqltype="cf_sql_varchar" value='#VARIABLES.orderDetails.sessionID#'>
										AND userID = <cfqueryparam sqltype="int" value='#VARIABLES.getConsultantRank.ID#'>
								</cfquery>
								<h3><table><tr>
									<th>#DateFormat(VARIABLES.orderDetails.orderCreated, "mm/dd/yyyy")#</th>
									<th>#VARIABLES.orderDetails.sessionID#</th>
									<th>#dollarFormat(queryReduce(VARIABLES.ordersum,function(previousValue, value){return previousValue + value.ordersum;},0))#</th>
									<th>#dollarFormat(queryReduce(VARIABLES.ordersum,function(previousValue, value){return previousValue + value.usersum;},0))#</th>
								</tr></table></h3>
								<div>
									<table class="order-gp-detail mo" href="_orderPieChart.cfm?orderID=#VARIABLES.orderDetails.sessionID#" title="Click for Pie chart">
										<thead>
											<tr>
												<th>Item Description</th>
												<th>Item Quantity</th>
												<th>Attribute Description</th>
												<th>Attributed GP</th>
												<th>Person</th>
											</tr>
										</thead>
										<tbody>
											<cfoutput>
											<!--- Start order line detail loop here --->
											<tr>
												<td>#VARIABLES.orderDetails.Name#</td>
												<td>#VARIABLES.orderDetails.orderQuantity#</td>
												<td>#VARIABLES.orderDetails.description#</td>
												<td>#dollarFormat(VARIABLES.orderDetails.gsd)#</td>
												<td<cfif VARIABLES.orderDetails.personName EQ VARIABLES.currentConsultant> class="currentConsultant"</cfif>>#VARIABLES.orderDetails.personName#</td>
											</tr>
											<!--- End order line detail loop here --->
											</cfoutput>
										</tbody>
									</table>
								</div>
							</cfoutput>
							<!--- End order loop here --->
						</div>
					</cfif>
				</div>
			</cfloop>
		</cfif>
		</div>
	</div>
	<div id="hideDialog" style="display:none;">
		<div id="dialog-confirm" title="Edit Credit">
			<input type="hidden" value="" id="modal-objID">
			<label>AGP Days<input type="text" id="modal-days" name="modal-days"/></label><br />
			<label>AGP Percentage<input type="text" id="modal-pct" name="modal-pct"/></label><br />
			<label>Hours<input type="text" id="modal-hours" name="modal-hours"></label><br />
			<label>Comment<textarea id="modal-comment" name="modal-comment" rows="4" cols="60"></textarea></label>
		</div>
		<div id="dialog-status-response" title="">
			<span id="status-message"></span>
		</div>
		<div id="creditLogOuter" title="">
			<div id="creditLogInner" title=""></div>
		</div>
	</div>
</div>

<cfinclude template="/partnernet/shared/_footer.cfm">
