<cfset screenID = '655'>
<cfinclude template="/partnernet/shared/_header.cfm">

<cfparam name="attributes.objID" default="">
<cfparam name="attributes.TypeID" default="">
<cfparam name="attributes.ParentID" default="">
<cfparam name="attributes.action" default="">
<!--- <cfset userID = "CB6AAC16-D6A7-4DB4-B132-8ECCA091885B"> --->
<cfset dispsearch = 1>
<cfset message = "">
<!--- userID--

<cfdump var="#attributes#">
<cfoutput>===#attributes.action#===<br></cfoutput> --->

<cftry>
	
	<cfif attributes.action EQ "putType">
		<cfset dispsearch = 0>
		<cfinvoke
             component="#server.object#"
             method="putType"
             returnvariable="DefObj"
			 userID="#session.user.objID#"
			 attributes="#attributes#">
		<cfif DefObj.errorcode EQ 0>		
				
			<cfset message = "the New object type has been added">
			<cfset dispsearch = 1>
			<cfoutput>
			<Script Language="JavaScript">
			if(parent.frames['objnav']){
				parent.objnav.addnode("0_0_0","#DefObj.type.defaultContainer#","#DefObj.type.Name#","#DefObj.type.TypeID#","1")
			}
			</script>
			</cfoutput>
						
		<cfelseIF DefObj.errorcode EQ 1 >
			<cfset message = DefObj.errormessage>
			<cfset dispsearch = 1>
		</cfif>
			
	<cfelseif attributes.action EQ "edit">
		<!--- edit ----------------------------------------------------------------------->
		<cfset dispsearch = 0>
		<cfinvoke
             component="#server.object#"
             method="edit"
             returnvariable="editObj"
			 userID="#session.user.objID#"
			 objID="#attributes.objID#"
			 attributes = "#attributes#">
			 
		<cfif editObj.errorcode EQ 0>
			
			<!--- get the new object ---->
			<cfinvoke
				component="#server.object#"
				method="get"
				returnvariable="thisObj"
				objID="#editObj.objID#"
				TypeID="#attributes.TypeID#">
				
			 <cfif thisObj.errorcode EQ "0">
			 	
			  	<cfif attributes.objID EQ "">
					<!--- this is never true --->
					
					<cfinvoke component="#server.data#"
						method="GetDefaultContainer"
						returnvariable="defObj"
						objID="#thisobj.obj.objID#"
						TypeID="#thisobj.obj.TypeID#">
						
					<cfif defObj.errorcode EQ "0">
						<cfoutput>				
						<Script Language="JavaScript">
						if(parent.frames['objnav']){
							parent.objnav.adddefault("#defObj.DefaultObjID#","#thisobj.obj.objID#","#thisobj.obj.label#","#thisobj.obj.TypeID#")		
					 	}
						</Script>
						</cfoutput>
						
						<!--- cfif isDefined("attributes.ParentID") AND attributes.ParentID NEQ defObj.DefaultObjID>
						test2 -----<br>
							<cfset dispsearch = 0>
							<cfinvoke
								component="#server.object#"
								method="PutAssociation"
								returnvariable="ascObj"
								userID="#session.user.objID#"
								objID="#thisobj.obj.objID#"
								attributes = "#attributes#"
								parentID="#attributes.ParentID#">
								-----[#ascObj.errormessage#]<br>
								<!--- calling this function will set the action form var to PutAssociation --->
								<!--- so when the page is submitted it will call that function next --->
								<!--- and when that function completes it will call the javascript to add the node --->
					 		 
						</cfif --->
					</cfif>
					
				<cfelse>
				
					<cfoutput>
					<cfif isDefined("attributes.selected_node2")>
					
						<Script Language="JavaScript">
						if(parent.frames['objnav']){
							parent.objnav.editTitle('#attributes.selected_node2#','#thisobj.obj.label#')
						}
						</Script>
						
					</cfif>
					</cfoutput>					
				</cfif>
				<cfset message = "The object has been updated successfully">
				<cfset dispsearch = 1>  				 
			</cfif>
		<cfelseif editObj.errorcode EQ 1>
			<cfset message = "#editObj.errormessage#">
			<cfset dispsearch = 1>
		</cfif>

		
	<cfelseif attributes.action EQ "PutAssociation">
		<!--- associate --------------------------------------------------------------------->
		<cfset dispsearch = 0>
		<cfinvoke method="PutAssociation"
			component="#server.object#"
			returnvariable="assocObj"
			attributes="#attributes#"
			objID="#attributes.objID#"
			userID="#session.user.objID#"
			parentID="#attributes.parentID#">
			
			<cfif assocObj.errorcode EQ "0">
				<cfinvoke
					component="#server.object#"
					method="get"
					returnvariable="thisObj"
					objID="#attributes.objID#"
					TypeID="#attributes.TypeID#">
				<cfoutput>
				<cfif thisObj.errorcode EQ "0">
					<cfif isDefined("attributes.selected_node")>
						<Script Language="JavaScript">
						if(parent.frames['objnav']){
							parent.objnav.copynode('#attributes.selected_node#','#attributes.selected_node2#','#attributes.ascTypeID#')
						}
						</Script>
					<cfelseif isDefined("attributes.selected_node2")>
						<Script Language="JavaScript">
						if(parent.frames['objnav']){
							parent.objnav.addnode('#attributes.selected_node2#','#thisobj.obj.objID#','#thisobj.obj.label#','#thisobj.obj.TypeID#','#attributes.ascTypeID#')
						}
						</script>
					</cfif>
					<cfset message = "The object association has been added successfully">
				<cfelse>
					<cfset message = "#assocObj.errormessage#">
				</cfif>
				</cfoutput>
				<cfset dispsearch = 1>
			<cfelseif assocObj.errorcode EQ 1>
				<cfset message = "#assocObj.errormessage#">
				<cfset dispsearch = 1>
			</cfif>
			
			
		
	<cfelseIf attributes.action EQ "Delete">
		<!--- Delete --------------------------------------------------------------------->
			
			
		<cfinvoke method="Delete"
			component="#server.object#"
			returnvariable="assocObj"
			attributes="#attributes#"
			objID="#attributes.objID#"
			userID="#session.user.objID#">
			
		<cfoutput>
		<cfif assocObj.errorcode EQ "0">
			<Script Language="JavaScript">
				if(parent.frames['objnav']){
					parent.objnav.deleteObject("#attributes.objID#")
				}
			</Script>
			<cfset message = "The Object has been deleted Successfully">
		<cfelse>
			<cfset message = assocObj.errormessage>
		</cfif>
		</cfoutput>
			
			
			
	<cfelseIf attributes.action EQ "DeleteAssociation">
		<!--- Delete --------------------------------------------------------------------->
			
			
		<cfinvoke method="DeleteAssociation"
			component="#server.object#"
			returnvariable="assocObj"
			attributes="#attributes#"
			objID="#attributes.objID#"
			ParentID="#attributes.ParentID#"
			userID="#session.user.objID#"
			ascTypeID="#attributes.ascTypeID#">
						
			<cfoutput>
			<cfif assocObj.errorcode EQ "0">
				<Script Language="JavaScript">
				if(parent.frames['objnav']){
					parent.objnav.deletenode("#attributes.selected_node#")
				}
				</Script>
				<cfset message = "The object association has been deleted Successfully">
			<cfelse>
				<cfset message = assocObj.errormessage>
			</cfif>
			</cfoutput>
			
			
	
	
	<cfelseIf attributes.action EQ "Display">
		<!--- Display --------------------------------------------------------------------->
		<cfset dispsearch = 0>
		<cfinvoke method="Display"
			component="#server.object#"
			returnvariable="DispObj"
			objID="#attributes.objID#"
			userID="#session.user.objID#"
			displaytype="detailed">
			
		<cfif DispObj.errorcode EQ 1>
			<cfset message = DispObj.errormessage>
			<cfset dispsearch = 1>
		<cfelse>
			<br>
			<br>
			<cfoutput>
			<script language="JavaScript">
				function deleteobj(){
					if(confirm('Are you sure you want to delete this object?')){
						if(confirm('Are you really sure you want to delete this object, all of it\'s attributes and it\'s associations?')){
							document.location.href = 'action.cfm?action=delete&objID=#attributes.objID#'
						}
					}
				}
			</script>
			<table width="75%" cellpadding="3" align="center" style="border: 1px Gray;">
				<tr>
					<td align="center"><a href="permissions.cfm?objID=#attributes.objID#">Permissions</a></td>
					<td align="center"><a href="action.cfm?action=edit&objID=#attributes.objID#">Edit</a></td>
					<td align="center"><a href="javascript: deleteobj()">Delete</a></td>
					<td align="center"><a href="javascript: history.back()">Back</a></td>
				</tr>
			</table>
			</cfoutput>
		</cfif>
		
		
	<cfelseIf attributes.action EQ "PutPermissions">
		<!--- PutPermisions --------------------------------------------------------------------->
			
			
		<cfinvoke method="putpermissions"
			component="#server.object#"
			returnvariable="assocObj"
			attributes="#attributes#"
			objID="#attributes.objID#"
			PermissionID="#attributes.PermissionID#"
			userID="#session.user.objID#">
			
		<cfoutput>
		<cfif assocObj.errorcode EQ "0">
			<cfset message = "The permissions were saved successfully.">
		<cfelse>
			<cfset message = assocObj.errormessage>
		</cfif>
		</cfoutput>
		
	<cfelseif Len(attributes.objID) GT 30>
		old function<br>
		<cfif attributes.ParentID NEQ "">
			
			<cfinvoke
             component="#server.object#"
             method="#attributes.action#"
             returnvariable="thisObj"
			 userID="#session.user.objID#"
			 objID="#attributes.objID#"
			 attributes = "#attributes#"
			 parentID="#attributes.ParentID#">
			 
		<cfelse>
			 
			<cfinvoke
             component="#thisObj#"
             method="#attributes.action#"
             returnvariable="thisObj"
			 userID="#session.user.objID#"
			 objID="#attributes.objID#"
			 attributes = "#attributes#">
			 
		</cfif>
		<!--- <cfdump var="#thisobj#"> --->
			
		<cfoutput>
		<cfif thisObj.errorcode EQ "1">
			#defObj.errormessage#
		</cfif>
		</cfoutput>
		
		
		
	</cfif>
	
<cfcatch>
	<cfoutput>
	#cfcatch.message#<br>
	#cfcatch.detail#
	</cfoutput>
</cfcatch>

</cftry>

<cfif dispsearch EQ 1>
	<cfif message NEQ "">
	<cfoutput><div align="center" class="normal"><font color="red"><strong>#message#</strong></font></div></cfoutput>
	</cfif>
	<br>
	<div align="center" class="normal"><strong>Please choose an object to the left or search for an object below.</strong></div>
	<br>
	<cfinclude template="find.cfm">
	
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">