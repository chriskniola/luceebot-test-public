<cfsetting requesttimeout="900">
<cfif ![465,860].find(application.wirebox.getInstance('ScopeStorage').get('request.currentUser').getID())>
	Unauthorized
	<cfabort>
</cfif>
<cfscript>
	private string function saveKitBuilderSystems(required string relativeFilePath){
		try{
			var kits = deserializeJSON(fileRead(expandPath(arguments.relativeFilePath)));
			var errors = [];
			for(var kit in kits) {
				transaction {
					try {
						queryExecute("
							DECLARE @products VARCHAR(500) = (
								SELECT STRING_AGG(ID ,',') WITHIN GROUP (ORDER BY ID)
								FROM products 
								WHERE ID IN (:Products)
							)
							IF NOT EXISTS (
								SELECT 1
								FROM KitBuilderSplitSystems s
								CROSS APPLY (
									SELECT STRING_AGG(ProductID,',') WITHIN GROUP (ORDER BY ProductID) AS 'products'
									FROM KitBuilderSplitComponents
									WHERE KitID = s.ID
								) p
								WHERE s.AHRI = :AHRI
									AND s.[Configuration] = :Configuration
									AND s.FuelType = :FuelType
									AND p.products = @products
							)
								BEGIN
									DECLARE @kitID INT
									DECLARE @active BIT = CASE WHEN :DisabledReason IS NOT NULL THEN 0 ELSE (SELECT MAX(Active) FROM products WHERE ID IN (:Products)) END

									INSERT INTO KitBuilderSplitSystems (AHRI, Equipment, Manufacturer, SEER, EER, SEER2, EER2, Tons, Configuration, HeatingBTU, FuelType, AFUE, LoNox, Blower, CoilCasing, Region, HSPF, HSPF2, coolingCapacity_2017, coolingCapacity_2023, condenserHeatingCapacity_2017, condenserHeatingCapacity_2023, COP_5F, DisabledReason, Notes, Active)
									VALUES (:AHRI, :Equipment, :Manufacturer, :SEER, :EER, :SEER2, :EER2, :Tons, :Configuration, :HeatingBTU, :FuelType, :AFUE, :LoNox, :Blower, :CoilCasing, :Region, :HSPF, :HSPF2, :coolingCapacity_2017, :coolingCapacity_2023, :condenserHeatingCapacity_2017, :condenserHeatingCapacity_2023, :COP_5F, :DisabledReason, :Notes, @active)

									SELECT @kitID = SCOPE_IDENTITY()

									INSERT INTO KitBuilderSplitComponents (KitID, ProductID, Quantity)
										SELECT @kitID, ID, 1
										FROM Products
										WHERE ID IN (:Products)
								END
						",{
							AHRI: {sqltype:"INT", value:kit.AHRI},
							Equipment: {sqltype:"VARCHAR", value:kit.Equipment},
							Manufacturer: {sqltype:"VARCHAR", value:kit.Manufacturer},
							SEER: {sqltype:"DECIMAL", value:kit.SEER, null:isEmpty(kit.SEER)},
							EER: {sqltype:"DECIMAL", value:kit.EER, null:isEmpty(kit.EER)},
							SEER2: {sqltype:"DECIMAL", value:kit.SEER2 ?: '', null:isEmpty(kit.SEER2 ?: '')},
							EER2: {sqltype:"DECIMAL", value:kit.EER2 ?: '', null:isEmpty(kit.EER2 ?: '')},
							Tons: {sqltype:"DECIMAL", value:kit.Tons},
							Configuration: {sqltype:"VARCHAR", value:kit.Configuration},
							HeatingBTU: {sqltype:"INT", value:kit.HeatingBTU, null:isEmpty(kit.HeatingBTU)},
							FuelType: {sqltype:"VARCHAR", value:kit.FuelType, null:isEmpty(kit.FuelType)},
							AFUE: {sqltype:"DECIMAL", value:kit.AFUE, null:isEmpty(kit.AFUE)},
							LoNox: {sqltype:"VARCHAR", value:kit.LoNox, null:isEmpty(kit.LoNox)},
							Blower: {sqltype:"VARCHAR", value:kit.Blower, null:isEmpty(kit.Blower)},
							CoilCasing: {sqltype:"VARCHAR", value:kit.CoilCasing, null:isEmpty(kit.CoilCasing)},
							Region: {sqltype:"VARCHAR", value:kit.Region, null:isEmpty(kit.Region)},							
							HSPF: {sqltype:"DECIMAL", value:kit.HSPF, null:isEmpty(kit.HSPF)},
							HSPF2: {sqltype:"DECIMAL", value:kit.HSPF2, null:isEmpty(kit.HSPF2)},
							coolingCapacity_2017: {sqltype:"INT", value:kit.coolingCapacity_2017, null:isEmpty(kit.coolingCapacity_2017)},
							coolingCapacity_2023: {sqltype:"INT", value:kit.coolingCapacity_2023, null:isEmpty(kit.coolingCapacity_2023)},
							condenserHeatingCapacity_2017: {sqltype:"INT", value:kit.condenserHeatingCapacity_2017, null:isEmpty(kit.condenserHeatingCapacity_2017)},
							condenserHeatingCapacity_2023: {sqltype:"INT", value:kit.condenserHeatingCapacity_2023, null:isEmpty(kit.condenserHeatingCapacity_2023)},
							COP_5F: {sqltype:"DECIMAL", value:kit.COP_5F, null:isEmpty(kit.COP_5F)},
							Products: {sqltype:"VARCHAR", value:kit.Products},
							DisabledReason: {sqltype:"VARCHAR", value:kit.DisabledReason, null:isEmpty(kit.DisabledReason)},
							Notes: {sqltype:"VARCHAR", value:kit.Notes, null:isEmpty(kit.Notes)}
						},{datasource:"ahapdb"});
					} catch (e) {
						transaction action="rollback";
						errors.append(kit);
						if(errors.len() == 1) {
							mail to='technical@alpinehomeair.com' from='system@alpinehomeair.com' subject='e' type='html' {
								dump(e);
							}
						}
					}
				}
			}

			if(errors.len()) {
				mail subject="Failed KB Insert" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump(errors); }			
			}
			mail subject="Successfully Imported #kits.len() - errors.len()# Systems" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump(now()); }
			return "Successfully Imported #kits.len() - errors.len()# Systems";
		} catch (e) {
			mail subject="Error Importing Kit Builder Split Systems" to="technical@alpinehomeair.com" from="errors@alpinehomeair.com" type="html" { dump(e); }
			return "Successfully Imported 0 Systems";
		}
	}
