<!-----------------------------------------------------------
NAME: /partnernet/productmanagement/passdescription.cfm
PURPOSE: passes back a product description
DATE CREATED: 2008-3-31
AUTHOR: JT
CHANGE HISTORY:
----------------------------------------------------------->



<cfset screenID = "955">

<cfparam name="attributes.maxrows" default="100">
<cfparam name="attributes.criteria" default="">
<cfparam name="attributes.searchtype" default="Advanced">

<cfinclude template="/partnernet/shared/_header.cfm">

<cfoutput>
	<form name="searchform" action="#cgi.script_name#" method="post" onSubmit="return getreport();">
	<input type="hidden" value="100" name="maxrows">
		<div class="options">
			<table>
				<tr>
					<th colspan="2">Search Alpine products using the criteria below:</th>
				</tr>
				<tr>
					<th>Criteria</th><td><input type="text" name="criteria" value="#attributes.criteria#" size="50"></td>
				</tr>
				<tr><th>&nbsp;</th><td><input type="submit" value="Search" name="search"></td></tr>
			</table>
		</div>
	</form>
</cfoutput>

<div id="spellchecker"></div>

<div id="report"></div>

<cfinclude template="/partnernet/shared/_footer.cfm">

<script type="text/javascript">

function passshortdesc(desc) {
	parent.replaceShortDesc(desc);
}

function passlongdesc(prodID) {
	var path = 'ajax_getprodvalue.cfm?item=description&productID=' + prodID;
	j$.ajax(path,{
			method: 'get',
			onSuccess: function(transport) {
				parent.replaceLongDesc(transport.responseText.trim());
				}
			}
		)
}

function copydetail(detail) {
	document.searchform.criteria.value = detail;
	getreport();
}

function getreport()
{
	if (document.searchform.criteria.value != '') {
		elm=document.getElementById("report");
		elm.innerHTML = 'Loading... Please wait...';



		objXml.open("GET","ajax_passdescription.cfm?options=editproduct&criteria=" + cleanspecials(document.searchform.criteria.value) + "&maxrows="+document.searchform.maxrows.value + "&noc=" + new Date().getTime(), true);
		objXml.onreadystatechange=function() {
		   if (objXml.readyState==4) {
				elm.innerHTML= objXml.responseText;
		  }
		 }
		objXml.send(null);

		speller=document.getElementById("spellchecker");
		speller.innerHTML = '';

		ajaxspell.open("GET","/partnernet/utilities/ajax_spellchecker.cfm?criteria=" + cleanspecials(document.searchform.criteria.value) + "&noc=" + new Date().getTime(), true);
		ajaxspell.onreadystatechange=function() {
		   if (ajaxspell.readyState==4) {
				speller.innerHTML= ajaxspell.responseText;
		  }
		 }
		ajaxspell.send(null);


	} else
		{alert('Criteria cannot be blank.');}
	return false;
}

function showmore(rows){
	var valueArray = rows.split(",");
	for(var i=0; i<valueArray.length.toString(); i++){
	 //do something by accessing valueArray[i];
	 //alert('row'+valueArray[i]);
		document.getElementById('row'+valueArray[i]).style.display = document.getElementById('report').style.display;
	}
	document.getElementById('seemore').style.display = "none";
}

var nav4 = window.Event ? true : false;
if (nav4){
	objXml = new XMLHttpRequest();
	ajaxspell = new XMLHttpRequest();
}else{
	objXml = new ActiveXObject("Microsoft.XMLHTTP");
	ajaxspell = new ActiveXObject("Microsoft.XMLHTTP");
}

</script>
