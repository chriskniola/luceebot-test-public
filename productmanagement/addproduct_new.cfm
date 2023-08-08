<!-----------------------------------------------------------
NAME: addproduct_new.cfm
PURPOSE: gateway to adding a new product to the system
DATE CREATED: 2007-1-29
AUTHOR: JT
CHANGE HISTORY:
----------------------------------------------------------->

<cfset screenID = "240">
<cfset recordhistory = 0>

<cfparam name="attributes.manufacturer" default="">
<cfparam name="attributes.modelnumber" default="">
<cfparam name="attributes.listdescription" default="">

<cfset popup = 1>
<cfset recordhistory = 0>

<cfinclude template="/partnernet/shared/_header.cfm">

<cfoutput>
	<div class="title">Add a new product &nbsp; OR &nbsp; <a href="/partnernet/vendors/searchProducts.cfm">Add from Vendor Products</a></div>

	<form name="searchform" action="#cgi.script_name#" method="post" onSubmit="return getreport();">
		<div class="options" id="options">
			<table>
				<tr>
					<th colspan="2">Add the following product:</th>
				</tr>
				<tr>
					<th>Manufacturer</th><td><input type="text" name="manufacturer" value="#attributes.manufacturer#" size="50"></td>
				</tr>
				<tr>
					<th>Model Number</th><td><input type="text" name="modelnumber" value="#attributes.modelnumber#" size="50"></td>
				</tr>
				<tr>
					<th>Short Description</th><td><input type="text" name="listdescription" value="#attributes.listdescription#" size="50"></td>
				</tr>

				<tr><th></th><td>Enter the values as they will appear on the web site, then click "Check for Duplicates."<br>You will NOT need to re-enter the information above.<br><br><input type="submit" value="Check For Duplicates" name="Continue"></td></tr>
			</table>
		</div>
	</form>
</cfoutput>

<div id="ContinuetoAdd" style="display:none;" align="center">
	<cfoutput>
		<div class="alertbox">Check the products below and verify that this is not a duplicate product. <br><A href="javascript:addproduct();">This is not a duplicate product. Continue to Add.</A></div>
	</cfoutput>
</div>

<div id="report">

</div>
<script type="text/javascript">

function copydetail(detail) {
	document.searchform.criteria.value = detail;
	getreport();
}

function addproduct() {
	var path = '/templates/object.cfm?objecttype=product&action=edit&';
	path += 'manufacturer=' + document.searchform.manufacturer.value + '&modelnumber=' + document.searchform.modelnumber.value + '&listdescription=' + document.searchform.listdescription.value;
	document.location = path;
}

function getreport()
{
	if (document.searchform.manufacturer.value != '' && document.searchform.modelnumber.value != '') {
		elm=document.getElementById("report");
		elm.innerHTML = 'Checking for potential duplicate products...';

		objXml.open("GET","/partnernet/productmanagement/ajax_searchproducts.cfm?recommendpostback=0&criteria=" + document.searchform.manufacturer.value + " "+document.searchform.modelnumber.value + " "+document.searchform.listdescription.value, true);
		objXml.onreadystatechange=function() {
		   if (objXml.readyState==4) {
				elm.innerHTML= objXml.responseText;
				document.getElementById('ContinuetoAdd').style.display = document.getElementById('report').style.display;
		  }
		 }
		objXml.send(null);


	} else
		{alert('Manufacturer and Model Number cannot be blank.');}
	return false;
}

var nav4 = window.Event ? true : false;
if (nav4){
	objXml = new XMLHttpRequest();
}else{
	objXml = new ActiveXObject("Microsoft.XMLHTTP");
}

</script>
<cfinclude template="/partnernet/shared/_footer.cfm">

