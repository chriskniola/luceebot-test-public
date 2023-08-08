<cfset screenID = "655">

<cfparam name="isPost" default="0">
<cfparam name="useBootstrap" default="0">

<cfstoredproc procedure="security_getscreenbyscreenID" datasource="#DSN#">
	<cfprocparam sqltype="INT" type="in" value="#screenID#">
	<cfprocresult name="screen">
</cfstoredproc>

<cfinvoke component="#APPLICATION.user#" method="checkscreenpermission" returnvariable="success">
	<cfinvokeargument name="screenID" value="#screenID#">
</cfinvoke>

<cfparam name="attributes.returnToForm" default="0">
<cfparam name="attributes.returnValue" default="objID">
<cfparam name="attributes.returnName" default="Label">

<cfparam name="attributes.ObjID" default="">
<cfparam name="attributes.TypeID" default="0">
<cfparam name="attributes.action" default="">


<cfif attributes.returnToForm NEQ "0">
	<script language="JavaScript">
		<cfoutput>
		function AddValue(val1,val2){	
			window.opener.AddOption(val1, val2)
			window.close()
		}
		</cfoutput>
	</script>
</cfif>

<link rel="stylesheet" href="/partnernet/shared/css/_styles.css">
<cfif attributes.action EQ "edit">

	<cfinvoke
	component="#server.object#"
	method="edit"
	returnvariable="editObj"
	attributes="#attributes#"
	userID="#session.user.objID#"
	objID="#attributes.objID#"> 
	
	<cfif editObj.errorcode EQ 0>
		<cfif attributes.returnToForm NEQ "0">
			<cfinvoke
			component="#server.object#"
			method="get"
			returnvariable="getObj"
			userID="#session.user.objID#"
			objID="#editObj.objID#">
			<!--- <cfdump var="#getObj#"> --->
			<script language="JavaScript">
				<cfoutput>		
				AddValue('#evaluate("getObj.obj."&attributes.returnName)#', '#evaluate("getObj.obj."&attributes.returnvalue)#')
				</cfoutput>
			</script>
		</cfif>
	<cfelse>
		<cfoutput>#editObj.errormessage#</cfoutput>
	</cfif>
	
<cfelseif attributes.action EQ "display">

	<cfinvoke
	component="#server.object#"
	method="display"
	returnvariable="displayObj"
	attributes="#attributes#"
	userID="#session.user.objID#"
	displaytype="inline"
	objID="#attributes.objID#">
	<cfif displayObj.errorcode EQ 0>
		<cfoutput>
		<cfif attributes.returnToForm NEQ "0">
		<br>
		<a href="JavaScript: AddValue('#evaluate("displayObj.obj."&attributes.returnName)#', '#evaluate("displayObj.obj."&attributes.returnvalue)#')">Add this Object</a>
		</cfif>
		<br>
		<a href="#cgi.script_Name#?action=searchagain&returnToForm=#attributes.returnToForm#&returnValue=#attributes.returnValue#&returnName=#attributes.returnName#&typeID=#attributes.TypeID#">Search Again</a>
		</cfoutput>
	</cfif>

<cfelse>

	<cfparam name="attributes.label" default="">
	<cfparam name="attributes.description" default="">
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
	<form action="#cgi.script_name#" method="post" name="form1" id="form1">
	<table align="center">
	<tr>
		<td colspan=3 align="center"><a href="#cgi.script_Name#?action=edit&returnToForm=#attributes.returnToForm#&returnValue=#attributes.returnValue#&returnName=#attributes.returnName#&typeID=#attributes.TypeID#">Create a New object</a></td>
	</tr>
	<tr>
		<td colspan=3 align="center">or</td>
	</tr>
	<tr>
		<td colspan=3 align="center">Search for existing object</td>
	</tr>
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
		<td valign="top" class="normal">In date range</td>
		<td></td>
		<td>
		<table>
			<tr>
				<td class="normal">from: </td>
				<td><input type="text" name="MinCreated" VALUE="#attributes.MinCreated#">
				<cfinvoke 
				component="alpine-objects.calendar" 
				method="button"
				scriptobject="opener.form1.MinCreated"></td>
			</tr>	
			<tr>
				<td class="normal">to:</td>
				<td><input type="text" name="MaxCreated" VALUE="#attributes.MaxCreated#">
				<cfinvoke 
				component="alpine-objects.calendar" 
				method="button"
				scriptobject="opener.form1.MaxCreated"></td>
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
	<input type="hidden" name="ReturnToForm" value="#attributes.ReturnToForm#">
	</form>
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
			<cfinvoke component="#Server.data#"
				method="findobj"
				returnvariable="SearchObj"
				MaxCreated="#MaxCreatedVal#"
				MinCreated="#MinCreatedVal#"
				longDescription="#attributes.description#"
				label="#attributes.label#"
				ObjTypeID="#attributes.TypeID#"
				ProcessID="#attributes.processID#"
				ObjID="#attributes.ObjID#"
				OrderBy="#attributes.orderby#">
					
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
							<td></td>
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
						<td class="normal"><a href="#cgi.script_Name#?action=display&returnToForm=#attributes.returnToForm#&returnValue=#attributes.returnValue#&returnName=#attributes.returnName#&objID=#thisObj.obj.objID#">#thisObj.obj.label#</a></td>
						<td class="normal">#thisObj.obj.created#</td>
						<cfquery name="TypeNameQRY" dbtype="query">
							SELECT Name FROM TypesObj.Types WHERE ID = #thisObj.obj.TypeID#
						</cfquery>
						<td class="normal">#TypeNameQRY.Name#</td>
						<td class="normal"><cfoutput>#attributes.returnToForm#</cfoutput>
						<cfif attributes.returnToForm NEQ "0">
						<a href="JavaScript: AddValue('#evaluate("thisObj.obj."&attributes.returnName)#', '#evaluate("thisObj.obj."&attributes.returnvalue)#')">Add this Object</a>
						</cfif></td>
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
				</table>
			
			<cfelse>
				<cfif searchObj.errorcode NEQ 0>
				
					<div align="center"><strong>Search Error:&nbsp;<cfoutput>#searchObj.errormessage#</cfoutput></strong></div>
				</cfif>
				<div align="center"><strong>Sorry, Your search did not return any results.</strong></div>
			</cfif>
		<cfelse>
			<div align="center"><strong><cfoutput>#errormessage#</cfoutput></strong></div>
		</cfif>
	<cfelse>
		<div align="center"><strong>Please enter your search criteria.</strong></div>
	
	</cfif>

</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">
