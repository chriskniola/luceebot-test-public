<cfsetting showdebugoutput="false">
<cfparam name="attributes.manufacturer" default="">

<cfquery name="getmfginfo" datasource="#DSN#">
SELECT Manufacturer, COUNT(*) as Total, COUNT(CASE WHEN active = 1 THEN 1 END) as Active, COUNT(CASE WHEN active = 0 THEN 1 END) as Inactive
FROM Products WITH (NOLOCK)
WHERE Manufacturer = '#attributes.manufacturer#'
GROUP BY Manufacturer
</cfquery>

<cfoutput>[<cfloop query="getmfginfo">{m:'#replacelist(xmlformat(Manufacturer),"&,/",",")#',t:'#Total#',a:'#Active#',i:'#Inactive#'}</cfloop>]</cfoutput>