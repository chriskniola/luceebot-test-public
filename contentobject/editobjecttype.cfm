<cfset screenID = "440">

<cfinclude template="/partnernet/shared/_header.cfm">

<cfparam name="objTypeName" default="">
<cfparam name="objTypeShortDescription" default="">
<cfparam name="objTypeID" default="">
<cfparam name="submit" default="">
<cfparam name="Delete" default="">

<!--- if submitted --->
<cfif submit IS NOT "" AND objTypeName IS NOT "">
	<cftransaction action="BEGIN">
	
		<cfquery name="duplicateobjecttype" datasource="#DSN#">
			SELECT *
			FROM tblContentObjectTypes
			WHERE objTypeName = <cfqueryparam sqltype="VARCHAR" value="#objTypeName#">
		</cfquery>
		
		<cfif duplicateobjecttype.recordcount IS 0>
			<cfstoredproc procedure="contentobjects_putobjecttype" datasource="#DSN#">
				<cfprocparam sqltype="VARCHAR" value="#objTypeName#">
				<cfprocparam sqltype="VARCHAR" value="#objTypeShortDescription#">
				<cfprocparam sqltype="VARCHAR" type="InOut" variable="objTypeID" value="#objTypeID#">
			</cfstoredproc>
			
			
			<!--- needs to be changed to CFC --->
			<cfquery name="adddefaultcontainer" datasource="#DSN#">
				INSERT INTO tblContentObjects
				(objLabel,objLongDescription,objtypeID)
				Values (<cfqueryparam sqltype="VARCHAR" value="#objTypeName#">,
						<cfqueryparam sqltype="VARCHAR" value="Default container for object type">,
						<cfqueryparam sqltype="INT" value="#objtypeID#">)
			</cfquery>
			
			<cfquery name="getobjID" datasource="#DSN#">
				SELECT objID
				FROM tblContentObjects
				WHERE objLabel = <cfqueryparam sqltype="VARCHAR" value="#objTypeName#">
				ORDER BY objCreated desc
			</cfquery>
			
				<cfinvoke
					component="#server.data#"
					method="PutPermissions"
					returnvariable="ppremObj"
					objID="#getobjID.objID#" 
					userID = "0"
					permissions = "L,R">
				<cfif ppremObj.errorcode NEQ 0>
					<cfoutput>#ppremObj.errormessage#<br></cfoutput>
				</cfif>


			<!--- <cfif getobjID.recordcount GT 0>
				<cfoutput>Please choose a different name for this object type - name conflict.</cfoutput>
				<cftransaction action="rollback">
				
			<cfelse> --->
			
				<cfquery name="addassociation" datasource="#DSN#">
					INSERT INTO tblContentObjectAssociations
					(objID,parentID,ascTypeID,ascpriority)
					Values (<cfqueryparam sqltype="VARCHAR" value="#getobjID.objID#">,'0',1,10)
				</cfquery>
				
				
				<cfif objTypeID IS NOT "">
					<cfoutput>Content Object '<strong>#objTypeName#</strong>' saved with ID '<strong>#objTypeID#</strong>'</cfoutput>
				<cfelse>
					There was an error saving the content object...<br><br>Please try again...
					<cftransaction action="ROLLBACK">
				</cfif>
				
				<cfquery name="updateobjecttype" datasource="#DSN#">
					UPDATE tblContentObjectTypes
					SET objDefaultContainerID = <cfqueryparam sqltype="VARCHAR" value="#getobjID.objID#">
					WHERE objTypeName = <cfqueryparam sqltype="VARCHAR" value="#objTypeName#">
				</cfquery>
			
			<!--- </cfif> --->
		<cfelse>
			The name chosen would create a duplicate object type name. Please rename and try again.
		</cfif> <!--- end duplicate object type --->
		<!--- END needs to be changed to CFC --->
	
		<cfset objTypeName = "">
		<cfset objTypeShortDescription = "">
		<cfset objTypeID = "">
	
		<cftransaction action="COMMIT">
	</cftransaction>
<cfelseif objTypeID IS NOT "">
	<cfinvoke component="#server.data#" method="GetType" returnvariable="TypeObj" objTypeID="#objTypeID#"></cfinvoke>
	
	
	<cfset TypeID = TypeObj.TypeID>
	<cfset TypeName = TypeObj.Name>
	<cfset CFCName = TypeObj.CFCName>
	<cfset ShortDescription = TypeObj.ShortDescription>
	<cfset DefaultContainer = TypeObj.DefaultContainer>
	<cfset IconPath = TypeObj.IconPath>

</cfif>

<cfif Delete IS NOT "">	
	Not functional yet
		
	
	<cfset TypeID = "">
	<cfset TypeName = "">
	<cfset CFCName = "">
	<cfset ShortDescription = "">
	<cfset DefaultContainer = "">
	<cfset IconPath = "">
	
</cfif>

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
						<input type="text" maxlength="50" size="50" name="TypeName" value="#TypeName#" class="normal">
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
					<td class="normal">&nbsp;</td>
					<td class="normal">
						<input type="submit" name="Submit" value="Put Object Type" class="normal"> &nbsp; &nbsp; <input type="submit" name="Delete" value="Delete" class="normal">
					</td>
				</tr>
			
		</table>
	</cfoutput>		
</form>

<cfinclude template="/partnernet/shared/_footer.cfm">