<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfparam name="url.categoryIDs" default="67">
<cfparam name="url.productIDs" default="">
<cfparam name="url.photoIDs" default="">
<cfparam name="url.active" default="0"><!--- 1: acive only, 0: all --->
<cfparam name="url.obsolete" default="0"><!--- 1: all; 0: no obsolete --->


<cfstoredproc datasource="#DSN#" procedure="hierarchy_photos_getbycatprodresID">
	<cfprocparam sqltype="VARCHAR" value="#url.categoryIDs#">
	<cfprocparam sqltype="VARCHAR" value="#url.productIDs#">
	<cfprocparam sqltype="VARCHAR" value="#url.photoIDs#">
	<cfprocparam sqltype="BIT" value="#url.active#">
	<cfprocparam sqltype="BIT" value="#url.obsolete#">
	<cfprocresult name="catquery" resultset=1>
	<cfprocresult name="prdquery" resultset=2>
	<cfprocresult name="prdresquery" resultset=3>
</cfstoredproc>

<cffunction name="writecat">
<cfargument name="categoryID">
<cfargument name="name">
<cfargument name="photoID">
<cfargument name="active">
<cfset var getchildren = "">
<cfset var getProd = "">
<cfset var getcatresources = "">
<cfset var getprdresources = "">
	
	<cfoutput>{n:'#xmlformat(replacelist(arguments.name,"'",""))#',i:'#arguments.categoryID#',t:'c',r:[#arguments.photoID#],a:#val(arguments.active)#</cfoutput>
		
	<cfquery name="getchildren" dbtype="query">
	SELECT categoryID,name,parentlevel,photoID,active
	FROM catquery
	WHERE parent = #arguments.categoryID#
	ORDER BY parentlevel,parent,name
	</cfquery>

	<cfoutput>,c:[</cfoutput>
	<cfloop query="getchildren">
			<cfoutput>#writecat(getchildren.categoryID,getchildren.name,getchildren.photoID,getchildren.active)#<cfif getchildren.recordcount NEQ getchildren.currentRow>,</cfif></cfoutput>
	</cfloop>

	<cfquery name="getprod" dbtype="query">
	SELECT category,prdname,prdID,active
	FROM prdquery
	WHERE category = #arguments.categoryID#
	ORDER BY active DESC, prdname
	</cfquery>

	<cfloop query="getprod">
		<cfquery name="getprdresources" dbtype="query">
		SELECT photoID
		FROM prdresquery
		WHERE prdID = #prdID#
		</cfquery>
		<cfoutput>
			<cfif getchildren.recordcount GT 0 OR getprod.currentRow GT 1>,</cfif>{n:'#xmlformat(replacelist(prdname,"'",""))#',i:'#prdID#',t:'p',r:[#valuelist(getprdresources.photoID)#],c:[],a:#val(getprod.active)#}#chr(13)#
		</cfoutput>
	</cfloop>
	<cfoutput>]}</cfoutput>
</cffunction>



<cfquery name="distincttoplevel" dbtype="query">
SELECT DISTINCT categoryID,name,parentlevel,photoID,active,parent
FROM catquery
WHERE parentlevel = 1
ORDER BY parent,name
</cfquery>

<cfoutput>[<cfloop query="distincttoplevel"><cfif distincttoplevel.currentRow GT 1>,</cfif>#writecat(distincttoplevel.categoryID,distincttoplevel.name,distincttoplevel.photoID,distincttoplevel.active)#</cfloop>]</cfoutput>
