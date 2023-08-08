<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.criteria" default="">
<cfparam name="attributes.type" default="">

	<cfquery name="photoSearch" datasource="#DSN#">
		SELECT DISTINCT TOP 50 ph.photoID, ph.photoPath
		FROM tblPhotos ph
		LEFT JOIN tblProductPhotos pp ON ph.photoID = pp.photoID
		LEFT JOIN Products p ON p.ID = pp.prdID
		WHERE
			<cfif attributes.criteria EQ "last7days">
				CONVERT(DATE,ph.photoCreated) > <cfqueryparam sqltype="DATE" value="#dateAdd('d', -7, now())#">
			<cfelseif attributes.type == 'p'>
				CONVERT(VARCHAR,pp.prdID) = <cfqueryparam sqltype='VARCHAR' value='#attributes.criteria#'>
			<cfelseif attributes.type == 'c'>
				CONVERT(VARCHAR,p.category) = <cfqueryparam sqltype='VARCHAR' value='#attributes.criteria#'>
			<cfelse>
				ph.photoshortdescription LIKE <cfqueryparam sqltype='VARCHAR' value='%#attributes.criteria#%'>
				OR ph.photopath LIKE <cfqueryparam sqltype='VARCHAR' value='%#attributes.criteria#%'>
			</cfif>
	</cfquery>

<cfoutput>[<cfloop query="photoSearch"><cfif photoSearch.currentrow GT 1>,</cfif>{n:'#URLEncodedFormat(photoSearch.photoPath)#',i:'#photoSearch.photoID#'}</cfloop>]</cfoutput>
