<cfset screenID = 240>
<cfset recordhistory = 0>
<cfinclude template="/partnernet/shared/_header.cfm">
<cfoutput>
<div class="options">
	<ul class="horiz">
		<li class="horiz"><a href="/partnernet/productmanagement/accessorizeProducts.cfm?productID=#attributes.productID#">Accessorize Product</a></li>
		<li class="horiz"><strong>View Product Accessorizations</strong></li>
	</ul>
</div>
</cfoutput>

<table>
	<tr>
		<td>
			<cfquery name="getAcc" datasource="#dsn#">
				SELECT p.ListDescription, p.ModelNumber, p.Manufacturer, p.ID, pr.[Route] AS 'url', pc.[Name] AS 'category', p.Active
				FROM tblProductAssociations a
				INNER JOIN products p ON a.prdID = p.id
				INNER JOIN v_ProductRoutes pr ON pr.ProductID = p.ID 
				INNER JOIN ProductCategories pc ON pc.ID = p.Category
				WHERE a.prdRelative = <cfqueryPARAM value="#attributes.productID#" CFSQLType='cf_sql_integer'/>
					AND a.ascType = 'R'
				ORDER BY category, p.Active DESC, p.Manufacturer, p.ModelNumber
			</cfquery>
			<div id="report">
				<table>
					<tr>
						<th>This product is an Accessory to:</th>
					</tr>
					<cfif getAcc.recordcount>
						<cfoutput query="getAcc" group="category">
							<tr>
								<td style="background-color: ##efefff;"><strong>#getAcc.category#</strong></td>
							</tr>
							<cfoutput>
								<tr>
									<td <cfif !getAcc.Active>style='color:##C0C0C0'</cfif>>
										<a target="_blank" href="#getAcc.url#" <cfif !getAcc.Active>style='color:##C0C0C0'</cfif>>#getAcc.Manufacturer# / #getAcc.ModelNumber#</a>
										<br>
										#getAcc.ListDescription#
									</td>
								</tr>
							</cfoutput>
						</cfoutput>
					<cfelse>
						<tr><td>None Found</td></tr>
					</cfif>
				</table>
			</div>
		</td>
	</tr>
	<tr>
		<td>
			<cfquery name="getAcc" datasource="#dsn#">
				SELECT p.ListDescription, p.ModelNumber, p.Manufacturer, p.ID, a.accRequired, a.isAddOn, a.isPopUp, p.Active, pr.[Route] AS 'url', pc.[Name] AS 'category'
				FROM tblProductAssociations a
				INNER JOIN products p ON a.prdRelative = p.id
				INNER JOIN v_ProductRoutes pr ON pr.ProductID = p.ID 
				INNER JOIN ProductCategories pc ON pc.ID = p.Category
				WHERE a.prdID = <cfqueryPARAM value="#attributes.productID#" CFSQLType='cf_sql_integer'/>
					AND a.ascType = 'R'
				ORDER BY category, p.Active DESC, p.Manufacturer, p.ModelNumber
			</cfquery>
			<cfquery name="checkCategory" datasource="#dsn#">
				SELECT CASE WHEN controlledCategories.categoryID IS NOT NULL THEN 1 ELSE 0 END AS 'isControlledCategory'
				FROM Products p
				LEFT JOIN (
					SELECT categoryID
					FROM dbo.hierarchy_GetChildren(97)
					WHERE categoryID <> 240 --Mini-Split System Accessories
					UNION
					SELECT categoryID
					FROM dbo.hierarchy_GetChildren(17)
					UNION
					SELECT categoryID
					FROM dbo.hierarchy_GetChildren(18)
					UNION
					SELECT categoryID
					FROM dbo.hierarchy_GetChildren(614)
					UNION
					SELECT categoryID
					FROM dbo.hierarchy_GetChildren(126)
					UNION
					SELECT categoryID
					FROM dbo.hierarchy_GetChildren(128)
					UNION
					SELECT 656
					UNION
					SELECT 97
				) controlledCategories
				ON controlledCategories.categoryID = p.Category
				WHERE p.ID = <cfqueryPARAM value="#attributes.productID#" CFSQLType='cf_sql_integer'/>
			</cfquery>
			<div id="report">
				<table>
					<tr>
						<th>Accessories to this Product:</th>
						<th>
							<div class="tooltip-info rel">
								Required Components <a class="show-tooltip" id="req-comp"><i class="icon-info"></i></a>
								<div class="tooltip-main adjust-tooltip-arrow" id="req-comp-tooltip">
									<div class="tooltip-main-head" style="background: ##f8f8f8; padding: 4px 10px; font-weight: bold; border-top-left-radius: 3px; border-top-right-radius: 3px;">
										<h5 style="font-weight: bold;">Required Components</h5>
									</div>
									<div class="tooltip-main-body" style="padding: 10px;">
										<p>Adds product to Required Component area in<br/>the Accessories section of the product page.</p>
									</div>
									<a class="tooltip-close" style=""></a>
								</div>
							</div>
						</th>
						<th>
							<div class="tooltip-info rel">
								"Add On" Items <a class="show-tooltip" id="addon"><i class="icon-info"></i></a>
								<div class="tooltip-main adjust-tooltip-arrow" id="addon-tooltip" style="top: -142px; left: -54px;">
									<div class="tooltip-main-head" style="background: ##f8f8f8; padding: 4px 10px; font-weight: bold; border-top-left-radius: 3px; border-top-right-radius: 3px;">
										<h5 style="font-weight: bold;">"Add On" Items</h5>
									</div>
									<div class="tooltip-main-body" style="padding: 10px;">
										<p>Adds short description and checkbox under<br/>Add to Cart button. Limit 5 choices of in stock<br/>items.</p>
									</div>
									<a class="tooltip-close" style=""></a>
								</div>
							</div>
						</th>
						<cfif checkCategory.isControlledCategory>
							<th>
								<div class="tooltip-info rel">
									Accessories Pop-Up <a class="show-tooltip" id="pop-up"><i class="icon-info"></i></a>
									<div class="tooltip-main adjust-tooltip-arrow" id="pop-up-tooltip" style="top: -140px; left: -46px;">
										<div class="tooltip-main-head" style="background: ##f8f8f8; padding: 4px 10px; font-weight: bold; border-top-left-radius: 3px; border-top-right-radius: 3px;">
											<h5 style="font-weight: bold;">Accessories Pop-Up</h5>
										</div>
										<div class="tooltip-main-body" style="padding: 10px;">
											<p>Triggers a pop-up when selecting Add to Cart to<br/>display the selected accessory items across<br/>multiple categories.</p>
										</div>
										<a class="tooltip-close" style=""></a>
									</div>
								</div>
							</th>
						</cfif>
					</tr>
				<cfif getAcc.recordcount GT 0>
					<cfoutput query="getAcc" group="category">
						<tr>
							<td colspan="#checkCategory.isControlledCategory ? 4 : 3#" style="background-color: ##efefff;"><strong>#getAcc.category#</strong></td>
						</tr>
						<cfoutput>
							<tr>
								<td <cfif !getAcc.Active>style='color:##C0C0C0'</cfif>>
									<a <cfif !getAcc.Active>style='color:##C0C0C0'</cfif>target="_blank" href="#getAcc.url#">#getAcc.Manufacturer# / #getAcc.ModelNumber#</a>
									<br>
									#getAcc.ListDescription#
								</td>
								<td style="text-align:center">
									<input class="acc-cb" id="acc-cb-#getAcc.ID#" value=#getAcc.ID# type="checkbox" <cfif getAcc.accRequired>checked</cfif>></input>
								</td>
								<td style="text-align:center">
									<input class="addon-cb" id="addon-cb-#getAcc.ID#" value=#getAcc.ID# type="checkbox" <cfif getAcc.isAddOn>checked</cfif>></input>
								</td>
								<cfif checkCategory.isControlledCategory>
									<td style="text-align:center">
										<input class="popup-cb" id="popup-cb-#getAcc.ID#" value=#getAcc.ID# type="checkbox" <cfif getAcc.isPopUp>checked</cfif>></input>
									</td>
								</cfif>
							</tr>
						</cfoutput>
					</cfoutput>
				<cfelse>
					<cfoutput><tr><td colspan="#checkCategory.isControlledCategory ? 4 : 3#">None Found</td></tr></cfoutput>
				</cfif>
				</table>
			</div>
		</td>
	</tr>
	
	<tr>
		<td colspan="2" style="padding:10px">
			<button id="sub_req_items">Save Required Items</button><br>
		</td>
	</tr>
	<tr>
		<td colspan="2" style="padding:10px">
			<small id="save_req_items_success" style="border: 1px solid green;background-color: rgb(102, 228, 102);padding: 6px; color: green;border-radius: 3px; display:none"></small><br>
		</td>
	</tr>
