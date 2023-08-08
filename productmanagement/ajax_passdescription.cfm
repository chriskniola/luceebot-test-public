<cfsetting showdebugoutput="No">

<cfparam name="attributes.criteria">
<cfparam name="attributes.maxrows" default="50">
<cfparam name="attributes.searchtype" default="advanced">
<cfparam name="attributes.options" default="">
<cfparam name="attributes.productID" default="">
<cfparam name="attributes.excludevendor" default="">


<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="100" returnvariable="products" incVendorSummary="true">

<cfset searchproducts = products.products>

<cfif searchProducts.recordcount>
<table>
	<caption>Displaying a maximum of <cfoutput>#searchProducts.recordcount#</cfoutput> record(s) that match your criteria.</caption>
	<thead>
		<tr>
			
			<th>Actions</th>
			<th>Active</th>
			<!--- <th>Obsolete</th> --->
			<th>Product ID</th>
			<th>Manufacturer</th>
			<th>Mfg. Part No.</th>
			<th>Short Description</th>
			<th>Long Description</th>
			<th>Primary Category</th>
			<th>Price</th>
		</tr>
	</thead>
	
	<tbody>
		<cfquery name="getmax" dbtype="query">
		SELECT max(score) - ((max(score)-min(score)) / 2) as thevalue
		FROM searchProducts
		</cfquery>
		
		
		<cfif searchProducts.recordcount LT 10>
			<cfset minscore = 0>
		<cfelse>
			<cfset minscore = round(getmax.thevalue)>
		</cfif>
		
		<cfset rowstoshow = "">
		<cfoutput query="searchProducts">
			<cfif score GTE minscore>
				<tr>
					<th scope="row"><cfif session.user.ID EQ 100>(#score#)</cfif><a href="javascript:popurl('#searchProducts.url#');">view</a></th>
					<td><cfif val(searchproducts.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></td>
					<td>#productID#</td>
					<td>#manufacturer#</td>
					<td>#modelnumber#</td>
					<td><a href="javascript:passshortdesc($('sd_#productID#').innerHTML);">Use This</a><br><div id="sd_#productID#">#listdescription#</div></td>
					<td><a href="javascript:passlongdesc(#productID#);">Use This</a><br>#description#<cfif len(description) EQ 1500>...</cfif></td>
					<td>#category#</td>
					<td><cfif alpinesaleprice GT 0>On Sale<br>#dollarformat(alpinesaleprice)#<cfelse>#dollarformat(alpineprice)#</cfif></td>
				</tr>
				
			
			<cfelse>
				<cfset rowstoshow=listappend(rowstoshow,searchProducts.currentrow,",")>
				<tr id="row#searchProducts.currentrow#" style="display:none;">
					<th scope="row"><cfif session.user.ID EQ 100>(#score#)</cfif><a href="javascript:popurl('#searchProducts.url#');">view</a></th>
					<td><cfif val(searchproducts.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></td>
					<td>#productID#</td>
					<td>#manufacturer#</td>
					<td>#modelnumber#</td>
					<td><a href="javascript:passshortdesc($('shortDesc').innerHTML););">Use This</a><br><div id="shortDesc">#listdescription#</div></td>
					<td><a href="javascript:passlongdesc(#productID#);">Use This</a><br>#description#<cfif len(description) EQ 1500>...</cfif></td>
					<td>#category#</td>
					<td><cfif alpinesaleprice GT 0>On Sale<br>#dollarformat(alpinesaleprice)#<cfelse>#dollarformat(alpineprice)#</cfif></td>
				</tr>
			</cfif>
		</cfoutput>
		
	</tbody>
	
</table>

<cfelse>
	<div class="alertbox">No products found with above criteria.</strong></div>
</cfif>
<div class="tiny">If you believe these results are not scoring properly, <a class='reportIssueLink' data-content="Vendor Search Results&comments=<cfoutput>Criteria used: |#attributes.criteria#|</cfoutput>','','','')">click here to explain</a>.</div>