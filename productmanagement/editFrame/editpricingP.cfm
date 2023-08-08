
<cfset screenID = "240">
<cfsetting showdebugoutput="no" requestTimeout="300">

<cfparam name="attributes.productID">
<cfparam name="attributes.objID" default="#attributes.productID#">

<cfset popup=1>
<cfset showPrototype=1>
<cfset showEXT=1>
<cfset showjQuery=1>

<cfinclude template="/partnernet/shared/_header.cfm">
	
	<cflock scope="session" timeout="30" throwontimeout="true">
	
	<cfinvoke component="ajax.sessionless.lock" method="putlock" userID="#getCurrentUser()#" objID="#attributes.productID#" returnvariable="lockresult" onChange="checkLock"/>
	<cfoutput>#lockresult.js#</cfoutput>
	
	<input type="hidden" name="productID" value="#attributes.productID#" />
	<input type="hidden" name="objID" value="#attributes.productID#" />
	
	<cfinvoke component="alpine-objects.productpricing"
		method="singleproductpricing"
		productID="#attributes.productID#"
		returnvariable="result"
		/>
	
	</cflock>
	
<cfinclude template="/partnernet/shared/_footer.cfm">