</table>

<script type="text/javascript">
	j$('.show-tooltip').click(function(){
		j$('.tooltip-main').each(function() {
			j$(this).removeClass('active');
		})

		var id = j$(this).attr('id');
		j$('#'+ id + '-tooltip').addClass('active');
	})

	j$('.tooltip-close').click(function() {
		j$(this).parent().removeClass('active');
	})

	// Close tooltips when clicked outside
	j$(document).mouseup(function(e) {
		var tooltips = j$('.tooltip-main');
		var event = e;

		tooltips.each(function() {
			if(!j$(this).is(event.target) && j$(this).has(event.target).length === 0) {
				j$(this).removeClass('active');
			}
		})
	})

	// Handle display logic of the checkboxes. 
	j$('.addon-cb, .popup-cb').each(function(){
		j$(this).click(function() {
			var numChecked = 0;
			j$('.addon-cb').each(function() {
				if(j$(this).prop('checked')) {
					numChecked++;
				}
			})

			//Do not allower user to select 
			if(numChecked > 5) {
				event.preventDefault();
			} else {
				var accID = j$(this).val();
			
				if(j$(this).prop('checked')) {
					if(j$(this).hasClass('addon-cb')){
						j$('.popup-cb[value="' + accID + '"]').prop('checked', false);
					} else if(j$(this).hasClass('popup-cb')) {
						j$('.addon-cb[value="' + accID + '"]').prop('checked', false);
					}
				}
			}		
		})
	})
	
	//Submit the required accessories
	j$("#sub_req_items").click(function() {
		var required = [];
		j$(".acc-cb").each(function() {
			if(this.checked) { required[required.length] = j$(this).val(); }
		});

		var addon = [];
		j$(".addon-cb").each(function() {
			if(this.checked) { addon[addon.length] = j$(this).val(); }
		});

		var popup = [];
		j$(".popup-cb").each(function() {
			if(this.checked) { popup[popup.length] = j$(this).val(); }
		});

		j$.post("./ajax_SubmitReqAcc.cfm?product=<cfoutput>#attributes.productID#</cfoutput>&check=" + required.join(", ") + "&addon=" + addon.join(", ") + "&popup=" + popup.join(", "), "", function(data, status) {
			j$("#save_req_items_success").html("Saved Required Accessories!").show();
		});
	});
