<cfsetting showdebugoutput="no">

<cfset screenID = "240">

<cfparam name="attributes.manufacturer1" default="">
<cfparam name="attributes.manufacturer2" default="">
<cfparam name="attributes.submit" default="">

<cfinclude template="/partnernet/shared/_header.cfm">

<script type="text/javascript">
function checkForm() {
	var frmMC = document.forms['changemfg'];

	if (frmMC.manufacturer1.value == '') {
		alert( "A manufacturer is required.");
		frmMC.manufacturer1.focus();
    return false;
	}

	if (frmMC.manufacturer2.value == '') {
		alert( "A manufacturer is required.");
		frmMC.manufacturer2.focus();
    return false;
	}

	return true;
}

function mfgInfo(theEl) {
	var mfg = theEl.value;
	var thestring = theEl.name + 'tr';
	var mfgtr = document.getElementById(thestring);
	thestring = theEl.name + 'div';
	var mfgdiv = document.getElementById(thestring);

	mfgdiv.innerHTML = '';

	var path = 'ajax_getmfginfo.cfm?manufacturer=' + escape(mfg);
	j$.ajax(path,{
		method: 'get'
	})
	.success(function(transport) {
		values = eval(transport);
		for(var x=0; x < values.length; x++){
			if(values[x].m.length > 1) {
				mfgdiv.innerHTML = 'Total: ' + values[x].t + ', Active: ' + values[x].a + ', Inactive: ' + values[x].i;
			}
			mfgtr.style.display = '';
		}
	});
}

function pushUp(thevalue,theselect) {
	var strselect = 'manufacturer' + theselect;
	var theEl = document.getElementById(strselect);

	theEl.value = thevalue;

	mfgInfo(theEl);

}

window.onload=function(){
	var theEl = document.getElementById('manufacturer1');

	if (theEl.value != '') {
		mfgInfo(theEl);
	}

	theEl = document.getElementById('manufacturer2');

	if (theEl.value != '') {
		mfgInfo(theEl);
	}

	var theheight = document.body.clientHeight;
	var thediv = document.getElementById('mfglisting');
	thediv.style.height = theheight - 360;

	var row = document.getElementById('scrollhere');
	if (row === undefined || row == null) {
		// do nothing
	} else {
		row.scrollIntoView(true);
	}

}

</script>

<cfif attributes.submit EQ "Submit">

	<cfset mfgsuccess = 0>

	<cfquery name="updatemfgs" datasource="#DSN#">
	DECLARE @product TABLE ([ID] INT)

	UPDATE Products
	SET Manufacturer = '#attributes.manufacturer1#'
		, prdmodified = getDate()
		, prdmodifiedby = #session.user.ID#
	OUTPUT INSERTED.id INTO @product
	WHERE Manufacturer = '#attributes.manufacturer2#'

	SELECT * FROM @product
	</cfquery>

	<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
	<cfloop query="#updatemfgs#">
		<cfset productUpdatedPublisher.publish({ 'id': updatemfgs.id })>
	</cfloop>

	<cfset mfgsuccess = 1>

</cfif>

<cfquery name="mfglist" datasource="#DSN#">
SELECT Manufacturer, COUNT(*) as Total, COUNT(CASE WHEN active = 1 THEN 1 END) as Active, COUNT(CASE WHEN active = 0 THEN 1 END) as Inactive
FROM Products
GROUP BY Manufacturer
ORDER BY Manufacturer
</cfquery>

<div class="options">

	<cfoutput>

	<form name="changemfg" method="post" onsubmit="return checkForm();">

		<table align="center">
			<cfif isDefined("mfgsuccess") AND mfgsuccess EQ 1>
				<tr>
					<td colspan="2">
					<div class="successbox" id="idsuccess">
						Successfully consolidated #attributes.manufacturer2# into #attributes.manufacturer1#!<br>
					</div>
					</td>
				</tr>
			</cfif>
			<tr>
				<th colspan="2" style="text-align: center;"><h2>Consolidate Manufacturers</h2></th>
			</tr>
			<tr>
				<td colspan="2">
					All products with the manufacturer selected in "to consolidate"<br>will be changed to the manufacturer selected in "to keep".<br><br>
					<br>
				</td>
			</tr>
			<tr>
				<td>Manufacturer to keep:</td>
				<td>
					<select name="manufacturer1" id="manufacturer1" tabindex=1 onChange="javascript:mfgInfo(this);">
					<option value=""></option>
					<cfloop query="mfglist">
					<option value="#manufacturer#"<cfif manufacturer EQ attributes.manufacturer1> SELECTED</cfif>>#manufacturer#</option>
					</cfloop>
					</select>
				</td>
			</tr>
			<tr id="manufacturer1tr" style="display:none;">
				<td style="text-align:right;"><div class="mb10">Count:</div></td>
				<td><div id="manufacturer1div" class="mb10"></div></td>
			<tr>
			<tr>
				<td>Manufacturer to consolidate:</td>
				<td>
					<select name="manufacturer2" id="manufacturer2" tabindex=2 onChange="javascript:mfgInfo(this);">
					<option value=""></option>
					<cfloop query="mfglist">
					<option value="#manufacturer#"<cfif manufacturer EQ attributes.manufacturer2> SELECTED</cfif>>#manufacturer#</option>
					</cfloop>
					</select>
				</td>
			</tr>
			<tr id="manufacturer2tr" style="display:none;">
				<td style="text-align:right;">Count:</td>
				<td><div id="manufacturer2div"></div></td>
			<tr>
			<tr>
				<td colspan="2">
					<div class="pt10">&nbsp;</div>
				</td>
			</tr>
			<tr>
				<td>
					<input name="submit" type="submit" value="Submit" tabindex=3>
				</td>
				<td>

				</td>
			</tr>
		</table>

	</form>

	</cfoutput>

</div>

<div class="report" style="width:100%; overflow:auto;" id="mfglisting">
	<table align="center">
		<tr>
			<th colspan="5" style="text-align:center;"><cfoutput>#mfglist.recordcount#</cfoutput> Manufacturers Found</th>
		<tr>
			<th>Manufacturer</th>
			<th>Total Count</th>
			<th>Active</th>
			<th>Inactive</th>
			<th style="text-align:center;">Push Up</th>
		</tr>
		<cfoutput query="mfglist">
			<tr<cfif manufacturer EQ attributes.manufacturer1 AND attributes.manufacturer1 NEQ ""> id="scrollhere"</cfif>>
				<td>#manufacturer#</td>
				<td>#total#</td>
				<td>#active#</td>
				<td>#inactive#</td>
				<td><strong><a href="javascript:;" onClick="pushUp('#manufacturer#','1')" style="padding-left:10px; padding-right:10px; border: 1px solid grey;">1</a>&nbsp;&nbsp;&nbsp;<a href="javascript:;" onClick="pushUp('#manufacturer#','2')" style="padding-left:10px; padding-right:10px; border: 1px solid grey;">2</a></strong></td>
			</tr>
		</cfoutput>
	</table>
</div>

<cfinclude template="/partnernet/shared/_footer.cfm">
