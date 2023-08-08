<cfparam name="ATTRIBUTES.productID" default=204>
<cfsetting showdebugoutput="false">
<cfset screenID = "100">
<cfinvoke component="#APPLICATION.user#" method="checkscreenpermission" returnvariable="success">
	<cfinvokeargument name="screenID" value="#screenID#">
</cfinvoke>
<cfquery name="DRTHistory" datasource="#DSN#">
	DECLARE @prod INT
	SET @prod = <cfqueryparam cfsqltype="cf_sql_integer" value="#ATTRIBUTES.productID#">

	SELECT TOP 10 ol.created , ol.value
		, CASE WHEN su.ID <> 0 THEN su.LastName + ', ' + su.FirstName ELSE 'System' END as createdBy
	FROM tblObjectLog ol WITH(NOLOCK)
	INNER JOIN Products p (NOLOCK) on p.ID=@prod AND CAST(p.ID AS VARCHAR) = ol.objID
	LEFT OUTER JOIN tblSecurity_Users su (NOLOCK) ON su.ID = ol.createdby_int
	WHERE ol.value LIKE '(DR)%'
	ORDER BY ol.created DESC
</cfquery>
<cfquery name="ScheduledAdjustments" datasource="#DSN#">
	DECLARE @prod INT
	SET @prod = <cfqueryparam cfsqltype="cf_sql_integer" value="#ATTRIBUTES.productID#">

	SELECT rsr.oldPrice, rsr.scheduledOn
		, CASE WHEN su.ID <> 0 THEN su.LastName + ', ' + su.FirstName ELSE 'System' END as createdBy
		, CASE WHEN rsr.resetOnStock = 1
			THEN 'when stock reaches or falls below ' + CAST(rsr.resetStockLevel AS VARCHAR)
			ELSE 'on ' + CONVERT(VARCHAR, rsr.resetAtDate, 101)
		END AS resetText
	FROM tblRepriceScheduledResets rsr WITH (NOLOCK)
	INNER JOIN tblSecurity_Users su (NOLOCK) ON su.ID = rsr.userID
	WHERE prodID=@prod
</cfquery>
<cfif ScheduledAdjustments.recordCount OR DRTHistory.recordCount>
	<style>
		.repriceHistoryOutput table{ border-collapse: collapse; }
		.repriceHistoryOutput table th, .repriceHistoryOutput table td{ border: 1px solid black; padding: 2px; }
		.repriceHistoryOutput{ height: 300px; overflow-y:auto; }
	</style>
	<div class="repriceHistoryOutput">
		<cfoutput>
			<cfif ScheduledAdjustments.recordCount>
				<h4>An automatic reprice was scheduled by #ScheduledAdjustments.createdBy#</h4>
				<p>The price of the product will be reset to #DollarFormat(ScheduledAdjustments.oldPrice)# #ScheduledAdjustments.resetText#</p>
			</cfif>
		</cfoutput>
		<cfif DRTHistory.recordCount>
			<table>
				<tr>
					<th>Date</th>
					<th>User</th>
					<th>Log</th>
				</tr>
				<cfoutput query="DRTHistory">
					<tr>
						<td>#DateFormat(created, "mm/dd/yyyy")#</td>
						<td>#createdBy#</td>
						<td>#value#</td>
					</tr>
				</cfoutput>
			</table>
		</cfif>
	</div>
<cfelse>
	<div class="repriceHistoryOutput">
		<p>There is no history to display</p>
	</div>
</cfif>
