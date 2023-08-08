<cfset screenID = "350">
<cftry>
<cfparam name="objID" default="0">
<cfparam name="ParentID" default="0">
<cfparam name="objTypeID" default=0>
<cfparam name="submit" default="">
<cfparam name="NewAtrName" default="">
<cfparam name="NewAtrValue" default="">
<cfparam name="NewAtrGroup" default="">
<cfparam name="Newsortable" default=0>
<cfparam name="Newcomparable" default=0>
<cfparam name="NewDisplayonsite" default=0>
<cfparam name="Newoperator" default="=">
<cfparam name="NewUnits" default="">
<cfparam name="NewPriority" default=1>
<cfparam name="NewDescription" default="">
<cfparam name="pagefrom" default="">
<cfparam name="tmpAtrID" default="0">
<cfparam name="old_attribute_values" default="">
<cfparam name="namesonly" default="0">

<cfif objID EQ ""><cfset objID = 0></cfif>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Attributes</title>
<cfif submit EQ "Add New Attribute">
	<!--- this is a new attribute and needs to be added to the category level and the product level --->
	<cfif NewAtrName NEQ "">
		<cfset Details = "">
		<cfif INT(NewSortable)><cfset Details = Details & "Sortable,"></cfif>
		<cfif INT(NewComparable)><cfset Details = Details & "Comparable,"></cfif>
		<cfif INT(NewDisplayonSite)><cfset Details = Details & "DisplayonSite,"></cfif>
		<cfset newobjID = objID>
		<cfstoredproc procedure="contentobjects_modify_attribute" datasource="#DSN#">
			<cfprocparam type="InOut" sqltype="INT" variable="tmpAtrID" value="#tmpAtrID#">
			<cfprocparam type="InOut" sqltype="VARCHAR" variable="newobjID" value="#objID#">
			<cfprocparam type="In" sqltype="INT" value="#INT(objTypeID)#" null="No">
			<cfprocparam type="In" sqltype="VARCHAR" value="#NewAtrValue#" null="No">
			<cfprocparam type="In" sqltype="VARCHAR" value="#NewAtrName#" null="No">
			<cfprocparam type="In" sqltype="VARCHAR" value="#NewOperator#" null="No">
			<cfprocparam type="In" sqltype="VARCHAR" value="#NewUnits#">
			<cfprocparam type="In" sqltype="INT" value="#INT(NewPriority)#" null="No">
			<cfprocparam type="In" sqltype="VARCHAR" value="#NewDescription#">
			<cfprocparam type="In" sqltype="INT" value="">
			<cfprocparam type="In" sqltype="VARCHAR" value="#NewAtrGroup#">
			<cfprocparam type="In" sqltype="VARCHAR" value="#Details#">
		</cfstoredproc>
		<!--- cfoutput>newobjID = #newobjID#</cfoutput--->
		<cfset Newformval1 = NewAtrName & " - " & NewAtrValue>
		<cfset Newformval2 = tmpAtrID & " - " & NewAtrName & " - " & NewAtrValue>
		<cfset old_attribute_values = old_attribute_values & Newformval2 & ",">
		<cfoutput>
		<Script language="JavaScript">
			theform = window.opener.editform.attributes
			window.opener.setoption(theform.options.length,'#Newformval1#','#Newformval2#');
		</SCRIPT></cfoutput>
		<cfset session.message = "The attribute has been added.">
	<cfelse>
		<cfset session.message = "Please enter an attribute name.">
	</cfif>
</cfif>	

