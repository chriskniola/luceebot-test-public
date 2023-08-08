<cfset screenID = "0">

<cfinclude template="/partnernet/shared/_header.cfm">

<!--- clear variables --->
<cfparam name="url.typeID" default="">

<!--- get object definition by ID --->
<cfstoredproc procedure="contentobjects_get_distinctobjectypes" datasource="#DSN#">
<cfprocresult name="objecttypes">
</cfstoredproc>




<cfif url.typeID IS "">
	<div class="normal">Type ID must be provided.</div>
	<cfabort>
</cfif>


<!--- get listing of distinct object types --->



<table width="100%">

	<tr>
		<td class="normal">Select an object type to add:</td>
	</tr>
	
	<!--- loop distinct object types --->
		<tr>
			<td class="normal">
				<ul><cfoutput query="objecttypes">
					
					<li><a href="addobject.cfm?typeID=#objecttypes.objtypeID#">#objecttypes.objtypename#</a> - #objecttypes.objTypeShortDescription#</li>
				</cfoutput></ul>
			</td>
		</tr>
	<!--- end loop of distinct object types --->
	
</table>


<cfinclude template="/partnernet/shared/_footer.cfm">