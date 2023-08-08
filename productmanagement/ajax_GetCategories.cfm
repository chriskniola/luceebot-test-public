<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.criteria" default="">		

<cfif attributes.criteria EQ "last7days">
	<Cfset attributes.criteria = "">
	<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="25" returnvariable="products" datefrom="#dateformat(dateadd('d','-7',now()),'yyyy-mm-dd')#" resulttype="simple" domain="category" withproducts="true">

<cfelseif attributes.criteria EQ "last14days">
	<Cfset attributes.criteria = "">
	<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="25" returnvariable="products" datefrom="#dateformat(dateadd('d','-14',now()),'yyyy-mm-dd')#" resulttype="simple" domain="category" withproducts="true">

<cfelse>
	<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="25" returnvariable="products" resulttype="simple" domain="category" withproducts="true">

</cfif>

<cfset searchcategories = products.categories>

<cfoutput>[<cfloop query="searchcategories"><cfif searchcategories.currentrow GT 1>,</cfif>{n:'#replacelist(xmlformat(category),"&,/",",")#',i:'#categoryID#',t:'c'}</cfloop>]</cfoutput>
