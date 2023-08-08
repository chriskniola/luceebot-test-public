<cfsetting showdebugoutput="No">

<!-----------------------------------------------------------
NAME: /productmanagement/searchproducts_manager.cfm
PURPOSE: allows searching across all vendor products
DATE CREATED: 2008-3-28
AUTHOR: JT
CHANGE HISTORY:

----------------------------------------------------------->

<cfset screenID = "300">
<cfset useFlashMessages = 1 />
<cfparam name="attributes.maxrows" default="100">
<cfparam name="attributes.criteria" default="">
<cfparam name="attributes.filter" default="">
<cfparam name="attributes.resultformat" default="updated"><!--- standard --->
<cfparam name="attributes.createdby" default="#session.user.ID#">
<cfparam name="attributes.approvalstatus" default="0">
<cfparam name="attributes.submit" default="">
<cfparam name="attributes.isHidden" default="0">
<cfparam name="attributes.updatenotes" default="">
<cfparam name="attributes.productstate" default="">
<cfparam name="attributes.reason" default="">
<cfparam name="attributes.prodstoupdate" default="">

<cfset activationmsg = ''>

<cfinvoke component="#APPLICATION.user#" method="returnpermission" returnvariable="isadmin">
	<cfinvokeargument name="screenID" value="995">
</cfinvoke>


<cfinvoke component="#APPLICATION.user#" method="returnpermission" returnvariable="isapprover">
	<cfinvokeargument name="screenID" value="1005">
</cfinvoke>


<cfif session.user.id EQ 465 AND attributes.submit IS "">
	<cfset attributes.createdby = "">
	<cfset attributes.approvalstatus = 2>
	<cfset attributes.submit = "Search">

<cfelseif isadmin AND attributes.submit IS "">
	<cfset attributes.createdby = "">
	<cfset attributes.approvalstatus = 3>
	<cfset attributes.submit = "Search">

<cfelseif attributes.submit IS "">
	<cfset attributes.createdby = session.user.ID>
	<cfset attributes.isHidden = "0">
	<cfset attributes.approvalstatus = 0>
	<cfset attributes.submit = "Search">

</cfif>


<cfquery name="distinctusers" datasource="#DSN#">
SELECT DISTINCT prdcreatedby,firstname + ' ' + lastname as username
FROM products INNER JOIN tblSecurity_Users u ON products.prdcreatedby = u.ID
WHERE (isreadyforapproval = 1 AND active = 0)
	OR (prdcreated > '2008-1-1')
	OR prdcreatedby = #val(attributes.createdby)#

UNION

SELECT DISTINCT createdby,firstname + ' ' + lastname as username
FROM productcategories pc INNER JOIN tblSecurity_Users u ON pc.createdby = u.ID
WHERE (isreadyforapproval = 1 AND active = 0)
	OR (pc.created > '2008-1-1')
	OR pc.createdby = #val(attributes.createdby)#
</cfquery>

<cfquery name="productstates" datasource="#DSN#">
SELECT id,name,isActive,isOrderable,isObsolete,isActiveOnStock
	, CASE WHEN id IN (SELECT ps.id
						FROM tblProductStates ps
						INNER JOIN tblProductStateSecurityGroups sg ON sg.productStateID = ps.ID
						INNER JOIN tblSecurity_UserGroups ug ON ug.groupID = sg.groupID AND ug.userID = <cfqueryparam sqltype="INT" value="#session.user.id#">)
		THEN 0 ELSE 1 END AS Disabled
FROM tblProductStates
</cfquery>

