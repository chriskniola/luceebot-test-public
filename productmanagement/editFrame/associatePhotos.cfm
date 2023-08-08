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

	.pu_OptionR, .pu_Option{
		cursor: pointer;
	}

	.pu_OptionR{
		height: 75px;
		padding-left: 73px;
		padding-top: 15px;
		background-repeat: no-repeat;
	}

	#hierarchy{
		height: 375px;
		overflow-y: scroll;
	}

	#Products, #Photos{
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
var colorsArr = ['black','red','green','blue','orange','purple','teal','Tomato','SlateGray','Navy','Indigo','DarkGreen','DeepPink','SeaGreen','Maroon','Aqua','black','Olive','DodgerBlue','Orchid','LightSalmon','Khaki','OrangeRed','yellow','Bisque','black','red','green','blue','orange','purple','teal','Tomato','SlateGray','Navy','Indigo','DarkGreen','DeepPink','SeaGreen','Maroon','Aqua','black','Olive','DodgerBlue','Orchid','LightSalmon','Khaki','OrangeRed','yellow','Bisque']
var lastColor = 0;
//test = "[{n:'c1name', i:'c1ID', t:'c', r:['c1r1','c1r2'], c:[{n:'p1name', i:'p1ID', t:'p', r:['p1r1','p1r2'], c:[]}]}, {n:'p2name', i:'p2ID', t:'p', r:['p2r1','p2r2'], c:[]}]";
//products = eval('(' + test + ')');

	//displays or hides the popup with the search options - uses the setPosition function in _scipts.js to set the div to the mouse click position
	//if criteria is passed in it will get the values and display them
	//the updateId is saved as a property of the savedValues div that is checked when we display it so we now where and how to do that
	function hideShowSearch(updateId,evt,closePopUp,criteria,type){
		var type, popup, leftPos, criteria, closePopUp, evt, svObj
		popup = document.getElementById('popup');
		svObj = document.getElementById('selectedValues')
		if(svObj.updateId != updateId) popup.style.display = 'none';
		svObj.innerHTML = "";
		document.getElementById('comments').innerHTML = "";
		if(popup.style.display == 'none' && !closePopUp){
			//add new attribute updateId that defines the div that will be updated with the selected items
			document.getElementById('popupTitle').innerHTML = 'Find ' + updateId;
			svObj.updateId = updateId;
			setPosition(evt,popup);
			document.getElementById('criteria').value = '';
			if(criteria){
				document.getElementById('criteria').value = (criteria.value)?criteria.value:criteria;
				getValues(criteria,type);
				svObj.focus();
			}else{
				document.getElementById('criteria').focus();
			}
		}else{
			popup.style.display = 'none';
		}
	}

	//creates the research results used in the popup from the values returned from the ajax call with the search criteria
	function getValues(criteria, type){
		var criteria, type, path, popup, thisCrit, values
		values = document.getElementById('selectedValues')
		values.innerHTML = "";
		document.getElementById('comments').innerHTML = "";
		values.appendChild(createOption('loading...',0,'na'))
		popup = document.getElementById('popup');
		if(criteria){
			if(criteria.value)
				thisCrit = criteria.value;
			else
				thisCrit = criteria;
		}else
			thisCrit = document.getElementById('criteria').value

		if(values.updateId == 'Products')
			path = '/partnernet/productmanagement/ajax_GetProducts.cfm?criteria=' + thisCrit;
		else
			path = '/partnernet/productmanagement/ajax_GetPhotos.cfm?criteria=' + thisCrit;

		if(type) path += '&type=' + type;

		j$.ajax(path,{
			method: 'get'
		})
		.success(function(transport) {
			var selectedValues, values, elType
			selectedValues = document.getElementById('selectedValues');
			values = eval(transport);
			selectedValues.innerHTML = "";
			if(values.length < 1)
				selectedValues.appendChild(createOption('None Found',0,'na'));
			else{
				if(values.length == 50) document.getElementById('comments').innerHTML = "Maximum of 50 records displayed. Your search has been truncated."
				for(var x=0; x < values.length; x++){
					<!--- to add new values like "type" enter them below --->
					elType = 'r'
					if(selectedValues.updateId == "Products") elType = values[x].t;
					if(values[x].n.length) selectedValues.appendChild(createOption(values[x].n,values[x].i,elType));
				}
			}
		});
	}

	//creates and returns the LI "option" used in the popup search results with an image and the onclick function
	function createOption(thisName, thisId, thisElType){
		var thisName,thisId,thisElType
		newOption = document.createElement('li');
		newOption.appendChild(document.createTextNode(thisName));
		newOption.id = thisId;
		newOption.selected = false;
		if(thisElType) newOption.elType = thisElType
		if(thisElType != 'na'){
			if(thisElType == 'r'){
				newOption.className = 'pu_OptionR';
				newOption.style.backgroundImage = 'url(https://images.alpinehomeair.com/75x75/photos/' + thisName+ ')';  //'url(/images/calendar.gif)'; //'
			}else{
				newOption.className = 'pu_Option';
			}

			newOption.onclick = function(){optionClick(this)};
			newOption.ondblclick = function(){this.selected = true; this.style.backgroundColor = '#005fc3'; this.style.color = 'white'; addValues(this.parentNode)};
		}
		return newOption;
	}


	//called when one of the LI tags is clicked inside the popup - this could be updated to perform the shift and control click functions
	function optionClick(thisOpt){
		if(!thisOpt.selected){
			thisOpt.selected = true;
			thisOpt.style.backgroundColor = '#005fc3';
			thisOpt.style.color = 'white';
		}else{
			thisOpt.selected = false;
			thisOpt.style.backgroundColor = 'white';
			thisOpt.style.color = 'black';
		}
	}

	//adds the photos or products to the global variable - called from the pop-up after selecting the values
	function addValues(values,close){
		var theArr,values,close,selectedValues
		if(values.updateId == 'Products'){
			theArr = productsArr;
		}else{
			theArr = resourcesArr;
			lastColor = 0;
			//get the last index of the color array used - if we use 3 colors then delete the 2nd one the next one used will still be the 4th color, the 2nd one just won't be used
			if(theArr.length > 0) lastColor = parseInt(theArr[theArr.length-1].cc);
		}

		//add the new values to the results
		selectedValues = values.getElementsByTagName('li')
		for(var x=0; x < selectedValues.length; x++){
			if(selectedValues[x].selected == true){
				theArr = addToArr(theArr,selectedValues[x].innerHTML,selectedValues[x].id, selectedValues[x].elType);
			}
		}

		//replace the old array with the new updated array
		if(values.updateId == 'Products')
			productsArr = theArr;
		else
			resourcesArr = theArr;

		if(close) hideShowSearch(0,0,1);
		displayElements(values.updateId);
	}

	//adds the products directly to the global variable - used when the page loads
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
				productsArr = addToArr(productsArr,products[x].n,products[x].i.toString(),products[x].t.toString());
			}
			displayElements('Products',true);
			addResources(productID);
		});
	}

	//adds the photos directly to the global variable - used when the page loads
	function addResources(criteria){
		var criteria, path
		path = '/partnernet/productmanagement/ajax_GetPhotos.cfm?type=p&criteria='+criteria
		j$.ajax(path,{
			method: 'get'
		})
		.success(function(transport) {
			var resources
			resources = eval(transport);
			for(var x=0; x < resources.length; x++){
				resourcesArr = addToArr(resourcesArr,resources[x].n,resources[x].i.toString(),'r');
			}
			displayElements('Photos');
		});
	}

	//adds the defined values to it's global array - called from addValues, addProducts, and addResources
	function addToArr(theArr,n,i,t){
		var theArr,n,i,t,cn,cc,exists
		if(t == 'r'){
			i = i;
			t = t;
			cn = 'thisRsrc';
			cc = (lastColor + 1);
		}else{
			i = i;
			t = t;
			cn = 'thisProd';
			cc = 0;
		}

		exists = 0;
		for(var y=0; y < theArr.length; y++){
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

	//creates the resources or products as an element and displays it on the page with the corect color and with the close(remove) box
	function displayElements(updateId,dontGetHeir){
		var theArr, newEl, type, updateId, dontGetHeir
		theDiv = document.getElementById(updateId);
		theDiv.innerHTML = "";
		if(updateId == 'Products'){
			theArr = productsArr;
		}else{
			theArr = resourcesArr;
		}
		for(var x=0; x < theArr.length; x++){

			newEl = document.createElement('div');
			newEl.id = theArr[x].i;
			newEl.className = theArr[x].cn;
			newEl.style.border = '1px solid ' + colorsArr[theArr[x].cc];
			newEl.style.color = colorsArr[theArr[x].cc];
			newEl.innerHTML = theArr[x].n;
			if(updateId != 'Products'){
				//display the image on click
				newEl.style.cursor = "pointer";
				newEl.onclick = function(){popurl('/partnernet/photoAdmin/displayphoto.cfm?width=150&maxheight=150&photoID='+this.id,'photo',175,175)};
			}
			newEl.appendChild(createRemoveLink(colorsArr[theArr[x].cc]));
			theDiv.appendChild(newEl);
		}
		if(!dontGetHeir) getHierarchy();
		hideShowSearch(updateId,0,1)
	}

	// creates the link as an element with the color and onclick event defined
	function createRemoveLink(theColor){
		var values, box, color
		box = document.createElement('A');
		box.href="javascript:void(0);";
		box.style.border = '1px solid ' + theColor;
		box.style.color = theColor;
		box.innerHTML = 'X';
		box.onclick = function(){removeElement(this);};
		box.className = 'closeBox'
		return box
	}

	//function that is called when a resource or product is removed from the page and it's global array
	function removeElement(obj){
		var obj, element, id, type
		element = obj.parentNode;
		if(element.parentNode.id == 'Products'){
			for(var x=0; x < productsArr.length; x++){
				if(productsArr[x].i == element.id) productsArr.splice(x,1);
			}
		}else{
			for(var x=0; x < resourcesArr.length; x++){
				if(resourcesArr[x].i == element.id) resourcesArr.splice(x,1);
			}
		}
		displayElements(element.parentNode.id);
	}

	//get the jason Obj to be used for the heirachy passing the selected products, categories, and resources
	var theHierarchy = ""
	function getHierarchy(){
		var theProds, theCats, theRsrcs
		theProds = '';
		theCats = '';
		theRsrcs = '';
		document.getElementById('hierarchy').innerHTML = 'loading...';
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
		//prompt('test','ajax_getHierarchy.cfm?products='+theProds+'&categories='+theCats+'&photos='+theRsrcs)
		//hierarchySearch_ajax.cfm
		j$.ajax('/partnernet/productmanagement/ajax_GetPhotoHierarchy.cfm?productIDs='+theProds+'&categoryIDs='+theCats+'&PhotoIDs='+theRsrcs,{
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

	//loop thru each of the elements of the global array and display them as a hierarchy
	function displayHierarchy(hierarchy,level,ID, active){
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

					childEl.appendChild(createProductName(hierarchy[x].n,hierarchy[x].a));
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

	//called when a checkbox is clicked and saves the value with ajax
	function putResource(rsrc){
		var rsrcID,path,thisParent,status,kids,valid,GParent
		thisParent = rsrc.parentNode;
		kids = [];
			path = '/partnernet/productmanagement/ajax_PutPhotoAssociation.cfm?PhotoID='+rsrc.rsrcID
			if(thisParent.elType == 'p')
				path = path + '&productID='+ thisParent.id;
			else
				path = path + '&categoryID='+ thisParent.id;

			status = 1;
			if(rsrc.checked) status = 0;
			path = path + '&status=' + status;
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
						//clear any child check boxes
						//checkChildRscr(kids,rsrc.rsrcID,true);
					}
				}
			});
	}


	//not used on this page
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

	//creates the "+"/"-" links that open/close the hierarchy branch
	function createExpandLink(){
		var box
		box = document.createElement('A');
		box.innerHTML = '-';
		box.href="javascript:void(0);";
		box.className = 'thisExpand';
		box.onclick = function(){expandDiv(this)};
		return box;
	}

	//fucntion that is called when the open/close link is click in the hierarchy branch
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

	//creates the link next to each of the products to find all the photos for that product
	function createGetAllResources(){
		var box
		box = document.createElement('A');
		box.innerHTML = 'Get All Photos';
		box.href="javascript:void(0);";
		box.className = 'tiny thisml8';

		box.onclick = function(event){hideShowSearch('Photos',event,0,this.parentNode.id,this.parentNode.elType)}; //hideShowPopUp(0,0,1);
		return box;
	}

	//sets the height of the hierarchy div so it will fill the available screen area
	function setHeight(){
	    var thisPos, thisObj
	    thisObj = document.getElementById('hierarchy');
	    thisPos = getPosition(thisObj);
		thisObj.style.height = (document.body.clientHeight - thisPos.y - 35) + 'px';
	}

<cfif attributes.productID NEQ "">
<cfoutput>
	//set the initial values for the product when the page loads
	function init(event){
		addProduct('#attributes.productID#');
		//addResources('#attributes.productID#');
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
<div class="options">
	<ul class="horiz">
		<li class="horiz"><a href="/partnernet/photoAdmin/addphoto.cfm?productID=#attributes.productID#">Add new photo</a></li>
		<li class="horiz"><strong>Associate Photos</strong></li>
		<li class="horiz"><a href="/partnernet/photoAdmin/editpriority.cfm?productID=#attributes.productID#">Edit Photo Priority</a></li>
	</ul>
</div>
</cfoutput>
<form action="#cgi.SCRIPT_NAME#">
<div class="box">
	<div class="title">Products</div>
	<div id="Products" class="floatLeft box"></div>
	<div class="floatLeft">
		<input type="button" id="addProduct" name="addProduct" value="Add" onclick="hideShowSearch('Products',event);">
	</div>
	<div class="clear"></div>
</div>

<div class="box topmarg">
	<div class="title">Photos</div>
	<div id="Photos" class="floatLeft box"></div>
	<div class="floatLeft">
		<input type="button" id="addResource" name="addResource" value="Add" onclick="hideShowSearch('Photos',event);">
	</div>
	<div class="clear"></div>
</div>

<div class="box topmarg">
	<div class="title">
		Product Hierarchy - <span class="tiny">changes made are immediate</span>
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


<!--- div id="resPopup" style="display: none;" class="box">
	<div class="title"><div class="right"><a class="closeBox" href="javascript:void(0);" onclick="hideShowPopUp('r',event)">X</a></div>Find Photos</div>
	<input id="resCriteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="button" value="GO" onclick="getResources();"><br>
	<a href="javascript:getResources('last7days');" class="tiny thism4">last 7 days</a><br>
	<!--- select id="selectedResources" name="values" multiple="true" ondblclick="addElements('r');"></select><br--->
	<ul id="selectedResources" ></ul>
	<input type="button" value="Add" onclick="addElements('r',true);">
</div>

<div id="prodPopup" style="display: none;" class="box">
	<div class="title"><div class="right"><a class="closeBox" href="javascript:void(0);" onclick="hideShowPopUp('p',event)">X</a></div>Find Products</div>
	<input id="prodCriteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="button" value="GO" onclick="getProducts();"><br>
	<a href="javascript:getProducts('last7days');" class="tiny thism4">last 7 days</a><br>
	<!--- select id="selectedProducts" name="values" multiple="true" ondblclick="addElements('p');"></select><br--->
	<ul id="selectedProducts" ></ul>
	<input type="button" value="Add" onclick="addElements('p',true);">
</div--->

<div id="popup" style="display: none;" class="box">
	<div class="title"><div class="right"><a class="closeBox" href="javascript:void(0);" onclick="hideShowSearch(0,0,1)">X</a></div><span id="popupTitle">Find Products</span></div>
	<form onsubmit="getValues(); return false;"><input id="criteria" name="criteria" type="text" value="" size="8">&nbsp;<input type="submit" value="GO"></form>
	<div><div id="comments" class="red floatright"></div><a href="javascript:getValues('last7days','product');" class="tiny thism4">last 7 days</a></div>
	<ul id="selectedValues"></ul>
	<input type="submit" value="Add" onclick="addValues(document.getElementById('selectedValues'),true);" class="objLock"<cfif lockresult.myLock NEQ true> disabled="true"</cfif>>
</div>
<div id="hideModal" style="display:none;">
	<div id="ajaxModal" style="text-align:center;">
		<img src="/images/icons/wait30trans.gif" style="margin-top:80px;" />
	</div>
</div>
<cfinclude template="/partnernet/shared/_footer.cfm">
