<cfparam name="attributes.productID" default="">
<cfsetting showdebugoutput="false">
<cfset screenID = "240">
<cfinclude template="/partnernet/shared/_header.cfm">

<style>

	.thisml8{
		margin-left: 8px;
	}

	.thisRsrc, .thisProd{
		float: left;
		padding: 1px 12px 1px 1px;
		margin: 0px 2px 2px 0px;
		position: relative;
		border-width: 1px;
	}

	.thisRsrcCB, .thisExpand{
		font-size: 8px;
		line-height: 10px;
		word-spacing: 8px;
		float: left;
		border: 1px solid black;
		padding: 0px;
		margin: 1px 2px 1px 1px;
		height: 9px;
		width: 9px;
		cursor: pointer;
		background-color: white;
		display: block;
		text-align: center;
		vertical-align: top;
		text-decoration: none;
	}

	.thisExpand{
		font-size: 8px;
		line-height: 8px;
		height: 7px;
		width: 7px;
		margin: 1px;
		margin-left: -12px;
		color: black;
	}

	.thisTree{
		position: relative;
	}

	.thisTree .gray{
		color: #AAAAAA;
	}

	.clear{
		clear: both;
		padding: 0px;
		margin: 0px;
		height: 0px;
		font-size: 0px;
		border: 0px;
	}

	.scroll{
		overflow-horizontal:scroll;
		height: 150px;
	}

	.topmarg{
		margin-top: 5px;
	}

	#resPopup, #prodPopup{
		position: absolute;
		background-color: white;
		width: 600px;
	}

	#resPopup select, #prodPopup select{
		margin: 3px 0px 3px 0px;
		width: 590px;
		height: 350px;
	}

	#resPopup form, #prodPopup form{
		margin: 0px 0px 3px 0px;
		vertical-align: middle;
	}

	#resCriteria, #prodCriteria{
		width: 540px;
	}

	#hierarchy{
		height: 375px;
		overflow-y: scroll;
	}

	#products, #resources{
		width: 85%;
		/*height: 40px;*/
		overflow-y: scroll;
		margin-right: 10px;
	}

	.radio{
		background-color: #E5E5E5;
		margin-top: 0;
		margin-bottom: 0;
		display: inline-block;
	}

	.radio label {
		padding: 0 10px;
	}

	input[name="displayActive"] { display: none; }


</style>

<script>
var productsArr = [];
var resourcesArr = [];
var colorsArr = ['black','red','green','blue','orange','purple','teal','Tomato','SlateGray','Navy','Indigo','DarkGreen','DeepPink','SeaGreen','Maroon','Aqua','black','Olive','DodgerBlue','Orchid','LightSalmon','Khaki','OrangeRed','yellow','Bisque']
var lastColor = 0;
//test = "[{n:'c1name', i:'c1ID', t:'c', r:['c1r1','c1r2'], c:[{n:'p1name', i:'p1ID', t:'p', r:['p1r1','p1r2'], c:[]}]}, {n:'p2name', i:'p2ID', t:'p', r:['p2r1','p2r2'], c:[]}]";
//products = eval('(' + test + ')');

function hideShowPopUp(type,evt,criteria,closePopUp){
	var type, popup, leftPos, criteria, criteriaBox
	if(type == 'r'){
		document.getElementById('prodPopup').style.display = 'none';
		document.getElementById('selectedResources').options.length = 0;
		criteriaBox = document.getElementById('resCriteria');
		popup = document.getElementById('resPopup');
	}else{
		document.getElementById('resPopup').style.display = 'none';
		document.getElementById('selectedProducts').options.length = 0;
		criteriaBox = document.getElementById('prodCriteria');
		popup = document.getElementById('prodPopup');
	}

	if(popup.style.display == 'none' && !closePopUp){

		setPosition(evt,popup);
		criteriaBox.value = '';
		if(criteria){
			criteriaBox.value = (criteria.value)?criteria.value:criteria;
			if(type == 'r'){
				getResources(criteria);
				document.getElementById('selectedResources').focus();
			}else{
				getProducts(criteria);
				document.getElementById('selectedProducts').focus();
			}
		}else{
			criteriaBox.focus();
		}
	}else{
		popup.style.display = 'none';
	}
}


