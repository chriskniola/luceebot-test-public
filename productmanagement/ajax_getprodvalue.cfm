<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfparam name="attributes.productID"> <!--- this is the alpine product that is being retrieved --->
<cfparam name="attributes.item"> <!--- the value that should be returned --->

<!--- get the vendor product associations for this product --->
<cfobject name="product" component="alpine-objects.product">
<cfinvoke component="#product#" method="get" objID="#attributes.productID#">

<cftry>
	<cfoutput>#product[attributes.item]#</cfoutput>
	<cfcatch><cfoutput>Attribute #attributes.item# does not exist.</cfoutput></cfcatch>
</cftry>