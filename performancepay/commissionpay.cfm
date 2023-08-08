<cfsetting showdebugoutput="no">

<cfset screenID = "920">
<cfset recordhistory = "0">
<cfset showjQuery = 1>

<cfparam name="attributes.mindate" default="#DateFormat(dateAdd('d', -30, Now()), 'mm/dd/yyyy')#">
<cfparam name="attributes.maxdate" default="#DateFormat(Now(), 'mm/dd/yyyy')#">
<cfparam name="attributes.asuser" default="0">
<cfparam name="attributes.cid" default="0">
<cfparam name="attributes.pcnt" default="1">
<cfparam name="attributes.mgrpcnt" default="0.1">
<cfparam name="attributes.getdata" default="">
<cfparam name="attributes.reason" default="">
<cfparam name="attributes.order" default="">
<cfparam name="attributes.enabled" default="">
<cfparam name="attributes.amountid" default="">
<cfparam name="attributes.showdisabled" default="No">
<cfparam name="attributes.repuse" default="timeline">

<cfif session.user.ID EQ 110>
	<cfset superadmin = 1>
</cfif>

<cfif superadmin AND attributes.asuser NEQ 0>
<!--- <cfset attributes.cid = attributes.asuser> --->
<cfset superadmin = 0>
</cfif>

<cfquery name="consultants" datasource="#DSN#">
SELECT 0 as ID, 'All' as FirstName, '' as LastName, 'All' as name

UNION 

SELECT ID, FirstName, LastName, FirstName + ' ' + LastName as name
FROM tblSecurity_Users
WHERE isconsultant = 1
<cfif NOT superadmin>
AND isactive = 1
<!--- AND (id = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.cid#">
	OR id = <cfqueryparam cfsqltype="CF_SQL_INT" value="#session.user.id#">
	OR (SELECT manages FROM tblSecurity_Users WHERE ismanager = 1 AND id = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.cid#">) LIKE '%' + CONVERT(varchar(25), id) + '%') --->
	
</cfif>
<cfif attributes.cid NEQ 0>
AND id = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.cid#">
</cfif>
</cfquery>

<cfif attributes.cid NEQ 0>
	<cfquery name="curuser" datasource="#DSN#">
	SELECT ismanager
	FROM tblSecurity_Users
	WHERE id = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.cid#">
	</cfquery>
<cfelse>
	<cfset curuser.ismanager = 0>
</cfif>

<cfif attributes.reason EQ "popup">
	
	<cfquery name="orderdetail" datasource="#DSN#">
	DECLARE @tmp TABLE (id varchar(5), name varchar(25), product varchar(255), commreason varchar(255), commission float, mngcomm float, manages varchar(255), sessionid varchar(50), oid int)
	
	INSERT INTO @tmp (id, name, product, commreason, commission, mngcomm, manages, sessionid, oid)
		SELECT su.ID
			, su.FirstName
			, o.description
			, opp.description
			, SUM(Round(opp.GSD * (pp.amount / 100), 2))
			, SUM(Round(opp.GSD * (ppm.amount / 100), 2))
			, su.manages
			, o.sessionID
			, o.ID
		FROM tblOrderPerformancePay opp (NOLOCK)
		INNER JOIN tblSecurity_Users su (NOLOCK) ON CONVERT(varchar(50), su.ID) = opp.userID
		INNER JOIN orders o (NOLOCK) ON o.ID = opp.orderlineID
		INNER JOIN checkouts c (NOLOCK) ON c.sessionID = o.sessionID 
		LEFT OUTER JOIN tblPerformancePayPercents pp (NOLOCK) ON pp.ID = (SELECT TOP 1 tpp.ID FROM tblPerformancePayPercents tpp (NOLOCK) WHERE tpp.enabled = 1 AND tpp.type = 'direct' AND tpp.date < opp.datetoapply ORDER BY tpp.date DESC)
		LEFT OUTER JOIN tblPerformancePayPercents ppm (NOLOCK) ON ppm.ID = (SELECT TOP 1 tpp.ID FROM tblPerformancePayPercents tpp (NOLOCK) WHERE tpp.enabled = 1 AND tpp.type = 'manager' AND tpp.date < opp.datetoapply ORDER BY tpp.date DESC)
		WHERE o.sessionID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attributes.order#">
		AND su.isconsultant = 1
		<!--- <cfif attributes.cid NEQ 0> --->
			AND su.ID IN (<cfqueryparam cfsqltype="CF_SQL_INT" list="yes" value="#ValueList(consultants.id)#">)
		<!--- </cfif> --->
		GROUP BY o.ID, su.ID, su.FirstName, o.description, opp.description, su.manages, o.sessionID
		ORDER BY o.ID, su.FirstName
	
	SELECT *
	FROM @tmp t
	</cfquery>
	
	<cfoutput>
	<div id="report" class="indialog">
		<cfif superadmin>
			<div class="ui-state-error" style="border:0;">
				<span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
			</div>
			<small>Commissions displayed here are using timeline-based numbers only</small>
		</cfif>
		<table style="white-space:nowrap">
			<thead>
				
				<tr>
					<th colspan="5" align="center">Order Line Detail for #attributes.order#</th>
				</tr>
				<tr>
					<th>Name</th>
					<th>Product</th>
					<th>Commission</th>
					<cfif superadmin OR curuser.ismanager><th><span title="How much a manager of this employee earned" class="ui-icon ui-icon-help" style="float: left; margin-right: .3em;"></span>As Manager</th></cfif>
					<th>Commission Note</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="orderdetail">
					<tr>
						<td>#orderdetail.name#</td>
						<td style="white-space:nowrap">#orderdetail.product#</td>
						<td>#DollarFormat(orderdetail.commission)#</td>
						<cfif superadmin OR curuser.ismanager><td>#DollarFormat(orderdetail.mngcomm)#</td></cfif>
						<td style="white-space:nowrap">#orderdetail.commreason#</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</div>
	</cfoutput>
	
	<cfexit>

</cfif>

<cfif attributes.reason EQ "savepercent">
	
	<cftry>
		<cfquery name="savepercent" datasource="#DSN#">
		INSERT INTO tblPerformancePayPercents (date, type, amount, created, createdby, enabled)
		VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DATE" value="#CreateODBCDate(attributes.effdate)#">
			, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="25" value="direct">
			, <cfqueryparam cfsqltype="CF_SQL_FLOAT" value="#attributes.pcnt#">
			, <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#CreateODBCDateTime(Now())#">
			, <cfqueryparam cfsqltype="CF_SQL_INT" value="#session.user.ID#">
			, <cfqueryparam cfsqltype="CF_SQL_BIT" value="1">
		)
		</cfquery>
		
		<cfquery name="savepercent" datasource="#DSN#">
		INSERT INTO tblPerformancePayPercents (date, type, amount, created, createdby, enabled)
		VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DATE" value="#CreateODBCDate(attributes.effdate)#">
			, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="25" value="manager">
			, <cfqueryparam cfsqltype="CF_SQL_FLOAT" value="#attributes.mgrpcnt#">
			, <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#CreateODBCDateTime(Now())#">
			, <cfqueryparam cfsqltype="CF_SQL_INT" value="#session.user.ID#">
			, <cfqueryparam cfsqltype="CF_SQL_BIT" value="1">
		)
		</cfquery>
	<cfcatch>
		0
		<cfexit>
	</cfcatch>
	</cftry>
	
	1
	<cfexit>