function getProducts(criteria){
	var criteria, path, selectedProducts
	if(criteria){
		if(criteria.value){
			path = '/partnernet/productmanagement/ajax_GetProducts.cfm?criteria=' + criteria.value + '&type=' + criteria.type;
		}else{
			path = '/partnernet/productmanagement/ajax_GetProducts.cfm?criteria=' + criteria;
		}
	}else{
		path = '/partnernet/productmanagement/ajax_GetProducts.cfm?criteria=' + document.getElementById('prodCriteria').value
	}
	selectedProducts = document.getElementById('selectedProducts');
	selectedProducts.options.length = 0;
	selectedProducts.options[selectedProducts.options.length] = new Option('Loading...', '0');
	j$.ajax(path,{
		method: 'get'
	})
	.success(function(transport) {
		var selectedProducts, products
		selectedProducts = document.getElementById('selectedProducts');
		products = eval(transport);
		selectedProducts.options.length = 0;
		for(var x=0; x < products.length; x++){
			if(products[x].n.length > 1) selectedProducts.options[selectedProducts.options.length] = new Option(products[x].n, products[x].t.toString() + products[x].i.toString());
		}
		if(products.length < 1) selectedProducts.options[selectedProducts.options.length] = new Option('None Found', '0');
	});
}

function getResources(criteria){
	var criteria, path, selectedResources
	if(criteria){
		if(criteria.value){
			path = '/partnernet/productmanagement/ajax_GetResources.cfm?criteria=' + criteria.value + '&type=' + criteria.type;
		}else{
			path = '/partnernet/productmanagement/ajax_GetResources.cfm?criteria=' + criteria;
		}
	}else{
		path = '/partnernet/productmanagement/ajax_GetResources.cfm?criteria=' + document.getElementById('resCriteria').value
	}
	selectedResources = document.getElementById('selectedResources');
	selectedResources.options.length = 0;
	selectedResources.options[selectedResources.options.length] = new Option('Loading...', '0');
	j$.ajax(path,{
		method: 'get'
	})
	.success(function(transport) {
		var selectedResources, resources
		selectedResources = document.getElementById('selectedResources');
		resources = eval(transport);
		selectedResources.options.length = 0;
		for(var x=0; x < resources.length; x++){
			if(resources[x].n.length > 0) selectedResources.options[selectedResources.options.length] = new Option(resources[x].n, resources[x].i);
		}
		if(resources.length < 1) selectedResources.options[selectedResources.options.length] = new Option('None Found', '0');
	});
}

function addElements(type,close){
	var theDiv,theArr,n,i,t,v,c,exists,type,close
	if(type == 'r'){
		theSelect = document.getElementById('selectedResources');
		theArr = resourcesArr;
		lastColor = 0;
		if(theArr.length > 0) lastColor = parseInt(theArr[theArr.length-1].cc);
	}else{
		theSelect = document.getElementById('selectedProducts');
		theArr = productsArr;
	}
	if(theSelect.options.length > 1 || theSelect.options[0].text != 'None Found'){
		for(var x=0; x < theSelect.options.length; x++){
			if(theSelect.options[x].selected == true){
				n = theSelect.options[x].text;
				v = theSelect.options[x].value.toString();
				theArr = addToArr(type,theArr,n,v);
			}
		}
		if(type == 'r')
			resourcesArr = theArr;
		else
			productsArr = theArr;

		if(close) hideShowPopUp(type,0,0,1);
		displayElements(type);
	}
}

