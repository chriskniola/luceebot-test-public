<cfset screenID = "440">

<cfinclude template="/partnernet/shared/_header.cfm">

<cfparam name="attributes.Name" default="">
<cfparam name="attributes.ShortDescription" default="">
<cfparam name="attributes.TypeID" default="">
<cfparam name="attributes.IconPath" default="">
<cfparam name="attributes.CFCName" default="">
<cfparam name="attributes.submit" default="">
<cfparam name="attributes.Delete" default="">
<cfparam name="attributes.Delete2" default="">
<!--- <cfset userID = "7B9E53D3-453E-44C2-A842-E2A371098A75"> --->

<cfset TypeID = attributes.TypeID>
<cfset Name = attributes.Name>
<cfset ShortDescription = attributes.ShortDescription>
<cfset CFCName = attributes.CFCName>
<cfset ShortDescription = attributes.ShortDescription>
<cfset IconPath = attributes.IconPath>
<cfset showform = 1>

<!--- if submitted --->
<cfif attributes.submit IS NOT "" AND attributes.Name IS NOT "">
	<cfinvoke 
		component="#server.object#"
		method="PutType"
		returnvariable="TypeObj"
		userID="#session.user.objID#"
		Attributes = "#attributes#">
	<cfif TypeObj.errorcode EQ 0>
		The object type has been updated.
		<cfset showform = 0>
	<cfelse>
		<cfoutput>#TypeObj.errormessage#<br><br></cfoutput>
	</cfif>
	
<cfelseif attributes.TypeID IS NOT "">

	<cfinvoke 
		component="#server.object#"
		method="GetType"
		returnvariable="TypeObj"
		userID="#session.user.objID#"
		TypeID="#attributes.TypeID#">
	
	<cfset TypeID = TypeObj.type.ID>
	<cfset Name = TypeObj.type.Name>
	<cfset ShortDescription = TypeObj.type.ShortDescription>
	<cfset CFCName = TypeObj.type.CFCName>
	<cfset ShortDescription = TypeObj.type.ShortDescription>
	<cfset IconPath = TypeObj.type.IconPath>
	
</cfif>

<cfif attributes.Delete IS NOT "">
	<div align="center">
	Are you sure you want to delete this object type?<br>
	<form action="#cgi.script_name#" method="post">
		<input type="hidden" name="objID" value="#attributes.objID#">
		<input type="Submit" name="submit" value="Yes">&nbsp;&nbsp;<input type="Submit" name="submit" value="No">
	</form>
	</div>
<cfelseif attributes.Delete2 EQ "Yes">
	<cfstoredproc procedure="contentobjects_delete_objecttype_byID" datasource="#DSN#">
		<cfprocparam sqltype="VARCHAR" value="#objTypeID#">
	</cfstoredproc>
	
	<cfoutput>Content Object '<strong>#objTypeName#</strong>' with ID '<strong>#objTypeID#</strong>' was deleted.</cfoutput>
	
	<cfset showform = 0>
	
</cfif>

<cfif showform EQ 1>
<form name="addobjecttype" action="#cgi.script_name#" method="post">
	<cfoutput>		
		<table width="100%">
		
				<tr>
					<td class="normal">
						Object ID
					</td>
					<td class="normal">
						<input type="hidden" name="objTypeID" value="#TypeID#" class="normal">#TypeID#
					</td>
				</tr>
				<tr>
					<td class="normal">
						Object Name
					</td>
					<td class="normal">
						<input type="text" maxlength="50" size="50" name="Name" value="#Name#" class="normal">
					</td>
				</tr>
				<tr>
					<td class="normal">
						Short Description
					</td>
					<td class="normal">
						<input type="text" maxlength="255" size="50" name="ShortDescription" height="3" value="#ShortDescription#" class="normal">
					</td>
				</tr>
				<tr>
					<td class="normal">
						CFC Name
					</td>
					<td class="normal">
						<input type="text" maxlength="255" size="50" name="CFCName" height="3" value="#CFCName#" class="normal">
					</td>
				</tr>
				<tr>
					<td class="normal">
						Icon Path
					</td>
					<td class="normal">
						<input type="text" maxlength="255" size="50" name="IconPath" height="3" value="#IconPath#" class="normal">
					</td>
				</tr>
				<tr>
					<td class="normal" colspan=2><a href="obj_atredit.cfm?objTypeID=#TypeID#&namesonly=1">Edit Attributes</a></td>
				</tr>
				<tr>
					<td class="normal">&nbsp;</td>
					<td class="normal">
						<input type="submit" name="Submit" value="Put Object Type" class="normal"> &nbsp; &nbsp; <input type="submit" name="Delete" value="Delete" class="normal">
					</td>
				</tr>
			
		</table>
	</cfoutput>		
</form>
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">