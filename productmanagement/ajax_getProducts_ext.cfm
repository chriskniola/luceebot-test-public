<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.criteria" default="">
<cfparam name="attributes.maxRows" default="50">
<cfparam name="attributes.startRow" default="0">
<cfparam name="attributes.filter" default="1">
<cfparam name="attributes.excludeIDs" default="">
<cfparam name="attributes.callback" default="evaluate">	
<cfparam name="attributes.incVendorSummary" default="true">	
<cfparam name="attributes.type" default="">	

<cfinvoke component="alpine-objects.product" method="search" returnvariable="products" argumentcollection="#attributes#">
<cfset searchProducts = products.products>
<cfoutput>
#HTMLEditFormat(attributes.callBack)#({recordCount: #products.productCount#, 
records: [<cfloop query="searchProducts"><cfif searchProducts.currentRow GT 1>,</cfif>{i:'#searchproducts.productID#',a:#searchproducts.active#,s:#searchproducts.score#,mfg:'#XMLFormat(searchproducts.manufacturer)#',mod:'#XMLFormat(searchproducts.modelnumber)#',ld:'#XMLFormat(searchproducts.listdescription)#',c:'#searchproducts.category#',sp:#val(searchproducts.alpinesaleprice)#,p:#val(searchproducts.alpineprice)#,q:#val(searchproducts.qtyavailable)#,oo:#val(searchproducts.qtyonorder)#,od:'#searchproducts.onorderdate#'}</cfloop>]})
</cfoutput>