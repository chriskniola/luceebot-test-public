<cfsetting showdebugoutput="no">

<cfparam name="attributes.productID" default="">
<cfparam name="attributes.atrID" default="">
<cfparam name="attributes.imdone" default="">

<cfset screenID = 240>
<cfset recordhistory = 0>
<cfset showjQuery = 1>

<cfset popup = 1>

<cfinclude template="/partnernet/shared/_header.cfm">

<cfif CGI.REMOTE_ADDR NEQ "127.0.0.1">
<cfinvoke component="ajax.sessionless.lock" method="putlock" userID="#getCurrentUser()#" objID="#attributes.productID#" returnvariable="lockresult"/>
<cfoutput>#lockresult.js#</cfoutput>
</cfif>

<cfif attributes.imdone EQ "Save Attributes" AND attributes.productID NEQ 0>
	<cfquery name="deleteprdatts" datasource="#DSN#">
	DELETE tblProductAttributes
	WHERE prdID = <cfqueryparam sqltype="INT" value="#attributes.productID#">
	</cfquery>

	<cfloop list="#form.fieldnames#" index="fieldName">
		<cfset tmpattid = REReplace(fieldName, "\_[0-9]+", "")>
		<cfif FIND("_max",fieldName)>
			<cfcontinue>
		</cfif>
		<cfif FIND("_min",fieldName)>
			<cfif isEmpty(attributes[fieldName])>
				<cfcontinue>
			</cfif>
			<cfset tmpattid = REReplace(tmpattid, "_min", "")>
			<cfset maxidname = REReplace(fieldName, "_min", "_max")>
			<cfset tmpformval = "#trim(attributes[fieldName])##!isEmpty(attributes[maxidname]) ? ' - #trim(attributes[maxidname])#' : ''#">
		<cfelse>
			<cfset tmpformval = trim(attributes[fieldName])>
		</cfif>

		<cfif isNumeric(tmpattid)>
			<cfif tmpformval NEQ "" AND tmpformval NEQ "N/A" AND tmpformval NEQ "Add New">
				<cfquery name="updateAttributes" datasource="#DSN#">
			    INSERT INTO tblProductAttributes (prdAtrValue,prdAtrID,prdID)
				VALUES(
					<cfqueryparam sqltype="VARCHAR" value="#tmpformVal#">
					, <cfqueryparam sqltype="INT" value="#tmpattid#">
					, <cfqueryparam sqltype="INT" value="#attributes.productID#">
				)
				</cfquery>

				<cfset session.message="The attribute values have been added.">
			</cfif>
		</cfif>
	</cfloop>

	<cfset productAttributeUpdatedPublisher = application.wirebox.getInstance('ProductAttributeUpdatedPublisher')>
	<cfset productAttributeUpdatedPublisher.publish({ 'id': attributes.productID })>

	<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Product attributes added or updated"/>

	<script type="text/javascript">
	if(window.parent.frames['header']){
		window.parent.moveToNextStep();
	}
	<cfif Len(session.message)>
		alert('<cfoutput>#session.message#</cfoutput>');
		<cfset session.message = "">
	</cfif>
	</script>
</cfif>

<cfstoredproc procedure="sp_getAttribute_names_values_by_product" datasource="#DSN#">
	<!--- this is the query that gets all the names and values for attributes with this product id or category id --->
	<cfprocparam type="IN" sqltype="INT" value="#attributes.productID#">
	<cfprocparam type="IN" sqltype="INT" value="0">
	<cfprocparam type="IN" sqltype="INT" value="0">
	<cfprocresult name="ListAttributes">
</cfstoredproc>

<cfquery name="distinctatts" dbtype="query">
	SELECT DISTINCT atrID
	FROM ListAttributes
</cfquery>

<style type="text/css">
#myatts > div {
	float:left;
}

#colleft,#colright,#coladdleft,#coladdright {
	float:left;
	width:49%;
	margin:3px;
	border:1px solid #C8C8C8;
	min-height:2em;
}

.anatt {
	margin:2px 8px;
	padding:2px;
	border-bottom:1px solid #C8C8C8;
	line-height:16px;
}

.required {
	background-color:#FFD7D7;
	border:2px solid red !important;
}

.atttitle {
	float:left;
	width:45%;
}

.atttitle a {
	margin:0 8px 0 4px;
	font-size:0.8em;
}

.attform {
	float:left;
	text-align:left;
	font-size:10px;
}

