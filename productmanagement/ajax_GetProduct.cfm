<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.productID" default="">		

<cfobject component="alpine-objects.product" name="product">
<cfinvoke component="#product#" method="get" objID="#attributes.productID#">

<cfoutput>[{n:'#xmlformat(product.manufacturer)# #xmlformat(product.modelnumber)#',i:'#productID#',t:'p'}]</cfoutput>
