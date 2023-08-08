<cfsetting showdebugoutput="false" enablecfoutputonly="true">

<cfparam name="attributes.criteria" default="">		
<cfparam name="attributes.type" default="">	

<cfset args = {
	'criteria': attributes.criteria,
	'filter': attributes.type
}>

<cfif attributes.criteria EQ "last7days">
	<cfset args.append({
		'dateFrom': dateformat(dateadd('d','-7',now()),'yyyy-mm-dd'),
		'criteria': ''
	})>
<cfelseif attributes.criteria EQ "last14days">
	<cfset args.append({
		'dateFrom': dateformat(dateadd('d','-14',now()),'yyyy-mm-dd'),
		'criteria': ''
	})>
</cfif>

<cfset searchresources = new contexts.Product.DataAccess.DatabaseProductDocumentRepository().searchDocuments(argumentCollection=args)>
<cfset searchresources = searchresources.map(function(e) { 
	return {
		'n':'#xmlformat(arguments.e.resourceshortname)#',
		'i':'#arguments.e.resourceID#'
	};
})>

<cfoutput>#serializeJSON(searchresources)#</cfoutput>