.collapser {
	display:none;
}

label {
	position:relative;
	top:-3px;
}

.atrBoxes {
	float: right;
	width: 40px;
	font-size:0.8em;
	font-weight:bold;
}

.atrPhoto{
	position:relative;
	color:teal;
}
.atrComp{
	position:relative;
	color:maroon;
}
.atrSort{
	position:relative;
	color:#CC7A00;
}

.px20 {
	width: 8px;
	float: left;
	margin-right: 5px;
}

.group {
	float:right;
	margin-left:1em;
}

.searchElements{
	text-align: left;
	float: left;
	white-space: nowrap;
	line-height:25px;
	margin-right:4em;
}

.cbxcontainer {
	display: flex;
    flex-wrap: wrap;
}

.cbxitem {
	flex: 1 1 15%;
	white-space: nowrap;
	margin-right: 25px;
}

.addnewlink {
	float:right; 
	margin-right:1em;
}
</style>

<cfobject component="alpine-objects.ui" name="ui">

<cfoutput>
<div id="myatts" class="box container">
	<div class="title">Selected Attributes: &nbsp; <span class="atrPhoto">P: Photo</span> &nbsp; <span class="atrComp">C: Comparable</span> &nbsp; <span class="atrSort">F: Filterable</span></div>
	<div class="clear"></div>
	<form id="selatts" name="selatts" action="#CGI.SCRIPT_NAME#?productID=#attributes.productID#" method="post">
		<div id="colleft">

			<cfloop query="distinctatts">

				<cfquery name="attinfo" dbtype="query">
				SELECT *
				FROM ListAttributes
				WHERE atrID = <cfqueryparam sqltype="INT" value="#distinctatts.atrID#">
				</cfquery>

				<cfquery name="getattributevalues" datasource="#DSN#">
				SELECT DISTINCT prdAtrValue, prdAtrID, CASE WHEN ISNUMERIC(prdatrvalue) = 1 THEN CONVERT(DECIMAL, prdatrvalue) ELSE CONVERT(DECIMAL,'0') END AS Sort
				FROM tblProductAttributes
				WHERE prdatrID IN (<cfqueryparam sqltype="INT" list=true value="#valuelist(attinfo.atrID)#">)
				ORDER BY sort, prdAtrValue
				</cfquery>

				<cfif attinfo.formtype EQ "">
					<cfset myformtype = "select">
				<cfelse>
					<cfset myformtype = attinfo.formtype>
				</cfif>

				<div class="anatt<cfif attinfo.required EQ 1> required</cfif><cfif attinfo.prdatrvalue EQ ""> empty</cfif>" id="#distinctatts.atrID#">
					<cfloop query="attinfo">

						<cfif attinfo.currentrow EQ 1>
						<div class="atrBoxes">
							<cfif attinfo.atrPhotoID NEQ 0>
								<div class="atrPhoto px20" style="position: relative;">P</div>
							</cfif>
							<cfif attinfo.atrComparable NEQ 0>
								<div class="atrComp px20" style="position: relative;">C</div>
							</cfif>
							<cfif attinfo.atrSortable NEQ 0>
								<div class="atrSort px20" style="position: relative;">F</div>
							</cfif>
						</div>
						<div class="atttitle">
							<a href="javascript:;" name="#distinctatts.atrID#">remove</a>
							<span>#atrname#<cfif atrunits NEQ ""> (#atrunits#)</cfif></span>
							<a href="javascript:;" name="#distinctatts.atrID#">edit</a>
						</div>
						<div name="formtype" style="display:none;">#attinfo.formtype#</div>
						</cfif>

						<cfif myformtype EQ "checkbox">
							<cfset myvalues = attinfo.prdAtrValue>
							<cfquery name="cbxloop" dbtype="query">
							SELECT 1 as checked, prdAtrValue, prdatrID
							FROM getattributevalues
							WHERE prdAtrValue IN (<cfqueryparam sqltype="VARCHAR" list="yes" value="#attinfo.columnData('prdatrvalue')#">)

							UNION

							SELECT 0 as checked, prdAtrValue, prdatrID
							FROM getattributevalues
							WHERE prdAtrValue NOT IN (<cfqueryparam sqltype="VARCHAR" list="yes" value="#attinfo.columnData('prdatrvalue')#">)
							ORDER BY prdAtrValue
							</cfquery>

							<div class="group tiny">#attinfo.atrgroup#</div>

							<cfif cbxloop.recordcount GT 4>
							<div class="clear"></div>
							<span class="ui-icon ui-icon-circle-triangle-s" style="float:left; margin-left:2px;" title="Click to expand/collapse options"></span>
							<br>

							<div class="attform collapser">
							<cfelse>

							<div class="attform" style="width:100%;">
							</cfif>

								

								<div class="cbxcontainer">
									<cfloop query="cbxloop">
										<cfset myname = attinfo.atrID & "_" & cbxloop.currentrow>
										<cfset myvalues = cbxloop.prdAtrValue>

										<cfif cbxloop.checked EQ 1>
											<cfset imchecked = myvalues>
										<cfelse>
											<cfset imchecked = "">
										</cfif>

										<!--- type,values,id,name,class,style,label,selected,dectofract,minmaxrange --->
										<cfset element = ui.get(myformtype, myvalues, myname, myname, "tiny", "", myvalues, imchecked,attinfo.atrconvertdecimal, 1)>

										<div class="cbxitem">#element.element#</div>
									</cfloop>
								</div>
								<div ><a class="addnewlink" href="javascript:;">Add New</a></div>
							</div>

							<cfbreak>

						<cfelseif myformtype EQ "radio">
							<cfset myvalues = attinfo.prdAtrValue>

							<cfquery name="radloop" dbtype="query">
							SELECT 1 as selected, prdAtrValue, prdatrID
							FROM getattributevalues
							WHERE prdAtrValue IN (<cfqueryparam sqltype="VARCHAR" list="yes" value="#attinfo.columnData('prdatrvalue')#">)
							AND prdAtrValue <> ''

							UNION

							SELECT 0 as selected, prdAtrValue, prdatrID
							FROM getattributevalues
							WHERE prdAtrValue NOT IN (<cfqueryparam sqltype="VARCHAR" list="yes" value="#attinfo.columnData('prdatrvalue')#">)
							ORDER BY prdAtrValue
							</cfquery>

							<div class="attform">
								<cfset myname = attinfo.atrID & "_" & attinfo.currentrow>

								<cfloop query="radloop">
									<cfset myid = attinfo.atrID & "_" & radloop.currentrow>
									<cfset myvalue = radloop.prdAtrValue>

									<cfif radloop.selected EQ 1>
										<cfset imselected = myvalue>
									<cfelse>
										<cfset imselected = 0>
									</cfif>

									<!--- type,values,id,name,class,style,label,selected,dectofract,minmaxrange --->
									<cfset element = ui.get(myformtype, myvalue, myid, myname, "tiny", "", myvalue, imselected,attinfo.atrconvertdecimal, 1)>
									#element.element#
								</cfloop>

								<cfif ListFind(ValueList(radloop.selected), 1)>
									<cfset imselected = 0>
								<cfelse>
									<cfset imselected = "N/A">
								</cfif>

								<cfset myid = attinfo.atrID & "_" & radloop.recordcount + 1>
								<cfset element = ui.get(myformtype, "N/A", myid, myname, "tiny", "", "N/A", imselected)>
								#element.element#
							</div>

							<a class="addnewlink" href="javascript:;">Add New</a>

						<cfelse>
							<cfset myname = attinfo.atrID & "_" & attinfo.currentrow>
							<cfset myvalues = getattributevalues.columnData('prdAtrValue')>
							<!--- type,values,id,name,class,style,label,selected,dectofract,minmaxrange --->
							<cfset element = ui.get(myformtype, myvalues, myname, myname, "tiny", "", "", attinfo.prdAtrValue,attinfo.atrconvertdecimal, 1)>
							<div class="attform">#element.element#</div>

						</cfif>

					</cfloop>

					<cfif myformtype NEQ "checkbox">
						<div class="group tiny">#attinfo.atrgroup#</div>
					</cfif>

					<div class="clear"></div>

				</div>

				<div class="clear"></div>

				<cfif distinctatts.currentrow EQ Fix(distinctatts.recordcount / 2)>

					</div>
					<div id="colright">

				</cfif>

			</cfloop>

			<cfif listattributes.recordcount LT 2>
				</div>
				<div id="colright">
			</cfif>

		</div>

		<div class="clear"></div>

		<div style="float:right; margin-right:10px;">
			<input type="hidden" name="productID" value="#attributes.productID#" />
			<input type="submit" name="imdone" value="Save Attributes" <cfif isDefined("lockresult.myLock") AND lockresult.myLock NEQ true>disabled="true"</cfif> />
		</div>

		<div class="clear"></div>
	</form>
