<cfset screenID = "825">
<cfset title = "Shipping Bill Manager">
<cfparam name="ATTRIBUTES.subtitle" default="">

<cfsavecontent variable="content">
	<div class="col-lg-6">
		<h3>Shipping Bill Workflow</h3>
		<ol class="list-group">
			<li class="list-group-item">
				Received automatically, <a href="/templates/object.cfm?objecttype=freightbill&action=edit" target="_blank"> manually added</a> or <a href="importfedexground2.cfm">Shipping Bill Import</a>
			</li>
			<li class="list-group-item">
				Audit, dispute - <a href="freightbilllookup.cfm">Search shipping bills</a>
			</li>
			<li class="list-group-item">
				Amount Paid entered, Dispute Status changed to "Ready to Pay"
			</li>
			<li class="list-group-item">
				Generate Bill - <a href="createPO.cfm">for All Invoices in Ready to Pay Status</a>
			</li>
			<li class="list-group-item">
				Accounting cuts check
			</li>
			<li class="list-group-item">
				Check received, check number entered on PO - <a href="createpayment.cfm">Update Check Number on Bill Payment</a>
			</li>
			<li class="list-group-item">
				Check mailed
			</li>
		</ol>
	</div>
	<div class="col-lg-6">
		<h3>Reports</h3>
		<ul class="list-group">
			<li class="list-group-item">
				<a href="findduplicates.cfm">Duplicate Bills in Ready to Pay Status</a>
			</li>
			<li class="list-group-item">
				<a href="/partnernet/reports/freightbills/freight_po_shipments.cfm">Freight Shipments by PO Date</a>
			</li>
			<li class="list-group-item">
				<a href="/partnernet/reports/freightbills/shippingTrackingNumbers.cfm">Shipment Tracking Numbers and Statuses</a>
			</li>
			<li class="list-group-item">
				<a href="/partnernet/reports/freightbills/missingFreightBills.cfm">Free Shipping Orders Missing Freight Bills</a>
			</li>
			<li class="list-group-item">
				<a href="/partnernet/reports/freightbills/missingShippingCost.cfm">POs Without Shipping Cost</a>
			</li>
			<li class="list-group-item">
				<a href="/partnernet/reports/freightbills/missingPONumbers.cfm">Shipping Bills with Missing PO Numbers</a>
			</li>
		</ul>
	</div>
</cfsavecontent>

<cfinclude template="/partnernet/shared/layouts/basic.cfm">