</script>
<style>
.tooltip-icon {
	position: relative;
	top: 0;
	left: 0;
}

.tooltip-main {
	position: absolute;
	top: -120px;
  left: -17px;
	z-index: 5;
	display: none;
	width: 300px;
	border-radius: 4px;
	background: #fff;
	box-shadow: 0 1px 9px rgba(0, 0, 0, 0.3);
}
.tooltip-main::after {
	content: '';
	position: absolute;
	width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
	border-right: 10px solid transparent;
	border-top: 10px solid #fff;
	left: 50%;
	transform: translateX(-50%);
}
.tooltip-info {
	position: relative;
}
.tooltip-main.active {
	display: block !important;
	z-index: 1000;
}
.tooltip .tooltip-main-head {
	overflow: hidden;
}

.tooltip-main-head h5 {
	text-transform: uppercase;
}

.tooltip-main-body p {
	font-size: 13px;
	font-weight: 400;
	line-height: 1.67;
	margin: 0;
}
.tooltip-close {
	position: absolute;
	top: 14px;
  right: 9px;
	width: 15px;
	height: 15px;
	background: url("/css/images/close-icon.png") no-repeat 0 0;
	background-size: contain;
}

.tooltip-close:hover {
	opacity: 0.8;
	filter: alpha(opacity=80);
}

.icon-info {
	width: 14px;
	height: 14px;
	background: url("/css/images/icon-info.png") no-repeat 0 0;
	display: inline-block;
	margin-bottom: -2px;
}

</style>
<cfinclude template="/partnernet/shared/_footer.cfm">
