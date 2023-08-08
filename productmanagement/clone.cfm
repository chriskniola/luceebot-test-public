<cfsetting requesttimeout="360">
<cfset screenID = "240">

<cfinclude template="/partnernet/shared/_header.cfm">
<script>
	function addrow(){
		document.getElementById('rows').value++;
		var r = j$('#rows').val();
		j$('#clonetable tr:last-child').after('<tr class="prod"><td><input type="number" class="prodid" name="p' + r + '_original" max="999999999" required onblur="getName(this);"><span onclick="hideName(this);"></span></td><td><input type="text" name="p' + r + '_newmodel" maxlength="75" required></td><td><input type="text" name="p' + r + '_newmfr" maxlength="50"></td><td><input type="checkbox" name="p' + r + '_supersede" value="1"></td><td><input type="checkbox" name="p' + r + '_copyResources" value="1" checked></td><td><input type="checkbox" name="p' + r + '_copyPhotosVids" value="1" checked></td><td><input type="checkbox" name="p' + r + '_copyAttributes" value="1" checked></td><td><input type="checkbox" name="p' + r + '_copyAccessories" value="1" checked></td><td class="rel"><input type="checkbox" name="p' + r + '_copyToAccessories" value="1"><div class="remove" onclick="removeMe(this);">Remove</div></td></tr>');
	}
	
	function getName(t){
		var t = j$(t);
		if(j$.isNumeric(t.val())){
			j$.ajax({ 
				url: 'changestatus.cfm?productID=' + t.val() + '&column=none', 
				type: 'post', 
				success: function(r) {
					t.prop('type','hidden');
					t.next().text(r).removeClass('error').show();
					if(r == 'Product Not Found')
						t.next().addClass('error');
				}
			});
		}
	}
	
	function hideName(t){
		var t = j$(t);
		t.text('').hide();
		t.prev().prop('type','number').focus();	
	}
	
	function removeMe(t){
		j$(t).closest('tr').fadeOut(function(){j$(this).remove();});	
	}
</script>
<style>
	#clonetable {border-collapse: collapse;text-align: center;}
	.prod td:first-child {width:184px;}
	.prod span {display:none;}
	.rel {position: relative;}
	.remove	{position: absolute;right: -50px;top: 10px;cursor: pointer;color: #0071BB;}
	.remove:hover {text-decoration: underline;}
	.error {color: #f75050;}
	.button {font-size: 1.2em;}
</style>
<h1>Clone Products</h1>
<form name="copyform" method="post">
	<input type="hidden" id="rows" name="rows" value="1">
	<table id="clonetable" border="1" cellpadding="5">
		<tr>
			<th rowspan="2">Original<br />Product ID</th>
			<th rowspan="2">New Model Number</th>
			<th rowspan="2">New Manufacturer</th>
			<th rowspan="2">Replaces<br />Old</th>
			<th colspan="5">Copy</th>
		</tr>
		<tr>
			<th>Docs</th>
			<th>Pics/Videos</th>
			<th>Attributes</th>
			<th>Accessories</th>
			<th>As Accessory</th>
		</tr>
		<tr class="prod">			
			<td><input type="number" class="prodid" name="p1_original" max="999999999" required onblur="getName(this);"><span onclick="hideName(this);"></span></td>
			<td><input type="text" name="p1_newmodel" maxlength="75" required></td>
			<td><input type="text" name="p1_newmfr" maxlength="50"></td>
			<td><input type="checkbox" name="p1_supersede" value="1"></td>
			<td><input type="checkbox" name="p1_copyResources" value="1" checked></td>
			<td><input type="checkbox" name="p1_copyPhotosVids" value="1" checked></td>
			<td><input type="checkbox" name="p1_copyAttributes" value="1" checked></td>
			<td><input type="checkbox" name="p1_copyAccessories" value="1" checked></td>
			<td><input type="checkbox" name="p1_copyToAccessories" value="1"></td>
		</tr>
	</table>
	<br />
	<input type="submit" name="submit" value="Submit" class="button primary"><input type="button" name="addRow" value="Add Row" onclick="addrow();" class="button" style="margin-left: 50px;">	
</form>


<cfif CGI.request_method EQ "POST">
	<cfset objProd = createObject("component","alpine-objects.product")>
	<hr>
	<h3>Results:</h3>
	<cfoutput>
		<cfloop from="1" to="#attributes.rows#" index="i">
			<cfif isDefined("attributes['p#i#_original']")>
				<cfset orig = attributes["p#i#_original"]>
				<cfset getResult = objProd.get(orig)>
				
				<cfif getResult.errorCode>
					<div class="error">Original Product (#orig#) Error: #getResult.errorMessage#</div>
				<cfelse>
					<cfset args = {}>
					<cfset args.newModelNumber = attributes["p#i#_newmodel"]>
					<cfset args.manufacturer = attributes["p#i#_newmfr"]>
					<cfset args.supersede = attributes["p#i#_supersede"] ?: 0>
					<cfset args.copyAttributes = attributes["p#i#_copyAttributes"] ?: 0>
					<cfset args.copyResources = attributes["p#i#_copyResources"] ?: 0>
					<cfset args.copyPhotosVids = attributes["p#i#_copyPhotosVids"] ?: 0>
					<cfset args.copyAccessories = attributes["p#i#_copyAccessories"] ?: 0>
					<cfset args.copyToAccessories = attributes["p#i#_copyToAccessories"] ?: 0>
		
					<cfset cloneResult = objProd.clone(argumentCollection=args)>
					<div <cfif cloneResult.errorCode>class="error"</cfif>>#cloneResult.message#</div>
				</cfif>
			</cfif>
		</cfloop>
	</cfoutput>
</cfif>

<cfinclude template="/partnernet/shared/_footer.cfm">