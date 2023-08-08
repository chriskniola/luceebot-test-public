<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.categoryID" default="">		
<cfparam name="attributes.productID" default="">			
<cfparam name="attributes.resourceID" default="">
<cfparam name="attributes.status" default="">

<cftry>
	<cfif !val(attributes.resourceID)>
		<cfthrow message="ResourceID is required.">
	</cfif>
	
	<cfset productDocumentRepository = new contexts.Product.DataAccess.DatabaseProductDocumentRepository()>
	
	<cfif val(attributes.productID)>
		<cfif val(attributes.status)>
			<cfset productDocumentRepository.associateToProduct(documentID=attributes.resourceID, productID=attributes.productID)>					
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Resource ID #attributes.resourceID# association added"/>
		<cfelse>
			<cfset productDocumentRepository.deleteProductAssociation(documentID=attributes.resourceID, productID=attributes.productID)>
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Resource ID #attributes.resourceID# association removed"/>
		</cfif>
	</cfif>

	<cfif val(attributes.categoryID)>
		<cfif val(attributes.status)>
			<cfset productDocumentRepository.associateToCategory(documentID=attributes.resourceID, categoryID=attributes.categoryID)>
		<cfelse>
			<cfset productDocumentRepository.deleteCategoryAssociation(documentID=attributes.resourceID, categoryID=attributes.categoryID)>
		</cfif>					
	</cfif>

	<cfoutput>true</cfoutput>
	
	<cfcatch>
		<cfmail subject="basdlf" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html">
			<cfdump var = "#cfcatch#">
		</cfmail>
		<cfoutput>false</cfoutput>
	</cfcatch>
</cftry>