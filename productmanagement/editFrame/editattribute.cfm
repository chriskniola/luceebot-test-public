<cfsetting showdebugoutput="no">

<cfparam name="attributes.atrid" default="">
<cfparam name="attributes.atrname" default="">
<cfparam name="attributes.atrpossiblevalues" default="">
<cfparam name="attributes.catid" default="">
<cfparam name="attributes.productid" default="">
<cfparam name="attributes.atrsortable" default="0">
<cfparam name="attributes.atrcomparable" default="0">
<cfparam name="attributes.atrphotoid" default="">
<cfparam name="attributes.atrunits" default="">
<cfparam name="attributes.atrgroup" default="Default">
<cfparam name="attributes.atrpriority" default="50">
<cfparam name="attributes.atrdescription" default="">
<cfparam name="attributes.atrlearn" default="">
<cfparam name="attributes.atrdescriptionimage" default="">
<cfparam name="attributes.atrdisplayonsite" default="0">
<cfparam name="attributes.atrdisplayestimator" default="0">
<cfparam name="attributes.atrconvertdecimal" default="0">
<cfparam name="attributes.atrminmaxrange" default="1">
<cfparam name="attributes.atrexclusiveresult" default="0">
<cfparam name="attributes.operator" default="=">
<cfparam name="attributes.formtype" default="Select">
<cfparam name="attributes.delimiter" default="">
<cfparam name="rangeconfig" default="">
<cfparam name="attributes.photofile" default="">
<cfparam name="attributes.imdone" default="">

<cfset submitmessage = "">

<cfif attributes.atrgroup EQ "Default" OR attributes.atrgroup EQ "Add New"><cfset attributes.atrgroup = ""></cfif>
<cfif isEmpty(attributes.catid) && !isEmpty(attributes.productid)>
	<cfset attributes.catid = queryExecute('
		SELECT Category
		FROM Products
		WHERE id = :productid
	', { productid: { sqlType='int', value=attributes.productid } }, { datasource='ahapdb' }).category>
</cfif>

<cfif attributes.imdone EQ "Add">

	<!--- <cftry> --->

		<cfquery name="addatt" datasource="#DSN#">
		INSERT INTO tblAttributes (atrname, atrpossiblevalues, atrsortable, atrcomparable, atrphotoid, atrunits, atrgroup, atrpriority, atrdescription, atrlearn, atrdescriptionimage, atrdisplayonsite, atrdisplayestimator, atrconvertdecimal, atrminmaxrange, atrexclusiveresult, operator, formtype, delimiter)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="50" value="#attributes.atrname#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="255" value="#attributes.atrpossiblevalues#">
				, <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrsortable#">
				, <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrcomparable#">
				, <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrphotoid#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="50" value="#attributes.atrunits#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="75" value="#attributes.atrgroup#">
				, <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrpriority#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="5000" value="#attributes.atrdescription#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="150" value="#attributes.atrlearn#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="255" value="#attributes.atrdescriptionimage#">
				, <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrdisplayonsite#">
				, <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrdisplayestimator#">
				, <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrconvertdecimal#">
				, <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrminmaxrange#">
				, <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrexclusiveresult#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="10" value="#attributes.operator#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="15" value="#attributes.formtype#">
				, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="5" value="#attributes.delimiter#">
			)

		SELECT @@IDENTITY as newID
		</cfquery>

		<cfset attributes.atrID = addatt.newID>

		<cfsavecontent variable="submitmessage">
		<div class="ui-widget">
			<div class="ui-state-highlight ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
				<p><span class="ui-icon ui-icon-info" style="float: left; margin-right: .3em;"></span>
				<strong>Success!</strong> Attribute was added.</p>
			</div>
		</div>
		</cfsavecontent>

	<!--- <cfcatch>

		<cfsavecontent variable="submitmessage">
		<div class="ui-widget">
			<div class="ui-state-error ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
				<p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
				<strong>Error!</strong> Attribute was not added.</p>
			</div>
		</div>
		</cfsavecontent>

	</cfcatch>
	</cftry> --->

