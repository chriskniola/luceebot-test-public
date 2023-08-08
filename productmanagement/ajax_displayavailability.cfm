<cfsetting showdebugoutput="false">
<cfset screenID = "240">

<cfparam name="attributes.productID">

<cfinvoke component="#APPLICATION.user#" method="checkscreenpermission" returnvariable="success">
	<cfinvokeargument name="screenID" value="#screenID#">
</cfinvoke>


<cfobject name="thisproduct" component="alpine-objects.product">
<cfinvoke component="#thisproduct#" method="get" objID="#attributes.productID#" light="true" withcosting="false">

<cfoutput>#thisproduct.displayavailability().html#</cfoutput>