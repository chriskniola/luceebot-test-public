<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.criteria" default="">		
<!--- cfquery name="receivable" datasource="#DSN#">
	SELECT R.*, (SELECT sum(recoveredAmount) FROM tblReceivables_Receipts RR WHERE RR.objID = R.objID) AS recoverdAmount,
	FROM products P
	<cfif attributes.criteria NEQ "last7">
	
	<cfelse>
	WHERE description LIKE '%<cfqueryParam cfsqltype="cf_sql_varchar" value="#attributes.criteria#">%'
	OR listDesccription LIKE '%<cfqueryParam cfsqltype="cf_sql_varchar" value="#attributes.criteria#">%'
	OR modelNumber LIKE '%<cfqueryParam cfsqltype="cf_sql_varchar" value="#attributes.criteria#">%'
	OR DistributorNumber LIKE '%<cfqueryParam cfsqltype="cf_sql_varchar" value="#attributes.criteria#">%'
	</cfif>
</cfquery--->
<!--- 
<cfif attributes.criteria EQ 'last7days'>
<cfoutput>[{n:'Air Cleaners / Filters / Ventilation',i:'5',t:'c'},{n:'Alpine Home Air Products AHA091', i:'453056827', t:'p'},{n:'Honeywell, Inc. HR200B1005', i:'453058898', t:'p'},{n:'Honeywell HR200B 1005',i:'224',t:'p'},{n:'cat 67', i:'67', t:'c'}]</cfoutput>
<cfelse>
<cfoutput>[{n:'Air Cleaners / Filters / Ventilation',i:'5',t:'c'},{n:'Honeywell, Inc. HR200B1005', i:'453058898', t:'p'},{n:'Honeywell Y8150A', i:'453056667', t:'p'},{n:'Honeywell hr200b1005',i:'453055220',t:'p'},{n:'Aprilaire 6506', i:'453055573', t:'p'}]</cfoutput>
</cfif>
 --->

<cfif attributes.criteria EQ "last7days">
	<Cfset attributes.criteria = "">
	<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="25" returnvariable="products" datefrom="#dateformat(dateadd('d','-7',now()),'yyyy-mm-dd')#">

<cfelseif attributes.criteria EQ "last14days">
	<Cfset attributes.criteria = "">
	<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="25" returnvariable="products" datefrom="#dateformat(dateadd('d','-14',now()),'yyyy-mm-dd')#">

<cfelse>
	<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="25" returnvariable="products">

</cfif>

<cfset searchproducts = products.products>
<cfset searchcategories = products.categories>

<cfoutput>[<cfloop query="searchcategories"><cfif searchcategories.currentrow GT 1>,</cfif>{n:'#xmlformat(category)#',i:'#categoryID#',t:'c'}</cfloop><cfloop query="searchproducts"><cfif searchproducts.currentrow GT 1 OR searchcategories.recordcount GT 0>,</cfif>{n:'#xmlformat(manufacturer)# #xmlformat(modelnumber)#',i:'#productID#',t:'p'}</cfloop>]</cfoutput>