function addProduct(productID){
	var productID, path
	path = '/partnernet/productmanagement/ajax_GetProduct.cfm?productID='+productID
	j$.ajax(path,{
		method: 'get'
	})
	.success(function(transport) {
		var products
		products = eval(transport);
		for(var x=0; x < products.length; x++){
			productsArr = addToArr('p',productsArr,products[x].n,products[x].t + products[x].i.toString());
		}
		displayElements('p',true);
		addResources(productID);
	});
}

function addResources(criteria){
	var criteria, path
	path = '/partnernet/productmanagement/ajax_GetResources.cfm?type=p&criteria='+criteria
	j$.ajax(path,{
		method: 'get'
	})
	.success(function(transport) {
		var resources
		resources = eval(transport);
		for(var x=0; x < resources.length; x++){
			resourcesArr = addToArr('r',resourcesArr,resources[x].n,resources[x].i.toString());
		}
		displayElements('r');
	});
}



function addToArr(type,theArr,n,v){
	var type,theArr,i,v,exists
	if(type == 'r'){
		i = v;
		t = 'r';
		cn = 'thisRsrc';
		cc = (lastColor + 1);
	}else{
		i = v.substring(1,v.length);
		t = v.substring(0,1);
		cn = 'thisProd';
		cc = 0;
	}
	exists = 0;
	for(var y in theArr){
		if(theArr[y].i == i){
			exists = 1;
			break;
		}
	}

	if(!exists){
		theArr[theArr.length] = {n:n, i:i, t:t, cn:cn, cc:cc};
		lastColor++;
	}
	return theArr;
}

function displayElements(type,dontGetHeir){
	var theDiv, theArr, newEl, type, dontGetHeir
	if(type == 'r'){
		theDiv = document.getElementById('resources');
		theArr = resourcesArr;
	}else{
		theDiv = document.getElementById('products');
		theArr = productsArr;
	}
	theDiv.innerHTML = '';
	for(var x=0; x < theArr.length; x++){

		newEl = document.createElement('div');
		newEl.id = 'e'+theArr[x].i;
		newEl.innerHTML = theArr[x].n;
		newEl.appendChild(createRemoveLink(theArr[x].i,type,colorsArr[theArr[x].cc]))
		newEl.className = theArr[x].cn;
		newEl.style.border = '1px solid ' + colorsArr[theArr[x].cc];
		newEl.style.color = colorsArr[theArr[x].cc];
		theDiv.appendChild(newEl);
	}
	if(!dontGetHeir) getHierarchy();
	hideShowPopUp(0,0,0,1);
}


function createRemoveLink(id,type,color){
	var type, box, color
	box = document.createElement('A');
	box.href="javascript:void(0);";
	box.style.border = '1px solid ' + color;
	box.style.color = color;
	box.innerHTML = 'X';
	box.onclick = function(){removeElement(id,type);};
	box.className = 'closeBox'
	return box
}


function removeElement(id,type){
	var type
	if(type == 'r'){
		for(var x=0; x < resourcesArr.length; x++){
			if(resourcesArr[x].i == id)	resourcesArr.splice(x,1);
		}
	}else{
		for(var x=0; x < productsArr.length; x++){
			if(productsArr[x].i == id) productsArr.splice(x,1);
		}
	}
	displayElements(type);
}


var theHierarchy = "";
function getHierarchy(){
	var theProds, theCats, theRsrcs
	theProds = '';
	theCats = '';
	theRsrcs = '';
	document.getElementById('hierarchy').innerHTML = 'Loading...';
	//add please wait graphic here
	for(var x=0; x < resourcesArr.length; x++){
		if(theRsrcs != "") theRsrcs = theRsrcs + ","
		theRsrcs = theRsrcs + resourcesArr[x].i + ',';
	}
	for(var x=0; x < productsArr.length; x++){
		if(productsArr[x].t == 'p'){
			if(theProds != "") theProds = theProds + ","
			theProds = theProds + productsArr[x].i;
		}else{
			if(theCats != "") theCats = theCats + ","
			theCats = theCats + productsArr[x].i;
		}
	}
	//prompt('test','ajax_getHierarchy.cfm?products='+theProds+'&categories='+theCats+'&Resources='+theRsrcs)
	//hierarchySearch_ajax.cfm
	j$.ajax('/partnernet/productmanagement/ajax_GetHierarchy.cfm?productIDs='+theProds+'&categoryIDs='+theCats+'&resourceIDs='+theRsrcs,{
		method: 'get'
	})
	.success(function(transport) {
		theHierarchy = eval(transport);
		//clear the please wait graphic here
		document.getElementById('hierarchy').innerHTML = "";
		document.getElementById('hierarchy').appendChild(displayHierarchy(theHierarchy,1,0,dispAct));
	});
}