</cfif>

<cfif attributes.reason EQ "turnonoff">
	
	<cftry>
		<cfquery name="setenabled" datasource="#DSN#">
		UPDATE tblPerformancePayPercents
		SET enabled = <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.enabled#">
		WHERE ID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.amountid#">
		</cfquery>
	<cfcatch>
		0
		<cfexit>
	</cfcatch>
	</cftry>
	
	1
	<cfexit>
</cfif>


<cfif attributes.reason EQ "">
	
	<cfset showreport = 0>
	
	<cfinclude template="/partnernet/shared/_header.cfm">
	
	<p><a href="default.cfm"><strong>Back to Menu</strong></a></p>
	
	<cfoutput>
	<div id="comtabs" class="options">
		<ul>
			<li><a href="##reporting">Reports</a></li>
			<cfif superadmin><li><a href="##save">Make Adjustments</a></li></cfif>
			<cfif superadmin><li><a href="##edit">Edit Past Amounts</a></li></cfif>
		</ul>
		
		<div id="reporting" style="">
			<h3>Consultant Commission Metrics</h3>
			<form id="config" name="config" method="post" action="#CGI.SCRIPT_NAME#">
				<div style="display:inline-block; zoom:1; *display:inline;">
					<div style="position:relative; float:left;">
						<label for="mindate">Start Date:</label><br><input type="text" id="mindate" name="mindate" class="dpDate" value="#attributes.mindate#"></input>
					</div>
					<div style="position:relative; float:left; margin-left:2em;">
						<label for="maxdate">End Date:</label><br><input type="text" id="maxdate" name="maxdate" class="dpDate" value="#attributes.maxdate#"></input>
					</div>
					<div style="position:relative; float:left; margin-left:2em;">
						<label for="cid">Consultant:</label><br>
						<select id="cid" name="cid" class="" value="#attributes.cid#">
							<cfloop query="consultants">
							<option value="#consultants.ID#"<cfif consultants.id EQ attributes.cid> selected</cfif>>#consultants.name#</option>
							</cfloop>
						</select>
					</div>
					<cfif superadmin>
						<div style="float:left; margin-left:2em;">
							<label for="pcnt">Commission:</label><br><input type="text" id="pcnt" name="pcnt" size="3" value="#attributes.pcnt#">%</input>
						</div>
						<div style="float:left; margin-left:2em;">
							<label for="mgrpcnt">Mgr Commission:</label><br><input type="text" id="mgrpcnt" name="mgrpcnt" size="3" value="#attributes.mgrpcnt#">%</input>
						</div>
						<!--- <div class="clear"></div> --->
						<div style="float:left; margin:0 2em;">
							<label for="repuse">Use Commission:</label><br>
							<select id="repuse" name="repuse">
								<option value="timeline"<cfif attributes.repuse EQ "timeline"> selected</cfif>>Timeline</option>
								<option value="manual"<cfif attributes.repuse EQ "manual"> selected</cfif>>Manually Entered</option>
								<option value="recent"<cfif attributes.repuse EQ "recent"> selected</cfif>>Most Recent</option>
							</select>
						</div>
					</cfif>
					<div class="clear"></div>
					<div style="margin-top:2em;">
						<input type="hidden" name="asuser" value="#attributes.asuser#" />
						<input type="submit" id="getdata" name="getdata" value="Submit" class="button"></input>
					</div>
				</div>
				
			</form>
			<div class="clear"></div>
		</div>
		
		<cfif superadmin>
			<div id="save" class="">
				<h3>Save Consultant Commission Metrics</h3>
				<form id="savepercents" name="savepercents" action="javascript: donothing();">
					<div style="display:inline-block; zoom:1; *display:inline;">
						<div style="position:relative; float:left;">
							<label for="effdate">Effective Date:</label><br><input type="text" id="effdate" name="effdate" class="dpDate" value="#Dateformat(Now(), 'mm/dd/yyyy')#"></input>
						</div>
						<!--- <div class="clear"></div> --->
						<div style="position:relative; float:left; white-space:nowrap; margin-left:1em; margin-top:1em;">
							<div style="float:left; margin-right:0.5em; padding-top:0.6em;">
								Set commision to 
							</div>
							<div id="pcnttoset" style="float:left; padding-top:0.6em;">
								#attributes.pcnt#
							</div>
							<div style="float:left; padding-top:0.6em; margin-right:0.5em;">% for direct, and </div>
							<div id="mgrpcnttoset" style="float:left; padding-top:0.6em;">
								#attributes.mgrpcnt#
							</div>
							<div style="float:left; padding-top:0.6em; margin-right:0.5em;">% for manager's commission?</div>
							<div class="clear"></div>
						</div>
						<div class="clear"></div>
						<div style="margin-top:2em;">
							<button id="setcommission" name="setcommission" class="button">Save</button>
						</div>
					</div>
				</form>
			</div>
		</cfif>
		
		<cfif superadmin>
			<div id="edit" class="">
				<h3>Edit Past Commission Amounts</h3>
				<form id="pastamounts" name="pastamounts" method="post" action="#CGI.SCRIPT_NAME#">
					<div style="display:inline-block; zoom:1; *display:inline;">
						<div style="position:relative; float:left;">
							<label for="mindate2">Start Date:</label><br><input type="text" id="mindate2" name="mindate" class="dpDate" value="#attributes.mindate#"></input>
						</div>
						<div style="position:relative; float:left; margin-left:2em;">
							<label for="maxdate2">End Date:</label><br><input type="text" id="maxdate2" name="maxdate" class="dpDate" value="#attributes.maxdate#"></input>
						</div>
						<div style="margin:1.5em 0 0 2em; float:left;">
							Show Disabled Amounts?
							Yes<input type="radio" name="showdisabled" value="yes"<cfif attributes.showdisabled EQ "Yes"> checked</cfif>></input>
							No<input type="radio" name="showdisabled" value="no"<cfif attributes.showdisabled EQ "No"> checked</cfif>></input>
						</div>
						<div class="clear"></div>
						<div style="margin-top:2em; float:left;">
							<input type="submit" id="getdata" name="getdata" value="Get Amounts" class="button"></input>
						</div>
					</div>
				</form>
				<div class="clear"></div>
			</div>
		</cfif>
		
	</div>
	</cfoutput>

