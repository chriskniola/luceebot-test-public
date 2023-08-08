<meta http-equiv="Expires" content="1/1/2000">
<link rel="stylesheet" href="/partnernet/shared/css/_styles.css">
<script src="../shared/javascripts/_scripts.js?v=15" type="text/javascript"></script>
<cfparam name="attributes.action" default="">
<cfparam name="attributes.TypeID" default="">
<cfparam name="attributes.objID" default="">
<!--- <cfset userID = "7B9E53D3-453E-44C2-A842-E2A371098A75"> --->
<cfset showobjects = 1>

<CFTRY>

	<cfif attributes.objID NEQ "" AND attributes.ACTION EQ "Delete">

		<cfinvoke
			component="#server.object#"
			method="Delete"
			returnvariable="editObj"
			attributes="#attributes#"
			userID="#session.user.objID#"
			objID="#attributes.objID#"> 

		<cfif editObj.errorcode EQ 0>
			The object has been deleted.
			<cfset showobjects = 1>
		<cfelse>
			<cfset showobjects = 0>
			<cfoutput><br>#editObj.errormessage#</cfoutput>
		</cfif>
		
	<cfelseif attributes.objID NEQ "" OR attributes.ACTION EQ "edit">

		<cfinvoke
			component="#server.object#"
			method="edit"
			returnvariable="editObj"
			attributes="#attributes#"
			userID="#session.user.objID#"
			objID="#attributes.objID#"> 
		<cfif editObj.errorcode EQ 0>
			
			The object has been updated.
			<cfset showobjects = 1>
		<cfelse>
			<cfset showobjects = 0>
			<cfoutput><br>#editObj.errormessage#</cfoutput>
		</cfif>
	</cfif>			 
	<cfif attributes.TypeID NEQ "" AND showobjects EQ 1>
		<script language="JavaScript">
			function deleteobj(){
				if(confirm('Are you sure you want to delete this object?')){
					if(confirm('Are you really sure you want to delete this object, all of it\'s attributes and it\'s associations?')){
						return true;
					}
				}
				return false;
			}
		</script>
		<cfoutput><a href="#CGI.Scipt_Name#?ACTION=EDIT&TypeID=#attributes.TypeID#">Add A New Object</a></cfoutput>
	</cfif>
	
	<CFCATCH>
<CFOUTPUT>
#CFCATCH.MESSAGE#
#CFCATCH.DETAIL#
</CFOUTPUT>
</CFCATCH>

</CFTRY>