var dispAct = "";
function checkActive(){
	var dispval = document.getElementsByName('displayActive');
	for(i=0; i<dispval.length; i++)
	    if(dispval[i].checked) dispval=dispval[i].value;
	if(dispval != dispAct){
		dispAct = dispval;
		document.getElementById('hierarchy').innerHTML = "";
		document.getElementById('hierarchy').appendChild(displayHierarchy(theHierarchy,1,0,dispAct));
	}
}


function displayHierarchy(hierarchy,level,ID,active){
	var level,hierarchy,ID,topEl,childEl,checked
	if(dispAct == "" || active == dispAct || (hierarchy.length && dispAct == 0)){
		topEl = document.createElement('div');
		topEl.id = 'c'+ID;
		topEl.style.paddingLeft = '15px';
		for(var x=0; x < hierarchy.length; x++){
			if(dispAct == "" || hierarchy[x].a == dispAct || (hierarchy[x].t == 'c' && dispAct == 0)){
				childEl = document.createElement('div');
				childEl.className = 'thisTree';
				//adding new attribute elType for the element type
				childEl.elType = hierarchy[x].t;
				childEl.id = hierarchy[x].i;
				childEl.style.marginLeft = '0px';
				<cfoutput>
					if(childEl.id == "#attributes.productID#"){
						childEl.style.background = '##66CCFF';
					}
				</cfoutput>
				if(hierarchy[x].c.length) childEl.appendChild(createExpandLink());

				for(var r=0; r < resourcesArr.length; r++){
					checked = false;
					if(hierarchy[x].r.join().match(resourcesArr[r].i)) checked = true;
					childEl.appendChild(createCheckBox(r, checked, hierarchy[x].i));
				}

				childEl.appendChild(createProductName(hierarchy[x].n, hierarchy[x].a));
				childEl.appendChild(createGetAllResources());


				if(hierarchy[x].c.length) childEl.appendChild(displayHierarchy(hierarchy[x].c,level+1,hierarchy[x].i,hierarchy[x].a));
				topEl.appendChild(childEl);
			}
		}
		return topEl;
	}
}

function createProductName(pName,isActive){
	var tn = document.createTextNode(pName);
	if(!isActive){
		var sp = document.createElement('span');
		sp.className = "gray";
		sp.appendChild(tn);
		return sp;
	}
	return tn;
}

function createCheckBox(rsrc, checked, id){
	var rsrcID,rsrc,thisColorInd,newEl,id,checked
	rsrcID = resourcesArr[rsrc].i
	thisColorInd = resourcesArr[rsrc].cc

	newEl = document.createElement('A');
	newEl.href = "javascript:void(0);";
	newEl.id = 'r'+ rsrcID + '_' + id;
	newEl.rsrcID = rsrcID;
	newEl.checked = checked;
	newEl.cc = thisColorInd;
	newEl.className = 'thisRsrcCB';
	newEl.style.border = "1px solid " + colorsArr[thisColorInd];
	if(checked)	newEl.style.backgroundColor = colorsArr[thisColorInd];
	newEl.innerHTML = ' &nbsp; ';
	newEl.onclick = function(){putResource(this)};
	return newEl;
}


