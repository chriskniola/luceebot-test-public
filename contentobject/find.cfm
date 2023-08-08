<cfif NOT findNoCase("action.cfm",CGI.script_name)>
	<cfset screenID = "655">
	<cfinclude template="/partnernet/shared/_header.cfm">
</cfif>

<cfparam name="attributes.TypeID" default="0">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.istemplate" default="0">
<cfparam name="attributes.description" default="">
<cfparam name="attributes.ObjID" default="">
<cfparam name="attributes.ProcessID" default="">
<cfparam name="attributes.MaxCreated" default="">
<cfparam name="attributes.MinCreated" default="">
<cfparam name="attributes.Submit" default="">
<cfparam name="attributes.orderby" default="objcreated desc">


<cfset posturl="?typeID=" & attributes.typeID>
<cfloop list="#StructKeyList(attributes)#" index="i">
	<cfif i IS NOT "typeID" AND i IS NOT "orderby" AND i IS NOT "fieldnames">
		<cfset posturl = posturl & "&" & i & "=" & Evaluate("attributes." & i)>
	</cfif>
</cfloop>


<cfoutput>
	<div class="container-fluid">
	<form action="#cgi.script_name#" method="post" name="form1" id="form1">
	<table align="center">
	<tr>
		<td class="normal">Object Type:</td>
		<td></td>
		<td class="normal">
		<cfinvoke component="#Server.Data#" method="GetTypes" returnvariable="TypesObj">
			<select name="TypeID">
			<option value="0">Any</option>
			<cfloop query="TypesObj.Types">
			<option	value="#TypesObj.Types.id#"<cfif attributes.TypeID EQ TypesObj.Types.id> SELECTED</cfif>>#TypesObj.Types.name#</option>
			</cfloop>
			</select>
		</td>
	</tr>
	<tr>
		<td class="normal">Label/Name/Title:</td>
		<td></td>
		<td><input type="text" name="label" value="#attributes.label#"></td>
	</tr>
	<tr>
		<td class="normal">Description:</td>
		<td></td>
		<td><input type="text" name="description" value="#attributes.Description#"></td>
	</tr>
	<tr>
		<td class="normal">Object ID:</td>
		<td></td>
		<td><input type="text" name="ObjID" value="#attributes.ObjID#"></td>
	</tr>
	<tr>
		<td class="normal">Process ID:</td>
		<td></td>
		<td><input type="text" name="ProcessID" value="#attributes.ProcessID#"></td>
	</tr>
	<tr>
		<td class="normal">Templates?:</td>
		<td></td>
		<td><select name="istemplate">
				<option value="0" <cfif attributes.istemplate IS "0">SELECTED</cfif>>Only non-template objects</option>
				<option value="1" <cfif attributes.istemplate IS "1">SELECTED</cfif>>Only template objects</option>
			</select></td>
	</tr>
	<tr>
		<td valign="top" class="normal">In date range</td>
		<td></td>
		<td>
		<table>
			<tr>
				<td class="normal" align="right"><cfinvoke
				component="alpine-objects.calendar"
				method="button"
				scriptobject="opener.form1.MinCreated"
				title="from:"
				button="0"></td>
				<td><input type="text" name="MinCreated" value="#attributes.MinCreated#" size="14">
				</td>
			</tr>
			<tr>
				<td class="normal" align="right"><cfinvoke
				component="alpine-objects.calendar"
				method="button"
				scriptobject="opener.form1.MaxCreated"
				title="to:"
				button="0"></td>
				<td><input type="text" name="MaxCreated" VALUE="#attributes.MaxCreated#" size="14">
				</td>
			</tr>
		</table>
		</td>
	</tr>
	<tr>
		<td></td>
		<td></td>
		<td><input type="submit" name="submit" value="Search"></td>
	</tr>
	</table>
	</form>
</div>
</cfoutput>
<br><br>

