<!---  
name: listassociations.cfm
Created By: Jason Todd
Created On: 2007-6-7
Notes: 


Modified By: 
Modified On: 
Notes: 

--->

<cfset screenID = "240">
<cfset recordhistory = 0>
<cfset popup=1>

<cfinclude template="/partnernet/shared/_header.cfm">

<!--- the master product that we're adding associations to --->
<cfparam name="attributes.productID" default="">
<cfparam name="attributes.assocproductID" default="">
<cfparam name="attributes.type" default="">
<cfparam name="attributes.step" default="1">


<cfobject component="alpine-objects.product" name="thisproduct">
<cfinvoke component="#thisproduct#" method="get" objID="#attributes.productID#"></cfinvoke>

<cfif IsDefined("attributes.add") AND attributes.productID IS NOT attributes.assocproductID>
	<cfif IsDefined("attributes.type") AND ListLen(attributes.type) EQ ListLen(attributes.assocproductID)>
		
		<cfloop from="1" to="#ListLen(attributes.assocproductID)#" index="i">
			
			<cfif ListGetAt(Attributes.assocproductID,i) GT 0>
				
				<cfinvoke component="#thisproduct#" method="PutProductAssociation" relative="#ListGetAt(attributes.assocproductID,i)#" type="#ListGetAt(attributes.type,i)#">
			</cfif>
		</cfloop>
		
		<cfinvoke component="#thisproduct#" method="get" objID=attributes.productID>

	</cfif>
</cfif>


<cfstoredproc procedure="cfc_getAllproducts_GroupedBy_CategoryID" datasource="#DSN#">
<cfprocresult name="listProducts">
</cfstoredproc>


<!--- display current kit --->
<!--- productID & details, number used in kit --->
<cfquery name="getassocproducts" datasource="#DSN#" dbtype="ODBC">
SELECT tblProductAssociations.*,products.manufacturer,products.modelnumber
FROM tblProductAssociations INNER JOIN products ON tblProductAssociations.prdRelative = products.ID
WHERE prdID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#attributes.productID#">
</cfquery>

<cfset excludeIDs = ValueList(getassocproducts.prdRelative, ",")>
<cfset excludeIDs = listappend(excludeIDs,attributes.productID,",")>

<div class="large"><A href="javascript:closethiswin();">Click to Close</A></div>

<script language="javascript">
function closethiswin() {
	if (window.opener && !window.opener.closed)
			window.opener.location.reload();
			
		window.close();
}
</script>

<cfif attributes.step EQ 1>
	<cfoutput>
		<!--- products --->
		<form method="post" action="#cgi.script_name#" name="tmpForm">
		<input type="hidden" name="step" value="1" />
		<input type="hidden" name="productID" value="#attributes.productID#" />
			 You are editing associations for <strong>#thisproduct.manufacturer# #thisproduct.modelnumber#</strong> (#thisproduct.listdescription#)<br><br>
			 <table cellpadding="2" cellspacing="0" border="0">
			 	<tr>
					<td class="normal"></td>
					<td class="normal">Associated Product</td>
					<td class="normal">Association Type</td>
				</tr>
				
				<cfloop query="getassocproducts">
				 	<tr>
						<td class="normal"></td>
						<td class="normal">
							#manufacturer# #modelnumber#
						</td>
						<td class="normal">
							#asctype#
						</td>
					</tr>
				 </cfloop>
				 
			 	<tr>
					<td class="normal">
						<!--- <input type="submit" name="add" value="#getassocproducts.ID#"> --->
					</td>
					<td class="normal">
						 <div id="productdescription"></div>
						 <a href="javascript:openwin('/templates/scanproduct.cfm?sendID=ProductID&excludeIDs=#excludeIDs#&formname=tmpForm&senddescription=productdescription','');">Add association</a>
						 <input type="hidden" name="AssocProductID" id="ProductID">
					</td>
					<td class="normal">
						<select name="Type">
							<option value="Alternative Product">Alternative Product</option>
						</select>
					</td>
				</tr>
				
			 	<tr>
					<td class="normal"></td>
					<td class="normal">
						<input type="submit" name="add" value="Update Associations"><br><br>
						
					</td>
					<td class="normal"></td>
				</tr>
				 
			 </table>
		</form>
	</cfoutput>
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">





