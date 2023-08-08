<!-----------------------------------------------------------
NAME: consolidateproducts.cfm
PURPOSE: for a given vendorID / vendor product number, consolidate all purchases to the new product
DATE CREATED: 2007-4-4
AUTHOR: JT
CHANGE HISTORY: 
----------------------------------------------------------->

<cfparam name="attributes.vendorID">
<cfparam name="attributes.vendorproductnumber">

<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
SELECT *
FROM products
WHERE distributorID = '#attributes.vendorID#'
	AND distributornumber = '#attrbutes.vendorproductnumber#'
</cfquery>


