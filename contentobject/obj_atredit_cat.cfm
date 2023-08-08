<cfset screenID = "350">
<cfparam name="submit" default="">
<cfparam name="objAttributeID" default="">
<cfparam name="objTypeID" default="0">
<cfparam name="objAttributeValue" default="">
<cfparam name="objAttributeName" default="">
<cfparam name="objAttributeOperator" default="=">
<cfparam name="objAttributeunits" default="">
<cfparam name="objAttributepriority" default=1>
<cfparam name="objAttributeDescription" default=0>
<cfparam name="objAttributeGroup" default="">

<cfparam name="atrsortable" default=0>
<cfparam name="atrcomparable" default=0>
<cfparam name="atrDisplayonsite" default=0>
<cfparam name="atrMinMaxRange" default=1>
<cfparam name="atrExclusiveResult" default=0>
<cfparam name="objID" default="0">
<cfparam name="Pagefrom" default="">
<cfparam name="old_attribute_values" default="">

<cfset lastpage = "/partnernet/contentobject/obj_atredit.cfm?objTypeID=#objTypeID#&objID=#objID#&old_attribute_values=#old_attribute_values#">
<cfif pagefrom NEQ "">
	<cfset lastpage = lastpage & "&pagefrom=cat">
</cfif>

<cfset objAttributeDetails = ",">
<cfif INT(atrsortable)><cfset objAttributeDetails = objAttributeDetails & "Sortable,"></cfif>
<cfif INT(atrcomparable)><cfset objAttributeDetails = objAttributeDetails & "Comparable,"></cfif>
<cfif INT(atrDisplayonsite)><cfset objAttributeDetails = objAttributeDetails & "DisplayonSite,"></cfif>
<cfif INT(atrMinMaxRange)><cfset objAttributeDetails = objAttributeDetails & "MinMaxRange,"></cfif>
<cfif INT(atrExclusiveResult)><cfset objAttributeDetails = objAttributeDetails & "ExclusiveResult,"></cfif>

<cfif submit EQ "Back to Previous Page">

	<cflocation url="#lastpage#" addtoken="no">

<cfelseif submit EQ "Update Attribute">
	
	<cfstoredproc procedure="contentobjects_modify_attribute" datasource="#DSN#">
		<cfprocparam type="InOut" sqltype="INT" variable="tmpAtrID" value="#objAttributeID#">
		<cfprocparam type="InOut" sqltype="VARCHAR" variable="newobjID" value="#objID#">
		<cfprocparam type="In" sqltype="INT" value="#INT(objTypeID)#" null="No">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objAttributeValue#" null="No">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objAttributeName#" null="No">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objAttributeOperator#" null="No">
		<cfprocparam type="InOut" sqltype="VARCHAR" variable="tmpAttributeUnits" value="#objAttributeunits#">
		<cfprocparam type="In" sqltype="INT" value="#INT(objAttributepriority)#" null="No">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objAttributeDescription#">
		<cfprocparam type="In" sqltype="INT" value="">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objAttributeGroup#">
		<cfprocparam type="In" sqltype="VARCHAR" value="#objAttributeDetails#">
	</cfstoredproc>
	
	<cfset session.message = "The attribute has been updated.">
	
	<cflocation url="#lastpage#" addtoken="no">

<cfelseif submit EQ "Delete Attribute">

	<cfquery name="delattribute" datasource="#DSNADMIN#">
		Delete tblContentObjectAttributes
		WHERE objAttributeID = <cfqueryparam sqltype="INT" value="#objAttributeID#">
	</cfquery>
	<cfquery name="delattributetype" datasource="#DSNADMIN#">
		Delete tblContentObjectAttributesTypes
		WHERE objAttributeID = <cfqueryparam sqltype="INT" value="#objAttributeID#">
	</cfquery>
	<cfset session.message = "The attribute has been deleted.">
	<cflocation url="#lastpage#" addtoken="no">

</cfif>

<cfquery name="getattribute" datasource="#DSNADMIN#">
	Select *
	FROM tblContentObjectAttributeTypes
	WHERE objAttributeID = <cfqueryparam sqltype="INT" value="#objAttributeID#">
</cfquery>
<link rel="STYLESHEET" type="text/css" href="/_styles.css">
</head>
<Script language="javascript">
function validate(thisform){
	if(thisform.objAttributeName.value.length < 1){
		alert("Name is a required field!");
		thisform.objAttributeName.focus();
		return false;
	} 

	return true;
}


function getoption(formname){
	if (formname.options[formname.options.selectedIndex].value == 'Add New') {
		newname = window.prompt('Please enter the value for the option you would like to add to this attribute.')
		if(newname != null && newname != "undefined"){
			formname.options[formname.options.length] =	new Option(newname, newname);
			formname.selectedIndex = formname.options.length -1
		}
	}
}

function deleteprompt(){
	return confirm("Are you sure you want to delete this \"attribute type\" and any \"attribute values\" of this type curently associated with objects?")
}

