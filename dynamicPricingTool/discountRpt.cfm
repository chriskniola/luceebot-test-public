<cfset screenID = 1115>
<style>
	#reportmain{
		text-align:left;
		margin-left:400px;
		position:relative;
		width:400px;
	}
	#discRptForm label{
		display:block;
		margin-bottom:5px;
	}
	.rbuttonLbl{
		display:block;
		position:absolute;
	}
	.rbuttonLbl+input{
		display:block;
		position:absolute;
		vertical-align:middle;
		left:85px;
	}
	.spacer{
		height:5px;
	}
</style>
<cfset showjQuery = 1>
<cfif NOT findNoCase("scheduledtasks",cgi.script_name)>
	<cfinclude template="/partnernet/shared/_header.cfm">
</cfif>
<script>
j$(function(){
	j$('form').validate();
	j$('.dt').datepicker({
		autoSize: true
	});
	j$('#report').css("padding", "0px");
});
</script>
<div id="reportmain"><h3>Discount Report</h3>
<cfif CGI.REQUEST_METHOD EQ "POST">
	<cfquery name="getDiscounts" datasource="#DSN#">
		DECLARE @soldSince BIT
			SET @soldSince = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
		DECLARE @startDate DATE
			SET @startDate = <cfqueryparam cfsqltype="cf_sql_date" value="#attributes.startDate#">
		DECLARE @endDate DATE
			SET @endDate = <cfqueryparam cfsqltype="cf_sql_date" value="#attributes.endDate#">
		DECLARE @discounts TABLE(prodID INT, logEntry VARCHAR(50), discDT DATE, discBy INT, currentPrice MONEY)
		INSERT INTO @discounts
			SELECT p.ID
				, (SELECT TOP 1 ol.value
					FROM tblObjectLog ol 
					WHERE ol.objID = CAST(p.ID AS VARCHAR) 
					AND ol.value LIKE '(DR)Discounted%' 
					ORDER BY ol.created DESC) AS 'log'
				, (SELECT TOP 1 ol.created
					FROM tblObjectLog ol 
					WHERE ol.objID = CAST(p.ID AS VARCHAR) 
					AND ol.value LIKE '(DR)Discounted%' 
					ORDER BY ol.created DESC) AS 'discDt'
				, (SELECT TOP 1 ol.createdby
					FROM tblObjectLog ol 
					WHERE ol.objID = CAST(p.ID AS VARCHAR) 
					AND ol.value LIKE '(DR)Discounted%' 
					ORDER BY ol.created DESC) AS 'discBy'
				, p.retailPrice AS 'currentPrice'
			FROM Products p
			WHERE EXISTS(SELECT TOP 1 ol.value
					FROM tblObjectLog ol 
					WHERE ol.objID = CAST(p.ID AS VARCHAR) 
					AND ol.value LIKE '(DR)Discounted%' 
					ORDER BY ol.created DESC)
					
		SELECT d.prodID
			, d.currentPrice
			, d.discBy
			, d.discDT
			, ISNULL(SUM(o.Quantity), 0) as 'soldSince'
			, CAST(SUBSTRING(d.logEntry, CHARINDEX(':',d.logEntry) + 1, CHARINDEX('>', d.logEntry) - CHARINDEX(':', d.logEntry) - 1) AS MONEY) AS 'oldPrice'
			, CAST(REPLACE(d.logEntry, LEFT(d.logEntry, CHARINDEX('>', d.logEntry)), '') AS MONEY) AS 'discountedPrice'
			, su.FirstName + ' ' + su.LastName AS 'userName'
		FROM @discounts d
		LEFT OUTER JOIN checkouts c ON c.DT BETWEEN d.discDT AND CASE WHEN @soldSince = 1 THEN CURRENT_TIMESTAMP ELSE @endDate END
			AND c.process BETWEEN 20 AND 30
		LEFT OUTER JOIN orders o ON o.ProductNumber=d.prodID 
			AND o.SessionID=c.SessionID
			AND o.ordlinerev <> 0
		INNER JOIN tblSecurity_Users su on su.ID=d.discBy
		WHERE d.discDT BETWEEN @startDate AND @endDate
		GROUP BY d.prodID
			, d.logEntry
			, d.discBy
			, d.currentPrice
			, su.FirstName
			, su.LastName
			, d.discDT
		ORDER BY d.discDT ASC
	</cfquery>
	
	<cfquery name="eliminateMarkups" dbtype="query">
		SELECT * FROM getDiscounts
		WHERE currentPrice = discountedPrice
	</cfquery>

	<cfset colOrder = "discDT,userName,prodID,oldPrice,currentPrice,soldSince">
	<cfset colnames="Date,User,Product ID,Old Price,Current Price,Units Sold Since Discount">
	<cfinvoke component="alpine-objects.report"
		method="display"
		recordset="#eliminateMarkups#"
		columnorder="#colOrder#"
		columnnames="#colnames#"
		returnvariable="result"
		format="#attributes.outputType#"			
	/>
	<cfif attributes.outputType EQ 'HTML'>
		<cfoutput>#result.html#</cfoutput>
		<cfelse>
			0 Records found.
	</cfif>
<p><a href="discountRpt.cfm"><strong>Back to Report Options</strong></a></p>
	<cfelse>
		<div id="discRptForm">
			<form name="formOpts" action="discountRpt.cfm" method="POST">
				<cfoutput><label for="startDate">Start date: <input class="dt" name="startDate" type="date" required="true" value="#DateFormat(DateAdd('d', -7, NOW()), 'yyyy-mm-dd')#" ></label>
				<label for="endDate"> End date: &nbsp;&nbsp;<input class="dt" name="endDate" type="date" required="true" value="#DateFormat(Now(), 'yyyy-mm-dd')#"></label></cfoutput>
				<label class="rbuttonLbl" for="outputCsv"> Output as CSV</label><input id="outputCsv" name="outputType" type="radio" value="CSV" label="CSV" checked="false"><br />
				<div class="spacer"></div>
				<label class="rbuttonLbl" for="outputHtml">Output as HTML</label><input id="outputHtml" name="outputType" type="radio" value="HTML" label="HTML" checked="true"><br />
				<div class="spacer"></div>
				<input name="submit" type="submit" value="Submit">
			</form>
		</div>
</cfif>
<p><a target="_top" href="/partnernet/default.cfm"><strong>Back to Menu</strong></a></p></div>
<cfif NOT findNoCase("scheduledtasks",cgi.script_name)>
	<cfinclude template="/partnernet/shared/_footer.cfm">
</cfif>