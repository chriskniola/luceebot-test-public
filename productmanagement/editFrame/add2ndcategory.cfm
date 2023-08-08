<cfset screenID = "240">
<cfset recordhistory = 0>
<cfset showExt = 1>
<cfinclude template="/partnernet/shared/_header.cfm">
<script language="javascript" src="/partnernet/shared/javascripts/categorySearch.js"></script>
<cftry>

<cfparam name="attributes.submitparents" default="">
<cfparam name="attributes.catIDs" default="">
<cfparam name="attributes.objID" default="">

<cfif attributes.submitparents NEQ "">
	
	<cfinvoke component="alpine-objects.bookmarks" method="delete" childID="#attributes.objID#"></cfinvoke>
	
	<cfloop list="#attributes.catIDs#" index="parent">
		<cfinvoke component="alpine-objects.bookmarks" method="put" childID="#attributes.objID#" parentID="#parent#"></cfinvoke>
	</cfloop>

	<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
	<cfset productUpdatedPublisher.publish({ 'id': attributes.objID })>
		
	<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.objID#" value="Product category bookmarks added or updated"/>
	
	<cfset session.message = "The Category(s) have been added successfully.">
</cfif>

<cfoutput>
<script language="JavaScript">
	
	function DelCat(){
		thisform = document.MyForm
		for(i=0; i<thisform.catIDs.options.length; i++){
			if(thisform.catIDs.options[i].selected == true){
				thisform.catIDs.options[i] = null;
			}
		}
	}
		
	function addCat(values){
		var notFound;
		var myOptions = j$('##catIDs option');
		for(var x=0;x<values.length;x++){
			notFound = 1;
			for(var y=0;y<myOptions.length;y++){
				console.log(myOptions[y].value, 'val')
				if(myOptions[y].value == values[x].data.catID){
					notFound = 0;
				} 
			}		
			if(notFound){
				j$('##catIDs').append(new Option(values[x].data.catName, values[x].data.catID));
			}
		}
	};

	function selectall(){
		thisform = document.MyForm.catIDs
		for(x=0;x<thisform.options.length;x++){
			thisform.options[x].selected = true;
		}
		return true
	}

</script>
</cfoutput>

<cfoutput>
<!--- select PhotoID --->
<form method="post" action="#cgi.script_name#" name="MyForm" onsubmit="return selectall();">
<input type="hidden" name="objID" value="#attributes.objID#" />
<p>
<table>
	<tr>
		<td>
			<cfquery name="getprodname" datasource="#DSN#">
				SELECT manufacturer + ' ' + modelnumber as name
				FROM products
				WHERE ID = #attributes.objID#
			</cfquery>
			<strong>Currently Selected Parents for "#getprodname.name#".<br>
			<font size="-2">(does not include the parent for its actual home)</font></strong><br>
			<select name="catIDs" id="catIDs" size="10" multiple style="width: 350px;">
				<cfquery name="parents" datasource="#DSN#">
					SELECT b.parentID,pc.listname
					FROM tblBookmarkProducts b
					INNER JOIN productcategories pc ON pc.ID = b.parentID
					WHERE childID = #attributes.objID#
				</cfquery>
				<cfloop query="parents">
				<option value="#parents.parentID#">#parents.listname#</option>
				</cfloop>
			</select>
			<input type="button" name="Remove Selected" value="Remove Selected" onClick="DelCat()">
		</td>
	</tr>
	<tr>
		<td><br>
			<strong>Click below to add addition parents.</strong><br>
			<input type="button" name="Category" value="Add Parent Category" onClick="CatSearch.show(addCat);">
		</td>
	</tr>
</table>
</p>
<p>
	<input type="submit" name="submitparents" value="Submit" />
</p>
</form>	
</cfoutput>
	
<cfcatch>
<cfoutput>
#cfcatch.message#<br>
#cfcatch.detail#
</cfoutput>
</cfcatch>
</cftry>


<cfinclude template="/partnernet/shared/_footer.cfm">