</SCRIPT>
<body>

<cfif FindNoCase("Sortable,",getattribute.objAttributeDetails)><cfset atrsortable = 1></cfif>
<cfif FindNoCase("Comparable,",getattribute.objAttributeDetails)><cfset atrcomparable = 1></cfif>
<cfif FindNoCase("DisplayonSite,",getattribute.objAttributeDetails)><cfset atrDisplayonsite = 1></cfif>

<cfoutput query="getattribute">
<form action="#cgi.Script_Name#" method="post" enctype="multipart/form-data" name="form1" id="form1" onSubmit="return validate(this);">
<table width="100%" align="center" border="0" cellpadding="0" cellspacing="3">
	<tr>
		<td colspan=2 class="grayboxbody">
			<table width="100%" cellpadding="0" cellspacing="3" border="0" class="tiny">
				<tr class="grayboxheader">
					<td colspan="5"><strong>Update Attribute</strong></td>
				</tr>
				<tr class="grayboxbody">
					<td colspan="4">
						<table width="100%" cellpadding="0" cellspacing="0" border="0">
							<tr class="grayboxbody">
								<td colspan="2">Name: <input type="text" name="objAttributeName" value="#HTMLEditFormat(getattribute.objAttributeName)#" size="50" class="tiny"></td>
								<td colspan="2">
								</td>
							</tr>
						</table>
					</td>	
				</tr--->
				<tr class="grayboxbody">
					<td colspan="4">
						<table width="100%" cellpadding="0" cellspacing="0" border="0">
							<tr class="grayboxbody">
								<td colspan="1">Units: <input type="text" name="objAttributeunits" value="#HTMLEditFormat(getattribute.objAttributeunits)#" size="10" class="tiny"></td>
								<td>Display on Site: <input type="checkbox" name="atrDisplayOnSite" value="1" <cfif atrDisplayOnSite EQ 1> Checked</cfif> class="tiny"></td>
								<td>Comparable: <input type="checkbox" name="atrComparable" value="1" <cfif atrComparable EQ 1> Checked</cfif> class="tiny"></td>
								<td>Sortable: <input type="checkbox" name="atrSortable" value="1" <cfif atrSortable EQ 1> Checked</cfif> class="tiny"></td>
							</tr>
						</table>
					</td>
				</tr>
				<tr class="grayboxbody">
					<td colspan="4">
						<table width="100%" cellpadding="0" cellspacing="0" border="0">
							<tr class="grayboxbody">
								<cfquery name="Grouplist" datasource="#DSNADMIN#">
									SELECT Distinct objAttributeGroup
									FROM tblContentObjectAttributeTypes
									WHERE objTypeID = #getattribute.objTypeID#
								</cfquery>
								<td valign="top">Group:
								<Select name="objAttributeGroup" OnChange="getoption(this)" class="tiny">
									<option value="">Default</option>
								<cfloop query="Grouplist">
									<cfif Grouplist.objAttributeGroup NEQ "">
									<option value="#Grouplist.objAttributeGroup#"<cfif getattribute.objAttributeGroup EQ Grouplist.objAttributeGroup> SELECTED</cfif>>#Grouplist.objAttributeGroup#</option>
									</cfif>
								</cfloop>
									<option value="Add New">Add New</option>
								</SELECT></td>
								<td>Priority: <input type="text" name="objAttributepriority" value="#HTMLEditFormat(getattribute.objAttributepriority)#" size="5" class="tiny"></td>
								<td>Operator: <input type="text" name="objAttributeOperator" value="#HTMLEditFormat(getattribute.objAttributeOperator)#" size="5" class="tiny"></td>
							</tr>
						</table>
					</td>
				</tr>
				<tr class="grayboxbody">
					<td colspan="4">
						<table width="100%" cellpadding="0" cellspacing="0" border="0">
							<tr class="grayboxbody">
								<td valign="top">Description:</td>
								<td><textarea cols="75" rows="5" name="objAttributeDescription">#HTMLEditFormat(getattribute.objAttributeDescription)#</textarea></td>
							</tr>
						</table>
					</td>
				</tr>		
			</table>
		</td>
	</tr>
	<tr>
		<td align="center" class="grayboxbody"><input type="submit" name="submit" value="Update Attribute" class="tiny"></td>
		<td align="center" class="grayboxbody"><input type="submit" name="submit" value="Delete Attribute" class="tiny" onClick="return deleteprompt();"></td>
	</tr>	
</table>
<div align="center"><input type="submit" name="submit" value="Back to Previous Page" class="tiny"></div>
<input type="hidden" name="objAttributeID" value="#getattribute.objAttributeID#">
<input type="hidden" name="objTypeID" value="#getattribute.objTypeID#">
<input type="hidden" name="old_attribute_values" value="#old_attribute_values#">
<cfif pagefrom NEQ "">
<input type="hidden" name="pagefrom" value="#pagefrom#">
</cfif>

</form>
</body>
</html>
</cfoutput>