<cfif attributes.submit IS "update" AND attributes.productstate NEQ "" AND attributes.prodstoupdate NEQ "">
	<cfquery name="getproducts" datasource="#DSN#">
		SELECT productID,productStateID
		FROM tblProductStateAssociations
		WHERE ProductID IN (<cfqueryparam sqltype="INT" list="true" value="#attributes.prodstoupdate#">)
	</cfquery>

	<cfquery name="getstatesettings" dbtype="query">
		SELECT isActive,isOrderable,isObsolete,isActiveOnStock
		FROM productstates
		WHERE ID = <cfqueryparam sqltype="int" value="#attributes.productstate#">
			AND Disabled = 0
	</cfquery>
	<cfquery name="superAdmin" datasource="#DSN#">
		SELECT GroupID
		FROM tblSecurity_UserGroups
		WHERE GroupID = 6 AND UserID = <cfqueryparam sqltype="int" value="#session.user.id#">
	</cfquery>

	<cfif NOT getstatesettings.recordCount>
		<cfsavecontent variable="activationmsg">
			<p>You do not have permission to change products to the submitted product state.</p>
		</cfsavecontent>
	<cfelse>
		
		<cfset objPV = CreateObject("component", "alpine-objects.ProductActivationFilter.ProductValidator")>
		<cfset objUtils = CreateObject("component", "alpine-objects.objectutils")>
		
		<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
		<cfloop query="getproducts">
			<cfif productStateID NEQ attributes.productstate>
				<cfset activationCheckPassed = true>

				<cfif attributes.productState LTE 5>
					<cfset activationCheck = objPV.init(getproducts.productID).validate()>
					<cfif activationCheck.code EQ "Fail" AND NOT superAdmin.recordcount>
						<cfset activationCheckPassed = false>
					</cfif>
					<cfif activationCheck.details.recordcount>
						<cfsavecontent variable="activationmsg">
							<cfoutput>
								#activationmsg#
								#getproducts.productID#: <span class="#activationCheck.code#ed">#activationCheck.code#ed</span><cfif activationCheck.code EQ "Fail" AND superAdmin.recordcount> but Product State changed</cfif><br>
							</cfoutput>
							<table>
								<tr>
									<th>Type</th>
									<th>Message</th>
								</tr>
								<cfoutput query="activationCheck.details">
									<tr class="#activationCheck.details.type#">
										<td>#activationCheck.details.type#</td>
										<td>#activationCheck.details.message#</td>
									</tr>
								</cfoutput>
							</table>
							<hr>
						</cfsavecontent>
					</cfif>
				</cfif>

				<cfif activationCheckPassed>
					<cfquery datasource="#DSN#">
						DECLARE @prod INT = <cfqueryparam sqltype="INT" value="#getproducts.productID#">
						DECLARE @purchasingStatusID TINYINT = <cfqueryparam sqltype="INT" value="#attributes.PurchasingStatusID#">

						UPDATE Products SET
							isapproved=0
							,isreadyforapproval=0
							<cfif attributes.productState LTE 5>,ishidden=1</cfif>
							<cfif getstatesettings.isactive NEQ "">,Active=<cfqueryparam sqltype="BIT" value="#getstatesettings.isactive#"></cfif>
							,isOrderable=<cfqueryparam sqltype="BIT" value="#getstatesettings.isOrderable#">
							,prdisObsolete=<cfqueryparam sqltype="BIT" value="#getstatesettings.isObsolete#">
							,activeonstock=<cfqueryparam sqltype="BIT" value="#getstatesettings.isactiveonstock#">
							,PurchasingStatusID=@purchasingStatusID
						WHERE ID = @prod

						UPDATE tblProductStateAssociations SET productStateID=<cfqueryparam sqltype="INT" value="#attributes.productstate#">
						WHERE productID = @prod

						UPDATE ii
						SET PurchasingStatusID = @purchasingStatusID
						FROM InventoryItems ii
						INNER JOIN InventoryItemLink iil ON iil.InventoryItemID = ii.ID
						WHERE iil.ProductID = @prod
							AND NOT EXISTS (
								SELECT TOP 1 1 
								FROM tblproductkits
								WHERE kitmasterprodID = @prod
							)
					</cfquery>

					<cfset productUpdatedPublisher.publish({ 'id': productID })>

					<cfset logmessage = "Product State changed from&nbsp;&nbsp;<font color=""#productStateID GT 5? 'red' : 'green'#"">#listGetAt(valuelist(productstates.name),listFind(valuelist(productstates.id),productStateID))#</font>&nbsp;&nbsp;to&nbsp;&nbsp;<font color=""#attributes.productstate GT 5? 'red' : 'green'#""><strong>#listGetAt(valuelist(productstates.name),listFind(valuelist(productstates.id),attributes.productstate))#</strong></font> (mgmt tool)">
					<cfif attributes.reason NEQ ''>
						<cfset logmessage &= "<br><strong>Reason:</strong> #attributes.reason#">
					</cfif>
					<cfif attributes.updatenotes NEQ ''>
						<cfset logmessage &= "<br><strong>Notes:</strong> #attributes.updatenotes#">
					</cfif>
					<cfset objUtils.putlog(objID="#productID#",value="#logmessage#")>
				</cfif>
			</cfif>
		</cfloop>
		<cfif listFind("2,3,4,5",attributes.productState)>
			<cfset this.productID = attributes.prodstoupdate>
			<cfinclude template="/partnernet/scheduledtasks/updateActiveOnStock.cfm">
		</cfif>
	</cfif>
</cfif>

<cfset showExt = 0>
<cfinclude template="/partnernet/shared/_header.cfm">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.5/jquery.fancybox.min.css" />
<script src="https://cdnjs.cloudflare.com/ajax/libs/fancybox/2.1.5/jquery.fancybox.pack.js"></script>

