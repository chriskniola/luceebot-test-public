<cfset screenID = "445">

<cfinclude template="/partnernet/shared/_header.cfm">

<!--- get object definition by ID --->
<cfstoredproc procedure="contentobjects_get_distinctobjectypes" datasource="#DSN#">
<cfprocresult name="objecttypes">
</cfstoredproc>

<form name="addobjecttype" action="#cgi.script_name#" method="post">
		<table width="75%" align="center">
				<tr>
					<td class="normal" colspan=3>
						<a href="putobjecttype.cfm">Add new Object Type</a><br>&nbsp;
					</td>
				</tr>
			<!--- loop distinct object types --->
			<cfoutput query="objecttypes">
				<tr>
					<td class="normal">#objecttypes.name#</td>
					<td valign="top" nowrap class="normal">
						<a href="putobjecttype.cfm?TypeID=#objecttypes.ID#">Edit Type</a>&nbsp;
					</td>
					<td valign="top" nowrap class="normal">
						<a href="editobjects.cfm?TypeID=#objecttypes.ID#">Edit Objects</a>&nbsp;
					</td>
				</tr>
				<tr>
					<td colspan="3" height="1" bgcolor="##c0c0c0"></td>
				</tr>
			</cfoutput>
			<!--- end loop of distinct object types --->
		</table>
</form>

<br><br><br>

<cfinclude template="/partnernet/shared/_footer.cfm">