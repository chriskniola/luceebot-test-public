<cfset screenID = "240">

<cfinclude template="/partnernet/shared/_header.cfm">
<cfscript>
	endpoint = CreateObject("java", "java.lang.System").getEnv('imsEndpoint');
	urlPath = 'inventory-items';
	finalPath = "#endpoint#/#urlPath#";
</cfscript>
<cfoutput>
	<div class="wrap" style="height: calc(100vh - 30px)">
		<iframe id="ims" class="child" src="#finalPath#" frameborder="0" style="width: 100%;height: calc(100vh - 30px)"></iframe>
	</div>
</cfoutput>
<cfinclude template="/partnernet/shared/_ims_footer.cfm">