</div>
<div class="clear"></div>
</cfoutput>

<div class="box">
	<form id="form1">
		<div class="title">
			Search Options: &nbsp;
			<span class="atrPhoto tiny">P: Photo</span> &nbsp;
			<span class="atrComp tiny">C: Comparable</span> &nbsp;
			<span class="atrSort tiny">F: Filterable</span>
			<div class="clear"></div>
			<br class="clear" />

			<cfif attributes.productID NEQ "">
				<div class="searchElements">
					<a id="closelymatched" href="javascript:;">Closely Matched Attributes</a>
				</div>
			</cfif>

			<div class="searchElements"><a id="showsearch" href="javascript:;">From Selected Category</a></div>
			<div class="searchElements">Attribute Name: <input type="text" id="atrSearchCriteria" name="atrSearchCriteria" /><input type="submit" name="searchAttrs" value="Search / Add" /></div>
			<div class="searchElements" style=""><a id="assignall" href="javascript:;" style="">Assign All</a></div>
			<div class="clear"></div>
		</div>
	</form>

	<div id="helperdiv" style="display:none; float:left; margin-top:0.5em; margin-left:0.4em;"><small>Click 'add', or drag and drop the attributes to the above list to add them to the product.</small></div>

	<div id="addattdiv" style="display:none; float:right; margin-right:1.4em;">
		<small>If you don't see the attribute you need: <a id="addattlink" href="javascript:;">Add New Attribute</a></small>
		<div class="clear"></div>
	</div>
	<div class="clear"></div>
	<br class="clear" />

	<div id="searchedAttr" class="container">
		<div id="coladdleft"></div>
		<div id="coladdright"></div>
	</div>
	<div class="clear"></div>