</cfif>

<cfif attributes.getdata EQ "Submit">
	
	<cfquery name="comsummary" datasource="#DSN#">
	DECLARE @tmp TABLE (ID varchar(5), FirstName varchar(25), commission float, commissionpaid float, manages varchar(255), mngcomm float)
	
	INSERT INTO @tmp (ID, FirstName, commission, commissionpaid, manages, mngcomm)
		SELECT su.ID, su.FirstName + ', ' + Left(su.LastName, 2) + '.', Round(SUM(opp.GSD), 2) as commission
		 <cfif attributes.repuse EQ "timeline">
		, SUM(Round(opp.GSD * (pp.amount / 100), 2)) as commissionpaid
		<cfelseif attributes.repuse EQ "recent">
		, Round(SUM(Round(opp.GSD, 2)) * (SELECT TOP 1 amount / 100 FROM tblPerformancePayPercents WHERE enabled = 1 AND type = 'direct' ORDER BY date DESC), 2) as commissionpaid
		<cfelseif attributes.repuse EQ "manual">
		, Round(SUM(Round(opp.GSD, 2)) * <cfqueryparam cfsqltype="CF_SQL_FLOAT" value="#attributes.pcnt / 100#">, 2) as commissionpaid
		</cfif>
		, su.manages
		<cfif attributes.repuse EQ "timeline">
		, SUM(Round(opp.GSD * (ppm.amount / 100), 2)) as mgrcomm
		<cfelseif attributes.repuse EQ "recent">
		, Round(SUM(Round(opp.GSD, 2)) * (SELECT TOP 1 amount / 100 FROM tblPerformancePayPercents WHERE enabled = 1 AND type = 'manager' ORDER BY date DESC), 2) as mgrcomm
		<cfelseif attributes.repuse EQ "manual">
		, Round(SUM(Round(opp.GSD, 2)) * <cfqueryparam cfsqltype="CF_SQL_FLOAT" value="#attributes.mgrpcnt / 100#">, 2) as mgrcomm
		</cfif>
		FROM tblOrderPerformancePay opp (NOLOCK)
		INNER JOIN tblSecurity_Users su (NOLOCK) ON CONVERT(varchar(50), su.ID) = opp.userID
		INNER JOIN orders o (NOLOCK) ON o.ID = opp.orderlineID
		INNER JOIN checkouts c (NOLOCK) ON c.sessionID = o.sessionID 
			AND c.shipdate BETWEEN <cfqueryparam cfsqltype="CF_SQL_DATE" value="#attributes.mindate#"> AND <cfqueryparam cfsqltype="CF_SQL_DATE" value="#attributes.maxdate#">
		LEFT OUTER JOIN tblPerformancePayPercents pp (NOLOCK) ON pp.ID = (SELECT TOP 1 tpp.ID FROM tblPerformancePayPercents tpp (NOLOCK) WHERE tpp.enabled = 1 AND tpp.type = 'direct' AND tpp.date < opp.datetoapply ORDER BY tpp.date DESC)
		LEFT OUTER JOIN tblPerformancePayPercents ppm (NOLOCK) ON ppm.ID = (SELECT TOP 1 tpp.ID FROM tblPerformancePayPercents tpp (NOLOCK) WHERE tpp.enabled = 1 AND tpp.type = 'manager' AND tpp.date < opp.datetoapply ORDER BY tpp.date DESC)
		WHERE su.isconsultant = 1
		<!--- <cfif attributes.cid NEQ 0> --->
			AND su.ID IN (<cfqueryparam cfsqltype="CF_SQL_INT" list="yes" value="#ValueList(consultants.id)#">)
		<!--- </cfif> --->
		GROUP BY su.ID, su.FirstName, su.LastName, su.manages
		ORDER BY su.FirstName
	
	SELECT t.ID, t.FirstName, t.commissionpaid, t.manages
		, Round((SELECT SUM(mngcomm) FROM @tmp tm WHERE t.manages LIKE '%' + tm.ID + '%'), 2) as managedcomm
		, Round(t.commissionpaid + (SELECT SUM(mngcomm) FROM @tmp tm WHERE t.manages LIKE '%' + tm.ID + '%'), 2) as total
	FROM @tmp t
	</cfquery>
	
	<cfquery name="comdetail" datasource="#DSN#">
	DECLARE @tmp TABLE (ID varchar(5), FirstName varchar(25), commission float, commissionpaid float, manages varchar(255), mngcomm float, sessionID varchar(25), name varchar(50), thedate date, amount float)
	
	INSERT INTO @tmp (ID, FirstName, commission, commissionpaid, manages, mngcomm, sessionID, name, thedate, amount)
		SELECT su.ID, su.FirstName + ', ' + Left(su.LastName, 2) + '.', Round(SUM(opp.GSD), 2) as commission
		 <cfif attributes.repuse EQ "timeline">
		, SUM(Round(opp.GSD * (pp.amount / 100), 2)) as commissionpaid
		<cfelseif attributes.repuse EQ "recent">
		, Round(SUM(Round(opp.GSD, 2)) * (SELECT TOP 1 amount / 100 FROM tblPerformancePayPercents WHERE enabled = 1 AND type = 'direct' ORDER BY date DESC), 2) as commissionpaid
		<cfelseif attributes.repuse EQ "manual">
		, Round(SUM(Round(opp.GSD, 2)) * <cfqueryparam cfsqltype="CF_SQL_FLOAT" value="#attributes.pcnt / 100#">, 2) as commissionpaid
		</cfif>
		, su.manages
		<cfif attributes.repuse EQ "timeline">
		, SUM(Round(opp.GSD * (ppm.amount / 100), 2)) as mngcomm
		<cfelseif attributes.repuse EQ "recent">
		, Round(SUM(Round(opp.GSD, 2)) * (SELECT TOP 1 amount / 100 FROM tblPerformancePayPercents WHERE enabled = 1 AND type = 'manager' ORDER BY date DESC), 2) as mngcomm
		<cfelseif attributes.repuse EQ "manual">
		, Round(SUM(Round(opp.GSD, 2)) * <cfqueryparam cfsqltype="CF_SQL_FLOAT" value="#attributes.mgrpcnt / 100#">, 2) as mngcomm
		</cfif>
		, o.sessionID, c.name, CONVERT(varchar, c.dt, 23) as thedate
		, pp.amount
		FROM tblOrderPerformancePay opp (NOLOCK)
		INNER JOIN tblSecurity_Users su (NOLOCK) ON CONVERT(varchar(50), su.ID) = opp.userID
		INNER JOIN orders o (NOLOCK) ON o.ID = opp.orderlineID
		INNER JOIN checkouts c (NOLOCK) ON c.sessionID = o.sessionID 
			AND c.shipdate BETWEEN <cfqueryparam cfsqltype="CF_SQL_DATE" value="#attributes.mindate#"> AND <cfqueryparam cfsqltype="CF_SQL_DATE" value="#attributes.maxdate#">
		LEFT OUTER JOIN tblPerformancePayPercents pp (NOLOCK) ON pp.ID = (SELECT TOP 1 tpp.ID FROM tblPerformancePayPercents tpp (NOLOCK) WHERE tpp.enabled = 1 AND tpp.type = 'direct' AND tpp.date < opp.datetoapply ORDER BY tpp.date DESC)
		LEFT OUTER JOIN tblPerformancePayPercents ppm (NOLOCK) ON ppm.ID = (SELECT TOP 1 tpp.ID FROM tblPerformancePayPercents tpp (NOLOCK) WHERE tpp.enabled = 1 AND tpp.type = 'manager' AND tpp.date < opp.datetoapply ORDER BY tpp.date DESC)
		WHERE su.isconsultant = 1
		<!--- <cfif attributes.cid NEQ 0> --->
			AND su.ID IN (<cfqueryparam cfsqltype="CF_SQL_INT" list="yes" value="#ValueList(consultants.id)#">)
		<!--- </cfif> --->
		GROUP BY su.ID, su.FirstName, su.LastName, o.sessionID, c.name, CONVERT(varchar, c.dt, 23), su.manages, pp.amount
		ORDER BY su.FirstName
	
	SELECT *
		, Round((SELECT SUM(mngcomm) FROM @tmp tm WHERE t.manages LIKE '%' + tm.ID + '%' AND tm.sessionID = t.sessionID), 2) as managedcomm
	FROM @tmp t
	</cfquery>
	
	<cfif comsummary.recordcount>
		
		<cfset ppvalues = ListSort(ValueList(comsummary.commissionpaid), "numeric")>
		<cfset ppmax = ListLast(ppvalues)>
		
		<cfif ppmax EQ "">
			<cfset ppmax = 1>
		</cfif>
		
		<cfoutput>
		<div id="report" class="comreport">
			<table id="summary" style="width:790px; margin:0 auto;" align="center">
				<thead>
					<tr>
						<th style="width:100px;">Name</th>
						<th>Commission</th>
						<cfif superadmin OR curuser.ismanager><th style="width:85px; white-space:nowrap;"><span title="How much this employee earned as a manager" class="ui-icon ui-icon-help" style="float: left; margin-right: .3em;"></span>As Manager</th></cfif>
					</tr>
				</thead>
				<tbody>
					<cfloop query="comsummary">
						<tr>
							<td>#comsummary.FirstName#</td>
							<td class="clickable">#DollarFormat(comsummary.commissionpaid)# <div style="float:right;"><small>(click to expand details)</small></div></td>
							<cfif superadmin OR curuser.ismanager><td><cfif comsummary.manages NEQ "">#DollarFormat(comsummary.managedcomm)#</cfif></td></cfif>
						</tr>
						
						<cfquery name="comdetailq" dbtype="query">
						SELECT *
						FROM comdetail
						WHERE CAST(ID as INTEGER) = CAST(<cfqueryparam cfsqltype="CF_SQL_INT" value="#comsummary.ID#"> as INTEGER)
						ORDER BY thedate
						</cfquery>
						
						<tr style="display:none;">
							<td></td>
							<td>
								<div style="max-height:40em; overflow-y:scroll; overflow-x:none;">
									<table id="detail" align="center">
										<thead>
											<tr>
												<th>Order</th>
												<th>Name</th>
												<th>Date</th>
												<th>Commission Paid</th>
												<cfif superadmin OR curuser.ismanager><th><span title="How much this employee earned as a manager" class="ui-icon ui-icon-help" style="float: left; margin-right: .3em;"></span>As Manager</th></cfif>
												<th><span title="Commission percentage based on ship date of order" class="ui-icon ui-icon-help" style="float: left; margin-right: .3em;"></span>Percent</th>
											</tr>
										</thead>
										<tbody>
											<cfloop query="comdetailq">
												<tr>
													<td class="ood" id="#comdetailq.sessionid#">#comdetailq.sessionid#</td>
													<td>#comdetailq.name#</td>
													<td>#DateFormat(comdetailq.thedate, "mm/dd/yyyy")#</td>
													<td>#DollarFormat(comdetailq.commissionpaid)#</td>
													<cfif superadmin OR curuser.ismanager><td><cfif comsummary.manages NEQ "">#DollarFormat(comdetailq.managedcomm)#</cfif></td></cfif>
													<td>#comdetailq.amount#%</td>
												</tr>
											</cfloop>
										</tbody>
									</table>
								</div>
							</td>
							<cfif superadmin OR curuser.ismanager><td></td></cfif>
						</tr>
					</cfloop>
				</tbody>
			</table>
			
			<div style="margin:0 auto; text-align:center; padding-top:2em;">
				<cfchart 
					backgroundColor="white"
					chartWidth="800"
					scaleFrom="0"
					scaleTo="#ppmax * 1.1#"
					labelFormat="number"
					showBorder="no"
					format="jpg"
					title="Order Commissions"
					>
					
					<cfchartseries type="bar" query="comsummary" itemcolumn="firstname" valuecolumn="commissionpaid" paintStyle="shade" seriesColor="1874CD" />
				</cfchart>
			</div>
			<div class="clear"></div>
		</div>
		</cfoutput>
		
	<cfelse>
		<div style="margin:0 auto; text-align:center;" class="comreport">
			<div style="display:inline-block; padding:1em 2em; zoom:1; *display:inline;" class="ui-state-error ui-corner-all">
				<span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
				<strong>Sorry!</strong> No records found.
			</div>
		</div>
	</cfif>
	