<cfelseif attributes.imdone EQ "Update">
	<cftry>

		<cfquery name="currentvalues" datasource="#DSN#">
		SELECT atrID, atrname, atrpossiblevalues, atrsortable, atrcomparable, atrphotoid, atrunits, atrgroup, atrpriority, atrdescription, atrlearn, atrdescriptionimage, atrdisplayonsite, atrdisplayestimator, atrconvertdecimal, atrminmaxrange, operator, formtype, delimiter
		FROM tblAttributes
		WHERE atrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrid#">
		</cfquery>

		<cfif currentvalues.formtype EQ "Checkbox" AND attributes.formtype NEQ "Checkbox">

			<cfquery name="multiplevalues" datasource="#DSN#">
			SELECT p.ID, p.Manufacturer, p.ModelNumber
			FROM Products p (NOLOCK)
			INNER JOIN tblProductAttributes pa (NOLOCK) ON pa.prdID = p.ID
			INNER JOIN tblAttributes ta (NOLOCK) ON ta.atrID = pa.prdAtrID

			WHERE ta.atrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrid#">
			AND p.active = 1
			GROUP BY p.ID, p.Manufacturer, p.ModelNumber, ta.atrName, ta.atrID
			HAVING COUNT(pa.prdAtrValue) > 1

			ORDER BY p.Manufacturer, p.ModelNumber
			</cfquery>

		</cfif>

		<cfif attributes.formtype EQ "Range">
			<cfscript>
				function storeRangeConfig(required array rangeConfig, required numeric attributeID, numeric categoryID = 0) {
					if(isEmpty(arguments.rangeConfig)) {
						queryExecute("
							DELETE FROM AttributeRangeCategory
							WHERE attributeID = :attributeID
								AND categoryID = :categoryID
								AND categoryID IS NOT NULL
						",{
							attributeID: {sqltype="INT", value=arguments.attributeID},
							categoryID: {sqltype="INT", value=arguments.categoryID, null=!arguments.categoryID}
						},{datasource: DSN});

						return;
					}
					queryExecute("
						DECLARE @mergeResults TABLE (rangeID INT)
						MERGE INTO AttributeRangeConfig AS Target
						USING (
							VALUES (:rangeConfig)
						) AS Source (rangeConfig)
						ON Target.rangeConfig = Source.rangeConfig
						WHEN MATCHED THEN
							UPDATE SET rangeConfig = Source.rangeConfig
						WHEN NOT MATCHED BY Target THEN
							INSERT (rangeConfig)
							VALUES (Source.rangeConfig)
						OUTPUT Inserted.ID
						INTO @mergeResults;
						MERGE INTO AttributeRangeCategory AS Target
						USING (
							SELECT rangeID, :attributeID, :categoryID
							FROM @mergeResults
						) AS Source (rangeID, attributeID, categoryID)
						ON Target.attributeID = Source.attributeID
							AND ISNULL(Target.categoryID, 0) = ISNULL(Source.categoryID, 0)
						WHEN MATCHED THEN
							UPDATE SET rangeID = Source.rangeID
						WHEN NOT MATCHED BY Target THEN
							INSERT (rangeID, attributeID, categoryID)
							VALUES (Source.rangeID, Source.attributeID, Source.categoryID);
					",{
						rangeConfig: {sqltype="VARCHAR", value=serializeJSON(arguments.rangeConfig), maxlength=1000},
						attributeID: {sqltype="INT", value=arguments.attributeID},
						categoryID: {sqltype="INT", value=arguments.categoryID, null=!arguments.categoryID}
					},{datasource: DSN});
				}

				private array function createRangeConfig(form, isCategoryConfig) {
					var isCategoryConfig = arguments.isCategoryConfig;
					var isDecimal = false;
					var catSelector = isCategoryConfig ? 'Category' : '';
					var rangeConfig = arguments.form.reduce((acc, key, val) => {
						if (arguments.key.startsWith('variableRangeConfig') && isCategoryConfig == trueFalseFormat(arguments.key.find('Category')) && !arguments.key.find('.')) {
							if(!isDecimal && arguments.val.from.find('.')) {
								isDecimal = true;
							}
							arguments.val['key'] = "#numberFormat(arguments.val.from, isDecimal ? ',.0' : ',')# - #numberFormat(arguments.val.to, isDecimal ? ',.0' : ',')#";
							arguments.val['from'] = isDecimal ? numberFormat(arguments.val.from, '.0') : arguments.val.from;
							arguments.val['to'] = isDecimal ? numberFormat(arguments.val.to, '.0') : arguments.val.to;
							arguments.acc.append(arguments.val);
						}
						return acc;
					}, []);

					if (!rangeConfig.len()) {
						return [];
					}

					rangeConfig.sort((a, b) => a.from > b.from ? 1 : -1);

					rangeConfig.prepend({
						"key": "Up to #numberFormat(arguments.form['rangeConfig#catSelector#-upTo'].to, isDecimal ? ',.0' : ',')#",
						"to": isDecimal ? numberFormat(arguments.form['rangeConfig#catSelector#-upTo'].to, '.0') : arguments.form['rangeConfig#catSelector#-upTo'].to
					});

					rangeConfig.append({
						"key": "#numberFormat(arguments.form['rangeConfig#catSelector#-andAbove'].from, isDecimal ? ',.0' : ',')# & Above",
						"from": isDecimal ? numberFormat(arguments.form['rangeConfig#catSelector#-andAbove'].from, '.0') : arguments.form['rangeConfig#catSelector#-andAbove'].from
					});

					return rangeConfig;
				}

				var defaultRangeConfig = createRangeConfig(form, false);
				var categoryRangeConfig = createRangeConfig(form, true);

				storeRangeConfig(defaultRangeConfig, attributes.atrid);
				storeRangeConfig(categoryRangeConfig, attributes.atrid, attributes.catID);

			</cfscript>
			<cfif currentvalues.formtype NEQ "Range">
				<cfquery name="onlynumbers" datasource="#DSN#">
				SELECT p.ID, p.Manufacturer, p.ModelNumber, pa.prdAtrValue
				FROM Products p (NOLOCK)
				INNER JOIN tblProductAttributes pa (NOLOCK) ON pa.prdID = p.ID
				INNER JOIN tblAttributes ta (NOLOCK) ON ta.atrID = pa.prdAtrID

				WHERE ta.atrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrid#">
				AND p.active = 1
				AND isNumeric(pa.prdAtrValue) = 0
				ORDER BY ta.atrID, p.Manufacturer, p.ModelNumber
				</cfquery>
			</cfif>
		</cfif>

		<cfif isDefined("multiplevalues.recordcount") AND multiplevalues.recordcount GT 0>

			<cfsavecontent variable="submitmessage">
			<div class="ui-widget">
				<div class="ui-state-error ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
					<p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
					<strong>Error!</strong> Products with this attribute have multiple values:</p>
					<p>
						<cfoutput query="multiplevalues">
							#ID# #ModelNumber#<br>
						</cfoutput>
					</p>
				</div>
			</div>
			</cfsavecontent>

		<cfelseif isDefined("onlynumbers.recordcount") AND onlynumbers.recordcount GT 0>

			<cfsavecontent variable="submitmessage">
			<div class="ui-widget">
				<div class="ui-state-error ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
					<p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
					<strong>Error!</strong> Products with this attribute have non-numeric values:</p>
					<p>
						<cfoutput query="onlynumbers">
							#ID# #ModelNumber#<br>
						</cfoutput>
					</p>
				</div>
			</div>
			</cfsavecontent>

		<cfelse>
			<cfquery name="updatt" datasource="#DSN#">
				UPDATE tblAttributes
					SET
					atrname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="50" value="#attributes.atrname#">
					, atrpossiblevalues = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="255" value="#attributes.atrid#">
					, atrsortable = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrsortable#">
					, atrcomparable = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrcomparable#">
					, atrphotoid = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrphotoid#">
					, atrunits = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="50" value="#attributes.atrunits#">
					, atrgroup = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="75" value="#attributes.atrgroup#">
					, atrpriority = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrpriority#">
					, atrdescription = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="5000" value="#attributes.atrdescription#">
					, atrlearn = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="150" value="#attributes.atrlearn#">
					, atrdescriptionimage = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="255" value="#attributes.atrdescriptionimage#">
					, atrdisplayonsite = <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrdisplayonsite#">
					, atrdisplayestimator = <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrdisplayestimator#">
					, atrconvertdecimal = <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrconvertdecimal#">
					, atrminmaxrange = <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrminmaxrange#">
					, atrexclusiveresult = <cfqueryparam cfsqltype="CF_SQL_BIT" value="#attributes.atrexclusiveresult#">
					, operator = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="10" value="#attributes.operator#">
					, formtype = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="15" value="#attributes.formtype#">
					, delimiter = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="5" value="#attributes.delimiter#">
				WHERE atrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrid#">
			</cfquery>

			<cfsavecontent variable="submitmessage">
			<div class="ui-widget">
				<div class="ui-state-highlight ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
					<p><span class="ui-icon ui-icon-info" style="float: left; margin-right: .3em;"></span>
					<strong>Success!</strong> Attribute was updated.</p>
				</div>
			</div>
			</cfsavecontent>

		</cfif>

	<cfcatch>

		<cfsavecontent variable="submitmessage">
		<div class="ui-widget">
			<div class="ui-state-error ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
				<p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
				<strong>Error!</strong> Attribute was not updated.</p>
			</div>
		</div>
		</cfsavecontent>

	</cfcatch>
	</cftry>

	<cfset new system.CacheBuster().bustCacheByTag(cacheTags=['productAttributes'], cacheName='RedisQuery')>

