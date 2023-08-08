<cfparam name="attributes.currentStep" default="1">
<cfparam name="attributes.productID" default="">
<cfparam name="attributes.objID" default="#attributes.productID#">
<cfparam name="attributes.label" default="">
<cfparam name="attributes.vendorID" default="">
<cfparam name="attributes.vendorobjID" default="">
<cfparam name="attributes.tree" default="1">
<cfparam name="attributes.productUrl" default="">

<cfsetting showdebugoutput="Yes">

<cfinclude template="_config.cfm">

<cfif attributes.objID NEQ "" AND attributes.productUrl == "">
	<cfset attributes.label = getProduct(attributes.objID)>
	<cfset attributes.productUrl = getProductUrl(attributes.objID)>
</cfif>

<script>
<cfoutput>
var currentStep = '#attributes.currentStep#';
var objID = '#attributes.objID#';
var label = '#attributes.label#';
var stepCount = '#arraylen(iframeSrc)#';
var vendorID = '#attributes.vendorID#';
var vendorObjID = '#attributes.vendorObjID#';
var tree = '#attributes.tree#';
var productUrl = '#attributes.productUrl#';
</cfoutput>

<cfoutput>#writeJS(iframeSrc)#</cfoutput>

function moveToNextStep(stepNumber){
	var path
	if(objID == '' || objID == '0'){
		currentStep = 1;
		window.frames['header'].setCurrentStep(1);
		if(vendorID != ''){
			path = iframeSrc[1] + 'productID=' + productID;
			path += '&vendorID=' + vendorID + '&vendorobjID=' + vendorObjID;
		}else{
			path = '<cfoutput>#addNewPage#</cfoutput>';
		}
	}else{
		if(stepNumber != currentStep){
			if(stepNumber)
				currentStep = stepNumber;
			else
				currentStep ++;

			if(currentStep>iframeSrc.length)
				currentStep = 1;

			window.frames['header'].setCurrentStep(currentStep);

			setLabel();
		}

		path = iframeSrc[currentStep] ==='productUrl' ? productUrl : iframeSrc[currentStep] + objID + '&tree=' + tree;

	}

	window.frames.body.location = path;
	return false;
}


function setLabel(){
	window.document.title = label;
}


function checkForms(){
	var forms
	forms = window.frames['body'].document.getElementsByTagName('form');
	for(var x in forms){
		forms[x].action = forms[x].action + '&currentSteps=true&objID='+objID+'&tree='+tree;
	}
}

function changetree(treenum){
	var newpath;
	newpath = 'default.cfm?tree=' + treenum + '&productID=' + objID + '&objID=' + objID + '&vendorID=' + vendorID + '&vendorObjID=' + vendorObjID;
	window.location=newpath;
}
</script>

<cfset bodyPath = iframeSrc[attributes.currentStep].URL & attributes.objID & "&tree=" & attributes.tree>
<cfif attributes.objID EQ "" OR attributes.objID EQ "0">
	<cfset bodyPath = addNewPage>
	<cfif val(attributes.vendorID)>
		<cfset bodyPath = iframeSrc[attributes.currentStep].URL & attributes.objID & '&vendorID=' & attributes.vendorID & '&vendorobjID=' & attributes.vendorObjID>
	</cfif>
</cfif>

<frameset rows="33,*" frameborder="no" border="0" framespacing="10">
  <frame frameborder="0" src="<cfoutput>/partnernet/productmanagement/editFrame/header.cfm?currentStep=#attributes.currentStep#&tree=#attributes.tree#</cfoutput>" name="header" id="header" scrolling="NO" >
  <frame frameborder="0" src="<cfoutput>#bodyPath#</cfoutput>" name="body" id="body">
</frameset>

<cfdump var="#bodyPath#">
