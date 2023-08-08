<cfsetting showdebugoutput="false">
<cfparam name="attributes.criteria">
<cfparam name="attributes.excludeIDs" default="">
<cfparam name="attributes.maxrows" default="100">
<cfparam name="attributes.filter" default="1">
<cfparam name="attributes.searchtype" default="Advanced">
<cfparam name="attributes.shortlist" default="0">
<cfparam name="attributes.recommendpostback" default="1">
<cfparam name="attributes.resultformat" default="standard"><!--- standard, updated --->
<cfparam name="attributes.noedit" default="0">
<cfparam name="attributes.style" default="0">

<cfif attributes.style IS "yes">
	<link rel="stylesheet" href="/partnernet/shared/css/_styles.css"></link>
</cfif>

<cfinvoke component="alpine-objects.product" method="search" criteria="#attributes.criteria#" maxrows="100" returnvariable="products" filter="#attributes.filter#" excludeIDs="#attributes.excludeIDs#" incVendorSummary="true">

<cfset searchProducts = products.products>

<cfinvoke component="#APPLICATION.user#" method="returnpermission" returnvariable="isadmin">
	<cfinvokeargument name="screenID" value="995">
</cfinvoke>

<cfif searchProducts.recordcount>
	<cfif attributes.resultformat IS "standard">
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
					<th>Description</th>
					<th>Primary Category</th>
					<th>Price</th>
					<th>Vendors</th>
					<cfif NOT attributes.shortlist>
						<th>Qty Avail.</th>
						<th>Qty On<br>Order</th>
						<th>On Order<br>Date</th>
					</cfif>
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
							<th scope="row"><cfif session.user.ID EQ 100>(#score#)</cfif>
								<cfif NOT attributes.noedit>
									<cfif session.user.id EQ 395 OR session.user.id EQ 465>
										<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#productID#','',1400,1100);" onclick="changecolor('link#productID#');" id="link#productID#"><span class="tiny">edit</span></a><br>
									<cfelse>
										<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#productID#','',800,1100);" onclick="changecolor('link#productID#');" id="link#productID#"><span class="tiny">edit</span></a><br>
									</cfif>
									<a href="javascript:popurl('/offeraccessories.cfm?productnumber=#productID#&quantity=1','cart');"><span class="tiny">add to cart</span></a>
								</cfif>
							</td>
							<td <cfif isadmin>onmouseover="changemousehand()" onmouseout="changemousedefault()" onclick="changestatus(this,'#searchproducts.productID#','active')"</cfif>><cfif val(searchproducts.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></td>
							<td>#productID#</td>
							<td>#manufacturer#</td>
							<td>#modelnumber#</td>
							<td>#listdescription#</td>
							<td>#category#</td>
							<td><cfif val(isonsale)>On Sale<br></cfif>#dollarformat(retailPrice)#</td>
							<td>#val(vendorcount)#<cfif NOT attributes.noedit> &nbsp; <a href="javascript:openwin('listvendors.cfm?productID=#productID#','',800,1100);">edit</a></cfif></td>
							<cfif NOT attributes.shortlist>
								<td><cfif qtyavailable NEQ ""><cfif qtyavailable GT 0>#qtyavailable#</cfif><cfelse></cfif></td>
								<td><cfif qtyonorder NEQ ""><cfif qtyonorder GT 0>#qtyonorder#</cfif><cfelse></cfif></td>
								<td><cfif isdate(onorderdate)>#dateformat(onorderdate,"m/d/yy")#<cfelse></cfif></td>
							</cfif>
						</tr>
					<cfelse>
						<cfset rowstoshow=listappend(rowstoshow,searchProducts.currentrow,",")>
						<tr id="row#searchProducts.currentrow#" style="display:none;">
							<th scope="row"><cfif session.user.ID EQ 100>(#score#)</cfif>
								<cfif NOT attributes.noedit>
									<cfif session.user.id EQ 395 OR session.user.id EQ 465>
										<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#productID#','',1400,1100);" onclick="changecolor('link#productID#');" id="link#productID#"><span class="tiny">edit</span></a><br>
									<cfelse>
										<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#productID#','',800,1100);" onclick="changecolor('link#productID#');" id="link#productID#"><span class="tiny">edit</span></a><br>
									</cfif>
									<a href="javascript:popurl('/offeraccessories.cfm?productnumber=#productID#&quantity=1','cart');"><span class="tiny">add to cart</span></a></td>
								</cfif>
							<td onmouseover="changemousehand()" onmouseout="changemousedefault()" onclick="changestatus(this,'#searchproducts.productID#','active')"><cfif val(searchproducts.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></td>
							<td>#productID#</td>
							<td>#manufacturer#</td>
							<td>#modelnumber#</td>
							<td>#listdescription#</td>
							<td>#category#</td>
							<td><cfif val(isonsale)>On Sale<br></cfif>#dollarformat(retailPrice)#</td>
							<td>#val(vendorcount)#<cfif NOT attributes.noedit> &nbsp; <a href="javascript:openwin('listvendors.cfm?productID=#productID#','',800,1100);">edit</a></cfif></td>
							<cfif NOT attributes.shortlist>
								<td><cfif qtyavailable NEQ ""><cfif qtyavailable GT 0>#qtyavailable#</cfif><cfelse></cfif></td>
								<td><cfif qtyonorder NEQ ""><cfif qtyonorder GT 0>#qtyonorder#</cfif><cfelse></cfif></td>
								<td><cfif isdate(onorderdate)>#dateformat(onorderdate,"m/d/yy")#<cfelse></cfif></td>
							</cfif>
						</tr>
					</cfif>
				</cfoutput>

				<cfif rowstoshow IS NOT "">
					<tr id="seemore"><td colspan="<cfif NOT attributes.shortlist>12<cfelse>9</cfif>"><a href="javascript:showmore('<cfoutput>#rowstoshow#</cfoutput>');">See more results...</a></td></tr>
				</cfif>
			</tbody>

		</table>
	<cfelseif attributes.resultformat IS "updated">
		<table>
			<caption>Displaying a maximum of <cfoutput>#searchProducts.recordcount#</cfoutput> record(s) that match your criteria.</caption>
			<thead>
				<tr>

					<th>Actions</th>
					<th>Active</th>
					<th>Product ID</th>
					<th>Product</th>
					<th>Primary Category</th>
					<th>Price</th>
					<th>Vendors</th>
					<cfif NOT attributes.shortlist>
						<th>Qty Avail.</th>
						<th>Qty On<br>Order</th>
						<th>On Order<br>Date</th>
					</cfif>
				</tr>
			</thead>

			<tbody>
				<cfquery name="getmax" dbtype="query">
					SELECT max(score) - ((max(score)-min(score)) / 2) as thevalue
					FROM searchProducts
				</cfquery>

				<cfset minscore = round(getmax.thevalue)>

				<cfset rowstoshow = "">
				<cfoutput query="searchProducts">
					<cfif score GTE minscore>
						<tr>
							<th scope="row"><cfif session.user.ID EQ 100>(#score#)</cfif>
								<cfif NOT attributes.noedit>
								<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#productID#','',800,1100);" onclick="changecolor('link#productID#');" id="link#productID#"><span class="tiny">edit</span></a><br>
								<a href="javascript:popurl('/offeraccessories.cfm?productnumber=#productID#&quantity=1','cart');"><span class="tiny">add to cart</span></a></cfif></th>
							<td onmouseover="changemousehand()" onmouseout="changemousedefault()" onclick="changestatus(this,'#searchproducts.productID#','active')"><cfif val(searchproducts.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></td>
							<td>#productID#</td>
							<td><strong>#manufacturer# #modelnumber#</strong><br>#listdescription#</td>
							<td>#category#</td>
							<td><cfif val(isonsale)>On Sale<br></cfif>#dollarformat(retailPrice)#</td>
							<td>#val(vendorcount)#<cfif NOT attributes.noedit> &nbsp; <a href="javascript:openwin('listvendors.cfm?productID=#productID#','',800,1100);">edit</a></cfif></td>
							<cfif NOT attributes.shortlist>
								<td><cfif qtyavailable NEQ ""><cfif qtyavailable GT 0>#qtyavailable#</cfif><cfelse></cfif></td>
								<td><cfif qtyonorder NEQ ""><cfif qtyonorder GT 0>#qtyonorder#</cfif><cfelse></cfif></td>
								<td><cfif isdate(onorderdate)>#dateformat(onorderdate,"m/d/yy")#<cfelse></cfif></td>
							</cfif>
						</tr>

					<cfelse>
						<cfset rowstoshow=listappend(rowstoshow,searchProducts.currentrow,",")>
						<tr id="row#searchProducts.currentrow#" style="display:none;">
							<th scope="row"><cfif session.user.ID EQ 100>(#score#)</cfif>
								<cfif NOT attributes.noedit>
								<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#productID#','',800,1100); onclick="changecolor('link#productID#');" id="link#productID#""><span class="tiny">edit</span></a><br>
								<a href="javascript:popurl('/offeraccessories.cfm?productnumber=#productID#&quantity=1','cart');"><span class="tiny">add to cart</span></a></cfif></th>
							<td onmouseover="changemousehand()" onmouseout="changemousedefault()" onclick="changestatus(this,'#searchproducts.productID#','active')"><cfif val(searchproducts.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></td>
							<td>#productID#</td>
							<td><strong>#manufacturer# #modelnumber#</strong><br>#listdescription#</td>
							<td>#category#</td>
							<td><cfif val(isonsale)>On Sale<br></cfif>#dollarformat(retailPrice)#</td>
							<td>#val(vendorcount)#<cfif NOT attributes.noedit> &nbsp; <a href="javascript:openwin('listvendors.cfm?productID=#productID#','',800,1100);">edit</a></cfif></td>
							<cfif NOT attributes.shortlist>
								<td><cfif qtyavailable NEQ ""><cfif qtyavailable GT 0>#qtyavailable#</cfif><cfelse></cfif></td>
								<td><cfif qtyonorder NEQ ""><cfif qtyonorder GT 0>#qtyonorder#</cfif><cfelse></cfif></td>
								<td><cfif isdate(onorderdate)>#dateformat(onorderdate,"m/d/yy")#<cfelse></cfif></td>
							</cfif>
						</tr>
					</cfif>
				</cfoutput>

				<cfif rowstoshow IS NOT "">
					<tr id="seemore"><td colspan="<cfif NOT attributes.shortlist>10<cfelse>7</cfif>"><a href="javascript:showmore('<cfoutput>#rowstoshow#</cfoutput>');">See more results...</a></td></tr>
				</cfif>
			</tbody>
		</table>
	</cfif>
<cfelse>
	<div class="alertbox">No products found with above criteria.</strong></div>
</cfif>