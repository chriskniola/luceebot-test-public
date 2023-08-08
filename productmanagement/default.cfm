<cfsetting showdebugoutput="false">
<cfset screenID = "240">

<cfinclude template="/partnernet/shared/_header.cfm">
<style>
	h5 {margin-top: 25px;}
</style>
<div class="container-fluid">
	<div class="row">
		<div class="col-lg-12">
			<h1>Product Management</h1><hr>
		</div>
	</div>
	<div class="row">
		<div class="col-lg-4">
			<div class="panel panel-primary">
				<div class="panel-heading">
				    <h3 class="panel-title">Alpine Products</h3>
				</div>
				<div class="panel-body">
					<form name="searchform" action="/partnernet/productmanagement/searchproducts_manager.cfm" method="post">
						<div class="col-lg-12 input-group">
							<input type="text" name="criteria" class="form-control">
							<div class="input-group-btn">
							    <button class="btn btn-primary" type="submit">Search</button>
							</div>
						</div>
					</form>
					<div class="col-lg-12 list-group">
						<h5><strong>Basic Functions</strong></h5>
						<a class="list-group-item" href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm','',800,1100);">Add New</a>
						<a class="list-group-item" href="/partnernet/productmanagement/createwarrantyproduct.cfm">Create Basic Warranty Product</a>
						<a class="list-group-item" href="/partnernet/productmanagement/importproductsfromss.cfm">Import/Export Alpine Products From/To Spreadsheets</a>
						<a class="list-group-item" href="/partnernet/productmanagement/exportproductstons.cfm">Export Alpine Products To Spreadsheets</a>
						<a class="list-group-item" href="/partnernet/productmanagement/clone.cfm">Clone Products</a>
						<a class="list-group-item" href="/partnernet/productmanagement/inventoryLeadTimes.cfm">Inventory Lead Times</a>
						<a class="list-group-item" href="/partnernet/productmanagement/productserieseditor">Edit Product Series</a>
						<a class="list-group-item" href="/partnernet/product/regulations/list">Product Regulations</a>
					</div>
					<div class="col-lg-12 list-group">
						<h5><strong>Pricing</strong></h5>
						<a class="list-group-item" href="/partnernet/dynamicPricingTool/listpage.cfm">Dynamic Pricing List Page</a>
						<a class="list-group-item" href="/partnernet/dynamicPricingTool/adminpanel.cfm">Dynamic Pricing Admin Panel</a>
						<a class="list-group-item" href="/partnernet/productmanagement/clone_updateprice.cfm">Mass Update Prices</a>
						<a class="list-group-item" href="/partnernet/reports/products/pricinglog.cfm">Report of recent pricing updates</a>
					</div>
					<div class="col-lg-12 list-group">
						<h5><strong>Research Potential Problems</strong></h5>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_missingfilteratts.cfm">Products missing filter attributes</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_missingatts.cfm">Products missing attributes</a>
						<a class="list-group-item" href="/partnernet/reports/products/novendor.cfm">Products missing vendor links</a>
						<a class="list-group-item" href="/partnernet/reports/products/obsoleteproducts.cfm">Products with obsolete vendor products</a>
						<a class="list-group-item" href="/partnernet/reports/products/productsmissingphotos.cfm">Products Missing Photos</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_activeproductsinactivecats.cfm">Active Products in Inactive Categories</a>
					</div>
				</div>
			</div>
		</div>
		<div class="col-lg-4">
			<div class="panel panel-primary">
				<div class="panel-heading">
				    <h3 class="panel-title">Reports</h3>
				</div>
				<div class="panel-body">
					<div class="col-lg-12 list-group">
						<a class="list-group-item" href="/partnernet/reports/products/shippedOrderQtyByProductIds.cfm">Alpine Order Quantity By Product IDs</a>
						<a class="list-group-item" href="/partnernet/dynamicPricingTool/discountRpt.cfm">Dynamic Pricing Discount Report</a>
						<a class="list-group-item" href="/partnernet/reports/products/report_marketing_shipping_attributes.cfm">Alpine Products with Vendor Products and Basic Shipping Attributes</a>
						<a class="list-group-item" href="/partnernet/reports/product_evenbetterdeal.cfm">Product Better Deals</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_productdatabymfg.cfm">PNet Data for Master Document Template (Google Doc)</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_productstatechanges.cfm">Product State Changes</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_allProductStates.cfm">All Product States</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_requiredAccessories.cfm">Required Accessories</a>
						<a class="list-group-item" href="/partnernet/reports/products/productURLs.cfm">Product URLs</a>
						<a class="list-group-item" href="/partnernet/reports/resources/report_outdatedresources.cfm">Resources Not Updated in 180 Days</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_salepricecompareprice.cfm">Retail Price to Compare Price</a>
						<a class="list-group-item" href="/partnernet/reports/category_attributesByProduct">Get attributes for products in categories</a>
						<a class="list-group-item" href="/partnernet/reports/categories/categoryproblems.cfm">Report of Potential Category Problems</a>
						<a class="list-group-item" href="/partnernet/reports/products/rpt_expectedShippingDates.cfm">Product Expected Shipping Dates</a>
					</div>
				</div>
			</div>
			<div class="panel panel-primary">
				<div class="panel-heading">
				    <h3 class="panel-title">System Selector</h3>
				</div>
				<div class="panel-body">
					<div class="col-lg-12 list-group">
						<h5 style="margin-top: 0;"><strong>Administration</strong></h5>
						<a class="list-group-item" href="/partnernet/kitbuilder/accessory/list">Accessories</a>
						<a class="list-group-item" href="/partnernet/kitbuilder/minisplit/airhandler/list">Mini-Split Air Handlers</a>
						<a class="list-group-item" href="/partnernet/kitbuilder/minisplit/condenser/list">Mini-Split Condensers</a>
						<a class="list-group-item" href="/partnernet/kitbuilder/minisplit/admin">Mini-Split Settings</a>
						<a class="list-group-item" href="/partnernet/kitbuilder/minisplit/zone/list">Mini-Split Zones</a>
					</div>
					<div class="col-lg-12 list-group">
						<h5><strong>Tools</strong></h5>
						<a class="list-group-item" href="/partnernet/kitbuilder/minisplit/calcRoomBTUs">Calculate Room BTUs</a>
						<a class="list-group-item" href="/partnernet/reports/powerBI/miniSplitComponentAssembler.cfm">Mini Split Component Assembler</a>
						<a class="list-group-item" href="/partnernet/reports/powerBI/miniSplitSystemSelector.cfm">Mini Split System Selector</a>
						<a class="list-group-item" href="/partnernet/reports/powerBI/ductedSystemSelector.cfm">Ducted System Selector</a>
					</div>
					<div class="col-lg-12 list-group">
						<h5><strong>Reports</strong></h5>
						<a class="list-group-item" href="/partnernet/reports/kitbuilder_orders">System Selector Orders</a>
						<a class="list-group-item" href="/partnernet/reports/kitbuilder_events">System Selector Events</a>
					</div>
					<div class="col-lg-12 list-group">
						<h5><strong>System Selector Product Issues</strong></h5>
						<a class="list-group-item" href="/partnernet/kitbuilder/productIssues/split-system">Split-Sytem</a>
						<a class="list-group-item" href="/partnernet/kitbuilder/productIssues/mini-split">Mini-Split</a>
						<a class="list-group-item" href="/partnernet/kitbuilder/productIssues/self-contained">Self-Contained</a>
					</div>
				</div>
			</div>
		</div>
		<div class="col-lg-4">
			<div class="panel panel-primary">
				<div class="panel-heading">
				    <h3 class="panel-title">Inventory Items</h3>
				</div>
				<div class="panel-body">
					<div class="col-lg-12 list-group">
						<a class="list-group-item" href="/partnernet/productmanagement/viewInventoryItems.cfm">Search/Add New</a>
					</div>
				</div>
			</div>
			<div class="panel panel-primary">
				<div class="panel-heading">
				    <h3 class="panel-title">Product Categories</h3>
				</div>
				<div class="panel-body">
					<div class="col-lg-12 list-group">
						<a class="list-group-item" href="javascript:openwin('/partnernet/categories/editframe/default.cfm','',800,1100);">Add New</a>
						<a class="list-group-item" href="/partnernet/categories/list.cfm">Listing</a>
						<a class="list-group-item" href="/partnernet/productmanagement/precheckedQuoteCategories.cfm">Prechecked Quote Categories</a>
						<a class="list-group-item" href="/partnernet/categories/shopping_category_feeds.cfm">Set Shopping.com category x-ref</a>
					</div>
				</div>
			</div>
			<div class="panel panel-primary">
				<div class="panel-heading">
				    <h3 class="panel-title">Videos</h3>
				</div>
				<div class="panel-body">
					<form name="searchform" action="/partnernet/videos/search.cfm" method="post">
						<div class="col-lg-12 input-group">
							<input type="text" name="criteria" class="form-control">
							<div class="input-group-btn">
							    <button class="btn btn-primary" type="submit">Search</button>
							</div>
						</div>
					</form>
					<div class="col-lg-12 list-group">
						<h5><strong>Basic Functions</strong></h5>
						<a class="list-group-item" href="javascript:openwin('/templates/object.cfm?objecttype=video&action=edit&objID=','',800,1100);">Add New</a>
						<a class="list-group-item" href="/partnernet/videos/associatevideos.cfm">Associate to Products and Categories</a>
						<a class="list-group-item" href="/partnernet/videos/report_videoassociations.cfm">Videos Associated to Products and Categories</a>
					</div>
				</div>
			</div>
			<cfif listFind('465,860',getCurrentUser())>
				<div class="panel panel-primary">
					<div class="panel-heading">
					    <h3 class="panel-title">A-team Stuff</h3>
					</div>
					<div class="panel-body">
						<div class="col-lg-12 list-group">
							<a class="list-group-item" href="/partnernet/productmanagement/consolidatemfgs.cfm">Consolidate Manufacturers</a>
							<a class="list-group-item" href="/partnernet/misc/emailexclude.cfm">Mass Email Exclude</a>
							<a class="list-group-item" href="/partnernet/productmanagement/importKBSplitSystems.cfm">Import KB Split Systems</a>
						</div>
					</div>
				</div>
			</cfif>
		</div>
	</div>
</div>
<cfinclude template="/partnernet/shared/_footer.cfm">
