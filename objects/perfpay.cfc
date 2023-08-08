<cfcomponent displayname="performancepay">
	
	<cffunction name="CalculatePerfPay" returntype="void">
	<cfargument name="orderID" type="string" required="true">
		<cftransaction>
			<cftry>
				<cfstoredproc procedure="performancepay_getinfo" datasource="ahapdb-reports">
					<cfprocparam type="IN" sqltype="VARCHAR" value="#arguments.orderID#">
					<cfprocresult name="local.getqsinfo">
				</cfstoredproc>

				<cfif local.getqsinfo.recordcount>

					<cfstoredproc procedure="tel_usertimebyorderID" datasource="ahapdb-reports">
						<cfprocparam type="IN" sqltype="VARCHAR" value="#arguments.orderID#">
						<cfprocparam type="IN" sqltype="VARCHAR" value="Telephone">
						<cfprocparam type="IN" sqltype="VARCHAR" value="before">
						<cfprocresult name="local.getcallsa">
					</cfstoredproc>

					<cfset var pp = QueryNew("description,orderlineID,GSD,userID", "VARCHAR,INTEGER,DECIMAL,VARCHAR")>

					<cfquery datasource="ahapdb">
						DELETE FROM tblOrderPerformancePay
						WHERE locked = 0
							AND orderlineID IN (<cfqueryparam sqltype="VARCHAR" value="#ValueList(local.getqsinfo.ID,",")#" list="true">)
					</cfquery>

					<!--- for each line returned, break into pieces --->
					<cfloop query="local.getqsinfo">
						<!--- Use to denote copied orders, if necessary --->
						<cfset var tGSD = max(local.getqsinfo.mfrRebate + local.getqsinfo.gsd,0)>

						<cfset local.getqsinfo['gsd'][local.getqsinfo.currentRow] = tGSD>

						<cfif NOT local.getqsinfo.copied>
							<!--- if quoted by user --->
							<cfif len(trim(local.getqsinfo.quotedby))>
								<cfif local.getqsinfo.quotedto NEQ "system@alpinehomeair.com">
									<cfset var quotegsd = local.getqsinfo.gsd  * 0.30>
									<cfset QueryAddRow(pp)>
									<cfset QuerySetCell(pp,"orderlineID",local.getqsinfo.ID)>
									<cfset QuerySetCell(pp,"description","30% GSD for emailed quote (#local.getqsinfo.origquote#)")>
									<cfset QuerySetCell(pp,"GSD",val(quotegsd))>
									<cfset QuerySetCell(pp,"userID",local.getqsinfo.quotedby)>
								<cfelse>
									<cfset var quotegsd = local.getqsinfo.gsd  * 0.10>
									<cfset QueryAddRow(pp)>
									<cfset QuerySetCell(pp,"orderlineID",local.getqsinfo.ID)>
									<cfset QuerySetCell(pp,"description","10% GSD for tagged quote (#local.getqsinfo.origquote#)")>
									<cfset QuerySetCell(pp,"GSD",val(quotegsd))>
									<cfset QuerySetCell(pp,"userID",local.getqsinfo.quotedby)>
								</cfif>

								<!--- allocate 20% to sale closer or 0% to customer if payMethod is Amazon / Paypal / Affirm / Bread--->
								<cfif listFindNoCase("AMA,PAY,AFF,BRE", local.getqsinfo.payMethod) AND NOT val(local.getqsinfo.orderuser)>
									<cfset var salegsd = 0 />
									<cfset var description = '0% GSD to customer (AMAZON / PAYPAL / AFFIRM / BREAD pay method)'>
								<cfelse>
									<cfset var salegsd = local.getqsinfo.gsd * 0.20>
									<cfset var description = '20% GSD to sale closer for sale with quote'>
								</cfif>
								<cfset QueryAddRow(pp)>
								<cfset QuerySetCell(pp,"orderlineID",local.getqsinfo.ID)>
								<cfset QuerySetCell(pp,"description",description)>
								<cfset QuerySetCell(pp,"GSD",val(salegsd))>
								<cfset QuerySetCell(pp,"userID",local.getqsinfo.orderuser)>
							<cfelse>
								<!--- no quote, so allocate 50% to sale closer --->
								<cfset var quotegsd = 0>

								<cfset QueryAddRow(pp)>
								<cfset var salegsd = local.getqsinfo.gsd * 0.50>
								<cfset QuerySetCell(pp,"orderlineID",local.getqsinfo.ID)>
								<cfset QuerySetCell(pp,"description","50% GSD to sale closer for sale without quote")>
								<cfset QuerySetCell(pp,"GSD",val(salegsd))>
								<cfset QuerySetCell(pp,"userID",local.getqsinfo.orderuser)>

							</cfif>

							<cfif local.getcallsa.recordcount>
								<!--- allocate first caller --->
								<cfset QueryAddRow(pp)>
								<cfset var callgsd = local.getqsinfo.gsd * 0.15>
								<cfset QuerySetCell(pp,"orderlineID",local.getqsinfo.ID)>
								<cfset QuerySetCell(pp,"description","15% GSD to first phone consultant x#local.getcallsa.userID#")>
								<cfset QuerySetCell(pp,"GSD",val(callgsd))>
								<cfset QuerySetCell(pp,"userID",local.getcallsa.userID)>
							<cfelse>
								<cfset var callgsd = 0>
							</cfif>

							<!--- for each person quote talked with him on the phone, allocated GSD --->
							<cfset var totalgsd = local.getqsinfo.gsd - salegsd - quotegsd - callgsd>

							<cfset var currentorderlineID = local.getqsinfo.ID>

							<cfif local.getcallsa.recordcount>
								<cfloop query="local.getcallsa">
									<cfif totalgsd*local.getcallsa.prctofbeforeorafterminutes GT 0>
										<cfset QueryAddRow(pp)>
										<cfset QuerySetCell(pp,"orderlineID",currentorderlineID)>
										<cfset QuerySetCell(pp,"description","#Round(local.getcallsa.prctofbeforeorafterminutes*100)#% of #Dollarformat(totalgsd)# for pre-sale call at userID #local.getcallsa.userID#")>
										<cfset QuerySetCell(pp,"GSD",totalgsd*local.getcallsa.prctofbeforeorafterminutes)>
										<cfset QuerySetCell(pp,"userID",local.getcallsa.userID)>
									</cfif>
								</cfloop>
							<cfelse>
								<cfset QueryAddRow(pp)>
								<cfset QuerySetCell(pp,"orderlineID",currentorderlineID)>
								<cfset QuerySetCell(pp,"description","No call from customer")>
								<cfset QuerySetCell(pp,"GSD",totalgsd)>
								<cfset QuerySetCell(pp,"userID","customer")>
							</cfif>
						<cfelse>
							<cfset QueryAddRow(pp)>
							<cfset var salegsd = local.getqsinfo.gsd * 0.10>
							<cfset QuerySetCell(pp,"orderlineID",local.getqsinfo.ID)>
							<cfset QuerySetCell(pp,"description","10% GSD to sale closer for copied items.")>
							<cfset QuerySetCell(pp,"GSD",val(salegsd))>
							<cfset QuerySetCell(pp,"userID",local.getqsinfo.orderuser)>
						</cfif>
					</cfloop>

					<cfif pp.recordcount>
						<cfloop query = "pp">
							<cfquery name="insertpp" datasource="ahapdb" >
								SELECT *
								FROM tblOrderPerformancePay WITH (NOLOCK)
								WHERE locked = 1
									AND orderlineID = <cfqueryparam sqltype="VARCHAR" value='#pp.orderlineID#'>

								IF @@ROWCOUNT = 0
									INSERT INTO tblOrderPerformancePay
										(description,orderlineID,gsd,userID,datetoapply)
									VALUES
										(<cfqueryparam sqltype="VARCHAR" value='#pp.description#'>
										,<cfqueryparam sqltype="VARCHAR" value='#pp.orderlineID#'>
										,<cfqueryparam sqltype="MONEY" value="#val(pp.gsd)#">
										,<cfqueryparam sqltype="VARCHAR" value='#pp.userID#'>
										,<cfqueryparam sqltype="TIMESTAMP" value="#CreateODBCDateTime(local.getqsinfo.checkoutsdt)#">)
							</cfquery>
						</cfloop>
					</cfif>
				</cfif> <!--- no order lines returned for this order, it's a no cost order --->

				<cfcatch>
					<cftransaction action="rollback" />
					<cfmail from="errors@alpinehomeair.com" to="technical@alpinehomeair.com" subject="Error creating performance pay ledger">
						There was an error creating the performance pay ledger - order #arguments.orderID#

						#cfcatch.Detail#
						#cfcatch.message#
					</cfmail>
				</cfcatch>
			</cftry>
		</cftransaction>
	</cffunction>

	<cffunction name="InsertPerformanceMetrics" returntype="void">
	<cfargument name="minDate" type="date" default="#dateFormat(dateAdd('d',-7,now()),'yyyy-mm-dd')#">
	<cfargument name="maxDate" type="date" default="#dateFormat(now(),'yyyy-mm-dd')#">
	<cfargument name="minThreshold" type="numeric" default="0.20">
		<cfset var potPayoutValues = getPotPayoutValues(argumentCollection = arguments)>

		<cfquery name="insertpayout"  datasource="ahapdb">
			DECLARE @maxDate DATETIME = <cfqueryparam sqltype="DATE" value="#arguments.maxdate#">

			DELETE FROM tblOrderPerformanceMetrics
			WHERE DT = @maxDate

			INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
			VALUES (@maxDate,'30-Day Rolling Period GSD','',<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.periodGSD)#'>,1)

			INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
			VALUES (@maxDate,'30-Day Rolling Period GSD Per Hour','',<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.totalPeriodGSDPerHour)#'>,1)
		</cfquery>

		<cfloop query="potPayoutValues">
			<cfquery name="insertpayout"  datasource="ahapdb">
				DECLARE @userID VARCHAR(50) = <cfqueryparam sqltype="VARCHAR" value='#potPayoutValues.userID#'>
				DECLARE @maxDate DATETIME = <cfqueryparam sqltype="DATE" value="#arguments.maxdate#">

				INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
				VALUES (@maxDate,'Top 30 Survey Response Raw Score',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.rawsurveyscore)#'>,1)

				INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
				VALUES (@maxDate,'Top 30 Survey Response Ranked Score',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.rankedsurveyscore)#'>,1)

				INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
				VALUES (@maxDate,'30-Day Rolling GSD',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.userGSD)#'>,1)

				INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
				VALUES (@maxDate,'30-Day Rolling Percent of GSD',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.prctofGSD)#'>,1)

				INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
				VALUES (@maxDate,'30-Day Rolling GSD Per Hour',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.GSDperHour)#'>,1)

				<cfif potPayoutValues.incalc>
					INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
					VALUES (@maxDate,'30-Day Rolling GSD Per Hour Percent Contribution',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.totalPeriodGSDperhourprctContribution)#'>,1)

					INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
					VALUES (@maxDate,'30-Day Rolling Percent of Pot Payout',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.rankedscore)#'>,1)

					INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
					VALUES (@maxDate,'30-Day Rolling GSD Ranking',@userID,<cfqueryparam sqltype="VARCHAR" value='#val(potPayoutValues.prctofpot)#'>,1)

				<cfelse>
					-- <!--- this code grabs the oldest usable value --->
					INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
						SELECT TOP 1 @maxDate, metric, userid, metricvalue, 0
						FROM tblOrderPerformanceMetrics
						WHERE metric = '30-Day Rolling GSD Per Hour Percent Contribution'
							AND userID = @userID
						ORDER BY dt DESC

					INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
						SELECT TOP 1 @maxDate, metric, userid, metricvalue, 0
						FROM tblOrderPerformanceMetrics
						WHERE metric = '30-Day Rolling Percent of Pot Payout'
							AND userID = @userID
						ORDER BY dt DESC

					INSERT INTO tblOrderPerformanceMetrics (dt,metric,userid,metricvalue,goodvalue)
						SELECT TOP 1 @maxDate, metric, userid, metricvalue, 0
						FROM tblOrderPerformanceMetrics
						WHERE metric = '30-Day Rolling GSD Ranking'
							AND userID = @userID
						ORDER BY dt DESC
				</cfif>
			</cfquery>
		</cfloop>

	</cffunction>

	<cffunction name="getPotPayoutValues" returntype="query" access="private">
	<cfargument name="minDate" type="date" required="true">
	<cfargument name="maxDate" type="date" required="true">
	<cfargument name="minThreshold" type="numeric" required="true">

		<cfquery name="local.payoutValues" datasource="ahapdb-reports">
			DECLARE @mindate DATE = <cfqueryparam sqltype="DATE" value='#arguments.minDate#'>
			DECLARE @maxdate DATE = <cfqueryparam sqltype="DATE" value='#arguments.maxDate#'>
			DECLARE @minpct NUMERIC(18,2) = <cfqueryparam sqltype="FLOAT" value="#arguments.minThreshold#">

			DECLARE @tmp1 TABLE (userID VARCHAR(50),GSD NUMERIC(18,2),phonehours NUMERIC(18,2),GSDperhour NUMERIC(18,2))

			INSERT INTO @tmp1
				SELECT u.ID
					, GSD.GSD
					, ROUND(phonehours.prepurchase,2)
					, ROUND(GSD.GSD / phonehours.prepurchase,2)
				FROM tblSecurity_Users u
				INNER JOIN (SELECT SUM(opp.GSD) AS 'GSD', opp.userID
							 FROM tblOrderPerformancePay opp 
							 WHERE CONVERT(DATE,opp.datetoapply) BETWEEN @mindate 
								AND @maxdate AND ISNUMERIC(opp.userID) = 1
							 GROUP BY opp.userID) GSD ON u.ID = GSD.userID
				CROSS APPLY (
						SELECT ((
							SELECT SUM(tr.minutes) totalminutes
							FROM tblTelephoneRecords tr
							WHERE CONVERT(DATE,tr.calldate) BETWEEN @mindate AND @maxdate
								AND CONVERT(VARCHAR(25),tr.userID) = u.agentID
								AND NOT EXISTS (SELECT TOP 1 1 FROM tblTelephoneRecordsExcludes WHERE callerID = tr.custcallerID)
								AND NOT EXISTS (SELECT TOP 1 1
												FROM CustomerTelephoneNumbers 
												WHERE tr.custcallerID IN (telephone_number,'1'+telephone_number))
						) + (
							SELECT SUM(tr.minutes) totalminutes
							FROM Checkouts c
							INNER JOIN CustomerOrders co ON co.OrderID = c.SessionID
							INNER JOIN CustomerTelephoneLink ctl ON ctl.CustomerContactID = co.CustomerContactID
							INNER JOIN CustomerTelephoneNumbers ctn ON ctn.telephone_number_id = ctl.TelephoneID
							INNER JOIN tblTelephoneRecords tr ON CONVERT(DATE,tr.calldate) BETWEEN @mindate AND @maxdate
									AND tr.calldate < c.dt
									AND CONVERT(VARCHAR(25),tr.userID) = u.agentID
									AND tr.custcallerID NOT IN (SELECT callerID FROM tblTelephoneRecordsExcludes)
									AND tr.custcallerID IN (ctn.telephone_number,'1'+ctn.telephone_number)
							WHERE CONVERT(DATE,c.DT) BETWEEN @mindate AND @maxdate
						)) / 60 AS 'prepurchase'
					) phonehours
				ORDER BY u.ID
				OPTION (FORCE ORDER)

			-- <!--- then we remove those records with pre-purchasephonehours less than the minimum threshold --->
			DECLARE @tmp TABLE (userID VARCHAR(50),GSD NUMERIC(18,2),phonehours NUMERIC(18,2),GSDperhour NUMERIC(18,2),incalc BIT)

			INSERT INTO @tmp
				SELECT userID,GSD,phonehours,GSDperhour,CASE WHEN phonehours >= (SELECT MAX(phonehours) FROM @tmp1) * @minpct THEN 1 ELSE 0 END
				FROM @tmp1

			DECLARE @gsdh TABLE
						(userID VARCHAR(50)
						,userGSD NUMERIC(18,2)
						,prctofGSD NUMERIC(18,2)
						,periodGSD NUMERIC(18,2)
						,GSDperhour NUMERIC(18,2)
						,totalPeriodGSDPerHour NUMERIC(18,2)
						,totalPeriodGSDperhourprctContribution NUMERIC(18,2)
						,potpayoutat2prctofperiodGSD NUMERIC(18,2)
						,incalc BIT)

			INSERT INTO @gsdh
				SELECT userID
					,ROUND(SUM(GSD),2) AS userGSD
					,ROUND(SUM(GSD) / (SELECT SUM(GSD) FROM @tmp WHERE incalc=1),2) AS prctofGSD
					,ROUND((SELECT SUM(GSD) FROM @tmp WHERE incalc=1),2) AS periodGSD
					,ROUND(SUM(GSDperhour),2) AS GSDperHour
					,ROUND((SELECT SUM(GSDperhour) FROM @tmp WHERE incalc=1),2) AS totalPeriodGSDPerHour
					,ROUND(SUM(GSDperhour) / (SELECT SUM(GSDperhour) FROM @tmp WHERE incalc=1),2) AS totalPeriodGSDperhourprctContribution
					,ROUND(SUM(GSDperhour) / (SELECT SUM(GSDperhour) FROM @tmp WHERE incalc=1) * (SELECT SUM(GSD) FROM @tmp WHERE incalc=1) * .02,2) AS 'potpayoutat2prctofperiodGSD'
					,incalc
				FROM @tmp b
				GROUP BY userID,incalc

			DECLARE @maxGSDH numeric(18,2)
			SELECT @maxGSDH=MAX(totalPeriodGSDperhourprctContribution)
			FROM @gsdh
			WHERE incalc=1

			-- <!---  BEGIN SURVEY --->
			DECLARE @stmp TABLE (userID INT,sessionID VARCHAR(50),score FLOAT)

			INSERT INTO @stmp
				SELECT userID,quoteID,CONVERT(FLOAT,likelihoodofbuying)
				FROM tblCustomerServiceSurveys a WITH (NOLOCK)
				WHERE surveytype='postquote'
					AND created > DATEADD(m,-3,GETDATE())
					AND ID IN (SELECT TOP 20 ID FROM tblCustomerServiceSurveys WITH (NOLOCK) WHERE userID = a.userID AND surveytype='postquote' ORDER BY created DESC)
					AND q4 > 0
				GROUP BY userID,orderID,quoteID,created,likelihoodofbuying
				ORDER BY created DESC

			INSERT INTO @stmp
				SELECT userID,orderID,CONVERT(FLOAT,q4)
				FROM tblCustomerServiceSurveys a WITH (NOLOCK)
				WHERE surveytype='postpurchase'
					AND created > DATEADD(m,-3,GETDATE())
					AND ID IN (SELECT TOP 20 ID FROM tblCustomerServiceSurveys WITH (NOLOCK) WHERE userID = a.userID AND surveytype='postpurchase' ORDER BY created DESC)
					AND q4 > 0
				GROUP BY userID,orderID,quoteID,created,q4
				ORDER BY created DESC

			INSERT INTO @stmp
				SELECT userID,accountID,score
				FROM tblCustomerServiceSurveys a WITH (NOLOCK)
				WHERE surveytype='postservice'
					AND created > DATEADD(m,-3,GETDATE())
					AND ID IN (SELECT TOP 20 ID FROM tblCustomerServiceSurveys WITH (NOLOCK) WHERE userID = a.userID AND surveytype='postservice' ORDER BY created DESC)
					AND ID <> 105
				GROUP BY userID,accountID,created,score
				ORDER BY created DESC

			DECLARE @avgs TABLE (userID INT,score FLOAT)

			INSERT INTO @avgs
				SELECT userID,AVG(CONVERT(FLOAT,score))/5
				FROM @stmp
				GROUP BY userID
			-- <!---  END SURVEY --->

			-- <!--- tier the payouts based on each user's period pot size --->
			SELECT userID
				,totalperiodGSDperhourprctContribution
				,ROUND(totalperiodGSDperhourprctContribution/@maxGSDH,2) AS prctofpot
				, incalc, userGSD, prctofGSD, periodGSD, totalPeriodGSDPerHour, GSDperHour
				,(SELECT score FROM @avgs WHERE userID = c.userID) AS rawsurveyscore -- raw survey score
				,CASE WHEN userID IN (SELECT userID FROM @gsdh WHERE incalc=0) THEN 0 ELSE (SELECT score / (SELECT MAX(score) FROM @avgs WHERE userID IN (SELECT userID FROM @gsdh WHERE incalc = 1)) FROM @avgs WHERE userID = c.userID) END AS rankedsurveyscore -- ranked survey score
				,ROUND(totalperiodGSDperhourprctContribution/@maxGSDH*.75 + (SELECT score / ISNULL(NULLIF((SELECT score / (SELECT MAX(score) FROM @avgs WHERE userID IN (SELECT userID FROM @gsdh WHERE incalc = 1))),0),.001) FROM @avgs WHERE userID = c.userID)*.25,2) AS 'rankedscore' --ranked total score 
			FROM @gsdh c
			GROUP BY userID,totalperiodGSDperhourprctContribution,incalc,userGSD,prctofGSD,periodGSD,totalPeriodGSDPerHour,GSDperHour
			ORDER BY ROUND(totalperiodGSDperhourprctContribution/@maxGSDH,2) DESC
		</cfquery>

		<cfreturn local.payoutValues>
	</cffunction>

</cfcomponent>