<cfif submit EQ "Update Attributes">
	<!--- this is the query that gets all the names and values for attributes with this Object's id or typeID --->
	<cfstoredproc procedure="Contentobject_getAttributes" datasource="#DSN#">
		<cfprocparam type="In" sqltype="VARCHAR" value="#ParentID#">
		<cfprocparam type="In" sqltype="INT" value="#val(objTypeID)#">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objID#">
		<cfprocresult name="ListAttributes">	
	</cfstoredproc>
	<cfif objID NEQ "0">
		<!--- if we have a product number we need to see if the attributes associated with it have changed and update if so ----> 
		<cfquery name="getthisobjAttributes" datasource="#DSNADMIN#">
			SELECT *
			FROM tblContentObjectAttributes
			WHERE objID = '#objID#'
		</cfquery>
	</cfif>
	
	<cfloop index="fieldname" list="#attributes.fieldnames#">
		<cfif Left(fieldname,2) EQ 'a_'>
			<!--- its an attribute field value so we need to add/update/delete the values --->
			<cfset notfound = 1><!--- used to check if its an existing value or new --->
			<cfset tmpAtrID = Right(fieldname,Len(fieldname)-2)>
			<cfset tmpformval = attributes[fieldname]>
			
			<!--- get the name of the attribute so we can update the values on the opener page --->
			<cfquery name="atrnamecheck" dbtype="query">
				SELECT DISTINCT objAttributeName
				FROM ListAttributes
				WHERE objAttributeID = #tmpAtrID#
			</cfquery>	
			<cfset tmpAtrName = atrnamecheck.objAttributeName>
			<cfset Newformval1 = tmpAtrName & " - " & tmpformval>
			<cfset Newformval2 = tmpAtrID & " - " & tmpAtrName & " - " & tmpformval>
			
			<cfif objID NEQ "0">
		
				<!--- if we have a product number we need to see if the attributes associated with it have changed and update if so ----> 
				<cfloop query="getthisobjAttributes">
					<cfif tmpAtrID EQ getthisobjAttributes.objAttributeID>
						<!--- the Product has a value for this attribute --->
	
						<cfif tmpformval NEQ getthisobjAttributes.objAttributeValue>
							<!--- the value for this attribute has been changed --->
							<cfif tmpformval NEQ "" AND tmpformval NEQ "n/a" AND tmpformval NEQ "Add New">
								<!--- update the value ---->
								<cfquery name="updateAttributes" datasource="#DSN#">
								    UPDATE tblContentObjectAttributes
								    SET  objAttributeValue = '#tmpformVal#'
									WHERE objAttributeID='#tmpatrID#' and objID='#objID#'
								</cfquery>
							<cfelse>
								<!--- delete the value --->
								<cfquery name="updateAttributes" datasource="#DSNADMIN#">
								    DELETE tblContentObjectAttributes
									WHERE objAttributeID='#tmpAtrID#' and objID='#objID#'
								</cfquery>
							</cfif>
							<cfset session.message="The Attributes values have been updated.">				
						</cfif>
						<cfset notfound = 0>
					</cfif>
				</cfloop>
			</CFIF>
		<!---cfelse>< the object ID is not defined--->
		
			<cfif old_attribute_values NEQ "">			
				<cfset cnt = 0>
				<cfloop index="oldformval" list="#old_attribute_values#">
					<cfset cnt = cnt + 1> 
					<cfset oldAtrID = Left(oldformval,Find(" - ",oldformval)-1)>
					<cfif tmpAtrID EQ oldAtrID>
						<cfset notfound = 0>						
						<!--- the Product has a value for this attribute --->
						
						<cfif tmpformval EQ "" OR tmpformval EQ "n/a">
							<!--- delete the value ---------------->
							<cfset old_attribute_values = ListDeleteAt(old_attribute_values,cnt)>
							<cfoutput>
							<Script language="JavaScript">
								theform = window.opener.editform.attributes
								for(x=0;x<theform.options.length;x++){
									oldAtrID = theform.options[x].value.substring(0,theform.options[x].value.indexOf(' - '))
									if(oldAtrID == '#tmpAtrID#'){
										theform.options[x] = null
										break
									}
								}
							</SCRIPT>
							</cfoutput>
						<cfelse>
							<!--- update the value --------------->
							<cfset old_attribute_values = ListDeleteAt(old_attribute_values,cnt)>
							<cfset old_attribute_values = ListAppend(old_attribute_values,Newformval2)>
							<cfoutput>
							<Script language="JavaScript">
								theform = window.opener.editform.attributes
								foundit = false
								for(x=0;x<theform.options.length;x++){
									oldAtrID = theform.options[x].value.substring(0,theform.options[x].value.indexOf(' - '))
									if(oldAtrID == '#tmpAtrID#'){
										foundit = true
										window.opener.setoption(x,'#Newformval1#','#Newformval2#');
										break
									}
								}
								if(foundit == false){
									theform = window.opener.editform.attributes
									window.opener.setoption(theform.options.length,'#Newformval1#','#Newformval2#');
								}
							</SCRIPT>
							</cfoutput>
						
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
				
			<!--- /cfif--->
			<cfif notfound EQ 1 AND tmpformval NEQ "" AND tmpformval NEQ "n/a" AND tmpformval NEQ "Add New">
				<!--- this attribute ID already exists in the types DB but this object does not have a value for it - add one --->
				<cfif objID NEQ "0">
					<cfquery name="updateAttributes" datasource="#DSN#">
					    INSERT INTO tblContentObjectAttributes
					    (objAttributeValue,objAttributeID,objID)
						Values('#tmpformVal#',#tmpAtrID#,'#objID#')
					</cfquery>
				</cfif>
				
				<cfset old_attribute_values = ListAppend(old_attribute_values,Newformval2)>
				<cfoutput>
				<Script language="JavaScript">
					theform = window.opener.editform.attributes
					window.opener.setoption(theform.options.length,'#Newformval1#','#Newformval2#');
				</SCRIPT>
				</cfoutput>
				
				<cfset session.message="The Attributes values have been added.">	
			</cfif>
		</cfif>
	</cfloop>
</cfif>

<cfif IsDefined("session.message") AND session.message NEQ "">
	<cfoutput>
	<Script language="JavaScript">
		alert("#session.message#")
	</SCRIPT>
	</cfoutput>
	<cfset session.message = ""> 
</cfif>

	<cfstoredproc procedure="Contentobject_getAttributes" datasource="#DSN#">
		<cfprocparam type="In" sqltype="VARCHAR" value="#ParentID#">
		<cfprocparam type="In" sqltype="INT" value="#objTypeID#">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objID#">
		<cfprocparam type="In" sqltype="VARCHAR" value="#namesonly#">
		<cfprocresult name="ListAttributes">
	</cfstoredproc>

<cfquery name="atrcnt" dbtype="query">
	SELECT objAttributeID
	FROM ListAttributes
	GROUP BY objAttributeID
</cfquery>
<cfquery name="getobjAttributes" datasource="#DSN#">
	SELECT *
	FROM tblContentObjectAttributes
	WHERE objID = <cfqueryparam sqltype="VARCHAR" value="#objID#">
</cfquery>

<script language="JavaScript">

function getoption(formname){
	if (formname.options[formname.options.selectedIndex].value == 'Add New') {
		newname = window.prompt('Please enter the value for the option you would like to add to this attribute.')
		if(newname != null && newname != "undefined"){
			formname.options[formname.options.length] =	new Option(newname, newname);
			formname.selectedIndex = formname.options.length -1	
		}
	}
}

function addvalues(){
	if(window.opener){
		theform = window.opener.editform.attributes
		tmpvalues = ""
		for(x=0;x<theform.options.length;x++){
			if(theform.options[x].value != '') tmpvalues = tmpvalues + theform.options[x].value + ","
		}
		document.form1.old_attribute_values.value = tmpvalues
	}
}

</script>
<link rel="STYLESHEET" type="text/css" href="/_styles.css">
</head>

<body onload="addvalues()">

<form action="<cfoutput>#cgi.script_name#</cfoutput>" method="post" enctype="multipart/form-data" name="form1" id="form1" onSubmit="return addvalues()">
<table width="100%" align="center" border="0" cellpadding="0" cellspacing="3">
	<tr>
		<td width="50%" align="center" valign="top" class="grayboxbody">
			<table width="100%" border="0" cellpadding="0" cellspacing="3" class="tiny">
				<tr class="grayboxheader">
					<td>Name</td>
					<td>Values</td>
					<td>Group</td>
					<td><font size="1">Comp</font></td>
					<td><font size="1">Sort</font></td>
				</tr>
			<cfset cnt=1>
			<cfset tmpAtrCount = 0>
			<cfset rcolspan = 1>
			

			<cfloop condition="cnt LTE ListAttributes.Recordcount">
				<cfset tmpAtrID = ListAttributes.objAttributeID[cnt]>
				<cfset tmpGroup = ListAttributes.objAttributeGroup[cnt]>
				<cfset tmpsortable = FindNoCase("sortable,",ListAttributes.objAttributeDetails[cnt])>
				<cfset tmpcomparable = FindNoCase("comparable,",ListAttributes.objAttributeDetails[cnt])>
				<!--- if the attribute is not meant to be seen here the system column will be 1 --->
				<cfif namesonly NEQ "0" OR ListAttributes.system NEQ 1>
					<cfset selected=0>
					<cfquery name="prdvalues" dbtype="query">
						SELECT *
						FROM getobjAttributes
						WHERE objAttributeID = #ListAttributes.objAttributeID[cnt]#
					</cfquery>
					<cfif prdvalues.recordcount GT 0>
						<cfset selectedval = prdvalues.objAttributeValue>
					<cfelse>
						<cfset selectedval = "">
					</cfif>
					<cfif objID EQ "0" AND old_attribute_values NEQ "">
						<!--- get the selected value from the form field --->
						<!--- cfoutput>#form.old_attribute_values# - #ListContains(form.old_attribute_values,ListAttributes.atrID[cnt])# - #ListAttributes.atrID[cnt]#</cfoutput--->
						<cfif ListContains(old_attribute_values,"#ListAttributes.objAttributeID[cnt]# - ") GT 0>
							<cfset tmpselectedval = ListGetAt(old_attribute_values,ListContains(old_attribute_values,ListAttributes.objAttributeID[cnt]&" - "))>
							<cfset tmpselectedval = Right(tmpselectedval,Len(tmpselectedval) - Find(" - ",tmpselectedval)-2)>
							<cfset selectedval = Right(tmpselectedval,Len(tmpselectedval) - Find(" - ",tmpselectedval)-2)>
						</cfif>
					</cfif>
					
					<cfoutput>
					<tr>
						<td valign="top"><!--- old_attribute_values - #old_attribute_values#-Selectedval=#selectedval#---><a href="/partnernet/contentobject/obj_atredit_cat.cfm?objAttributeID=#tmpAtrID#&objTypeID=#objTypeID#&pagefrom=#pagefrom#&old_attribute_values=#old_attribute_values#">#ListAttributes.objAttributeName[cnt]#</a><cfinvoke component="alpine-objects.Edit" method="Edit"
									table="tblContentObjectAttributeTypes"
									datafield="objAttributeName"
									keyfield="objAttributeID"
									keyvalue="#tmpAtrID#"
									formtype="text">
				 			<cfif ListAttributes.objAttributeUnits[cnt] IS NOT "">(#ListAttributes.objAttributeUnits[cnt]#)<cfinvoke component="alpine-objects.Edit" method="Edit"
									table="tblContentObjectAttributeTypes"
									datafield="objAttributeUnits"
									keyfield="objAttributeID"
									keyvalue="#tmpAtrID#"
									formtype="text"></cfif></td>
		
						<td valign="top">
							<select name="<cfoutput>a_#ListAttributes.objAttributeID[cnt]#</cfoutput>" OnChange="getoption(this)" class="tiny">	
 							<cfloop condition="listattributes.objAttributeID[cnt] EQ tmpAtrID">
								<cfif ListAttributes.objAttributeValue[cnt] NEQ ''>		
								<option value="#ListAttributes.objAttributeValue[cnt]#"<cfif selectedval EQ ListAttributes.objAttributeValue[cnt]> SELECTED<cfset selected=1>
								</cfif>>#ListAttributes.objAttributeValue[cnt]#</option>
								</cfif>	
								<cfset cnt=cnt+1>
							</cfloop>
								<cfif selectedval NEQ "" AND selected EQ 0>
								<option value="#selectedval#" SELECTED>#selectedval#</option>
								<cfset selected=1>
								</cfif>
								<option value=""<cfif selected EQ 0> SELECTED</cfif>>n/a</option>
								<option value="Add New">Add New</option>						
							</select></td>
							<td align="center" valign="top">#tmpGroup#</td>
							<td align="center" valign="top"><cfif val(tmpcomparable)>&nbsp;<strong>X</strong>&nbsp;</cfif></td>
							<td align="center" valign="top"><cfif val(tmpsortable)>&nbsp;<strong>X</strong>&nbsp;</cfif></td>
					</tr>
					<tr><td colspan="6" height="1" bgcolor="##FEFEFE"></td></tr>
					</cfoutput>
					<cfset tmpAtrCount = tmpAtrcount + 1>
					<cfif tmpAtrCount EQ ceiling(evaluate((atrcnt.recordcount)/2))><!--- add 2nd column --->
				</table>
			</td>
			<td>&nbsp;&nbsp;</td>
			<td width="50%" align="center" valign="top" class="grayboxbody">
				<table width="100%" cellpadding="0" cellspacing="3" border="0" class="tiny">
					<tr class="grayboxheader">
						<td>Name</td>
						<td>Values</td>
						<td>Group</td>
						<td><font size="1">Comp</font></td>
						<td><font size="1">Sort</font></td>
					</tr>
					<cfset rcolspan = 3>
					</cfif><!--- add 2nd column --->
				<cfelse>
					<cfset cnt=cnt+1> 
					<cfset tmpAtrCount = tmpAtrcount + 1>
				</cfif><!--- ListAttributes.system check --->
			</cfloop>
			</table>
		</td>
	</tr>
	<cfoutput>
	<cfif pagefrom EQ "">
	<tr>
		<td colspan="#rcolspan#" align="center" class="grayboxbody"><input type="submit" name="submit" value="Update Attributes" class="tiny"></td>
	</tr>
	<tr>
		<td colspan="#rcolspan#" height="10"></td>
	</tr>
	<cfelse>
	<tr>
		<td colspan="#rcolspan#" height="10"><input type="hidden" name="pagefrom" value="cat"></td>
	</tr>
	</cfif>
	<tr>
		<td colspan="#rcolspan#" class="grayboxbody">
			<table width="100%" cellpadding="0" cellspacing="3" border="0" class="tiny">
				<tr class="grayboxheader">
					<td colspan="5"><strong>Add A New Attribute</strong></td>
				</tr>
				<tr class="grayboxbody">
					<td colspan="2" valign="top">Name: <input type="text" name="NewAtrName" value="#HTMLEditFormat(NewAtrName)#" size="50" class="tiny"></td>
					<td colspan="2" valign="top">Value: <input type="text" name="NewAtrValue" value="#HTMLEditFormat(NewAtrValue)#" size="50" class="tiny"></td>
					<td colspan="1" valign="top">Units: <input type="text" name="NewUnits" value="#HTMLEditFormat(NewUnits)#" size="10" class="tiny"></td>
				</tr>
				<tr class="grayboxbody">
					<td valign="top">Comparable: <input type="checkbox" name="NewComparable" value="1" <cfif NewComparable EQ 1> Checked</cfif> class="tiny"></td>
					<td valign="top">Sortable: <input type="checkbox" name="NewSortable" value="1" <cfif NewSortable EQ 1> Checked</cfif> class="tiny"></td>
					<td valign="top">Display on Site: <input type="checkbox" name="NewDisplayOnSite" value="1" <cfif NewDisplayOnSite EQ 1> Checked</cfif> class="tiny"></td>
					<td valign="top">Operator: <input type="text" name="NewOperator" value="#NewOperator#" size="5" class="tiny"></td>
					<td valign="top">Priority: <input type="text" name="NewPriority" value="#NewPriority#" size="5" class="tiny"></td>
				</tr>
				<tr class="grayboxbody">
					<td colspan="5">
						<table width="100%" cellpadding="0" cellspacing="0" border="0">
							<tr class="grayboxbody">
								<td valign="top">Description:</td>
								<td><textarea cols="75" rows="5" name="Description">#HTMLEditFormat(NewDescription)#</textarea></td>
							</tr>
							<tr class="grayboxbody">
								<td valign="top">Group:</td>
								<cfquery name="Grouplist" dbtype="query">
									SELECT Distinct objAttributeGroup
									FROM ListAttributes
								</cfquery>
								<td>
								<Select name="NewAtrGroup" OnChange="getoption(this)" class="tiny">
									<option value="">Default</option>
								<cfloop query="Grouplist">
									<cfif Grouplist.objAttributeGroup NEQ "">
									<option value="#Grouplist.objAttributegroup#">#Grouplist.objAttributegroup#</option>
									</cfif>
								</cfloop>
									<option value="Add New">Add New</option>
								</SELECT>
								</td>
							</tr>
						</table>
					</td>
				</tr>
				
			</table>
		</td>
	</tr>
	<tr>
		<td colspan="#rcolspan#" align="center" class="grayboxbody"><input type="submit" name="submit" value="Add New Attribute" class="tiny"></td>
	</tr>	
</cfoutput>
</table>
<cfoutput>
<input type="hidden" name="objID" value="#objID#">
<input type="hidden" name="ParentID" value="#ParentID#">
<input type="hidden" name="objTypeID" value="#objTypeID#">
<input type="hidden" name="old_attribute_values" value="#old_attribute_values#">
</cfoutput>
</form>
</body>
</html>
<cfcatch>
			<cfoutput>#cfcatch.message#<br>
			#cfcatch.detail#</cfoutput>
</cfcatch>
</cftry>