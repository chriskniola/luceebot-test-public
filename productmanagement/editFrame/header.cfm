<cfparam name="attributes.currentStep" default="1">
<cfparam name="attributes.tree" default="">

<cfinclude template="_config.cfm">

<HTML>
<head>
<link rel="stylesheet" href="/partnernet/shared/css/_styles.css"></link>
<style>
body{
	margin: 0px 0px 0px 0px;
	padding: 0px 0px 0px 0px;
	background-color: silver;
}

#thisTable{
	border-bottom: 1px solid #666666;
	position: relative;
	top: 2px;
}

#thisProduct{
	height: 30px;
	border-width: 1px;
	font-size: 11px;
	vertical-align: top;
	text-align: right;
	margin-right: 5px;
	position: absolute;
	right: 0px;
}

#thisTable a{
	width: 75px;
	height: 30px;
	display: block;
	text-align: center;
	font-size: 10px;
	margin-left: 4px;
	text-decoration: none;
	float: left;
	border: 1px solid #666666;
	position: relative;
	top: 1px;
}

#step9{
	color: red;
}


</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js"></script>
<script>var j$ = jQuery.noConflict();</script>
<script src="/partnernet/shared/javascripts/_scripts.js?v=15" type="text/javascript"></script>
<script>

function moveToNextStep(thisStep){
	var thisStep;
	window.parent.moveToNextStep(thisStep)
	return false;
}


function setCurrentStep(thisStep){
	var thisStep;
	var stepCount =<cfoutput>#arraylen(iframeSrc)#+1</cfoutput>;
	if(window.parent.objID) objID = window.parent.objID;

	for(var x=1;x<stepCount;x++){
		document.getElementById('step'+x).style.backgroundColor = "#DDDDDD";
		document.getElementById('step'+x).style.borderBottom = "#666666";
		document.getElementById('step'+x).href = "javascript:void(0);";
		if(x > 1 && (objID == '')){
			document.getElementById('step'+x).style.color = "gray";
			document.getElementById('step'+x).onclick = "";
		}else{
			document.getElementById('step'+x).style.color = "blue";
			document.getElementById('step'+x).onclick = function(){moveToNextStep(this.id.substring(4,this.id.length))}
		}
	}
	document.getElementById('step'+thisStep).style.backgroundColor = "#FFFFFF";
	document.getElementById('step'+thisStep).style.borderBottom = "#FFFFFF";
}


function init(){
	setCurrentStep('<cfoutput>#attributes.currentStep#</cfoutput>');
	window.parent.setLabel();
}

function changetree(obj){
	window.parent.changetree(obj.options[obj.selectedIndex].value);
}

window.addListener("onload", init);
</script>
</head>
<body>
<cfoutput>
#writemenuHTML(iframeSrc)#
</cfoutput>
</body>
</HTML>