function putResource(rsrc){
	var rsrcID,path,thisParent,status,kids,valid,GParent
	thisParent = rsrc.parentNode;
	valid = true;
	kids = [];

	GParent = thisParent.parentNode
	while(GParent.id != 'hierarchy'){
		if(document.getElementById('r'+ rsrc.rsrcID + '_' + GParent.id)){
			/*if(document.getElementById('r'+ rsrc.rsrcID + '_' + GParent.id).checked){
				valid = false;
				alert("The element you are trying to associate this resource to has a parent associated already and is therefore already associated itself.");
				break;
			}*/
		}
		GParent = GParent.parentNode
	}

	if(document.getElementById('c'+thisParent.id)){
		kids = document.getElementById('c'+thisParent.id);
		/*if(checkChildRscr(kids,rsrc.rsrcID)){
			valid = confirm("The element you are trying to associate this resource to currently has children with that resource already. Adding this resource to the parent will remove the resource from the children. Do you want to continue?");
		}*/
	}

	if(valid){
		//Add modal-out here
		var modal = j$( "#ajaxModal" ).dialog({
			modal: true,
            height: 250,
            width: 200,
            zIndex: 999,
            resizable: false,
            title: "Please wait...",
            open: function() { j$(".ui-dialog-titlebar-close").hide(); }
		});
		modal.show();
		//end modal-out
		path = '/partnernet/productmanagement/ajax_PutResourceAssociation.cfm?resourceID='+rsrc.rsrcID
		if(thisParent.elType == 'p')
			path = path + '&productID='+ thisParent.id;
		else
			path = path + '&categoryID='+ thisParent.id;

		status = 1;
		if(rsrc.checked) status = 0;
		path = path + '&status=' + status;

		j$.ajax(path,{
			method: 'get'
		})
		.success(function(transport) {
			//clear modal-out here
			modal.dialog("close");
			//end clear modal-out
			var response
			response = eval(transport);
			if(response==true){
				if(rsrc.checked){
					rsrc.style.backgroundColor = '';
					rsrc.checked = false;
				}else{
					rsrc.style.backgroundColor = colorsArr[rsrc.cc];
					rsrc.checked = true;
					checkChildRscr(kids,rsrc.rsrcID,true);
				}
			}
		});
	}
}

function checkChildRscr(node,rsrcID,reset){
	var node,rsrcID,reset,kids,retval;

	retval = false;
	kids = node.getElementsByTagName('a');
	for(var i = 0; i < kids.length; i++){
		if(kids[i].rsrcID && kids[i].rsrcID == rsrcID){
			if(kids[i].checked){
				retval = true;
				if(reset){
					kids[i].style.backgroundColor = '';
					kids[i].checked = false;
				}else{
					break;
				}
			}
		}
	}
	return retval;
}


function createExpandLink(){
	var box
	box = document.createElement('A');
	box.innerHTML = '-';
	box.href="javascript:void(0);";
	box.className = 'thisExpand';
	box.onclick = function(){expandDiv(this)};
	return box;
}


function expandDiv(thisLink){
	var thisLink, thisID, thisDiv
	thisID = 'c'+thisLink.parentNode.id;
	thisDiv = document.getElementById(thisID);
	if(thisDiv.style.display == ''){
		thisDiv.style.display = 'none';
		thisLink.innerHTML = '+';
	}else{
		thisDiv.style.display = '';
		thisLink.innerHTML = '-';
	}
}

function createGetAllResources(){
	var box
	box = document.createElement('A');
	box.innerHTML = 'Get All Resources';
	box.href="javascript:void(0);";
	box.className = 'tiny thisml8';

	box.onclick = function(event){hideShowPopUp('r',event,{value:this.parentNode.id,type:this.parentNode.elType})};
	return box;
}



function setHeight(thisObj){
    var thisPos, thisObj
    thisObj = document.getElementById('hierarchy');
    thisPos = getPosition(thisObj);
	thisObj.style.height = (document.body.clientHeight - thisPos.y - 35) + 'px';
}