<cfelseif attributes.imdone EQ "Delete">

	<cftry>

		<cfquery name="delatt" datasource="#DSN#">
		DELETE FROM tblAttributes
		WHERE atrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrID#">

		DELETE FROM tblProductAttributes
		WHERE prdAtrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrID#">
		</cfquery>

		<cfsavecontent variable="submitmessage">
		<div class="ui-widget">
			<div class="ui-state-highlight ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
				<p><span class="ui-icon ui-icon-info" style="float: left; margin-right: .3em;"></span>
				<strong>Success!</strong> Attribute was deleted.</p>
			</div>
		</div>
		</cfsavecontent>

	<cfcatch>

		<cfsavecontent variable="submitmessage">
		<div class="ui-widget">
			<div class="ui-state-error ui-corner-all" style="margin:5px auto; padding:0 0.7em;">
				<p><span class="ui-icon ui-icon-alert" style="float: left; margin-right: .3em;"></span>
				<strong>Error!</strong> Attribute was not deleted.</p>
			</div>
		</div>
		</cfsavecontent>

	</cfcatch>
	</cftry>

</cfif>

<cfquery name="getatt" datasource="#DSN#">
	SELECT
		a.atrID,
		a.atrname,
		a.atrpossiblevalues,
		a.atrsortable,
		a.atrcomparable,
		a.atrphotoid,
		a.atrunits,
		a.atrgroup,
		a.atrpriority,
		a.atrdescription,
		a.atrlearn,
		a.atrdescriptionimage,
		a.atrdisplayonsite,
		a.atrdisplayestimator,
		a.atrconvertdecimal,
		a.atrminmaxrange,
		a.atrexclusiveresult,
		a.operator,
		a.formtype,
		a.delimiter,
		ISNULL(dRangeConfig.rangeconfig, '[]') AS 'defaultRangeConfig',
		filterCat.categoryID,
		filterCat.categoryListName,
		ISNULL(catRange.rangeconfig, '[]') AS 'categoryRangeConfig'
	FROM tblAttributes a
	LEFT JOIN AttributeRangeCategory dRangeCat ON dRangeCat.attributeID = a.atrID
		AND dRangeCat.categoryID IS NULL
	LEFT JOIN AttributeRangeConfig dRangeConfig ON dRangeConfig.ID = dRangeCat.rangeID
	CROSS APPLY (
		SELECT
			ISNULL(ctfp.topFilteringParentID, pc.ID) AS 'categoryID',
			ISNULL(ctfp.parentName, pc.[Name]) AS 'categoryName',
			ISNULL(ctfp.parentListName, pc.ListName) AS 'categoryListName'
		FROM ProductCategories pc
		LEFT JOIN CategoryTopFilteringParent ctfp ON ctfp.categoryId = pc.ID
		WHERE pc.ID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.catid#">
	) filterCat
	OUTER APPLY (
		SELECT arc.rangeconfig
		FROM AttributeRangeCategory attRanCat
		INNER JOIN AttributeRangeConfig arc  ON attRanCat.rangeID = arc.ID
		WHERE attRanCat.attributeID = a.atrID
			AND attRanCat.categoryID = filterCat.categoryID
	) catRange
	WHERE a.atrID = <cfqueryparam cfsqltype="CF_SQL_INT" value="#attributes.atrID#">
