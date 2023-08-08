<cfsetting showdebugoutput="false">
<cfparam name="attributes.productID" default="">
<cfparam name="attributes.cost" default="">
<cfparam name="attributes.modp" default="">

<cfif attributes.cost EQ "">

	<cfinvoke component="alpine-objects.productpricing"
		method="vendcost"
		productID="#productID#"
		usevendorratio="1"
		returnvariable="result"
		/>
	
	<cfset attributes.cost = result.avgcost.productcost + result.avgcost.shipcost>
	
</cfif>

<cfinvoke 
	component="alpine-objects.productpricing" 
	method="returnretail" 
	cost="#attributes.cost#" 
	objID="#attributes.productID#" 
	modp="#attributes.modp#" 
	returnvariable="priceresult"
	/>

<cfoutput>#priceresult.retailprice#</cfoutput>