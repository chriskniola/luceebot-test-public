<cfsetting showdebugoutput="no" requesttimeout="60">

<cfset screenid = "1090">
<cfset showjQuery = 1>
<cfset mycols = "Manufacturer,ModelNumber,Name,ListDescription,Description,BoxContents,IncludesFreeShipping,IncludesFreeVideo,IncludesContractorAssistance,Priority,PackQuantity,AlpineCost,IsOnSale,AlpinePrice,AlpineSalePrice,MustShipWithEquipment,CanShipInMfrBoxSmallPack,CanShipInMfrBoxFreight,Weight,Height,Width,Length,Category,ProductVendor,CreateVendorRecord">
<cfset myformats = "Text,Text,Text,Text,Text/HTML,Text/HTML,Boolean,Boolean,Boolean,Number,Number,Number,Boolean,Number,Number,Boolean,Boolean,Boolean,Number,Number,Number,Number,Number,Text,Boolean">
<cfset myreqd = "Yes,Yes,No,Yes,No,No,No,No,No,No,No (Yes if multipack),No,No,No,No,No,No,No,No,No,No,No,Yes,Yes,No">

<cfinclude template="/partnernet/shared/_header.cfm">

<style type="text/css">
	#help {	margin:0 0 3em 0; cursor:pointer; }
	#helpinfo {	display:none; padding:1em 0 1em 2em; }
</style>

<script type="text/javascript">
	j$(function(){
		j$('#selectfile input[type=submit],#downloadlink').button();

		j$('#help > span').click(function(){
			j$('#helpinfo').slideToggle(1000);
		});
	});
</script>

<p><a href="default.cfm"><strong>Back to Menu</strong></a></p>
<cfoutput>
	<div class="options">
		<h2>Import/Export Alpine Products From/To Spreadsheet</h2>
		<div id="help">
			<span>Help Info<span title="" class="ui-icon ui-icon-help" style="float: left; margin-right: .3em;"></span></span>
			<div class="clear"></div>
			<div id="helpinfo">
				File format must match this:<br>
				<table>
					<tr>
						<th>Column Name</th>
						<th>Format</th>
						<th>Required?</th>
					</tr>
					<cfloop from="1" to="#ListLen(mycols)#" index="m">
						<tr>
							<td>#ListGetAt(mycols, m)#</td>
							<td>#ListGetAt(myformats, m)#</td>
							<td>#ListGetAt(myreqd, m)#</td>
						</tr>
					</cfloop>
				</table>
				<br><br>
				<a id="downloadlink" href="/partnernet/transfers_inbound/ImportProductTemplate.csv?v=2">Download Template File</a>
			</div>
		</div>
		<div class="clear"></div>

		<table style="border:1px solid black;">
			<tr>
				<td>
					<form id="selectfile" method="post" action="#CGI.SCRIPT_NAME#" enctype="multipart/form-data">
						<input type="file" name="filepath" class="normal" accept=".csv" /><br><br>
						<input type="submit" name="submit" value="submit" /> *Must be CSV
					</form>
				</td>
			</tr>
			<caption align="top">Upload Product Template</caption>
		</table>
	</div>
</cfoutput>