</cfquery>

<cfquery name="allgroups" datasource="#DSN#">
SELECT 'Default' as atrgroup, 1 as atrsort

UNION

SELECT atrgroup, 2 as atrsort
FROM tblAttributes
GROUP BY atrgroup

UNION

SELECT 'Add New' as atrgroup, 3 as atrsort
ORDER BY atrsort, atrgroup
</cfquery>

<cfobject component="alpine-objects.ui" name="ui">
<cfset ui.init()>

<style type="text/css">
h3 {
	margin:0 0 8px 0;
	padding:5px;
	text-align:center;
	background-color:#F0F0F0;
}

#editattribute {
	width:100%;
}

.grouping {
	width:100%;
	margin:6px 0;
	padding-bottom:5px;
	border:1px solid #C8C8C8;
}

.label {
	float:left;
	width:150px;
	line-height:25px;
	text-align:right;
	color: #000;
}

.formel {
	float:left;
	margin-left:5px;
}

#rangeConfig
input[type=number]::-webkit-inner-spin-button,
#rangeConfigCategory
input[type=number]::-webkit-inner-spin-button,
input[type=number]::-webkit-outer-spin-button {
	-webkit-appearance: none;
	-moz-appearance: none;
	appearance: none;
	margin: 0;
}
</style>