</cfscript>

<cfset screenID = 240>
<cfset title = "Import Kit Builder Split Systems">
<cfset subtitle = "">
<cfset useBootstrap = 1>

<cfoutput>
<cfsavecontent variable="content">
	<div class="col-lg-6 col-lg-offset-3">
		<cfif CGI.request_method IS "POST" AND len(trim(FORM.filepath))>
			<cfset folderPath = getTempDirectory()>
			<cfset uploadResult = fileUpload(destination=expandPath(folderPath), accept="application/json,text/csv", nameconflict="overwrite", filefield="form.filepath")>
			<cfset filePath = folderPath & uploadResult.serverFile>
			<cfif !['json','csv'].findNoCase(uploadResult.serverFileExt)>
				<cfset fileDelete(filePath)>
				<cfset throw(message="Incorrect File Type", type="FileRead")>
			</cfif>
			<cfif uploadResult.serverFileExt == 'csv'>
				<cfset tempFilePath = '#folderPath#kbupload.json'>
				<cfset prodArray = queryToArray(csvToQuery(fileRead(expandPath(filePath))))>
				<cfset prodArray.each((e) => arguments.e.products = deserializeJSON(arguments.e.products))>
				<cfset fileWrite(tempFilePath,serializeJSON(prodArray))>
				<cfset filePath = tempFilePath>
			</cfif>

			<p class="bg-success p10">
				<cfoutput>#saveKitBuilderSystems(filePath)#</cfoutput>
			</p>
		</cfif>

		<form id="selectfile" method="post" enctype="multipart/form-data">
			<div class="form-group">
				<label>File Upload</label><br>
				<div class="input-group">
	                <span class="input-group-btn">
	                    <span class="btn btn-primary btn-file">
	                       Upload file
	                        <input type="file" name="filepath" class="normal" accept=".json,.csv" />
	                    </span>
	                </span>
	                <input type="text" class="form-control" readonly value="">
            	</div>
			</div>
			<button class="ladda-button btn btn-primary" data-style="slide-up" type="submit" value="Submit" name="submit" >
			     <span class="ladda-label">Submit</span>
			</button> <span class="text-danger">*Must be JSON or CSV</span>
		</form>
	</div>

	<script type="text/javascript">
		j$(document).on('change', '.btn-file :file', function() {
		  var input = j$(this),
		      numFiles = input.get(0).files ? input.get(0).files.length : 1,
		      label = input.val().replace(/\\/g, '/').replace(/.*\//, '');
		  input.trigger('fileselect', [numFiles, label]);
		});

		j$(document).ready( function() {
		j$('.btn-file :file').on('fileselect', function(event, numFiles, label) {

		        var input = j$(this).parents('.input-group').find(':text'),
		            log = numFiles > 1 ? numFiles + ' files selected' : label;

		        if( input.length ) {
		            input.val(log);
		        } else {
		            if( log ) alert(log);
		        }

		    });
		});
	</script>
</cfsavecontent>
</cfoutput>

<cfinclude template="/partnernet/shared/layouts/basic.cfm">