</div>

<div id="searchpopup" style="display: none;" class="box" title="Find Category">
	<form onsubmit="getValues(); return false;">
		<input id="criteria" name="criteria" type="text" value="" size="8" style="width:85%;">&nbsp;
		<input type="submit" value="GO" style="float:right;">
	</form>
	<a href="javascript:getValues('last7days');" class="tiny m5">last 7 days</a><br>
	<select id="selectedValues" name="values" size="15" style="width:100%;"></select><br>
	<input id="searchsubmit" type="button" value="Add">
	<div class="clear"></div>
</div>

<script type="text/javascript">
j$('document').ajaxError(function(){
	alert('There was a network error while contacting the server.');
});

var divclear = j$('<div>').addClass('clear');

function attaction(mytype,myatt,thisa){
	if(mytype == 'edit'){
		var mydialog = j$('<div>').attr('title','Add / Update Attribute').attr('id','attdialog');
		j$.ajax({
			url: '/partnernet/productmanagement/editframe/editattribute.cfm',
			type: 'get',
			data: { atrid: myatt, productid: <cfoutput>#esapiEncode('javascript', attributes.productID)#</cfoutput> },
			success: function(response){
				mydialog.html(response);
				mydialog.dialog({ autoOpen:true, modal:true, close: function(){ j$('#attdialog').remove(); } });
				var mywidth = ('#editattribute',mydialog).width();
				j$(mydialog).dialog('option', 'width', parseInt(mywidth + 250)).dialog('option', 'position', ['center','center']);
				j$('input[name="imdone"]',mydialog).button();

				j$('#atrgroup',mydialog).on('change', function(){
					if(j$(this).val() == 'Add New') {
						var newval = prompt('Please enter the group you would like to add.','');
						if(newval != '' && newval != 'undefined' && newval != null){
							j$('<option>').append(newval).val(newval).appendTo(j$(this));
							j$(this).val(newval);
						}
					}
				});

				j$('input[name="imdone"][value="Delete"]',mydialog).on('click', function(){
					var confirmation = confirm('Are you sure you want to delete this attribute and all values for this attribute assigned to products?');
					if(confirmation !== true) return false;
				});
			}
		});

	} else if (mytype == 'remove') {
		if($(thisa).closest('div.anatt').data('required') == 1) {
			alert('This attribute is required, and cannot be removed.');
		} else {
			var myid = j$(thisa).parents('div.anatt').attr('id');
			if(j$('#'+myid, j$('#searchedAttr')).length == 0){
				var newatt = j$(thisa).parents('div.anatt').clone(true);
				newatt.css('display','none')
				j$('a:contains("remove")',newatt).text('add');
				var toaddto = chooseside('coladd');
				j$(toaddto).append(newatt);
				endisable(newatt, 0);
			} else {
				endisable(j$('#'+myid, j$('#searchedAttr')), 0);
			}
			j$(thisa).parents('div.anatt').remove();
			setborders();
		}

	} else if (mytype == 'add') {
		var myid = j$(thisa).parents('div.anatt').attr('id');
		if(j$('#'+myid, j$('#myatts')).length == 0){
			var newatt = j$(thisa).parents('div.anatt').clone(true);
			newatt.css('display','none')
			j$('a:contains("add")',newatt).text('remove');
			var toaddto = chooseside('col');
			j$(toaddto).append(newatt);
			endisable(newatt, 0);
			endisable(j$(thisa).parents('div.anatt'),1);
			setborders();
		}
	}
}

function getValues(criteria){
	if(!criteria) criteria = j$('#criteria').val();

	j$.ajax({
		url: '/partnernet/productmanagement/ajax_getCategories.cfm',
		data: {criteria:criteria},
		type: 'post',
		success: function(response){
			values = eval('(' + j$.trim(response) + ')');
			j$('#selectedValues').empty();
			if(values.length == 0) j$('<option>').append('None Found!').val('').appendTo(j$('#selectedValues'));
			j$.each(values, function(i, v){
				if(v.n.length > 1)  j$('<option>').append(v.n).val(v.i).appendTo(j$('#selectedValues'));
			});
		}
	});
}

function getSearchedAttrs(criteria,type,loc){
	if(!loc) loc = 1;
	var path = '/partnernet/productmanagement/ajax_getAttributes.cfm?criteria=' + criteria;
	if(type) path += '&type=' + type;
	if(loc == 1) j$('#searchedAttr').children('div').html('Loading...');

	j$.ajax({
		url: path,
		type: 'get',
		success: function(response) {
			if(loc == 1) j$('#searchedAttr').children('div').html('');
			searchedAttrArr = eval('(' + j$.trim(response) + ')');
			j$(searchedAttrArr).each(function(){
				var mydiv = createattdiv(j$(this)[0]);
				if(loc != 1) {
					var myside = chooseside('col');
					j$('a:contains("add")',mydiv).text('remove');
				} else {
					var myside = chooseside('coladd');
				}
				myside.append(mydiv).append(divclear.clone());
			});
			setborders();
		}
	});
}

function createattdiv(arrel){
	var newdiv = j$('<div>').addClass('anatt').attr('id',arrel.i);
	var attbox = j$('<div>').addClass('atrBoxes');
	var atttitle = j$('<div>').addClass('atttitle');
	var attform = j$('<div>').addClass('attform');
	var attgroup = j$('<div>').addClass('group tiny').text(arrel.g);
	var atttype = j$('<div>').attr('name','formtype').css('display','none').text(arrel.f);

	if (j$('#' + arrel.i, j$('#myatts')).length > 0) return false;

	if(arrel.p == 1) j$('<div>').addClass('atrPhoto px20').text('P').appendTo(attbox);
	if(arrel.c == 1) j$('<div>').addClass('atrComp px20').text('C').appendTo(attbox);
	if(arrel.s == 1) j$('<div>').addClass('atrSort px20').text('F').appendTo(attbox);
	newdiv.append(attbox);

	j$('<a>').attr('name',arrel.i).attr('href','javascript:;').text('add').appendTo(atttitle);
	j$('<span>').text(arrel.n).appendTo(atttitle);
	j$('<a>').attr('name',arrel.i).attr('href','javascript:;').text('edit').appendTo(atttitle);
	newdiv.append(atttitle).append(atttype);

	if(arrel.f == 'Checkbox'){
		newdiv.append(divclear.clone());
		j$('<span>').addClass('ui-icon ui-icon-circle-triangle-s')
			.attr('title','Click to expand/collapse options')
			.css({ 'float':'left','margin-left':'2px' })
			.appendTo(newdiv);
		newdiv.append('<br>');

		var mytable = j$('<table><tbody>');

		var mytr = j$('<tr>');
		j$.each(arrel.v, function(key,value){
			if(parseInt(key) % 4 == 0) mytr = j$('<tr>');

			var mytd = j$('<td>').attr('align','right').css('white-space','nowrap');
			if(arrel.cd == 1){
				var mylabel = j$('<label>').attr('for',arrel.i+'_'+key).append(displayFraction(value));
			}
			else {
				var mylabel = j$('<label>').attr('for',arrel.i+'_'+key).append(value);
			}
			var mycbx = j$('<input>').attr({ type:'checkbox', value:value, name:arrel.i+'_'+key, id:arrel.i+'_'+key, 'class':'tiny' });
			mytd.append(mylabel).append(mycbx);
			mytr.append(mytd);

			if(parseInt(key + 1) % 4 == 0) mytable.append(mytr);
		});

		mytable.append(mytr);
		attform.addClass('collapser').append(mytable);

	} else if(arrel.f == 'Radio') {
		j$.each(arrel.v, function(key,value){
			var myrad = j$('<input>').attr({ type:'radio', value:value, name:arrel.i+'_1', 'class':'tiny' });
			attform.append(value).append(myrad);
		});
		var myrad = j$('<input>').attr({ type:'radio', value:'N/A', name:arrel.i+'_1', 'class':'tiny' });
		attform.append('N/A').append(myrad);

	} else if(arrel.f == 'Select' || arrel.f == 'Range') {
		if(arrel.m !== '1') {
			myselect = j$('<select>').attr({ name:arrel.i+'_1', id:arrel.i+'_1', 'class':'tiny' });

			if(arrel.cd == 1){
				j$.each(arrel.v, function(key,value){
						myselect.append(j$('<option></option>').attr('value',value).text(displayFraction(value)));
				});
			}
			else {
				j$.each(arrel.v, function(key,value){
						myselect.append(j$('<option></option>').attr('value',value).text(value));
				});
			}

			myselect = fluffselect(myselect);
			myselect.val('');
			myselect.data('oldval',myselect.val());
			attform.html(myselect);
		} else {
			mininput = j$('<input>').attr({ type:'text', name:arrel.i+'_1_min', 'class':'tiny' });
			maxinput = j$('<input>').attr({ type:'text',  name:arrel.i+'_1_max', 'class':'tiny' });
			attform.html(mininput).append(maxinput);
		}
	} 

	newdiv.append(attform).append(attgroup).append(divclear.clone());

	return newdiv;
}

function endisable(thediv,disabled){
	if(disabled == 1){
		thediv.fadeOut(500);
		j$('input,select',thediv).attr('disabled','disabled');
	} else if(disabled == 0) {
		thediv.fadeIn(500);
		j$('input,select',thediv).removeAttr('disabled');
	}

	return thediv;
}

function chooseside(prefix){
	var lcount = j$('#' + prefix + 'left > div.anatt').length;
	var rcount = j$('#' + prefix + 'right > div.anatt').length;
	var toaddto = lcount <= rcount ? j$('#' + prefix + 'left') : j$('#' + prefix + 'right');
	return toaddto;
}

function fluffselect(theselect){
	theselect.prepend(j$('<option></option>').attr('value','').text('N/A'));
	theselect.append(j$('<option></option>').attr('value','Add New').text('Add New'));
	if(theselect.html().indexOf('selected') == -1) {
		theselect.val('');
	}
	return theselect;
}

function setborders(){
	j$('.anatt').css('border-bottom','1px solid #C8C8C8');
	j$('#colleft .anatt:last,#colright .anatt:last').css('border-bottom','0px');
	j$('#coladdleft .anatt:last,#coladdright .anatt:last').css('border-bottom','0px');
}

function showsearch(){
	j$('#searchpopup').dialog({ autoOpen:true, modal:true, width:600 });
}

function addAllAttr(){
	j$('#searchedAttr a:contains("add")').each(function(){
		var mytype = j$(this).text();
		var myatt = parseInt(j$(this).attr('name'));
		attaction(mytype,myatt,j$(this));
	});
}

function addnew(myele){
	var myrelative = j$(myele).closest('.anatt').find('input:last');
	var newvalue = myrelative.clone(true);
	var myid = newvalue.attr('id').split('_')[0];
	var mycount = parseInt(newvalue.attr('id').split('_')[1]) + 1;
	var mytype = newvalue.attr('type');

	var newval = prompt('Please enter the value you would like to add.','');
	var dnewval = displayDecimal(newval);

	if(newval != '' && newval != 'undefined' && newval != null){

		var newlabel = j$('label[for="'+myrelative.attr('id')+'"]').clone(true);
		newlabel.attr('for',myid + '_' + mycount).text(newval);
		
		if(mytype == 'checkbox'){
			newvalue.attr('name',myid + '_' + mycount).attr('id',myid + '_' + mycount).val(dnewval);
			var insertaft = myrelative.closest('.cbxitem');
			
			var newtd = j$('<div class="cbxitem">');
			newtd.append(newvalue).append(newlabel);

			j$(newtd).insertAfter(insertaft);

		} else if(mytype == 'radio'){
			newvalue.attr('id',myid + '_' + mycount).val(dnewval);
			var insertaft = j$(myrelative).closest('.attform');
			insertaft.append(newlabel).append(newvalue);
		}

	}

}

function setsort(){
	j$('#colleft,#colright,#coladdleft,#coladdright').sortable({
		items:'div.anatt',
		revert:true,
		helper:'original',
		opacity:0.5,
		distance:10,
		connectWith:'#colleft,#colright,#coladdleft,#coladdright',
		stop:function(e, u){
			sortstop(e, u);
		}
	});
}

function sortstop(e, u){
	if(j$(u.item).data('required') == 1 && j$(u.item).parents('#searchedAttr').length > 0) {
		j$('#myatts').sortable('cancel');
		//alert('You cannot remove that attribute.');
		return false;
	}

	if(j$(u.item).parents('#searchedAttr').length > 0){
		j$('a:contains("remove")',u.item).text('add');
	}
	if(j$(u.item).parents('#myatts').length > 0){
		j$('a:contains("add")',u.item).text('remove');
	}
	setborders();
}

function formsuccess() {
	if (j$('#imhidden').contents().find('#editattribute').length > 0) {
		j$('#editattribute').html(j$('#imhidden').contents().find('#editattribute').html());
		j$('#imhidden').empty();
		j$('input[name=imdone]').removeAttr('disabled').button();

		var atrid = j$('input[name="atrID"]',j$('#attedit')).val();
		var atrplace = j$('div #'+atrid).closest('.container').attr('id');
		var loc = atrplace == 'myatts' ? 2 : 1;

		j$('div #'+atrid).remove();

		getSearchedAttrs(atrid,'attribute',loc);

		j$('#attedit').submit(function(){
			formsuccess();
		});
	} else {
		setTimeout(formsuccess, 100);
	}
}

function displayFraction(i){
	if (isNaN(parseInt(i)))
		return i;

	var d = '';
	var n = '';
	var w = parseInt(i);
	var f = (parseFloat(i) - w) * 1000;

	if (f > 0){
		for (x=2;x<=1000;x++){
			if ((Math.round(f*x)%1000) == 0){
				d=x;
				n=Math.round(f*x)/1000;
				break;
			}
		}
	}

	if (w <= 0)
		w = '';

	if (d != '')
		fraction = String(w) + ' ' + String(n) + '/' + String(d);
	else
		fraction = i;

	return fraction;
}

function displayDecimal(i){
    if (parseFloat(i) == i)
        return i;
    var w=0;
    var v = i.split(' ');
    if(j$(v).length == 2){
        if(v[1].indexOf('/') > 0){
            var d = v[1].split('/');
            w = v[0];
        }
        else
            return i;
    }
    else if (j$(v).length == 1){
        if(v[0].indexOf('/') > 0)
            var d = v[0].split('/');
        else
            return i;
    }
    else
        return i;
    decimal = parseInt(w) + (d[0]/d[1]);

    if (parseFloat(decimal) == decimal)
        return decimal;
    else
        return i;
}

function isValidDecimalInput(input) {
	return input && input.split(".")[1] && input.split(".")[1].length === 1;
}

j$(function(){
	const strictDecimalValueFieldLookup = ['37', '725', '743', '1360', '1365', '1366'];

	setborders();

	j$('body').on('click', '.atttitle a', function(){
		var mytype = j$(this).text();
		var myatt = parseInt(j$(this).attr('name'));
		attaction(mytype,myatt,j$(this));
	});

	j$('body').on('submit', '#attedit', function(){
		formsuccess();
	});

	j$('#form1').on('submit', function(){
		getSearchedAttrs(j$('#atrSearchCriteria').val());
		j$('#addattdiv,#helperdiv').slideDown(1000);
		return false;
	});

	j$('#myatts').on('click', '.ui-icon', function(){
		j$(this).parents('div').children('.collapser').slideToggle(1000);
		j$(this).toggleClass('ui-icon-circle-triangle-s');
		j$(this).toggleClass('ui-icon-circle-triangle-n');
	});

	j$('#closelymatched').on('click', function(){
		getSearchedAttrs(j$('input[name="productID"]').val(),'closelyMatched')
	});

	j$('#showsearch').on('click', function(){
		showsearch();
	});

	j$('#assignall').on('click', function(){
		addAllAttr();
	});

	j$('#addattlink').on('click', function(){
		attaction('edit');
	}); j$('#addattlink').button();

	j$('.addnewlink').on('click', function(){
		addnew(j$(this));
	});

	j$('#myatts').on('change', 'select', function(){

		if(j$(this).val() == 'Add New') {
			var attId = j$(this).attr("id").split('_')[0];
			var newval = prompt('Please enter the value you would like to add.','');
			if(strictDecimalValueFieldLookup.includes(attId)) {
				while(newval && !isValidDecimalInput(newval)) {
					newval = prompt('Please enter the value you would like to add, ensuring only 1 decimal place is used (e.g 20.1).','');
				}
			}
			var dnewval = displayDecimal(newval);
			if(newval != '' && newval != 'undefined' && newval != null){
				var ftype = j$(this).parent().siblings('div[name="formtype"]').text();
				if(ftype == 'Range' && parseFloat(dnewval) != dnewval){
					alert('This attribute is used for range sliders, and all values must be numeric.');
					j$(this).val(j$(this).data('oldval'));
					return false;
				}
				j$('<option>').append(newval).val(dnewval).insertBefore(j$(this).children(':last'));
				j$(this).val(dnewval);
			} else {
				j$(this).val(j$(this).data('oldval'));
			}
		}

		j$(this).data('oldval',j$(this).val());
		if(j$(this).closest('div.anatt').data('required') == 1 && j$(this).val() == '') j$(this).parents('div.anatt').addClass('required');
			else j$(this).parents('div.anatt').removeClass('required');

	});

	j$('#myatts').on('change', 'input', function(){
		var myparent = j$(this).closest('div.anatt');
		if(myparent.data('required') == 1){
			if((j$('select',myparent).length > 0 && j$('select',myparent).val() != '') || (j$('input:checked',myparent).length > 0 && j$('input:checked',myparent).val() != 'N/A')){
				myparent.removeClass('required');
			} else {
				myparent.addClass('required');
			}
		}

	});

	j$('#searchsubmit').on('click', function(){
		getSearchedAttrs(j$('#selectedValues').val(),'category');
		j$('#searchpopup').dialog('close');
	});
	j$('#selectedValues').on('dblclick', function(){
		getSearchedAttrs(j$('#selectedValues').val(),'category');
		j$('#searchpopup').dialog('close');
	});

	j$('.anatt').each(function(){
		if(j$('select',j$(this)).length > 0)
			fluffselect(j$('select',j$(this)));

		if(j$(this).hasClass('required')){
			j$(this).data('required','1');
			if(j$(this).hasClass('empty') && j$('select',j$(this)).length > 0){
				j$('select',j$(this)).val('');
			}
			if(!j$(this).hasClass('empty'))
				j$(this).removeClass('required')
		}

		if(j$('select',j$(this)).length > 0)
			j$('select',j$(this)).data('oldval',j$('select',j$(this)).val());
	});

	j$('input[type="submit"],input[type="button"],#form1 a').button();


	j$('#selatts').on('submit', function(){
		var foundErr = false
		j$('[id$=_min],[id$=_max]').each(function() {
			var attId = j$(this).attr("id").split('_')[0];
			var attVal = j$(this).val();
			if(strictDecimalValueFieldLookup.includes(attId) && !isEmpty(attVal) && !isValidDecimalInput(attVal)) {
				j$(this).focus();
				alert('Min and Max ranges need to be decimal values (e.g 20.0)');
				foundErr = true;
				return false;
			}
		})
		if(foundErr) {
			return false;
		}

		<!--- this prevents submission if required attributes don't have values, commenting out for now --->
		<!--- j$('.required').each(function(){
			alert('You must select a value for all required attributes.')
			j$('select', j$(this)).focus();
			return false;
		});
		if(j$('.required').length > 0) return false; --->
	});

	setsort();

});
</script>

<cfinclude template="/partnernet/shared/_footer.cfm">