<cfoutput>
<div id="editattribute">
	#submitmessage#
	<form id="attedit" method="POST" target="imhidden" action="#CGI.SCRIPT_NAME#" enctype="multipart/form-data">
		<div style="width:100%">

			<div>
				<div class="grouping">

					<h3>Product Display</h3>

					<div class="label">Name</div>
					<div class="formel">#ui.get("text", getatt.atrname, "atrname", "atrname", "", "", "", "").element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Units</div>
					<div class="formel">#ui.get("text", getatt.atrunits, "atrunits", "atrunits", "", "", "", getatt.atrunits).element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Group</div>
					<div class="formel">#ui.get("select", ValueList(allgroups.atrgroup), "atrgroup", "atrgroup", "", "", "", getatt.atrgroup).element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Priority</div>
					<div class="formel">#ui.get("text", getatt.atrpriority, "atrpriority", "atrpriority", "", "width:3em;", "", "").element#&nbsp;</div>
					<div class="clear"></div>


				</div>

				<div class="grouping">

					<h3>Attributes</h3>

					<div class="label">Display On Site</div>
					<div class="formel">#ui.get("checkbox", 1, "atrdisplayonsite", "atrdisplayonsite", "", "", "", getatt.atrdisplayonsite).element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Comparable</div>
					<div class="formel">#ui.get("checkbox", 1, "atrcomparable", "atrcomparable", "", "", "", getatt.atrcomparable).element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Filterable</div>
					<div class="formel">#ui.get("checkbox", 1, "atrsortable", "atrsortable", "", "", "", getatt.atrsortable).element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Convert Decimal</div>
					<div class="formel">#ui.get("checkbox", 1, "atrconvertdecimal", "atrconvertdecimal", "", "", "", getatt.atrconvertdecimal).element#&nbsp;</div>
					<div class="clear"></div>

				</div>

				<cfset defaultRangeConfig = isEmpty(getatt.defaultrangeconfig) ? [] : deserializeJSON(getatt.defaultrangeconfig)>
				<cfset categoryRangeConfig = isEmpty(getatt.categoryrangeconfig) ? [] : deserializeJSON(getatt.categoryrangeconfig)>
				<div class="grouping">

					<h3>Filter Settings</h3>

					<div class="label">Form Type</div>
					<div class="formel">#ui.get("select", "Select,Checkbox,Range,Radio", "formtype", "formtype", "", "", "", getatt.formtype).element#&nbsp;</div>
					<div class="clear"></div>

					<!--- <div class="label">Has Min and Max Ranges</div>
					<div class="formel">#ui.get("checkbox", 1, "atrminmaxrange", "atrminmaxrange", "", "", "", getatt.atrminmaxrange).element#&nbsp;</div>
					<div class="clear"></div> --->

					<div id="exclusiveResult" style="#getatt.formtype != 'Range' ? '' : 'display:none;'#">
						<div class="label">Exclusive Result</div>
						<div class="formel">#ui.get("checkbox", 1, "atrexclusiveresult", "atrexclusiveresult", "", "", "", getatt.atrexclusiveresult).element#&nbsp;</div>
						<div class="clear"></div>
					</div>

					<div id="rangeConfig" style="#getatt.formtype == 'Range' ? '' : 'display:none;'#">
						<div class="label">Default Range Config</div>
						<div class="formel">
							<div style="display:flex;justify-content:flex-start;align-items:center;margin-bottom:0.5em;margin-left:1.7em;">
								Up to&nbsp;&nbsp;&nbsp;<input <cfif !defaultRangeConfig.len()>disabled</cfif> name="rangeConfig-upTo.to" id="rangeConfig-upTo-to" type="number" step="0.1" style="width:4em;" value="#arrayIsDefined(defaultRangeConfig, 1) ? defaultRangeConfig[1].to : ''#" class="defaultRangeConfig" required>
							</div>
							<cfif defaultRangeConfig.len() GT 2>
								<div id="rangeConfig-variableRanges">
									<cfloop array="#defaultRangeConfig#" item='item' index="i">
										<cfif i != 1 && i != defaultRangeConfig.len()>
											<div id="variableRangeConfig-#i#" style="display:flex;justify-content:flex-start;align-items:center;margin-bottom:0.5em;">
												<input <cfif !defaultRangeConfig.len()>disabled</cfif> name="variableRangeConfig-#i#.from" id="variableRangeConfig-#i#-from" type="number" step="0.1" style="width:4em;" value="#item.from#" class="defaultRangeConfig" required>
												&nbsp;-&nbsp;
												<input <cfif !defaultRangeConfig.len()>disabled</cfif> name="variableRangeConfig-#i#.to" id="variableRangeConfig-#i#-to" type="number" step="0.1" style="width:4em;" value="#item.to#" class="defaultRangeConfig" required>
												<cfif i != 2>
													<a id="variableRangeConfig-removeRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);margin-left:0.5em;">remove</a>
												</cfif>
											</div>
										</cfif>
									</cfloop>
								</div>
								<div style="display:#defaultRangeConfig.len() LT 8 ? 'flex' : 'none'#;justify-content:flext-start;align-items:center;margin-top:0.5em;margin-bottom:0.5em;">
									<a id="rangeConfig-addRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);">add range</a>
								</div>
							<cfelse>
								<div id="rangeConfig-variableRanges">
									<div id="variableRangeConfig-2" style="display:flex;justify-content:flex-start;align-items:center;margin-bottom:0.5em;">
										<input <cfif !defaultRangeConfig.len()>disabled</cfif> name="variableRangeConfig-2.from" id="variableRangeConfig-2-from" type="number" step="0.1" class="defaultRangeConfig" style="width:4em;" required>
										&nbsp;-&nbsp;
										<input <cfif !defaultRangeConfig.len()>disabled</cfif> name="variableRangeConfig-2.to" id="variableRangeConfig-2-to" type="number" step="0.1" class="defaultRangeConfig" style="width:4em;" required>
									</div>
								</div>
								<div style="display:#defaultRangeConfig.len() LT 8 ? 'flex' : 'none'#;justify-content:flext-start;align-items:center;margin-top:0.5em;margin-bottom:0.5em;">
									<a id="rangeConfig-addRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);">add range</a>
								</div>
							</cfif>

							<div style="display:flex;justify-content:flext-start;align-items:center;margin-bottom:0.5em;">
								<input <cfif !defaultRangeConfig.len()>disabled</cfif> name="rangeConfig-andAbove.from" id="rangeConfig-andAbove-from" type="number" step="0.1" style="width:4em;" value="#defaultRangeConfig.len() ? defaultRangeConfig[defaultRangeConfig.len()].from : ''#" class="defaultRangeConfig" required>
								&nbsp;&nbsp;&nbsp;&amp;&nbsp;Above
							</div>
						</div>
						<div class="clear"></div>
					</div>

					<div id="delimeterOperatorWrapper" style="#getatt.atrexclusiveresult != 1 ? '' : 'display:none;'#">
						<div class="label">Delimiter</div>
						<div class="formel">#ui.get("text", getatt.delimiter, "delimiter", "delimiter", "", "width:3em;", "", "").element#&nbsp;</div>
						<div class="clear"></div>

						<div class="label">Operator</div>
						<div class="formel">#ui.get("text", getatt.operator, "operator", "operator", "", "width:3em;", "", "").element#&nbsp;</div>
						<div class="clear"></div>
					</div>

					<div class="rangeConfig" style="#getatt.formtype == 'Range' ? '' : 'display:none;'#">
						<div class="label">Category Specific Ranges</div>

						<div class="formel">
							<input id="categorySpecificRanges" type="checkbox" <cfif categoryRangeConfig.len()>checked</cfif>>
						</div>
						<div class="clear"></div>
						<div id="rangeConfigCategory" style="display: <cfif categoryRangeConfig.len()>block<cfelse>none</cfif>;">
							<div class="label">Category Range Config</div>
							<div class="formel">
								<div style="display:flex;justify-content:flex-start;align-items:center;margin-bottom:0.5em;margin-left:1.7em;">
									Up to&nbsp;&nbsp;&nbsp;<input <cfif !categoryRangeConfig.len()>disabled</cfif> class="categoryRangeConfig" name="rangeConfigCategory-upTo.to" id="rangeConfigCategory-upTo-to" type="number" step="0.1" style="width:4em;" value="#arrayIsDefined(categoryRangeConfig, 1) ? categoryRangeConfig[1].to : ''#" required>
								</div>
								<cfif categoryRangeConfig.len() GT 2>
									<div id="rangeConfigCategory-variableRanges">
										<cfloop array="#categoryRangeConfig#" item='item' index="i">
											<cfif i != 1 && i != categoryRangeConfig.len()>
												<div id="variableRangeConfigCategory-#i#" style="display:flex;justify-content:flex-start;align-items:center;margin-bottom:0.5em;">
													<input <cfif !categoryRangeConfig.len()>disabled</cfif> class="categoryRangeConfig" name="variableRangeConfigCategory-#i#.from" id="variableRangeConfigCategory-#i#-from" type="number" step="0.1" style="width:4em;" value="#item.from#" required>
													&nbsp;-&nbsp;
													<input <cfif !categoryRangeConfig.len()>disabled</cfif> class="categoryRangeConfig" name="variableRangeConfigCategory-#i#.to" id="variableRangeConfigCategory-#i#-to" type="number" step="0.1" style="width:4em;" value="#item.to#" required>
													<cfif i != 2>
														<a id="variableRangeConfigCategory-removeRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);margin-left:0.5em;">remove</a>
													</cfif>
												</div>
											</cfif>
										</cfloop>
									</div>
									<div style="display:#categoryRangeConfig.len() LT 8 ? 'flex' : 'none'#;justify-content:flext-start;align-items:center;margin-top:0.5em;margin-bottom:0.5em;">
										<a id="rangeConfigCategory-addRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);">add range</a>
									</div>
								<cfelse>
									<div id="rangeConfigCategory-variableRanges">
										<div id="variableRangeConfigCategory-2" style="display:flex;justify-content:flex-start;align-items:center;margin-bottom:0.5em;">
											<input <cfif !categoryRangeConfig.len()>disabled</cfif> class="categoryRangeConfig" name="variableRangeConfigCategory-2.from" id="variableRangeConfigCategory-2-from" type="number" step="0.1" style="width:4em;" required>
											&nbsp;-&nbsp;
											<input <cfif !categoryRangeConfig.len()>disabled</cfif> class="categoryRangeConfig" name="variableRangeConfigCategory-2.to" id="variableRangeConfigCategory-2-to" type="number" step="0.1" style="width:4em;" required>
										</div>
									</div>
									<div style="display:#categoryRangeConfig.len() LT 8 ? 'flex' : 'none'#;justify-content:flext-start;align-items:center;margin-top:0.5em;margin-bottom:0.5em;">
										<a id="rangeConfigCategory-addRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);">add range</a>
									</div>
								</cfif>

								<div style="display:flex;justify-content:flext-start;align-items:center;margin-bottom:0.5em;">
									<input <cfif !categoryRangeConfig.len()>disabled</cfif> class="categoryRangeConfig" name="rangeConfigCategory-andAbove.from" id="rangeConfigCategory-andAbove-from" type="number" step="0.1" style="width:4em;" value="#categoryRangeConfig.len() ? categoryRangeConfig[categoryRangeConfig.len()].from : ''#" required>
									&nbsp;&nbsp;&nbsp;&amp;&nbsp;Above
								</div>
							</div>
							<div class="clear"></div>
						</div>
					</div>

				</div>

				<div class="grouping">

					<h3>Information</h3>

					<div class="label">Description</div>
					<div class="formel"><textarea id="atrdescription" name="atrdescription" rows="3" cols="40">#getatt.atrdescription#</textarea>&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Learn More URL</div>
					<div class="formel">#ui.get("text", getatt.atrlearn, "atrlearn", "atrlearn", "", "", "", getatt.atrlearn).element#&nbsp;</div>
					<div class="clear"></div>

					<div class="label">Sizing Estimator Link</div>
					<div class="formel">#ui.get("checkbox", 1, "atrDisplayEstimator", "atrDisplayEstimator", "", "", "", getatt.atrDisplayEstimator).element#&nbsp;</div>
					<div class="clear"></div>
				</div>

			</div>

		</div>

		<div style="margin:0 auto; text-align:center;">
			<input type="hidden" name="atrID" value="#attributes.atrID#">
			<input type="hidden" name="catID" value="#getatt.categoryID#">
			<cfif attributes.atrID EQ "">
			<input type="submit" name="imdone" value="Add">
			<cfelse>
			<input id="imdone" type="submit" name="imdone" value="Update">
			<cfif session.user.id EQ 465>
			<input type="submit" name="imdone" value="Delete">
			</cfif>
			</cfif>
		</div>

		<div class="clear"></div>
		<div style="float:left;" class="tiny">ID: #attributes.atrID#</div>
	</form>

	<iframe id="imhidden" name="imhidden" style="display:none;" />