</cfif>

<cfif attributes.getdata EQ "Get Amounts">
	
	<cfquery name="pastamounts" datasource="#DSN#">
	DECLARE @makenice TABLE (id int, mydate date, type varchar(25), amount float, directamount float, mgramount float, enabled bit, created date, createdby varchar(50))
	INSERT INTO @makenice (id, mydate, type, amount, directamount, mgramount, enabled, created, createdby)
		SELECT pp.ID
			, CONVERT(varchar, pp.date, 23)
			, pp.type
			, pp.amount
			, CASE WHEN pp.type = 'direct' THEN pp.amount END as directamount
			, CASE WHEN pp.type = 'manager' THEN pp.amount END as mgramount
			, pp.enabled
			, pp.created
			, su.FirstName + ' ' + Left(su.LastName, 1) + '.'
		FROM tblPerformancePayPercents pp
		INNER JOIN tblSecurity_Users su ON su.ID = pp.createdby
		WHERE pp.date BETWEEN <cfqueryparam cfsqltype="CF_SQL_DATE" value="#attributes.mindate#"> AND <cfqueryparam cfsqltype="CF_SQL_DATE" value="#attributes.maxdate#">
		<cfif NOT attributes.showdisabled>
			AND pp.enabled = 1
		</cfif>
		ORDER BY pp.date
	
	SELECT mn.id, mn.mydate as date, mn.type, mn.amount, enabled, created, createdby as name
		, ISNULL(mn.directamount, (SELECT TOP 1 mnt.directamount FROM @makenice mnt WHERE mnt.mydate <= mn.mydate AND mnt.type = 'direct' ORDER BY mnt.mydate DESC)) as directamount
		, ISNULL(mn.mgramount, (SELECT TOP 1 mnt.mgramount FROM @makenice mnt WHERE mnt.mydate <= mn.mydate AND mnt.type = 'manager' ORDER BY mnt.mydate DESC)) as mgramount
	FROM @makenice mn
	</cfquery>
	
	<cfif pastamounts.recordcount>
		
		<cfset ppvalues = ListSort(ValueList(pastamounts.directamount), "numeric")>
		<cfset ppmax = ListLast(ppvalues)>
		
		<cfif ppmax EQ "">
			<cfset ppmax = 1>
		</cfif>
		
		<cfoutput>
		<div id="report" class="amountreport">
			<table id="amttable" align="center">
				<thead>
					<tr>
						<th>Effective Date</th>
						<th>Type</th>
						<th>Percent</th>
						<th>Created By</th>
						<th>Created</th>
						<th>Enabled?</th> <!--- this must be the last column or javascript will break --->
					</tr>
				</thead>
				<tbody>
					<cfloop query="pastamounts">
						<tr>
							<td>#DateFormat(pastamounts.date, "mm/dd/yyyy")#</td>
							<td style="text-transform:capitalize;">#pastamounts.type#</td>
							<td>#pastamounts.amount#%</td>
							<td>#pastamounts.name#</td>
							<td>#DateFormat(pastamounts.created, "mm/dd/yyyy")#</td>
							<td style="text-align:center;"><input type="checkbox" id="#pastamounts.id#" class="amtchangebx"<cfif pastamounts.enabled> checked</cfif>></input></td> <!--- this must be the last column or javascript will break --->
						</tr>
					</cfloop>
				</tbody>
			</table>
			
			<div style="margin:0 auto; text-align:center; padding-top:2em;">
				<cfchart 
					backgroundColor="white"
					chartWidth="800"
					scaleFrom="0"
					scaleTo="#ppmax * 1.1#"
					labelFormat="number"
					showBorder="no"
					format="jpg"
					title="Commission Percentages"
					>
					
					<cfchartseries type="line" query="pastamounts" itemcolumn="date" valuecolumn="directamount" seriesColor="1874CD" markerStyle="circle" />
					<cfchartseries type="line" query="pastamounts" itemcolumn="date" valuecolumn="mgramount" seriesColor="green" markerStyle="circle" />
				</cfchart>
			</div>
		</div>
		</cfoutput>
		
	<cfelse>
		<div style="margin:0 auto; text-align:center;" class="amountreport">
			<div style="display:inline-block; padding:1em 2em; zoom:1; *display:inline;" class="ui-state-error ui-corner-all">
				<span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
				<strong>Sorry!</strong> No records found.
			</div>
		</div>
	</cfif>
	