<cfscript>
	if (CGI.request_method IS "POST" AND len(trim(FORM.filepath))) {
		productDeletedPublisher = application.wirebox.getInstance('ProductDeletedPublisher');
		transaction {
			createdProds = [];
			try {
				uploadResult = fileUpload(destination="#session.user.userfolderpath#", accept="text/plain,text/csv,application/vnd.ms-excel", nameconflict="overwrite", filefield="form.filepath");
				filename = uploadResult.serverFile;

				if (NOT uploadResult.serverFileExt IS "csv"){
					fileDelete("#session.user.userfolderpath#\#filename#");
					throw(message="Incorrect File Format: Must be a CSV file.");
				}

				prod = createObject("component","objects.product");
				pricing = createObject("component","objects.productpricing");

				thecsv = fileRead("#session.user.userfolderpath#\#filename#");
				newprods = CSVToQuery(thecsv);
				for (newprod in newprods) {
					if (lenTrim(newprod.modelnumber) AND lenTrim(newprod.manufacturer) AND lenTrim(newprod.listdescription) AND lenTrim(newprod.category)) {
						exists = queryExecute("
								SELECT ID
								FROM products
								WHERE modelnumber = :model
								AND manufacturer = :mfr
							"
							,{model={value=newprod.modelnumber, sqltype="VARCHAR"}, mfr={value=newprod.manufacturer, sqltype="VARCHAR"}}
							,{datasource=DSN}
						);

						if (NOT exists.recordcount) {
							try {
								prodisonsale = len(trim(newprod.isonsale)) ? newprod.isonsale : 0;
								prodweight = len(trim(newprod.weight)) ? newprod.weight : 5;
								cost = len(trim(newprod.alpinecost)) ? newprod.alpinecost : .01;
								myshipping = val((prodweight^2 * (prodweight^-1.25)) * 1.4);


								if (len(trim(newprod.alpineprice)) AND newprod.alpineprice NEQ 0) {
									myalpineprice = newprod.alpineprice;
								} else {
									result = pricing.returnretail(cost + myshipping);
									myalpineprice = prodisonsale ? Round(result.retailprice * 1.3) - 0.01 : result.retailprice;
								}

								if (len(trim(newprod.alpinesaleprice)) AND newprod.alpinesaleprice NEQ 0) {
									myalpinesaleprice = newprod.alpinesaleprice;
								} else {
									if (prodisonsale) {
										result = pricing.returnretail(cost + myshipping);
										myalpinesaleprice = result.retailprice;
									} else {
										myalpinesaleprice = 0;
									}
								}

								prod.init();
								prod.manufacturer = newprod.manufacturer;
								prod.modelnumber = newprod.modelnumber;
								prod.name = newprod.name;
								prod.listdescription = newprod.listdescription;
								prod.description = newprod.description;
								prod.boxcontents = newprod.boxcontents;
								prod.category = newprod.category;
								prod.includesfreeshipping = len(trim(newprod.includesfreeshipping)) ? newprod.includesfreeshipping : 0;
								prod.includespremiumguarantee = 1;
								prod.includesfreevideo = len(trim(newprod.includesfreevideo)) ? newprod.includesfreevideo : 0;
								prod.includescontractorassistance = len(trim(newprod.includescontractorassistance)) ? newprod.includescontractorassistance : 0;
								prod.priority = len(trim(newprod.priority)) ? newprod.priority : 50;
								prod.packquantity = len(trim(newprod.packquantity)) ? newprod.packquantity : 1;
								prod.alpinecost = cost;
								prod.isonsale = prodisonsale;
								prod.alpineprice = myalpineprice;
								prod.alpinesaleprice = myalpinesaleprice;
								prod.mustshipwithequipment = len(trim(newprod.mustshipwithequipment)) ? newprod.mustshipwithequipment : 0;
								prod.weight = prodweight;
								prod.createdby = session.user.id;

								prod.put();

								writeOutput("<div>The product #newprod.modelnumber# was imported successfully. (#prod.objID#)</div>");

								if (!isEmpty(newprod.CreateVendorRecord) && !trueFalseFormat(newprod.CreateVendorRecord)) {
									writeOutput("<div>Skipping vendor record.</div>");
								} else {
									writeOutput("<div>Vendor product for #newprod.modelnumber# already exists.</div>");
								}

							} catch (any e) {
								transaction action="rollback";
								writeDump(cfcatch);
							}
						}
					}
				}

				fileDelete("#session.user.userfolderpath#\#filename#");
			} catch (any e) {
				transaction action="rollback";
				for(var id in createdProds) {
					productDeletedPublisher.publish(id);
				}
				writeOutput("Error Importing file.");
				writeDump(cfcatch.message);
				rethrow;
			}
		}

	}
</cfscript>

<cfinclude template="/partnernet/shared/_footer.cfm">
