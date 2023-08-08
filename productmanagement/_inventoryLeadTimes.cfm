<cfsetting showdebugoutput="false">
<cfset LeadTimesObj = new objects.inventoryLeadTimes()>

<cfset manufacturers = LeadTimesObj.getLeadTimes()>
<cfset defaultTimes = LeadTimesObj.getDefaultTimes()>
<cfif NOT defaultTimes.recordCount>
	<cfset defaultTimes = {}>
	<cfset defaultTimes.ID = 'setDefault'>
	<cfset defaultTimes.avgLeadTime = 14>
</cfif>
<table class="data-table display table" cellspacing="0" width="100%" id="manufacturer">
	<thead>
		<tr>
			<th>Manufacturer</th>
			<th>Avg Lead Time</th>
			<th>Days to Order</th>
		</tr>
	</thead>
	<thead>
		<tr class="default">
			<cfoutput>
				<td><input type="hidden" data-id="#defaultTimes.ID#" name="manufacturer_#defaultTimes.ID#" value="#defaultTimes.ID#"><i><strong>default lead time</strong></i></td>
				<td><input type="number" class="avgLeadTime" data-id="#defaultTimes.ID#" name="avgLeadTime_#defaultTimes.ID#" value="#defaultTimes.avgLeadTime#" min="0"></td>
				<td><input type="number" class="daysToOrder" data-id="#defaultTimes.ID#" name="daysToOrder_#defaultTimes.ID#" value="#defaultTimes.daysToOrder#" min="0"></td>
			</cfoutput>
		</tr>
	</thead>
	<tbody>
		<cfoutput query="manufacturers" group="manufacturer">
			<cfoutput>
				<tr>
					<td><input type="hidden" data-id="#manufacturers.manufacturer#" name="manufacturer_#manufacturers.manufacturer#" value="#manufacturers.manufacturer#">
						<cfoutput>#Replace(manufacturer, '_','.', 'all')#</cfoutput> 
					</td>
					<td><input type="number" class="avgLeadTime" data-id="#manufacturers.manufacturer#" name="avgLeadTime_#manufacturers.manufacturer#" value="#manufacturers.avgLeadTime#" min="0"></td>
					<td><input type="number" class="daysToOrder" data-id="#manufacturers.manufacturer#" name="daysToOrder_#manufacturers.manufacturer#" value="#manufacturers.daysToOrder#" min="0"></td>
				</tr>
			</cfoutput>
		</cfoutput>
	</tbody>
</table>