<a href="javascript:history.go(-1);"><< Back</a><br><br>

<div class="large" align="center">Product & Category Activation State Team Approval</div>
<cfoutput>
	<form name="searchform" action="#cgi.script_name#" method="post">
		<div class="options floatleft" id="options" style="width:500px;">
			<div class="tabHeader" style="height:115px;">
				<strong>Enter Search Criteria</strong><br><br>
				<div class="tabContent">
					<div class="tabTitle">Status</div>
					<table id="statustable">
						<tr>
							<td>
								<strong>Status:</strong><br>
									<select name="approvalstatus">
										<option value="0" <cfif attributes.approvalstatus EQ "0">SELECTED</cfif>>Unapproved</option>
										<option value="1" <cfif attributes.approvalstatus EQ "1">SELECTED</cfif>>Not Ready for Approval</option>
										<option value="2" <cfif attributes.approvalstatus EQ "2">SELECTED</cfif>>Ready for Approval</option>
										<option value="3" <cfif attributes.approvalstatus EQ "3">SELECTED</cfif>>Approved but Inactive</option>
										<option value="4" <cfif attributes.approvalstatus EQ "4">SELECTED</cfif>>Approved and Active</option>
									</select>
							</td>
							<td>
								<strong>Created by:</strong><br>
									<select name="createdby">
										<option value="">All Users</option>
										<cfloop query="distinctusers">
											<option value="#prdcreatedby#" <cfif attributes.createdby EQ prdcreatedby>SELECTED</cfif>>#username#</option>
										</cfloop>
									</select>
							</td>
							<td>
								<strong>Show:</strong><br>
									<select name="isHidden">
										<option value="" <cfif attributes.isHidden EQ "">SELECTED</cfif>>All Matches</option>
										<option value="1" <cfif attributes.isHidden EQ "1">SELECTED</cfif>>Only Hidden</option>
										<option value="0" <cfif attributes.isHidden EQ "0">SELECTED</cfif>>Not Hidden</option>
									</select>
							</td>
						</tr>
					</table>
				</div>
				<div class="tabContent <cfif attributes.criteria NEQ ''> tabSelected</cfif>">
					<div class="tabTitle">Product</div>
					<table>
						<tr>
							<td>
								<strong>Criteria:</strong><br>
								<input type="text" name="criteria" value="#attributes.criteria#" size="45">
							</td>
							<td>
								<strong>Filter:</strong><br>
								<select name="filter">
									<option value="">None</option>
									<option value="active" <cfif attributes.filter EQ "active">SELECTED</cfif>>Active & Active on Stock</option>
									<option value="inactive" <cfif attributes.filter EQ "inactive">SELECTED</cfif>>Inactive Only</option>
									<option value="nosnd" <cfif attributes.filter EQ "nosnd">SELECTED</cfif>>No SND/Open Box</option>
								</select>
							</td>
						</tr>
					</table>
				</div>
			</div>
			<br>
			<input type="submit" value="Search" name="Submit" onclick="checktab();">
		</div>
		<div class="options floatleft"style="background:##FFDFB0;position:relative;">
			<div class="tabHeader" style="height:145px;">
				<strong>Change State on Selected Rows</strong><br><br>
				<table>
					<tr>
						<td>
							<div class="floatleft" style="display:inline-block;">
								<input type="hidden" name="prodstoupdate" value="">
								<select name="productstate" style="width:380px;" onchange="deactivatecheck();">
									<option value="">Select Product State</option>
								<cfloop query="productstates">
									<option value="#id#" <cfif disabled>DISABLED</cfif>>#name#</option>
								</cfloop>
								</select>
							</div>
							<div class="ui-state-highlight floatleft" style="width:0em;border:0;cursor:help;margin-right:16px;display:inline-block;"><div id="statehelp" class="ui-icon ui-icon-info"></div></div>
						</td>
					</tr>
					<tr style="height:26px;">
						<td>
							<select id="purchasing" name="PurchasingStatusID" style="width:380px;">
								<option value="">Select Purchasing Status</option>
							</select>
						</td>
					</tr>
					<tr style="height:26px;">
						<td>
							<select name="reason" style="display:none;width:380px;" onchange="checkreason();">
								<option value="">Select Change Reason</option>
								<option value="Manufacturer Obsolescence">Manufacturer Obsolescence</option>
								<option value="No Purchasing Relationship">No Purchasing Relationship</option>
								<option value="One-Time Purchase/Overstock Deal">One-Time Purchase/Overstock Deal</option>
								<option value="Shipping Issue with Product">Shipping Issue with Product</option>
								<option value="Technical Issue with Product">Technical Issue with Product</option>
								<option value="Product/Product Line Not Profitable">Product/Product Line Not Profitable</option>
								<option value="Temporarily Removed to Correct Issue with Product">Temporarily Removed to Correct Issue with Product</option>
								<option value="Make SND Product Orderable">Make SND Product Orderable</option>
								<option value="Other">Other</option>
							</select>&nbsp;
						</td>
					</tr>
					<tr>
						<td>
							<textarea name="updatenotes" value="#attributes.updatenotes#" style="height:36px;width:380px;" placeholder="Notes"></textarea>
						</td>
					</tr>
				</table>
			</div>
			<br>
			<div style="height:21px;">
				<input type="submit" value="Update" name="Submit" onclick="return checkstate();" style="float:left;">
				<cfif len(trim(activationmsg))>
					<div style="float:right;line-height:22px;cursor: pointer;" onclick="showActivationMsg();">Show Recent Product Activation Check Results</div>
					<div id="activationmsg" style="display:none;">
						<div class="report">
							<cfif superAdmin.recordcount AND findNoCase("failed",activationmsg)>
								<div>*Product state updated despite failure since you are an administrator.</div><br />
							</cfif>
							#activationmsg#
						</div>
					</div>
					<script>
						function showActivationMsg(){
							j$.fancybox({
								width:720,
								height:780,
								fitToView: false,
								type:'ajax',
								content: j$('##activationmsg').html()
							});
						}
						showActivationMsg();
					</script>
				</cfif>
			</div>
		</div>

	</form>
