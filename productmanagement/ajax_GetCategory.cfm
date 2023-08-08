<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.categoryID" default="">		

<cfobject component="alpine-objects.productcategory" name="category">
<cfinvoke component="#category#" method="get" objID="#attributes.categoryID#">

<cfoutput>[{n:'#xmlformat(category.listname)#',i:'#CategoryID#',t:'c'}]</cfoutput>
