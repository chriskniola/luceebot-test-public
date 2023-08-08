<cfsetting showdebugoutput="No" requesttimeout="1500">
<cfset screenID = "655">
<cfinclude template="/partnernet/shared/_header.cfm">

<cfparam name="attributes.overwrite" default="0">
<cfparam name="attributes.permsubbut" default="">
<cfif attributes.permsubbut EQ "Update">
	<cfset errormessage = "">
	<cfset code = 0>
<!--- 	<cfdump var="#attributes#"> --->
	<cfloop index="permID" list="#attributes.userIDs#">
		<cfset tmppermID = Replace(permID,"-","","all")>
		<cfparam name="attributes.permL#tmppermID#" default=0>
		<cfparam name="attributes.permR#tmppermID#" default=0>
		<cfparam name="attributes.permW#tmppermID#" default=0>
		<cfparam name="attributes.permD#tmppermID#" default=0>
		<cfparam name="attributes.permO#tmppermID#" default=0>
		<cfparam name="attributes.permN#tmppermID#" default=0>
		<cfset permissions = StructNew()>
		<cfset permissions.L = evaluate("attributes.permL#tmppermID#")>
		<cfset permissions.R = evaluate("attributes.permR#tmppermID#")>
		<cfset permissions.W = evaluate("attributes.permW#tmppermID#")>
		<cfset permissions.D = evaluate("attributes.permD#tmppermID#")>
		<cfset permissions.O = evaluate("attributes.permO#tmppermID#")>
		<cfset permissions.N = evaluate("attributes.permN#tmppermID#")>
		
		<cfif (permissions.N + permissions.L + permissions.R + permissions.W + permissions.D + permissions.O) GT 0>
			<!--- <cfoutput>objID = #attributes.objID# - userID = #permID#</cfoutput><cfdump var="#permissions#"> --->
				<cfinvoke
					component="#server.Data#"
					method="putpermissions"
					returnvariable="permObj"
					userID="#permID#"
					ObjID="#attributes.objID#"
					permissions="#permissions#">
				<!--- <cfoutput>permObj.errorcode = #permObj.errorcode#<br><br></cfoutput> --->
				
				<cfset message = permObj.errormessage>
				<cfif message EQ ""><cfset message = "Updated successfully"></cfif>
				<cfset code = code + permObj.errorcode>
				<cfset errormessage = errormessage & "#evaluate('attributes.username'&tmppermID)# - #message#<br>">
			
		<cfelse>
			<!--- <cfoutput>Delete - objID = #attributes.objID# - userID =#permID#<br></cfoutput> --->
				<cfinvoke
					component="#server.Data#"
					method="Deletepermissions"
					returnvariable="DelObj"
					userID="#permID#"
					ObjID="#attributes.objID#">
		</cfif> 
	</cfloop>
	
	<cfIf isDefined("attributes.Propogate")>
		<!--- update all the associated child objects of this type to the same permissions --->
		<cfinvoke
			component="#server.data#"
			method="PropogatePermissions"
			returnvariable="propObj"
			userID="#session.user.objID#"
			ObjID="#attributes.objID#"
			overwrite="#attributes.overwrite#">
		
			<cfset code = code + propObj.errorcode>
			<cfset errormessage = errormessage & "#propObj.errormessage#<br>">
	</cfif>
	
	<cfif code GT 0>
		<cfoutput>#errormessage#</cfoutput>

	<cfelse>
		<cfset session.message = "The permissions have been updated successfully.">
	</cfif>

		
</cfif>


	<cfinvoke
		component="#server.object#"
		method="FindObj"
		returnvariable="UserObjs"
		userID="#session.user.objID#"
		objTypeID="24">
<form action="#CGI.Script_Name" method="post">
<table>
	<tr>
		<td class="grayboxheader2">User</td>
		<td class="grayboxheader2">&nbsp;</td>
		<td class="grayboxheader2">List</td>
		<td class="grayboxheader2">Read</td>
		<td class="grayboxheader2">Write</td>
		<td class="grayboxheader2">Delete</td>
		<td class="grayboxheader2">Owner</td>
		<td class="grayboxheader2">None</td>
	</tr>
	<cfset users = "">
	<cfoutput query="UserObjs.objIDs">
	
		<cfinvoke
			component="#server.object#"
			method="Get"
			returnvariable="thisObj"
			userID="#session.user.objID#"
			ObjID="#UserObjs.objIDs.objID#">
		<cfif thisObj.errorcode EQ 0>
			
			<cfstoredproc procedure="contentobjects_get_permissions_simple" datasource="#DSN#">
				<cfprocparam type="In"	sqltype="VARCHAR" 	 value="#attributes.objID#">
				<cfprocparam type="In" 	sqltype="VARCHAR" 	 value="#thisObj.obj.objID#">
				<cfprocresult name="thisUserPerm">
			</cfstoredproc>
			
			<cfset permissionL = 0>
			<cfset permissionR = 0>
			<cfset permissionW = 0>
			<cfset permissionD = 0>
			<cfset permissionO = 0>
			<cfset permissionN = 0>
			<cfif thisUserPerm.recordcount GT 0>
				<cfset permissionL = thisUserPerm.permissionL>
				<cfset permissionR = thisUserPerm.permissionR>
				<cfset permissionW = thisUserPerm.permissionW>
				<cfset permissionD = thisUserPerm.permissionD>
				<cfset permissionO = thisUserPerm.permissionO>
				<cfset permissionN = thisUserPerm.permissionN>
			</cfif>
			
			<cfset tmpobjID = Replace(UserObjs.objIDs.objID,"-","","all")>
			<cfset users = users & "#thisObj.obj.objID#,">
		<tr>
			<td class="grayboxbody2"><a onMouseOver="window.status='#thisobj.obj.objid#'">#thisObj.obj.Label#</a><input type="hidden" name="userName#tmpobjID#" value="#thisObj.obj.Label#"></td>
			<td class="grayboxbody2"></td>
			<td class="grayboxbody2" width=50><input type="checkbox" name="permL#tmpobjID#" value="1"<cfif permissionL> Checked</cfif>></td>
			<td class="grayboxbody2" width=50><input type="checkbox" name="permR#tmpobjID#" value="1"<cfif permissionR> Checked</cfif>></td>
			<td class="grayboxbody2" width=50><input type="checkbox" name="permW#tmpobjID#" value="1"<cfif permissionW> Checked</cfif>></td>
			<td class="grayboxbody2" width=50><input type="checkbox" name="permD#tmpobjID#" value="1"<cfif permissionD> Checked</cfif>></td>
			<td class="grayboxbody2" width=50><input type="checkbox" name="permO#tmpobjID#" value="1"<cfif permissionO> Checked</cfif>></td>
			<td class="grayboxbody2" width=50><input type="checkbox" name="permN#tmpobjID#" value="1"<cfif permissionN> Checked</cfif>></td>
		</tr>
		<cfelse>
			<cfoutput>---#thisObj.errormessage#---</cfoutput>
		</cfif>
		
	</cfoutput>
	<tr>
		<td colspan="8" class="tiny">
		<input type="submit" name="permsubbut" value="Update">
		<input type="checkbox" name="Propogate" value="1">Propogate to children
		<input type="checkbox" name="overwrite" value="1">Overwrite existing
		</td>
	</tr>
</table>
<cfoutput><input type="hidden" name="UserIDs" value="#users#">
<input type="hidden" name="ObjID" value="#attributes.objID#"></cfoutput>
</form>


<cfinclude template="/partnernet/shared/_footer.cfm">