</cfoutput>

<style>
	td.pointer {cursor: pointer;}
</style>

<script language="javascript">
function changestatus(thetd,type,objectID,column){
	var d = new Date();
	var path = '';
	if (type == 'p')
		path = 'changestatus.cfm?productID=' + objectID + '&column=' + column;

	if (type == 'c')
		path = 'changestatus.cfm?categoryID=' + objectID + '&column=' + column;

	//if(confirm('Are you sure you want to change the status?')){	}
		thetd.innerHTML = 'wait...';
		j$.ajax(path + "&ts=" + d.getTime(),{
				method: 'get',
				onSuccess: function(transport) {
					thetd.innerHTML = transport.responseText.trim();

					if(column == 'isreadyforapproval'){
						if (type == 'p')
							path = 'changestatus.cfm?productID=' + objectID;

						if (type == 'c')
							path = 'changestatus.cfm?categoryID=' + objectID;
						j$.ajax(path + "&column=reqtype&ts=" + d.getTime(),{
							method: 'get',
							onSuccess: function(transport) {
								j$('#reqtype' + objectID).text(transport.responseText.trim());
							}
						})
					}

				}
			})
}

function changecolor(thelink) {
document.getElementById(thelink).style.color = 'red';
}

function checktab(){
	if (j$('#statustable').is(":visible"))
		j$('input[name="criteria"]').val('');
}

function checkstate(){
	if(j$('select[name="productstate"]').val() > 5 && j$('select[name="reason"]').val() == ''){
		alert('Changing product state(s) to inactive requires a reason.');
		j$('select[name="reason"]').focus();
		return false;
	}
	if(j$('select[name="reason"]').val() == 'Other' && j$('textarea[name="updatenotes"]').val() == ''){
		alert('Deactivation reason of "Other" requires a note.');
		j$('textarea[name="updatenotes"]').focus();
		return false;
	}
	if(j$('select[name="productstate"]').val() == ''){
		alert('No product state selected');
		return false;
	}
	j$('input[name="prodstoupdate"]').val('');
	j$('input[name="stateselect"]').each(function(){
		if(j$(this).is(":checked")){
			if(j$('input[name="prodstoupdate"]').val() == '')
				j$('input[name="prodstoupdate"]').val(j$(this).val());
			else
				j$('input[name="prodstoupdate"]').val(j$('input[name="prodstoupdate"]').val()+','+j$(this).val());
		}
	});
	if(j$('input[name="prodstoupdate"]').val() == ''){
		alert('Nothing selected to update!');
		return false;
	}
	return true;
}

function checkreason(){
	if(j$('select[name="reason"]').val() == 'Other')
		j$('textarea[name="updatenotes"]').focus();
}

function deactivatecheck(){
	var productState = j$('select[name="productstate"]').val();

	if(productState > 1)
		j$('select[name="reason"]').prop('required',true).prop('disabled',false).show();
	else
		j$('select[name="reason"]').val('').prop('required',false).prop('disabled',true).hide();

	j$.ajax({
		'url': '/partnernet/product/purchasingStatuses/' + productState,
		'success': function(r) {
			j$('#purchasing').empty();
			for(option of r) {
				j$('#purchasing').append('<option value="' + option.id + '">' + option.Label + '</option>');
			}
		}
	});
}


