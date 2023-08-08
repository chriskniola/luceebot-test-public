<cfsetting showdebugoutput="false">
<cfparam name="attributes.orderID" default="">
<cfset attributes.orderID = (attributes.orderID EQ "") ? URLDecode(URL.orderID) : attributes.orderID>
<cfquery name="orderGSDByConsultant" datasource="#DSN#">
	SELECT o.sessionID
		, SUM(opp.GSD) AS 'GSDShare'
		, ISNULL(su.FirstName, 'Customer') + ' ' + ISNULL(su.LastName, '') AS 'Consultant'
	FROM tblOrderPerformancePay opp WITH(NOLOCK)
	LEFT OUTER JOIN tblSecurity_Users su on CAST(su.ID AS VARCHAR)=opp.userID
	INNER JOIN orders o on o.ID=opp.orderlineID
	WHERE o.SessionID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#attributes.orderID#">
	GROUP BY o.SessionID
	, su.FirstName
	, su.LastName
</cfquery>

<cfchart tipStyle="mousedown" font="Arial" fontsize=14 fontBold="yes" backgroundColor = "##FFFFFF" show3D="no" labelformat="currency" format="png">  
    <cfchartseries type="pie" query="orderGSDByConsultant" valueColumn="GSDShare" itemColumn="Consultant"
		colorlist="##6666FF,##66FF66,##FF6666,##66CCCC"
	/>
</cfchart>