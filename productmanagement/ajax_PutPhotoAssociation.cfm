<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.categoryID" default="">		
<cfparam name="attributes.productID" default="">			
<cfparam name="attributes.photoID" default="">
<cfparam name="attributes.status" default="">
<cfparam name="attributes.isMobileImage" default=false>

<cfset productPhotoRepository = new contexts.Product.DataAccess.DatabaseProductPhotoRepository()>
<cftry>
	<cfif !isEmpty(attributes.productID) AND attributes.status EQ 1>
		<cfset productPhotoRepository.associateToProduct(photoID=attributes.photoID, productID=attributes.productID)>
		<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
		<cfset productUpdatedPublisher.publish({ 'id': attributes.productID })>
		<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Photo ID #attributes.photoID# association added"/>
	</cfif>

	<cfif !isEmpty(attributes.categoryID) AND !attributes.isMobileImage AND attributes.status EQ 1>
		<cfset productPhotoRepository.associateToCategory(attributes.PhotoID,attributes.categoryID)>
	</cfif>

	<cfif !isEmpty(attributes.categoryID) AND attributes.isMobileImage AND attributes.status EQ 1>
    	<cfset productPhotoRepository.associateToMobileCategory(attributes.PhotoID, attributes.categoryID)>
	</cfif>

	<cfif !isEmpty(attributes.productID) AND attributes.status EQ 0>
		<cfset productPhotoRepository.deleteProductAssociation(attributes.productID, attributes.photoID)>
		<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
		<cfset productUpdatedPublisher.publish({ 'id': attributes.productID })>
		<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Photo ID #attributes.photoID# association removed"/>
	</cfif>

	<cfif !isEmpty(attributes.categoryID) AND attributes.status EQ 0>
		<cfset productPhotoRepository.deleteCategoryAssociation(attributes.categoryID)>
		<cfset createObject('objects.productCategory').setPhotoID(attributes.categoryID)>
	</cfif>

	<cfoutput>true</cfoutput>
	<cfcatch>
		<cfmail subject="basdlf" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html">
			<cfdump var = "#cfcatch#">
		</cfmail>
		<cfoutput>false</cfoutput>
	</cfcatch>
</cftry>