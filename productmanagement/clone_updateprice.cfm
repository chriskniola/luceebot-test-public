<cfsetting requesttimeout="995">
<cfparam name="attributes.criteria" default="">

<cfset success = true>
<cfset message = "">
<cfset variables.screenID = "240" />
<cfinclude template="/partnernet/shared/_header.cfm" />

<cfif cgi.REQUEST_METHOD == 'POST'>
	<cfset attributes.criteria = replaceNoCase(attributes.criteria,"#chr(9)#","|","all")>

	<cfset productObj = createObject("objects.product")>

	<cftry>
		<cfloop list="#attributes.criteria#" delimiters="#Chr(13)##Chr(10)#" index="i">	
			<cfset splitInfo = listToArray(i,"|",true)>
			<cfset args = {
				'productID': splitInfo[1],
				'regularPrice': splitInfo[2],
				'salePrice': isDefined('splitInfo[3]') && !isEmpty(splitInfo[3]) ? splitInfo[3] : nullValue(),
				'isOnSale': isDefined('splitInfo[4]') && !isEmpty(splitInfo[4]) ? splitInfo[4] : nullValue(),
				'compareprice': isDefined('splitInfo[5]') && !isEmpty(splitInfo[5]) ? splitInfo[5] : nullValue(),
				'isInCartPrice': isDefined('splitInfo[6]') && !isEmpty(splitInfo[6]) ? splitInfo[6] : nullValue()
			}>

			<cfset productObj.putretail(argumentCollection = args)>
		</cfloop>
		<cfset message = "Products Updated">
		<cfcatch>
			<cfset success = false>
			<cfset message = cfcatch.message>
			<cfset logonly = 1>
			<cfinclude template="/partnernet/irongate/irongate.cfm">
		</cfcatch>
	</cftry>
</cfif>

<style>
	.required { color: red; }
</style>

<cfoutput>
	<div class="container-fluid">
		<div class="row">
			<div class="col-lg-12 #success ? 'bg-success' : 'bg-danger'#" style="font-size: 16px;">#message#</div>
		</div>
		<div class="row">
			<div class="col-lg-12">
				<h1>Mass Update Product Prices</h1>
			</div>
		</div>
		<form name="copyform" method="post">
			<div class="row">
				<div class="col-lg-12">
					<h4><span class="required">Product ID</span> | <span class="required">Regular Price</span> | Sale Price | Is On Sale | MAP/Compare Price | Use MAP Price</h4>
				</div>
				<div class="col-lg-12">
					<div class="row">
						<div class="col-lg-3">
							<span>(Tab or Pipe Delimited)</span>
						</div>
						<div class="col-lg-9">
							<span style="font-size: 14px;">
								<span class="required">Required</span> | Optional
							</span>
						</div>
					</div>
					<div class="row">
						<div class="col-lg-12">
							<textarea name="criteria" rows="30" style="width: 100%;">#ESAPIEncode('html',attributes.criteria)#</textarea>
						</div>
					</div>
				</div>
				<div class="col-lg-3">
					<input type="submit" name="submit" value="Submit">		
				</div>
			</div>
		</form>	
		<div class="row" style="margin-top: 30px;">
			<div class="col-lg-12">
				<h4>Column Descriptions</h4>
				<ul>
					<li><strong>Product ID</strong> - The Alpine product ID.</li>
					<li><strong>Regular Price</strong> - The regular price of the product.</li>
					<li><strong>Sale Price</strong> - The sale price of the product.</li>
					<li><strong>Is On Sale</strong> - IF enabled, the retail price of the product is the Sale Price otherwise it is the Regular Price. <strong>(true/false | yes/no | 1/0)</strong></li>
					<li><strong>MAP/Compare Price</strong> - The MAP/compare to price of the product.</li>
					<li><strong>Use MAP Price</strong> - IF enabled, the displayed price on the product and category pages is the MAP price. The price in the cart is the retail price computed as above. <strong>(true/false | yes/no | 1/0)</strong></li>
				</ul>
			</div>
		</div>
		<div class="row" style="margin-top: 30px;">
			<div class="col-lg-12">
				<h4>Usage</h4>
				<p>
					Enter data using one line per product with a <strong>Tab</strong> or a <strong>Pipe</strong> between column values.  Do not include dollar signs. You can copy and paste from Excel.
				</p>
				<p>
					<strong>Note:</strong> Only the first two columns are required.  Any included optional columns must also include preceeding columns.  For example, <strong>Is On Sale</strong> requires <strong>Sale Price</strong> whereas <strong>Use MAP Price</strong> requires all the columns.
				</p>
			</div>
		</div>
	</div>
</cfoutput>
<cfinclude template="/partnernet/shared/_footer.cfm" />