<cfset screenID = "240">
<cfset recordhistory = 0>

<cfscript>
	endpoint = CreateObject("java", "java.lang.System").getEnv('imsEndpoint');
	urlPath = 'alpine-item-association/#url.productID#';
	finalPath = "#endpoint#/#urlPath#";
	var isKit = queryExecute("
			SELECT * FROM tblproductkits
			WHERE kitmasterprodID = :productID
		", {
			productID: { value: url.productID, sqltype: "INT"}
		}, {datasource = DSN}).recordcount;
</cfscript>
<cfoutput>
	<div class="wrap">
		<cfif isKit>
			<h2 style="text-align: center;">This product is a kit.</h2>
			<p style="text-align: center;">Edit the kit items to change inventory item links.</p>
		<cfelse>
			<iframe id="ims" class="child" src="#finalPath#" frameborder="0" style="width: 100%;height: 100%"></iframe>
		</cfif>
  </div>
</cfoutput>
