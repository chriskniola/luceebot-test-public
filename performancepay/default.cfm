<cfsetting showdebugoutput="no">

<cfset screenID = "920">

<cfinclude template="/partnernet/shared/_header.cfm">
<div class="large">Performance Pay</div>
<div class="options">
	<ul>
		<li><a href="/partnernet/performancepay/performance_pay_reporting.cfm">Performance Pay Reporting --NEW</a></li>
		<li><a href="/partnernet/reports/telephonecallsbyuser.cfm">Consultant Telephone Call Averages (average minutes, total minutes)</a></li>
		<li><a href="/partnernet/reports/orderaveragesbyconsultant.cfm">Consultant Order Averages (order lines, revenue)</a></li>
		<li><a href="/partnernet/reports/performancePay_60DayAvg">Average GSD/Hour</a></li>
		<cfif superadmin OR session.user.ID EQ 110><li><a href="commissionpay.cfm">Commission Pay Metrics</a></cfif>
		<li><a href="/partnernet/reports/salesbybestmonths.cfm">Top Revenue Months</a></li>
		<li><a href="/partnernet/reports/rpt_orderExtrasByUser.cfm">Extras Added to Sales by User</a></li>
		<li><a href="/partnernet/reports/performancepay_froogleGSD">Total GSD by Date, Consultant, and Froogle Label</a></li>
		<li><a href="/partnernet/reports/performancepay_AGPByDateUserItem">Total AGP by Date, Consultant, and Item</a></li>
		<li><a href="/partnernet/reports/performancepay_orderListByDate">Order List By Date Showing If Order Has Consultant GSD Or Not</a></li>
		<li><a href="/partnernet/reports/performancePay_consultantPipelines">Consultant Pipelines</a></li>
	</ul>
	<strong>Survey Resources:</strong>
		<cfinclude template="/partnernet/survey/surveyLinks.cfm">
</div>
<cfinclude template="/partnernet/shared/_footer.cfm">