<cfif attributes.submit EQ "Search"><!---  AND (attributes.label IS NOT "" OR attributes.description IS NOT "") --->
	<cfset errormessage = "">
	<cfif attributes.MaxCreated EQ "">
		<cfset MaxCreatedVal = '9/9/99'>
	<cfelseif isDate(attributes.MaxCreated)>
		<cfset MaxCreatedVal = attributes.MaxCreated>
	<cfelse>
		<cfset errormessage = "The to date is not a valid date format">
	</cfif>

	<cfif attributes.MinCreated EQ "">
		<cfset MinCreatedVal = '9/9/99'>
	<cfelseif isDate(attributes.MinCreated)>
		<cfset MinCreatedVal = attributes.MinCreated>
	<cfelse>
		<cfset errormessage = "The from date is not a valid date format">
	</cfif>

	<cfif errormessage EQ "">
		<cfinvoke component="#Server.object#"
			method="findobj"
			userID="#session.user.objID#"
			returnvariable="SearchObj"
			MaxCreated="#MaxCreatedVal#"
			MinCreated="#MinCreatedVal#"
			longDescription="#attributes.description#"
			label="#attributes.label#"
			ObjTypeID="#attributes.TypeID#"
			ProcessID="#attributes.processID#"
			ObjID="#attributes.ObjID#"
			OrderBy="#attributes.orderby#"
			IsTemplate="#attributes.istemplate#">

		<!--- <cfdump var="#searchObj.objIDs#">	 --->
		<cfif searchObj.errorcode EQ 0 AND searchObj.objIDs.recordcount GT 0>
			<table align="center">
				<tr>
					<td colspan=5 class="normal">Results<br>&nbsp;</td>
				</tr>

				<cfoutput>
					<tr>
						<td></td>
						<td class="normal"><a href="#cgi.script_name##posturl#&orderby=<cfif attributes.orderby EQ 'objlabel asc'>objlabel desc<cfelse>objlabel asc</cfif>">Label/ Title</a></td>
						<td class="normal"><a href="#cgi.script_name##posturl#&orderby=<cfif attributes.orderby EQ 'objcreated desc'>objcreated asc<cfelse>objcreated desc</cfif>">Date Created</a></td>
						<td class="normal"><a href="#cgi.script_name##posturl#&orderby=<cfif attributes.orderby EQ 'objtypeid asc'>objtypeid desc<cfelse>objtypeid asc</cfif>">Object Type</a></td>
						<td class="normal"><a href="#cgi.script_name##posturl#&orderby=<cfif attributes.orderby EQ 'objid asc'>objid desc<cfelse>objid asc</cfif>">Object ID</a></td>
					</tr>
				</cfoutput>

			<cfloop query="searchObj.objIDs">

				<cfinvoke component="#Server.Object#"
					method="Get"
					returnvariable="thisObj"
					objID="#searchObj.objIDs.objid#">
				<cfoutput>
				<cfif thisObj.errorcode EQ 0>
				<tr>
					<td class="normal">#searchObj.objIDs.currentRow#</td>
					<td class="normal"><cfif thisobj.obj.istemplate><font color="red"><strong>*</strong></font> </cfif><a href="action.cfm?action=display&objID=#thisObj.obj.objID#">-#thisObj.obj.label#</a></td>
					<td class="normal">#thisObj.obj.created#</td>
					<cfquery name="TypeNameQRY" dbtype="query">
						SELECT Name FROM TypesObj.Types WHERE ID = #thisObj.obj.TypeID#
					</cfquery>
					<td class="normal">#TypeNameQRY.Name#</td>
					<td class="normal">#thisObj.obj.objID#</td>
				</tr>
				<tr>
					<td colspan=5 height=10></td>
				</tr>
				<cfelse>
				<tr>
					<td class="normal">#searchObj.objIDs.currentRow#</td>
					<td colspan=4 class="normal">#thisObj.errormessage#</td>
				</tr>
				</cfif>

				</cfoutput>

			</cfloop>
				<tr>
					<td colspan=5 class="normal"><font color="red"><strong>*</strong></font> denotes template object</td>
				</tr>
			</table>

		<cfelse>
			<cfif searchObj.errorcode NEQ 0>

				<div align="center"><strong>Error:&nbsp;<cfoutput>#searchObj.errormessage#</cfoutput></strong></div>
			</cfif>
			<div align="center"><strong>Sorry, Your search did not return any results.</strong></div>
		</cfif>
	<cfelse>
		<div align="center"><strong><cfoutput>#errormessage#</cfoutput></strong></div>
	</cfif>
<cfelse>
	<div align="center"><strong>Please enter your search criteria.</strong></div>

</cfif>


<cfif NOT findNoCase("action.cfm",CGI.script_name)>
	<cfinclude template="/partnernet/shared/_footer.cfm">
</cfif>