</div>
</cfoutput>

<script type="text/javascript">
	j$('#editattribute').on('change', '#categorySpecificRanges', function(e) {
		if (j$('#categorySpecificRanges').is(':checked')) {
			j$('#rangeConfigCategory').css('display', 'block');
			j$('.categoryRangeConfig').prop('disabled', false);
		} else {
			j$('#rangeConfigCategory').css('display', 'none');
			j$('.categoryRangeConfig').prop('disabled', true);
		}
	});

  	j$('#editattribute').on('change', '#formtype', function(e){
		if (e.target.value === 'Range') {
      		j$('#rangeConfig, .rangeConfig').css('display', 'block');
			j$('#exclusiveResult').css('display', 'none');
			j$('.defaultRangeConfig').removeAttr('disabled');
		} else {
			j$('#rangeConfig, .rangeConfig').css('display', 'none');
			j$('#exclusiveResult').css('display', 'block');
			j$('.defaultRangeConfig').prop('disabled', true);
		}
	});

	j$('#editattribute').on('click', '#rangeConfig-addRange, #rangeConfigCategory-addRange', function() {
		const isCatConfig = this.id === 'rangeConfigCategory-addRange';
		const catSelector = isCatConfig ? 'Category' : '';

		const lastIndex = +j$(`#rangeConfig${catSelector}-variableRanges`).children().last().attr('id').split('-')[1];
		const rowCount = j$(`#rangeConfig${catSelector}-variableRanges`).children().length;

		if (rowCount < 6) {
			j$(`#rangeConfig${catSelector}-variableRanges`).append(`
				<div id="variableRangeConfig${catSelector}-${lastIndex+1}" style="display:flex;justify-content:center;align-items:center;margin-bottom:0.5em;">
					<input ${isCatConfig ? 'class="categoryRangeConfig"' : ''} name="variableRangeConfig${catSelector}-${lastIndex+1}.from" id="variableRangeConfig${catSelector}-${lastIndex+1}-from" type="number" step="0.1" style="width:4em;" required>
					&nbsp;-&nbsp;
					<input ${isCatConfig ? 'class="categoryRangeConfig"' : ''} name="variableRangeConfig${catSelector}-${lastIndex+1}.to" id="variableRangeConfig${catSelector}-${lastIndex+1}-to" type="number" step="0.1" style="width:4em;" required>
					<a id="variableRangeConfig${catSelector}-removeRange" href="javascript:;" style="font-size:0.8em;color:rgb(51, 122, 183);margin-left:0.5em;">remove</a>
				</div>
			`);
		}

		updateAddRangeVisibility(rowCount < 5, catSelector);
	});

	j$('#editattribute').on('click', '#variableRangeConfig-removeRange, #variableRangeConfigCategory-removeRange' , function() {
		const isCatConfig = this.id === 'rangeConfigCategory-addRange';
		const catSelector = isCatConfig ? 'Category' : '';
		const rowCount = j$(`#rangeConfig${catSelector}-variableRanges`).children().length;

		if (rowCount > 1) {
			updateAddRangeVisibility(true, catSelector);
			j$(this).parent().remove();
		}
	});

	j$('#editattribute').on('click', '#imdone', function (event) {
		const categoryRangeSelected = j$('#categorySpecificRanges').is(':checked');
		const categoryRangesValid = categoryRangeSelected ? rangesAreValid(j$('#rangeConfigCategory').children('.formel').children()) : true;
		const atrId = j$(":input[name='atrID']").val();
		const strictDecimalValueFieldLookup = ['37', '725', '743', '1360', '1365', '1366'];

		if(!strictDecimalValueFieldLookup.includes(atrId) || categoryRangesValid && rangesAreValid(j$('#rangeConfig').children('.formel').children())) {
			return true;
		}

		alert('Please ensure the provided ranges are decimals (e.g 20.0) and do not have gaps or overlaps.');
		return false;
	})

	const rangesAreValid = (ranges) => { 
		var rangeMap = []
		if(!ranges[0].children[0].disabled) {
			rangeMap.push(ranges[0].children[0].value)
		}

		for (const child of (ranges[1]['children'])) {
			if(child['children'][0].disabled) {
				continue;
			}
			const isValidRangeStartInterval = Number(child['children'][0].value) === Number(rangeMap[rangeMap.length - 1]) + 0.1;
			if(isValidRangeStartInterval) {
				rangeMap.push(child['children'][0].value);
				rangeMap.push(child['children'][1].value);
			} else {
				return false;
			}
		}

		if(!ranges[3].children[0].disabled) {
			const isValidRangeEndInterval = Number(ranges[3].children[0].value) === Number(rangeMap[rangeMap.length - 1]) + 0.1;
			if(isValidRangeEndInterval) {
				rangeMap.push(ranges[3].children[0].value);
			} else {
				return false;
			}
		}

		// Check to make sure all values are decimals
		if(rangeMap.find(range => range.indexOf('.') === -1) !== undefined) {
			return false;
		}

		return true; 
	};
	const updateAddRangeVisibility = (shouldBeVisible, catSelector) => j$(`#rangeConfig${catSelector}-addRange`).parent().css('display', `${shouldBeVisible ? 'flex' : 'none'}`);
</script>