</cfif>

<style type="text/css">
.error {
	color:red;
	font-weight:bold;
	white-space:nowrap;
}
label.error {
	position:absolute;
	left:0;
	top:4.5em;
	white-space:nowrap;
}
.clickable {
	cursor:pointer;
}
.ood {
	cursor:pointer;
	color:blue;
	text-decoration:underline;
}
#comtabs {
	display:none;
}
</style>

<script type="text/javascript">
<cfif superadmin>
	function showhideenabled(aval){
		j$('#amttable tbody tr').each(function(){
			j$(this).show(500);
			if(aval == 'no') {
				if(j$(this).children('td').filter(':last').children('input:checkbox').is(':checked') == false){
					j$(this).hide(500);
				}
			}
		});
	}
</cfif>

j$(function(){
	var seltab = 0;
	
	<cfif superadmin AND attributes.getdata EQ "Get Amounts">
		seltab = 2;
	</cfif>
	
	j$('#comtabs').tabs({ 
		selected: seltab,
		select: function(event, ui){
			if(ui.index == 2){
				j$('.comreport').slideUp(500);
				j$('.amountreport').slideDown(500); 
			} else {
				j$('.amountreport').slideUp(500);
				j$('.comreport').slideDown(500); 
			}
		},
		create: function(){
			j$('#comtabs').fadeIn(500);
		}
	});
	
	j$('.ui-widget-header').css({ 'border':'0' });
	
	j$('#config,#savepercents,#pastamounts').validate({
		errorPlacement: function(error, element) {
	        error.insertBefore(element);
	    }
	});
	
	<cfif superadmin>
		j$('#savepercents').validate({
			errorPlacement: function(error, element) {
		        error.insertBefore(element);
		    }
		});
		j$('#pastamounts').validate({
			errorPlacement: function(error, element) {
		        error.insertBefore(element);
		    }
		});
	</cfif>
	
	j$('input[name=mindate]').datepicker({ autoSize:true, defaultDate: <cfoutput>'#attributes.mindate#'</cfoutput>, dateFormat: 'mm/dd/yy' });
	j$('input[name=maxdate]').datepicker({ autoSize:true, defaultDate: <cfoutput>'#attributes.maxdate#'</cfoutput>, dateFormat: 'mm/dd/yy' });
	j$('input[name=effdate]').datepicker({ autoSize:true, dateFormat: 'mm/dd/yy' });
	j$('#getdata,#setcommission').button();
	
	j$('input, select').not('[type="submit"]').each(function(){
		j$(this).css('font-size','1.2em').css('padding','0.3em');
	});
	
	j$('#summary > tbody > tr:nth-child(4n + 3)').css('background-color','#E8E8E8');
	
	j$('.clickable').click(function(){
		var myrow = j$(this).parent().parent().children().index(j$(this).parent());
		var nextrow = j$('#summary > tbody > tr').eq(myrow + 1);
		j$(nextrow).fadeToggle(800, 'linear');
		if(j$.browser.msie && j$('div', nextrow).height() > 600) j$('div', nextrow).css({ 'height':'40em','overflow-y':'scroll' });
	});
	
	j$('.ood').click(function(){
		var ordid = j$(this).prop('id');
		var pcnt = j$('#pcnt').val();
		var cid = j$('#cid').val();
		
		j$.ajax({
			url: <cfoutput>'#CGI.SCRIPT_NAME#'</cfoutput>,
			data: {reason: 'popup', order: ordid, pcnt: pcnt, cid: cid},
			type: 'POST',
			success: function(response){
				var mydialog = j$('<div>').prop('title','Order Commission Detail').css({ 'max-height':'40em','overflow-x':'none'  }).html(response).dialog({ modal: false, autoOpen:true, width:200 });
				var mywidth = j$('table', mydialog).width();
				if(j$.browser.msie && j$('.indialog', mydialog).height() > 600) j$('.indialog', mydialog).css({ 'height':'40em','overflow-y':'scroll' });
				j$(mydialog).dialog('option', 'width', parseInt(mywidth + 50)).dialog('option', 'position', ['center','center']);
			},
			failure: function(){
				alert('There was an error retrieving the order info.');
			}
		});
		
	});
	
	<cfif superadmin>
		
		j$('input[name=mindate],input[name=maxdate]').change(function(){
			var newdate = j$(this).val();
			var myname = j$(this).prop('name');
			j$('input[name=' + myname + ']').val(newdate);
		});
		
		// j$('#pastamounts #mindate').trigger('change');
		
		j$('#pcnt').change(function(){
			var myval = j$('#pcnt').val();
			j$('#pcnttoset').html(myval);
		});
		
		j$('#mgrpcnt').change(function(){
			var myval = j$('#mgrpcnt').val();
			j$('#mgrpcnttoset').html(myval);
		});
		
		j$('#setcommission').click(function(){
			var pcnt = j$('#pcnt').val();
			var mgrpcnt = j$('#mgrpcnt').val();
			var effdate = j$('#effdate').val();
			
			j$.ajax({
				url: <cfoutput>'#CGI.SCRIPT_NAME#'</cfoutput>,
				data: {reason: 'savepercent', pcnt: pcnt, mgrpcnt: mgrpcnt, effdate: effdate},
				type: 'POST',
				success: function(response){
					if(j$.trim(response) == '1') {
						alert('New commission percentage successfully saved.');
					} else {
						alert('There was an error saving the commission percentage.');
					}
				}, 
				failure: function(){
					alert('There was an error contacting the server.');
				}
			});
		});
		
		j$('.amtchangebx').change(function(){
			var mycbx = j$(this);
			var myval = j$(mycbx).is(':checked') ? 1 : 0;
			var mynum = j$(mycbx).prop('id');
			
			j$.ajax({
				url: <cfoutput>'#CGI.SCRIPT_NAME#'</cfoutput>,
				data: {reason: 'turnonoff', enabled: myval, amountid: mynum},
				type: 'POST',
				success: function(response){
					if(j$.trim(response) == '1') {
						if(myval == 1) {
							alert('Commission successfully enabled.');
						} else {
							alert('Commission successfully disabled.');
						}
					} else {
						alert('There was an error saving the commission change.');
					}
				}, 
				failure: function(){
					alert('Contacting the server.');
				}
			});
		});
		
		j$('input[name="showdisabled"]').click(function(){
			var myval = j$('input:radio[name="showdisabled"]:checked').val();
			showhideenabled(myval);
		});
		
		showhideenabled('<cfoutput>#attributes.showdisabled#</cfoutput>');
		
	</cfif>
});

function donothing () {
	//return false;
}
</script>
<cfinclude template="/partnernet/shared/_footer.cfm">