function hili(thetd){
	if(j$(thetd).find('input').attr('checked')){
		j$(thetd).find('input').removeAttr('checked');
		j$(thetd).parent().css('background-color','');
	}
	else {
		j$(thetd).find('input').attr('checked','checked');
		j$(thetd).parent().css('background-color','#FFDFB0');
	}
}

j$("#statehelp").click(function() {
	j$.fancybox({
		        width:720,
				height:780,
				fitToView: false,
				type:'ajax',
				href:'/partnernet/reports/products/rpt_productstatedescriptions.cfm'
		    });
	});
</script>

<!---

Product statuses:
unapproved = if isapproved EQ 0
ready for approval = if it is not yet active but ready for approval
approved = if isapproved
active, inactive

 --->
<cfif attributes.submit IS NOT "">
	<cfif listLen(attributes.criteria," ") GT 2>
		<cfset attributes.criteria = listToArray(attributes.criteria,' ').slice(1,2).toList(' ')>
	</cfif>

	<cfquery name="searchProducts" datasource="#DSN#">
	DECLARE @tmp TABLE
		(objID int
			,route varchar(260)
			,manufacturer varchar(75)
			,modelnumber varchar(75)
			,listdescription varchar(255)
			,modifiedby varchar(50)
			,modified datetime
			,createdby varchar(50)
			,created datetime
			,categoryname varchar(75)
			,active bit
			,username varchar(50)
			,isapproved bit
			,isreadyforapproval bit
			,emailaddress varchar(75)
			,type char(1)
			,objID2 varchar(75)
			,score float
			,isobsolete int
			,prodstatename varchar(75)
			,reqtype varchar(15)
			,ishidden bit
			,isonsale bit
			,price money
			,vendorcount int
			,qtyavailable int
			,qtyonorder int
			,onorderdate datetime
		)

	INSERT INTO @tmp
	SELECT TOP 300 p.ID, CONCAT('/product/', pr.route) AS 'route', manufacturer, modelnumber, listdescription
		,CASE WHEN prdmodifiedby IS NULL THEN prdcreatedby ELSE prdmodifiedby END AS modifiedby, prdmodified
		,CASE WHEN prdcreatedby IS NULL THEN prdmodifiedby ELSE prdcreatedby END AS createdby, prdcreated, pc.listname, p.active
		,firstname + ' ' + left(lastname,1) as username, p.isapproved, p.isreadyforapproval, u.emailaddress,'p', pc.ID
		,0.0<cfloop list="#attributes.criteria#" delimiters=" " index="i">
				<cfif isnumeric(i)>+ CASE WHEN p.ID = #i# THEN 3 ELSE 0 END</cfif>
				+ CASE WHEN manufacturer LIKE '%#i#%' THEN 1 ELSE 0 END
				+ CASE WHEN category LIKE '%#i#%' THEN 1 ELSE 0 END
				+ CASE WHEN listdescription LIKE '#i#%' THEN 1 ELSE 0 END
				+ CASE WHEN listdescription LIKE '%#i#%' THEN 1 ELSE 0 END
				+ CASE WHEN modelnumber LIKE '%#i#%' THEN 1 ELSE 0 END
				+ CASE WHEN modelnumber LIKE '#i#%' AND manufacturer NOT LIKE '%#i#%' AND listdescription NOT LIKE '%#i#%' THEN 2 ELSE 0 END
				<!--- + CASE WHEN Manufacturer LIKE '%#i#%' AND modelnumber NOT LIKE '%#i#%' AND listdescription NOT LIKE '%#i#%' THEN 2 ELSE 0 END --->
				- CASE WHEN listdescription NOT LIKE '% #i# %' AND modelnumber NOT LIKE '% #i# %' AND Manufacturer NOT LIKE '% #i# %' THEN -1 ELSE 0 END
				- CASE WHEN category LIKE '%#i#%' THEN -1 ELSE 0 END
				</cfloop> as score
		,ps.isobsolete
		,ps.name
		,CASE WHEN p.isreadyforapproval = 1
			  THEN CASE WHEN a.productStateID < 6 THEN 'Deactivate'
						 WHEN p.prdactivedays > 0 THEN 'Activate'
						 ELSE 'Activate New'
					 	END
			  ELSE '' END
		,p.ishidden
		,p.isonsale
		,p.retailPrice
		,(SELECT
				COUNT(ins.ID)
			FROM InventoryStock ins
			INNER JOIN InventoryItemLink iil ON iil.InventoryItemID = ins.InventoryItemID
			INNER JOIN v_locations l ON l.locationTypeId = ins.LocationTypeID
				AND l.locationId = ins.LocationID
				AND l.active = 1
			WHERE iil.productID = p.ID) AS 'vendorcount'
		,tfs.FulfillableStock AS 'qtyavailable'
		,(SELECT MIN(s.qtyOnOrder) AS 'qtyOnOrder'
			FROM InventoryItemLink iil
			CROSS APPLY (
				SELECT ins.InventoryItemId, SUM(ins.QtyOnOrder) / iil.Quantity AS 'qtyOnOrder'
				FROM InventoryStock ins 
				INNER JOIN v_locations l ON l.locationTypeId = ins.LocationTypeID
					AND l.locationId = ins.LocationID
					AND l.active = 1
				WHERE ins.InventoryItemID = iil.InventoryItemID
				GROUP BY ins.InventoryItemID
			) s
			WHERE iil.productID = p.id) as 'qtyonorder'
			,(
	SELECT
		MIN(COALESCE(CONVERT(DATETIME,s.ScheduledDeliveryDate) + CONVERT(DATETIME,s.ScheduledDeliveryTime),s.ExpectedDeliveryDate,vpoi.ExpectedReceiptDate)) AS 'ETA'
	FROM VendorPurchaseOrders vpo
	INNER JOIN Warehouses w ON w.ID = vpo.WarehouseId
	INNER JOIN VendorPurchaseOrderItems vpoi ON vpoi.PurchaseOrderId = vpo.ID
	INNER JOIN SublineItems si ON si.ID = vpoi.SublineItemId
		AND si.Active = 1
		AND si.Closed = 0
		AND si.CustomerPoLineId IS NULL
		AND si.LocationTransferItemId IS NULL
		AND si.BinId IS NULL
	INNER JOIN InventoryItemLink iil ON si.InventoryItemID = iil.InventoryItemID
		AND iil.ProductID = p.ID
	LEFT JOIN ShipmentSublineItemLink ssil ON ssil.SublineItemId = si.ID
	LEFT JOIN Shipments s ON s.ID = ssil.ShipmentId
) AS 'onorderdate'
	FROM products p
		INNER JOIN productcategories pc ON p.category = pc.ID
		LEFT JOIN tblSecurity_Users u ON (prdmodifiedby IS NOT NULL AND prdmodifiedby = u.ID) OR (prdmodifiedby IS NULL AND prdcreatedby = u.ID)
		INNER JOIN ProductRouting pr ON pr.productID = p.ID AND pr.RedirectID IS NULL
		INNER JOIN tblProductStateAssociations a ON p.ID = a.productID
		INNER JOIN tblProductStates ps ON ps.ID = a.productStateID
		INNER JOIN v_TotalFulfillableStock tfs ON tfs.ProductID = p.ID
	WHERE (
		<cfif attributes.criteria NEQ "">
			(0=1
			<cfloop list="#attributes.criteria#" delimiters=" " index="i">
			OR p.Manufacturer LIKE '%#i#%'
			OR p.cmfg LIKE '%#i#%'
			OR p.listdescription LIKE '%#i#%'
			OR pc.listname LIKE '%#i#%'
			OR p.modelnumber LIKE '%#i#%'
			<cfif isnumeric(i)>OR p.category = #i#</cfif>
			<cfif int(val(i)) EQ val(i)>OR CONVERT(varchar, p.ID) = '#val(i)#'</cfif>
			OR p.ID IN (
				SELECT
					iil.productID
				FROM InventoryItemLink iil
				INNER JOIN InventoryItems ii ON ii.ID = iil.InventoryItemID
				WHERE ii.SKU = '#i#')
			</cfloop>
			)
			<cfif attributes.filter EQ "active">
				AND a.productStateID < 6
			<cfelseif attributes.filter EQ "inactive">
				AND a.productStateID > 5
			</cfif>
			<cfif attributes.filter EQ "nosnd">
				AND p.category NOT IN  (96,231)
			</cfif>
		<cfelse>
			<cfif attributes.isHidden NEQ "">
				<cfif attributes.isHidden EQ "0">
					(p.isHidden = 0)
				<cfelseif attributes.isHidden EQ "1">
					(p.isHidden = 1)
				</cfif>
			AND
			</cfif>
			<cfif attributes.approvalstatus EQ "0">
				(p.isapproved = 0)
			<cfelseif attributes.approvalstatus EQ "1">
				(p.isreadyforapproval = 0 AND p.isapproved = 0)
			<cfelseif attributes.approvalstatus EQ "2">
				(p.isreadyforapproval = 1 AND p.isapproved = 0)
			<cfelseif attributes.approvalstatus EQ "3">
				(p.isapproved = 1 AND p.active = 0 AND prdactivedays < 1)
			<cfelseif attributes.approvalstatus EQ "4">
				(p.isapproved = 1 AND p.active = 1)
			</cfif>
			<cfif attributes.createdby IS NOT "">AND prdcreatedby = #val(attributes.createdby)#</cfif>
		</cfif>
		<!--- OR (products.active = 1 AND prdcreated > '2008-1-1') --->
		)
	ORDER BY score desc, p.active desc


	INSERT INTO @tmp
	SELECT TOP 300 pc.ID,'','','',pc.listname
		,CASE WHEN pc.modifiedby IS NULL THEN pc.createdby ELSE pc.modifiedby END AS modifiedby, pc.modified
		,CASE WHEN pc.createdby IS NULL THEN pc.modifiedby ELSE pc.createdby END AS createdby, pc.created,pc.name,pc.active
		,firstname + ' ' + left(lastname,1) as username,pc.isapproved,pc.isreadyforapproval,u.emailaddress,'c',pc.objId
		,0.0<cfloop list="#attributes.criteria#" delimiters=" " index="i">
			<cfif isnumeric(i)>+ CASE WHEN pc.ID = #i# THEN 3 ELSE 0 END</cfif>
			+ CASE WHEN pc.name LIKE '%#i#%' THEN 1 ELSE 0 END
			+ CASE WHEN pc.listname LIKE '%#i#%' THEN 2 ELSE 0 END
			</cfloop> as score
		,''
		,''
		,CASE WHEN pc.isreadyforapproval = 1
			THEN CASE WHEN pc.active = 1 THEN 'Deactivate' ELSE 'Activate' END
			ELSE '' END
		,pc.ishidden
		,''
		,''
		,''
		,''
		,''
		,''
	FROM productcategories pc WITH (NOLOCK)
	LEFT JOIN tblSecurity_Users u ON (pc.modifiedby IS NOT NULL AND pc.modifiedby = u.ID) OR (pc.modifiedby IS NULL AND pc.createdby = u.ID)
	WHERE (
		<cfif attributes.criteria NEQ "">
			0=1
			<cfloop list="#attributes.criteria#" delimiters=" " index="i">
			OR pc.name LIKE '%#i#%'
			OR pc.listname LIKE '%#i#%'
			<cfif isnumeric(i)>OR pc.ID = #i#</cfif>
			</cfloop>
		<cfelse>
			<cfif attributes.isHidden NEQ "">
				<cfif attributes.isHidden EQ "0">
					(pc.isHidden = 0)
				<cfelseif attributes.isHidden EQ "1">
					(pc.isHidden = 1)
				</cfif>
			AND
			</cfif>
			<cfif attributes.approvalstatus EQ "0">
				(pc.isapproved = 0)
			<cfelseif attributes.approvalstatus EQ "1">
				(pc.isreadyforapproval = 0 AND pc.isapproved = 0)
			<cfelseif attributes.approvalstatus EQ "2">
				(pc.isreadyforapproval = 1 AND pc.isapproved = 0)
			<cfelseif attributes.approvalstatus EQ "3">
				(pc.isapproved = 1 AND pc.active = 0)
			<cfelseif attributes.approvalstatus EQ "4">
				(pc.isapproved = 1 AND pc.active = 1)
			</cfif>
			<cfif attributes.createdby IS NOT "">AND createdby = #val(attributes.createdby)#</cfif>
		</cfif>
		<!--- OR (products.active = 1 AND prdcreated > '2008-1-1') --->
		)
	ORDER BY score desc, pc.modified desc

	SELECT TOP 300 *
	FROM @tmp
	ORDER BY type,score desc<cfif attributes.criteria NEQ "">,active desc</cfif>,categoryname, objID2, modelnumber
	</cfquery>


	<cfif searchProducts.recordcount EQ 300>
		<div class="alertbox clear">Maximum of 300 records displayed. Your search has been truncated.</div>
	</cfif>

	<div id="report" class="clear" style="z-index:20;">
			<cfoutput query="searchProducts" group="type">
				<h2><cfif type EQ "c">Categories<cfelse>Products</cfif></h2>
				<cfquery name="counts" dbtype="query">
				SELECT count(type) as matches
				FROM searchProducts
				WHERE type = '#type#'
				</cfquery>
				<table>
					<caption>Displaying #counts.matches# record(s) that match your criteria.</caption>
					<thead>
						<tr>
							<th>Actions</th>
							<th>State</th>
							<th nowrap>Submit<br>for<br>Approval</th>
							<th nowrap>Approval<br>Request<br>Type</th>
							<th>Approved</th>
							<th>Last<br>Modified</th>
							<th><cfif type IS "p">Product<cfelse>Category</cfif> ID</th>
							<cfif type IS "p">
							<th>Manufacturer</th>
							<th>Model Number</th>
							</cfif>
							<th>Description</th>
							<cfif type IS "p">
							<th>Primary Category</th>
							<th>Price</th>
							<th>Vendors</th>
							<th>Qty<br>Avail.</th>
							<th>Qty<br>On<br>Order</th>
							<th>On<br>Order<br>Date</th>
							</cfif>
						</tr>
					</thead>

					<tbody><cfoutput>
				<tr>
					<th scope="row" nowrap="true">
						<cfif type IS "p">

							<a href="javascript:openwin('/partnernet/productmanagement/editframe/default.cfm?productID=#objID#','',800,1100);" onclick="changecolor('link#objID#');" id="link#objID#" class="tiny">edit</a>
							| <a href="javascript: void(0);" onclick="changestatus(this,'#type#','#searchproducts.objID#','ishidden')" class="tiny"><cfif isHidden>unhide<cfelse>hide</cfif></a>
							<cfif active OR NOT isobsolete>
								<br>
								<a href="javascript:addToCart('#route#');" class="button orange tiny" style="padding:5px;margin-top:5px;text-decoration:none;color:white;"><strong>Add to Cart</strong></a>
							</cfif>

						<cfelseif type IS "c">
							<a href="javascript:openwin('/partnernet/categories/editFrame/default.cfm?objID=#objID#','',800,1100);" class="tiny">edit</a>
							| <a href="javascript: void(0);" onclick="changestatus(this,'#type#','#searchproducts.objID#','ishidden')" class="tiny"><cfif isHidden>unhide<cfelse>hide</cfif></a>
						</cfif>
					</th>
					<td nowrap="true" class="pointer" onclick="<cfif type EQ 'p'>hili(this);<cfelseif isadmin OR (type EQ "c" AND isapprover)>changestatus(this,'#type#','#searchproducts.objID#','active');</cfif>">
						<cfif val(searchproducts.active)>
							<font color="green">
								<cfif type EQ "p">
									#replace(prodstatename,"> ","><br>","all")#
								<cfelse>
									active
								</cfif>
							</font>
						<cfelse>
							<font color="red">
								<cfif type EQ "p">
									#replace(prodstatename,"> ","><br>","all")#
								<cfelse>
									inactive
								</cfif>
							</font>
						</cfif>
						<cfif type EQ "p"><input type="checkbox" name="stateselect" value="#objID#" style="display:none;"></cfif>
					</td>
					<cfif NOT isapproved>
						<td class="pointer" onclick="changestatus(this,'#type#','#searchproducts.objID#','isreadyforapproval');"><cfif isreadyforapproval><font color="green">yes</font><cfelse><font color="red">no</font></cfif></td>
					<cfelse>
						<td>approved</td>
					</cfif>
					<td id="reqtype#searchproducts.objID#">#reqtype#</td>
					<td <cfif isadmin OR isapprover>class="pointer" onclick="changestatus(this,'#type#','#searchproducts.objID#','isapproved')"</cfif>><cfif isapproved><font color="green">yes</font><cfelse><font color="red">no</font></cfif></td>

					<!--- <cfif NOT active>

					<cfelse>
						<td colspan="2">active</td>
					</cfif> --->



					<td nowrap>#username#<br>#dateformat(modified,"m/d/yy")#</td>
					<td>#objID#</td>
					<cfif type IS "p">
					<td>#manufacturer#</td>
					<td>#modelnumber#</td>
					</cfif>
					<td>#listdescription#</td>
					<cfif type IS "p">
					<td>#categoryname#</td>
					<td><cfif isonsale>On Sale<br></cfif>#dollarformat(price)#</td>
					<td>#val(vendorcount)# <a href="javascript:openwin('listvendors.cfm?productID=#objID#','',800,1100);">edit</a></td>
					<td>#qtyavailable GT 0 ? qtyavailable : ''#</td>
					<td>#qtyonorder GT 0 ? qtyonorder : ''#</td>
					<td><cfif isdate(onorderdate)>#dateformat(onorderdate,"m/d/yy")#</cfif></td>
					</cfif>
				</tr>
			</cfoutput>
		</tbody>
	</table><br></cfoutput>
	</div>
</cfif>
<cfinclude template="/partnernet/shared/_footer.cfm">


