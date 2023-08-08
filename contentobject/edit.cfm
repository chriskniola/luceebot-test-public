<cfparam name="objID" default="">
<cfparam name="NEW" default="0">
<cfparam name="objtypeID" default="4">
<cfparam name="submit" default="0">
<cfparam name="objLabel" default="">
<cfparam name="objLongDescription" default="">
<cfparam name="objKeywords" default="">
	
	<cfquery name="getdata" datasource="#DSN#">
		SELECT objID,objLabel,objLongDescription,objKeywords
		FROM tblContentObjects
		WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#objID#">
	</cfquery>
	
	<cfif submit EQ "Add / Update Data">
		<cfif getdata.recordcount GT 0>
			<cfquery name="updatedata" datasource="#DSN#">
				UPDATE  tblContentObjects
				SET objLabel = <cfqueryparam sqltype="VARCHAR" value="#objLabel#">,
					objLongDescription = <cfqueryparam sqltype="VARCHAR" value="#objLongDescription#">,
					objKeywords = <cfqueryparam sqltype="VARCHAR" value="#objKeywords#">
				WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#objID#">
			</cfquery>
			<div align="center"><strong><font color="#FF0000">Item Updated</font></strong></div><br>
		<cfelse>
			<cfquery name="Adddata" datasource="#DSN#">
				INSERT INTO tblContentObjects
				(objLabel,objLongDescription,objKeywords,objtypeID)
				Values (<cfqueryparam sqltype="VARCHAR" value="#objLabel#">,
						<cfqueryparam sqltype="VARCHAR" value="#objLongDescription#">,
						<cfqueryparam sqltype="VARCHAR" value="#objKeywords#">,
						<cfqueryparam sqltype="INT" value="#objtypeID#">)
			</cfquery>
			<div align="center"><strong><font color="#FF0000">Item Created</font></strong></div><br>
		</cfif>
		<cfstoredproc procedure="contentobjects_DefaultAssoc" datasource="#DSN#">
			<cfprocparam type="In" sqltype="INT" value="#objtypeID#" null="No">
			<cfprocparam type="In" sqltype="VARCHAR" value="#objID#">
		</cfstoredproc>
	</cfif>
	
	<cfif objID NEQ "" OR NEW EQ '1'>
	
		<cfif getdata.recordcount GT 0>
			<cfset objLabel = getdata.objLabel>
			<cfset objLongDescription = getdata.objLongDescription>
			<cfset objKeywords = getdata.objKeywords>
		<cfelseif NEW NEQ '1'>
			<div align="center">The ID you submitted is not valid.</div>
		</cfif>
		
		<cfoutput>
		<form action="#cgi.script_Name#" method="post">
			<input type="hidden" value="#objID#" name="objID">
			<table align="center">
				<tr>
					<td class="normal">Object ID: </td>
					<td class="normal">#objID#</td>
				</tr>
				<tr>
					<td class="normal">Title: </td>
					<td><input type="text" value="#objLabel#" name="objLabel" class="normal"></td>
				</tr>
				<tr>
					<td class="normal">KeyWords: </td>
					<td><input type="text" value="#objKeywords#" name="objKeywords" class="normal"></td>
				</tr>
				<tr>
					<td colspan=2>
						<textarea cols="75" rows="4" name="objLongDescription">#this.objLongDescription#</textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2" align="center">
						<input type="Submit" name="submit" value="Add / Update Data" class="normal">
					</td>
				</tr>
			</table>
		</form>
		</cfoutput>
	<cfelse>
		<form action="<cfoutput>#cgi.script_Name#</cfoutput>" method="post">
			<cfquery name="getuuids" datasource="#DSN#">
				SELECT objID,objLabel
				FROM tblContentObjects
				WHERE objTypeID = <cfqueryparam sqltype="INT" value="#objtypeID#"> AND objID <> '0'
			</cfquery>
			Choose An Object To Update:<br>
			<select name="objID">
			<cfoutput query="getuuids">	
				<option value="#getuuids.objID#">#getuuids.objLabel#</option>
			</cfoutput>
			</select>
			<input type="Submit" name="action" value="Show Details">
			<br><br>
			
			OR <br><br>
			
			<cfoutput><a href="#CGI.Scipt_Name#?new=1">Add A New Object</a></cfoutput>
		</form>
		
	</cfif>
	


