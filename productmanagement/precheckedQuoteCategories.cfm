<cfparam name="attributes.Submit" default="">
<cfset screenID = "275">
<cfinclude template="/partnernet/shared/_header.cfm">

<cfquery name="getQuoteCategories" datasource="#DSN#">
	select ID, Name, quoteCategory
	from ProductCategories
	where ID IN (42)
	OR (Active = 1
	AND exists (Select top 1 ID from products where products.Category = ProductCategories.ID AND products.active = 1))
	order by ID
</cfquery>

<cfloop query="getQuoteCategories">
	<cfparam name="attributes.qc_#ID#" default="">
</cfloop>

<cfif lenTrim(attributes.submit)>
	<cfloop query="getQuoteCategories">
		<cfif Evaluate("attributes.qc_"&id) NEQ quoteCategory>
			<cfquery name="updateQuoteCategory" datasource="#DSN#">
				update productCategories
				set quoteCategory = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Evaluate('attributes.qc_'&id)#" maxlength="10">
				where ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#getQuoteCategories.ID#">
			</cfquery>
			<cfquery name="insQuoteHistory" datasource="#DSN#">
				insert into productCategories_history(quoteCategoryModified,quoteCategoryModifiedBy,quoteCategoryModification,category)
				values(
				getDate(),
				<cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.id#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="Changed from '#getQuoteCategories.quoteCategory#' to '#Evaluate('attributes.qc_'&id)#'">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#getQuoteCategories.id#">
				)
			</cfquery>
		</cfif>
	</cfloop>
	<cfquery name="getQuoteCategories" datasource="#DSN#">
		select ID, Name, quoteCategory
		from ProductCategories
		where Active = 1
		AND exists (Select top 1 ID from products where products.Category = ProductCategories.ID AND products.active = 1)
		order by ID
	</cfquery>
</cfif>

<cfquery name="getQuoteHistory" datasource="#DSN#">
	select pch.quoteCategoryModified, u.firstName, u.lastName, pch.quoteCategoryModification, pc.Name
	from ProductCategories_history pch
	inner join ProductCategories pc on pc.ID = pch.Category
	inner join tblSecurity_Users u on u.ID = pch.quoteCategoryModifiedBy
	order by pch.quoteCategoryModified DESC
</cfquery>

<cfoutput>
	<br><br>
	<form name="mygrid" method="post" action="#CGI.SCRIPT_NAME#">
		<table cellpadding="3" cellspacing="0" border="0" style="text-align:center">
			<tr>
				<th>Category ID</th>
				<th>Category Name</th>
				<th>Primary</th>
				<th>Essential</th>
				<th>Optional</th>
			</tr>
			<cfloop query="getQuoteCategories">
				<tr <cfif getQuoteCategories.quoteCategory EQ "">style="background:##FFD7D7;"<cfelseif getQuoteCategories.currentrow mod 2 EQ 0> style="background:##E6E6E6;"</cfif>>
					<td class="normal">#getQuoteCategories.ID#</td>
					<td class="normal" align="left">#getQuoteCategories.Name#</td>
					<td class="normal"><input type="radio" name="qc_#getQuoteCategories.ID#" value="Primary" <cfif getQuoteCategories.quoteCategory EQ "Primary">checked="checked"</cfif>></td>
					<td class="normal"><input type="radio" name="qc_#getQuoteCategories.ID#" value="Essential" <cfif getQuoteCategories.quoteCategory EQ "Essential">checked="checked"</cfif>></td>
					<td class="normal"><input type="radio" name="qc_#getQuoteCategories.ID#" value="Optional" <cfif getQuoteCategories.quoteCategory EQ "Optional">checked="checked"</cfif>></td>
				</tr>
			</cfloop>
			<tr>
				<td class="normal"></td>
				<td class="normal"><input type="submit" value="Submit" name="submit" class="normal"></td>
			</tr>
		</table>
	</form>
	<br>
	<h2>History</h2>
	<table cellpadding="3" cellspacing="0" border="1" style="text-align:center">
		<tr>
			<th>Modified Date</th>
			<th>Modified By</th>
			<th>Category</th>
			<th>Modification</th>
		</tr>
		<cfloop query="getQuoteHistory">
			<tr>
				<td>#DateFormat(getQuoteHistory.quoteCategoryModified,"mm/dd/yyyy")#</td>
				<td>#getQuoteHistory.firstname# #getQuoteHistory.lastname#</td>
				<td>#getQuoteHistory.name#</td>
				<td>#getQuoteHistory.quoteCategoryModification#</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>
<cfinclude template="/partnernet/shared/_footer.cfm">