<cfif attributes.productID NEQ "">
<cfoutput>
function init(event){
	addProduct('#attributes.productID#');
	setHeight();
}
</cfoutput>
window.addListener('onload',init);
</cfif>
window.addListener('onresize',setHeight);
</script>

<cfinvoke component="ajax.sessionless.lock" method="putlock" userID="#getCurrentUser()#" objID="#attributes.productID#" returnvariable="lockresult"/>
<cfoutput>#lockresult.js#</cfoutput>

<cfoutput>
<div class="options">Associate Resources &nbsp; <b>OR</b> &nbsp; <a href="/partnernet/resourceAdmin/addResource.cfm?productID=#attributes.productID#">Add new Resource</a></div>
</cfoutput>
<form action="#cgi.SCRIPT_NAME#">
<div class="box">
	<div class="title">Products</div>
	<div id="products" class="floatLeft box"></div>
	<div class="floatLeft">
		<input type="button" id="addProduct" name="addProduct" value="Add" onclick="hideShowPopUp('p',event);">
	</div>
	<div class="clear"></div>
</div>

<div class="box topmarg">
	<div class="title">Resources</div>
	<div id="resources" class="floatLeft box"></div>
	<div class="floatLeft">
		<input type="button" id="addResource" name="addResource" value="Add" onclick="hideShowPopUp('r',event);">
	</div>
	<div class="clear"></div>
</div>

<div class="box topmarg">
	<div class="title">
		Product Hierarchy <span class="tiny"> - changes made are immediate &nbsp; </span>
		<div class="floatRight">
			Display:  
			<span class="radio">
				<input type="radio" id="dispAct1" name="displayActive" value="1" onclick="checkActive();">
				<label for="dispAct1">Active</label>
			</span>
			<span class="radio">
				<input type="radio" id="dispAct2" name="displayActive" value="0" onclick="checkActive();">
				<label for="dispAct2">Inactive</label>
			</span>
			<span class="radio">
				<input type="radio" id="dispAct3" name="displayActive" value="" checked="true" onclick="checkActive();">
				<label for="dispAct3">Both</label>
			</span>
		</div>
	</div>
	<div id="hierarchy" class="box"></div>
</div>
</form>


<div id="resPopup" style="display: none;" class="box">
	<div class="title"><div class="floatRight"><a class="closeBox" href="javascript:void(0);" onclick="hideShowPopUp('r',event,0,1)">X</a></div>Find Resource</div>
	<form onsubmit="getResources(); return false;"><input id="resCriteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="submit" value="GO" onclick="getResources();"></form>
	<div><a href="javascript:getResources('last7days');" class="tiny thism4">last 7 days</a></div>
	<select id="selectedResources" name="values" multiple="true" ondblclick="addElements('r');"></select><br>
	<input type="button" value="Add" onclick="addElements('r',true);">
</div>

<div id="prodPopup" style="display: none;" class="box">
	<div class="title"><div class="floatRight"><a class="closeBox" href="javascript:void(0);" onclick="hideShowPopUp('p',event,0,1)">X</a></div>Find Products</div>
	<form onsubmit="getProducts(); return false;"><input id="prodCriteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="submit" value="GO" onclick="getProducts();"></form>
	<div><a href="javascript:getProducts('last7days');" class="tiny thism4">last 7 days</a></div>
	<select id="selectedProducts" name="values" multiple="true" ondblclick="addElements('p');"></select><br>
	<input type="button" value="Add" onclick="addElements('p',true);" class="objLock"<cfif lockresult.myLock NEQ true> disabled="true"</cfif>>
</div>
<div id="hideModal" style="display:none;">
	<div id="ajaxModal" style="text-align:center;">
		<img src="/images/icons/wait30trans.gif" style="margin-top:80px;" />
	</div>
</div>
<cfinclude template="/partnernet/shared/_footer.cfm">
