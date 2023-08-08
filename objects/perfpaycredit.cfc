<cfcomponent displayname="Perf Pay Credit" hint="Apply average-based credits to gross profit calculations for consultant compensation" extends="alpine-objects.global" output="false">

	<cffunction name="getCreditSettings" returntype="query">
		<cfargument name="consultantID" type="numeric" required="true">
		<cfset var LOCAL ={}>
		<cfquery name="LOCAL.creditSettings" datasource="#DSN#">
			DECLARE @cID INT
			SET @cID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.consultantID#">
			SELECT types.typeID, ISNULL(concred.agpPct, types.defaultPct) AS 'agpPct', (SELECT TOP 1 agpDays FROM tblPerformanceSettings) AS 'agpDays'
			FROM tblPerformanceCreditTypes types WITH (NOLOCK)
			LEFT OUTER JOIN tblPerformanceConsultantCreditTypes concred ON concred.creditType=types.typeID AND concred.consultantID = @cID
		</cfquery>
		<cfreturn LOCAL.creditSettings>
	</cffunction>

	<cffunction name="getCreditPercentagesByCreditType" returntype="query">
		<cfargument name="typeID" type="numeric" required="true">
		<cfquery name="types" datasource="#DSN#">
			DECLARE @type INT
				SET @type = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.typeID#">
			DECLARE @default DECIMAL(8,4)
				SELECT @default = defaultPct FROM tblPerformanceCreditTypes WHERE typeID=@type

			SELECT su.FirstName + ' ' + su.LastName AS consultantName
				, su.ID
				, ISNULL(pcct.agpPct,@default)AS agpPct
				, @type AS typeID
			FROM tblSecurity_Users su WITH(NOLOCK)
			LEFT OUTER JOIN tblPerformanceConsultantCreditTypes pcct on pcct.consultantID=su.ID AND pcct.creditType=@type
			WHERE su.isactive=1 AND isconsultant=1
		</cfquery>
		<cfreturn types>
	</cffunction>

	<cffunction name="getCredits" returntype="query">
		<cfargument name="mindate" type="date" required="true">
		<cfargument name="maxdate" type="date" required="true">
		<cfargument name="consultantID" type="numeric" required="false" default=0>
		<cfset var LOCAL = {}>
		<cfquery name="LOCAL.credits" datasource="#DSN#">
			DECLARE @minDate DATE
			DECLARE @maxDate DATE
			SET @minDate = <cfqueryparam cfsqltype="cf_sql_date" value="#ARGUMENTS.mindate#">
			SET @maxDate = <cfqueryparam cfsqltype="cf_sql_date" value="#ARGUMENTS.maxdate#">

			SELECT * FROM tblPerformanceCredits
			WHERE CONVERT(DATE,validfor) BETWEEN @minDate AND @maxDate
			<cfif consultantID>
				AND consultantID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.consultantID#">
			</cfif>
		</cfquery>

		<cfreturn LOCAL.credits>
	</cffunction>

	<cffunction name="logCredit" returntype="boolean">
		<cfargument name="objID" type="string" required="true">
		<cfargument name="userID" type="Numeric" required="true">
		<cfargument name="logEntry" type="string" required="true">
		<cftry>
			<cfquery name="logging" datasource="#DSN#">
				DECLARE @now DATETIME
					SET @now = CURRENT_TIMESTAMP
				DECLARE @objID NVARCHAR(100)
					SET @objID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.objID#">
				DECLARE @userID INT
					SET @userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.userID#">
				DECLARE @logEntry VARCHAR(500)
					SET @logEntry = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.logEntry#">

				INSERT INTO tblObjectLog
				(objID, value, created, createdBy)
				VALUES
				(@objID, @logEntry, @now, @userID)

				UPDATE tblPerformanceCredits
				SET lastModified = @now
					, lastModifiedBy = @userID
				WHERE objID = @objID
			</cfquery>
			<cfcatch>
				<cfreturn false>
			</cfcatch>
		</cftry>
		<cfreturn true>
	</cffunction>

	<cffunction name="addCredit" returntype="boolean">
		<cfargument name="consultantID" required="true" type="numeric">
		<cfargument name="validfor" required="true" type="date">
		<cfargument name="creditType" required="true" type="numeric">
		<cfargument name="hours" required="true" type="numeric">
		<cfargument name="createdBy" required="true" type="numeric">
		<cfargument name="comment" required="false" type="string" default="">

		<cftry>
			<cfset var LOCAL = {}>
			<cfset LOCAL.objID = CreateUUID()>
			<cfset LOCAL.creditSettings = getCreditSettings(consultantID=ARGUMENTS.consultantID)>
			<cfquery name="LOCAL.creditSpecs" dbtype="query" maxrows="1">
				SELECT * FROM [LOCAL].creditSettings
				WHERE typeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.creditType#">
			</cfquery>

			<cfquery name="makeCredit" datasource="#DSN#">
				DECLARE @validFor DATE
					SET @validFor = <cfqueryparam cfsqltype="cf_sql_date" value="#ARGUMENTS.validfor#">
				DECLARE @type INT
					SET @type = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.creditType#">
				DECLARE @agpPct DECIMAL(8,4)
					SET @agpPct = <cfqueryparam cfsqltype="cf_sql_decimal" value="#LOCAL.creditSpecs.agpPct#" scale="4">
				DECLARE @hours DECIMAL(8,4)
					SET @hours = <cfqueryparam cfsqltype="cf_sql_decimal" value="#ARGUMENTS.hours#" scale="4">
				DECLARE @agpDays INT
					SET @agpDays = <cfqueryparam cfsqltype="cf_sql_integer" value="#LOCAL.creditSpecs.agpDays#">
				DECLARE @createdBy INT
					SET @createdBy = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.createdBy#">
				DECLARE @comment NVARCHAR(1000)
					SET @comment = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#ARGUMENTS.comment#" null="#(ARGUMENTS.comment EQ "")#">
				DECLARE @objID NVARCHAR(100)
					SET @objID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#LOCAL.objID#">
				DECLARE @consultantID INT
					SET @consultantID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.consultantID#">
				DECLARE @now DATE
					SET @now=CURRENT_TIMESTAMP

				DECLARE @amount MONEY
				SELECT @amount = ISNULL(dbo.getPerfCreditValue(CAST(@consultantID AS VARCHAR), @agpDays, @agpPct, @hours, @validFor), 0)
				INSERT INTO tblPerformanceCredits
				(created, validfor, type, agpPct	, hours, agpDays, addedBy, active, comment, objID, consultantID, lastmodified, lastmodifiedby, amt)
				VALUES(@now, @validFor, @type, @agpPct, @hours, @agpDays, @createdBy, 1, @comment, @objID, @consultantID, @now, @createdBy, @amount)

					<!--- --Automatically fix later credits if a crtedit is added out of order --->
				DECLARE @tmpObjIDs TABLE(oID nvarchar(200))
				INSERT INTO @tmpObjIDs
				SELECT objID FROM tblPerformanceCredits WHERE CONVERT(DATE,validfor) BETWEEN @validFor AND DATEADD(DAY, agpDays, @validFor) AND consultantID = @consultantID AND active=1

				IF @@ROWCOUNT > 0
				BEGIN
					UPDATE tblPerformanceCredits
					SET amt = dbo.getPerfCreditValue( CAST(consultantID AS VARCHAR), agpDays, agpPct, hours, validfor)
					WHERE objID IN (SELECT oID FROM @tmpObjIDs)
				END
			</cfquery>
			<cfset LOCAL.logSuccess = logCredit(LOCAL.objID, ARGUMENTS.createdBy, 'Credit Created')>
			<cfcatch><cfreturn false></cfcatch>
		</cftry>
		<cfreturn true>
	</cffunction>

	<cffunction name="editCredit" returntype="any">
		<cfargument name="objID" type="string" required="true">
		<cfargument name="comment" type="string" required="true">
		<!--- <cfargument name="validfor" required="true" type="date">
		<cfargument name="creditType" required="true" type="numeric"> --->
		<cfargument name="hours" required="true" type="numeric">
		<cfargument name="active" required="false" type="boolean" default="true">
		<cfargument name="changedBy" required="true" type="numeric">
		<cfargument name="pct" required="true" type="numeric">
		<cfargument name="days" required="true" type="numeric">
		<cftry>
			<cfset var LOCAL = {}>
			<cfquery name="LOCAL.currentDetails" datasource="#DSN#">
				SELECT * FROM tblPerformanceCredits WHERE objID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.objID#">
			</cfquery>
			<cfset LOCAL.logValue = "Credit altered. Old values: Hours: #LOCAL.currentDetails.hours# Value: #LOCAL.currentDetails.amt# Comment: #LOCAL.currentDetails.comment# Days: #LOCAL.currentDetails.agpDays# PCT:#LOCAL.currentDetails.agpPct#">
			<cfset LOCAL.logSuccess = logCredit(ARGUMENTS.objID, ARGUMENTS.changedBy, LOCAL.logValue)>
			<cfquery name="LOCAL.updateCredit" datasource="#DSN#">
				DECLARE @objID NVARCHAR(100)
					SET @objID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.objID#">
				DECLARE @comment NVARCHAR(1000)
					SET @comment = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#ARGUMENTS.comment#">
				<!--- DECLARE @validFor DATE
					SET @validfor = <cfqueryparam cfsqltype="cf_sql_date" value="#ARGUMENTS.validFor#">
				DECLARE @creditType INT
					SET @creditType = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.creditType#"> --->
				DECLARE @hours DECIMAL(8,4)
					SET @hours = <cfqueryparam cfsqltype="cf_sql_decimal" value="#ARGUMENTS.hours#" scale="4">
				DECLARE @active BIT
					SET @active = <cfqueryparam cfsqltype="cf_sql_bit" value="#ARGUMENTS.active#">
				DECLARE @lastModifiedBy INT
					SET @lastModifiedBy = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.changedBy#">
				DECLARE @pct DECIMAL(8,4)
					SET @pct = <cfqueryparam cfsqltype="cf_sql_decimal" value="#ARGUMENTS.pct#" scale=4>
				DECLARE @days INT
					SET @days = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.days#">
				DECLARE @now DATETIME
					SET @now = CURRENT_TIMESTAMP
				DECLARE @created DATE
					SELECT @created = created FROM tblPerformanceCredits WHERE objID = @objID

				DECLARE @consultantID INT
				SELECT @consultantID = consultantID FROM tblPerformanceCredits WHERE objID = @objID

				DECLARE @validFor date
				SELECT @validFor = validFor FROM tblPerformanceCredits WHERE objID = @objID

				--Get new credit value
				DECLARE @amount MONEY
				SELECT @amount = ISNULL(dbo.getPerfCreditValue(CAST(@consultantID AS VARCHAR), @days, @pct, @hours, @validFor), 0)

				UPDATE tblPerformanceCredits
					SET comment = @comment
						<!--- , validfor = @validFor
						, creditType = @creditType --->
						, hours = @hours
						, agpPct = @pct
						, agpDays = @days
						, active = @active
						, lastModifiedBy = @lastModifiedBy
						, lastModified = @now
						, amt = @amount
				WHERE objID = @objID

				--Update later credits if necessary
				DECLARE @tempValid DATE
				SELECT @tempValid = validFor FROM tblPerformanceCredits WHERE objID = @objID

				DECLARE @tmpObjIDs TABLE(oID nvarchar(200))
				INSERT INTO @tmpObjIDs
				SELECT objID FROM tblPerformanceCredits WHERE CONVERT(DATE,validfor) BETWEEN @tempValid AND DATEADD(DAY, agpDays, @tempValid) AND consultantID = @consultantID AND active=1

				IF @@ROWCOUNT > 0
				BEGIN
					UPDATE tblPerformanceCredits
					SET amt = dbo.getPerfCreditValue( CAST(consultantID AS VARCHAR), agpDays, agpPct, hours, validFor)
					, comment = 'edited'
					WHERE objID IN (SELECT oID FROM @tmpObjIDs)
				END

			</cfquery>
			<cfcatch><cfreturn cfcatch.queryerror></cfcatch>
		</cftry>
		<cfreturn true>
	</cffunction>

	<cffunction name="voidCredit" returntype="boolean">
		<cfargument name="objID" type="string" required="true">
		<cfargument name="changedBy" type="numeric" required="true">
		<cfset var LOCAL = {}>
		<cftry>
			<cfquery name="LOCAL.voidCred" datasource="#DSN#">
				DECLARE @objID NVARCHAR(100)
				SET @objID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.objID#">

				UPDATE tblPerformanceCredits
				SET active=0
				WHERE objID = @objID

				DECLARE @consultantID INT
				SELECT @consultantID = consultantID FROM tblPerformanceCredits WHERE objID = @objID

				--Update later credits if necessary
				DECLARE @tempValid DATE
				SELECT @tempValid = validFor FROM tblPerformanceCredits WHERE objID = @objID

				DECLARE @tmpObjIDs TABLE(oID nvarchar(200))
				INSERT INTO @tmpObjIDs
				SELECT objID FROM tblPerformanceCredits WHERE CONVERT(DATE,validfor) BETWEEN @tempValid AND DATEADD(DAY, agpDays, @tempValid) AND consultantID = @consultantID AND active=1

				IF @@ROWCOUNT > 0
				BEGIN
					UPDATE tblPerformanceCredits
					SET amt = dbo.getPerfCreditValue( CAST(consultantID AS VARCHAR), agpDays, agpPct, hours, validfor)
					WHERE objID IN (SELECT oID FROM @tmpObjIDs)
				END

			</cfquery>
			<cfset LOCAL.logSuccess = logCredit(ARGUMENTS.objID, ARGUMENTS.changedBy,'Performance Credit has been voided')>
			<cfcatch><cfreturn false></cfcatch>
		</cftry>
		<cfreturn true>
	</cffunction>

	<cffunction name="ajax_voidCredit" returntype="string" access="remote">
		<cfargument name="voidRequest" type="string" required="true">
		<cfset var LOCAL = {}>
		<cfset LOCAL.responseObj = {}>
		<cfset LOCAL.responseObj.status = 'Failure'>
		<cftry>
			<cfif NOT isJSON(ARGUMENTS.voidRequest)>
				<cfset LOCAL.responseObj.detail = 'Malformed JSON:#ARGUMENTS.voidRequest#'>
				<cfreturn Serializejson(LOCAL.responseObj)>
			</cfif>
			<cfset LOCAL.requestObj = Deserializejson(ARGUMENTS.voidRequest)>
			<cfcatch>
				<cfset LOCAL.responseObj.detail = cfcatch.message>
				<cfreturn Serializejson(LOCAL.responseObj)>
			</cfcatch>
		</cftry>
		<cfif voidCredit(LOCAL.requestObj.objID, LOCAL.requestObj.changedBy)>
			<cfset LOCAL.responseObj.status='Success'>
			<cfset LOCAL.responseObj.detail='Performance credit #LOCAL.requestObj.objID# has been voided.'>
			<cfelse>
				<cfset LOCAL.responseObj.detail='An Error has occurred'>
		</cfif>
		<cfreturn Serializejson(LOCAL.responseObj)>
	</cffunction>

	<cffunction name="ajax_addCredit" returntype="string" access="remote">
		<cfargument name="addRequest" type="string" required="true">
		<cfset var LOCAL = {}>
		<cfset LOCAL.responseObj = {}>
		<cfset LOCAL.responseObj.status='Failure'>
		<cfset LOCAL.responseObj.detail="">
		<cfif NOT isJSON(ARGUMENTS.addRequest)>
			<cfset LOCAL.responseObj.detail="Malformed JSON">
			<cfreturn Serializejson(LOCAL.responseObj)>
		</cfif>
		<cftry>
			<cfset LOCAL.requestObj = Deserializejson(ARGUMENTS.addRequest)>
			<cfif addCredit(argumentCollection = LOCAL.requestObj)>
				<cfset LOCAL.responseObj.status='Success'>
				<cfelse>
					<cfset LOCAL.responseObj.detail ="An error has occured.">
			</cfif>
			<cfcatch>
				<cfset LOCAL.responseObj.detail = cfcatch.message>
			</cfcatch>
		</cftry>
		<cfreturn SerializeJSON(LOCAL.responseObj)>
	</cffunction>

	<cffunction name="ajax_editCredit" returntype="string" access="remote">
		<cfargument name="editRequest" type="string" required="true">
		<cfset var LOCAL = {}>
		<cfset LOCAL.responseObj = {}>
		<cfset LOCAL.responseObj.status='Failure'>
		<cfset LOCAL.responseObj.detail="">
		<cfif NOT isJSON(ARGUMENTS.editRequest)>
			<cfset LOCAL.responseObj.detail="Malformed JSON">
			<cfreturn Serializejson(LOCAL.responseObj)>
		</cfif>
		<cftry>
			<cfset LOCAL.requestObj = DeserializeJSON(ARGUMENTS.editRequest)>
			<cfif editCredit(argumentCollection = LOCAL.requestObj)>
				<cfset LOCAL.responseObj.status='Success'>
				<cfelse>
					<cfset LOCAL.responseObj.detail ="An Error has ocurred.">
			</cfif>
			<cfcatch>
				<cfset LOCAL.responseObj.detail = cfcatch.message>
			</cfcatch>
		</cftry>
		<cfreturn SerializeJSON(LOCAL.responseObj)>
	</cffunction>

	<cffunction name="getConsultantCreditTable" returntype="String">
		<cfargument name="consultantID" type="numeric">
		<cfargument name="minDate" type="date">
		<cfargument name="maxDate" type="date">
		<cfargument name="tableID" required="false" default="table">
		<cfargument name="admin" required="false" default="0">
		<cfset var LOCAL = {}>
		<cfquery name="LOCAL.consultantCreditTable" datasource="#DSN#">
			DECLARE @consultantID INT
				SET @consultantID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.consultantID#">
			DECLARE @minDate DATE
				SET @minDate = <cfqueryparam cfsqltype="cf_sql_date" value="#ARGUMENTS.minDate#">
			DECLARE @maxDate DATE
				SET @maxDate = <cfqueryparam cfsqltype="cf_sql_date" value="#ARGUMENTS.maxDate#">

			SELECT pc.*, ISNULL(su.FirstName, 'System') + ' ' + ISNULL(su.LastName, '') AS addedByName, pct.typeName
			FROM tblPerformanceCredits pc WITH(NOLOCK)
			LEFT OUTER JOIN tblSecurity_Users su ON su.ID = pc.addedBy
			INNER JOIN tblPerformanceCreditTypes pct ON pct.typeID = pc.type
			WHERE pc.consultantID = @consultantID AND CONVERT(DATE,pc.validFor) BETWEEN @minDate AND @maxDate
		</cfquery>
		<cfsavecontent variable="LOCAL.table">
			<cfif LOCAL.consultantCreditTable.RecordCount GT 0>
				<table id=<cfoutput>"#ARGUMENTS.tableID#"</cfoutput> class="consultant-summary">
					<thead>
						<tr>
							<th>Date</th>
							<th>Type</th>
							<th>Adjusted GP %</th>
							<th>Hours</th>
							<th>AGP Days</th>
							<th>Added By</th>
							<th>Credit Status</th>
							<th>Credit Amt ($)</th>
							<th>Comments</th>
						</tr>
					</thead>
					<tbody>
						<cfoutput query="LOCAL.consultantCreditTable">
							<tr class="mo"<cfif ARGUMENTS.admin AND Active> onclick="confirmation('#objID#', #agpDays#, #agpPct#, #hours#, '#comment#');" title="Click To Edit"<cfelseif NOT ARGUMENTS.admin> title="Click To View Log" onclick="showCreditLog('#objID#');"</cfif> style="cursor:pointer;">
								<td>#DateFormat(ValidFor, "mm/dd/yyyy")#</td>
								<td>#typeName#</td>
								<td>#agpPct#</td>
								<td>#hours#</td>
								<td>#agpDays#</td>
								<td>#addedByName#</td>
								<td>#(active) ? "Active" : "Void"#</td>
								<td>#NumberFormat(Amt, "$.99")#</td>
								<td>#comment#&nbsp;</td>
							</tr>
						</cfoutput>
					</tbody>
				</table>
			<cfelse>
				<p id=<cfoutput>"#ARGUMENTS.tableID#"</cfoutput> class="no-records">No credits found for this consultant within the timeframe.</p>
			</cfif>
		</cfsavecontent>
		<cfreturn Trim(LOCAL.table)>
	</cffunction>

	<cffunction name="ajax_editCreditSettings" returntype="string" access="remote">
		<cfargument name="editRequest" type="string" required="true">

		<cfset var LOCAL = {}>
		<cfset LOCAL.responseObj = {}>
		<cfset LOCAL.responseObj.status="Failure">
		<cfset LOCAL.responseObj.detail="">
		<cftry>
			<cfif IsJSON(ARGUMENTS.editRequest)>
				<cfset LOCAL.requestObj = Deserializejson(ARGUMENTS.editRequest)>
				<cfquery name="LOCAL.updateCreditSettings" datasource="#DSN#">
					UPDATE tblPerformanceSettings
					SET agpDays = <cfqueryparam cfsqltype="cf_sql_integer" value="#LOCAL.requestObj.days#">
				</cfquery>
				<cfloop array="#LOCAL.requestObj.types#" index="LOCAL.creditType">
					<cfquery name="LOCAL.check" datasource="#DSN#">
						SELECT * FROM tblPerformanceConsultantCreditTypes
						WHERE consultantID = <cfqueryparam cfsqltype="cf_sql_integer" value="#LOCAL.creditType.consultant#">
						AND creditType = <cfqueryparam cfsqltype="cf_sql_integer" value="#LOCAL.creditType.type#">
					</cfquery>
					<cfquery name="LOCAL.updateCreditTypes" datasource="#DSN#">
						DECLARE @consultantID INT
							SET @consultantID = <cfqueryparam cfsqltype="cf_sql_integer" value="#LOCAL.creditType.consultant#">
						DECLARE @typeID INT
							SET @typeID =<cfqueryparam cfsqltype="cf_sql_integer" value="#LOCAL.creditType.type#">
						DECLARE @percent DECIMAL(8,4)
							SET @percent = <cfqueryparam cfsqltype="cf_sql_decimal" value="#LOCAL.creditType.value#">
						<cfif LOCAL.check.RecordCount>
							UPDATE tblPerformanceConsultantCreditTypes
							SET agpPct = @percent
							WHERE creditType = @typeID AND consultantID = @consultantID
							<cfelse>
								INSERT INTO tblPerformanceConsultantCreditTypes
								(consultantID,agpPct,creditType)
								VALUES(@consultantID, @percent, @typeID)
						</cfif>
					</cfquery>
				</cfloop>
				<cfset LOCAL.responseObj.status="Success">
				<cfelse>
					<cfset LOCAL.responseObj.detail="Malformed JSON">
			</cfif>
			<cfcatch>
				<cfset LOCAL.responseObj.detail = cfcatch.message>
				<cfset LOCAL.responseObj.status="Failure">
			</cfcatch>
		</cftry>
		<cfreturn SerializeJSON(LOCAL.responseObj)>
	</cffunction>

	<cffunction name="ajax_creditLogTable" returntype="string" access="remote">
		<cfargument name="creditID" type="string" required="true">

		<cfquery name="getCreditLog" datasource="#DSN#">
			SELECT ol.created, ol.value, ISNULL(su.FirstName, '') + ' ' + ISNULL(su.LastName, 'System') as createdBy
			FROM tblObjectLog ol WITH (NOLOCK)
			LEFT OUTER JOIN tblSecurity_Users su on su.ID = ol.createdBy_int
			where ol.objID = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#ARGUMENTS.creditID#">
		</cfquery>
		<cfsavecontent variable="table">
			<cfif getCreditLog.RecordCount>
			<table class="consultant-summary">
				<thead>
					<tr>
						<th>Date</th>
						<th>User</th>
						<th>Log Message</th>
					</tr>
				</thead>
				<tbody>
					<cfoutput query="getCreditLog">
						<tr>
							<td>#DateFormat(created, 'mm/dd/yyyy')#</td>
							<td>#createdBy#</td>
							<td>#value#</td>
						</tr>
					</cfoutput>
				</tbody>
			</table>
			<cfelse>
			<table>
				<thead>
					<tr><th>There are no log entries associated with this credit.</th></tr>
				</thead>
			</table>
			</cfif>
		</cfsavecontent>
		<cfreturn Trim(table)>
	</cffunction>

	<cffunction access="remote" name="getPotPrc" returntype="any" returnformat="plain">
		<cfargument name="returnType" type="STRING" required=false default="json" />
		<cfargument name="minDate" type="DATE" required=true />
		<cfargument name="maxDate" type="DATE" required=true />
		<cfargument name="poolSize" type="NUMERIC" required=false default=0.0 />
		<cfargument name="excludeUsers" type="STRING" required=false default="" />

		<cfstoredproc procedure="calcPerfPay" datasource="ahapdb">
			<cfprocparam type="IN" sqltype="DATE" value="#ARGUMENTS.minDate#">
			<cfprocparam type="IN" sqltype="DATE" value="#ARGUMENTS.maxDate#">
			<cfprocparam type="IN" sqltype="INT" value="#ARGUMENTS.poolSize#">
			<cfprocparam type="IN" sqltype="VARCHAR" value="#ARGUMENTS.excludeUsers#">
			<cfprocresult name="getRankingChart">
		</cfstoredproc>

		<cfif arguments.returnType NEQ 'query' && isEmpty(getRankingChart)>
			<cfheader statuscode="400">
			<cfreturn "There was an error retrieving the data">
		</cfif>

		<cfif arguments.returnType EQ 'json'>
			<cfreturn SerializeJSON(getRankingChart) />
		</cfif>
		<cfif arguments.returnType EQ 'array'>
			<cfreturn SerializeJSON(queryToArray(getRankingChart))>
		</cfif>
		<cfif arguments.returnType EQ 'struct'>
			<cfreturn queryExecute('SELECT * FROM getRankingChart', {}, { dbType: 'query', returnType: 'struct', columnKey: 'userID' })>
		</cfif>
		<cfreturn getRankingChart />

	</cffunction>

</cfcomponent>
