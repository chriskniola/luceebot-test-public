<cfsetting showdebugoutput="false" enablecfoutputonly="true">
<cfparam name="attributes.criteria" default=""> <!--- productID, categoryID --->
<cfparam name="attributes.type" default=""> <!--- product, category, closelymatched --->

<!---
n: Name
i: ID
g: Group
s: Sortable
c: Comparable
v: Possible Values

prdAtrValue,atrID,atrName,atrPossibleValues,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,atrPriority,atrDescription,atrDescriptionImage,atrDisplayonSite,operator

--->

<cfset listattributes = Querynew("prdAtrValue,prdAtrID")>

<cfif attributes.type EQ "category">
	<cfstoredproc procedure="sp_getAttribute_names_values_by_product" datasource="#DSN#">
	<!--- this is the query that gets all the names and values for attributes with this product id or category id --->
		<cfprocparam type="IN" sqltype="INT" value="0">
		<cfprocparam type="IN" sqltype="INT" value="#attributes.criteria#">
		<cfprocparam type="IN" sqltype="INT" value="0">
		<cfprocresult name="ListAttributes">
	</cfstoredproc>
	
	<!--- cfdump var="#listattributes#"--->
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT prdAtrValue,prdatrID
		FROM tblProductAttributes
		WHERE prdatrID IN (<cfqueryparam sqltype="INT" list=true value="#valuelist(listattributes.atrID)#">)
		</cfquery>
	</cfif>
	
	<cfoutput>[<cfloop query="listattributes"><cfif listattributes.currentrow GT 1>,</cfif>{n:'#atrName#<cfif atrUnits NEQ ""> (#atrUnits#)</cfif>',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',f:'#formtype#',v:[<cfquery name="thisattribute" dbtype="query">SELECT prdAtrValue FROM getattributevalues WHERE prdatrID = #atrID#</cfquery><cfloop query="thisattribute"><cfif thisattribute.currentrow GT 1>,</cfif>'#prdatrValue#'</cfloop>],cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}</cfloop>]</cfoutput>

<cfelseif attributes.type EQ "product">
	<cfstoredproc procedure="sp_getAttribute_names_values_by_product" datasource="#DSN#">
	<!--- this is the query that gets all the names and values for attributes with this product id or category id --->
		<cfprocparam type="IN" sqltype="INT" value="#attributes.criteria#">
		<cfprocparam type="IN" sqltype="INT" value="0">
		<cfprocparam type="IN" sqltype="INT" value="0">
		<cfprocresult name="ListAttributes">
	</cfstoredproc>
	
	<!--- <cfdump var="#listattributes#"> --->
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT prdAtrValue,prdatrID
		FROM tblProductAttributes
		WHERE prdatrID IN (<cfqueryparam sqltype="INT" list=true value="#valuelist(listattributes.atrID)#">)
		ORDER BY prdAtrValue
		</cfquery>
	</cfif>
	
	<cfoutput>[<cfloop query="listattributes"><cfif listattributes.currentrow GT 1>,</cfif>{n:'#atrName#<cfif atrUnits NEQ ""> (#atrUnits#)</cfif>',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',f:'#formtype#',v:[<cfquery name="thisattribute" dbtype="query">SELECT prdAtrValue FROM getattributevalues WHERE prdatrID = #atrID#</cfquery><cfloop query="thisattribute"><cfif thisattribute.currentrow GT 1>,</cfif>'#prdatrValue#'</cfloop>],d: '#ListAttributes.prdatrValue#',cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}</cfloop>]</cfoutput>

<cfelseif attributes.type EQ "closelymatched">
	<cfquery name="listattributes" datasource="#DSN#">
	DECLARE @productID int
	SELECT @productID = <cfqueryparam sqltype="INT" value="#attributes.criteria#">
	
	SELECT atrID,atrName,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,formtype,atrconvertdecimal,atrminmaxrange
	FROM tblProductAttributes pa INNER JOIN tblAttributes a ON a.atrID = pa.prdAtrID
	WHERE prdID IN (SELECT ID FROM products WHERE category = (SELECT TOP 1 category FROM products WHERE ID = @productID) OR category = @productID) OR pa.prdID = @productID
	GROUP BY atrID,atrName,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,formtype,atrconvertdecimal,atrminmaxrange
	</cfquery>
	
	<!--- <cfdump var="#listattributes#"> --->
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT prdAtrValue,prdatrID
		FROM tblProductAttributes
		WHERE prdatrID IN (<cfqueryparam sqltype="INT" list=true value="#valuelist(listattributes.atrID)#">)
		ORDER BY prdAtrValue
		</cfquery>
	</cfif>
	
	<cfoutput>[<cfloop query="listattributes"><cfif listattributes.currentrow GT 1>,</cfif>{n:'#atrName#<cfif atrUnits NEQ ""> (#atrUnits#)</cfif>',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',f:'#formtype#',v:[<cfquery name="thisattribute" dbtype="query">SELECT prdAtrValue FROM getattributevalues WHERE prdatrID = #atrID#</cfquery><cfloop query="thisattribute"><cfif thisattribute.currentrow GT 1>,</cfif>'#prdatrValue#'</cfloop>],cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}</cfloop>]</cfoutput>

<cfelseif attributes.type EQ "attribute">
	<cfquery name="ListAttributes" datasource="#DSN#">
	SELECT atrID,atrName,atrPossibleValues,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,atrPriority,atrDescription,atrDescriptionImage,atrDisplayonSite,operator,formtype,atrconvertdecimal,atrminmaxrange
	FROM tblAttributes
	WHERE atrID = <cfqueryparam sqltype="INT" value="#val(attributes.criteria)#">
	</cfquery>
	
	<!--- <cfdump var="#listattributes#"> --->
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT prdAtrValue,prdatrID
		FROM tblProductAttributes
		WHERE prdAtrID = <cfqueryparam sqltype="INT" value="#val(attributes.criteria)#">
		</cfquery>
	</cfif>
	
	<cfoutput query="ListAttributes">{n:'#atrName#<cfif atrUnits NEQ ""> (#atrUnits#)</cfif>',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',f:'#formtype#',v:[<cfloop query="getattributevalues"><cfif getattributevalues.currentrow GT 1>,</cfif>'#prdatrValue#'</cfloop>],cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}</cfoutput>


<cfelseif attributes.type EQ "attribute2">
	<cfquery name="ListAttributes" datasource="#DSN#">
	SELECT atrID,atrName,atrPossibleValues,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,atrPriority,atrDescription,atrDescriptionImage,atrDisplayonSite,operator,formtype,atrconvertdecimal,atrminmaxrange
	FROM tblAttributes
	WHERE atrName = <cfqueryparam sqltype="VARCHAR" value="#attributes.criteria#">
	</cfquery>
	
	<!--- <cfdump var="#listattributes#"> --->
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT prdAtrValue,prdatrID
		FROM tblProductAttributes
		WHERE ID = <cfqueryparam sqltype="INT" value="#val(attributes.criteria)#">
		</cfquery>
	</cfif>
	
	<cfoutput>[<cfloop query="ListAttributes">{n:'#atrName#',u:'#atrUnits#',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',f:'#formtype#',v:[<cfloop query="getattributevalues"><cfif thisattribute.currentrow GT 1>,</cfif>'#prdatrValue#'</cfloop>],cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}<cfif listattributes.recordcount GT 0 AND listattributes.currentrow NEQ listattributes.recordcount>,</cfif></cfloop>]</cfoutput>

<cfelseif attributes.type EQ "categoryattr">
	<cfstoredproc procedure="sp_getAttribute_names_values_by_category" datasource="#DSN#">
	<!--- this is the query that gets all the names of attributes associated to this category id --->
	<cfprocparam type="IN" sqltype="INT" value="#attributes.criteria#">
	<cfprocresult name="ListAttributes">
	</cfstoredproc>
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT catAtrID
		FROM tblCategoryAttributes
		WHERE catAtrID IN (<cfqueryparam sqltype="INT" list=true value="#valuelist(listattributes.atrID)#">)
		</cfquery>
	</cfif>
	
	<cfoutput>[<cfloop query="listattributes"><cfif listattributes.currentrow GT 1>,</cfif>{n:'#atrName#<cfif atrUnits NEQ ""> (#atrUnits#)</cfif>',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',v:'',cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}</cfloop>]</cfoutput>
	
<cfelseif attributes.criteria IS NOT "">
	<cfquery name="ListAttributes" datasource="#DSN#">
	DECLARE @temp TABLE (atrID int,atrName varchar(150),atrPossibleValues varchar(500),atrSortable bit, atrComparable bit, atrPhotoID int, atrUnits varchar(50), atrGroup varchar(50), atrPriority int, atrDescription varchar(max), atrDescriptionImage varchar(255), atrDisplayonSite bit, operator varchar(50), formtype varchar(25), atrConvertDecimal bit, atrMinMaxRange bit)
	
	INSERT INTO @temp
	SELECT atrID,atrName,atrPossibleValues,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,atrPriority,atrDescription,atrDescriptionImage,atrDisplayonSite,operator,formtype,atrconvertdecimal,atrminmaxrange
	FROM tblProductAttributes WITH (NOLOCK) RIGHT JOIN tblAttributes WITH (NOLOCK) ON tblProductAttributes.prdAtrID = tblAttributes.AtrID
	WHERE 0=1
		<cfloop list="#attributes.criteria#" index="i" delimiters=" ">
			OR atrName LIKE <cfqueryparam sqltype="VARCHAR" value="%#i#%">
		</cfloop>
	
	GROUP BY atrID,atrName,atrPossibleValues,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,atrPriority,atrDescription,atrDescriptionImage,atrDisplayonSite,operator,formtype,atrconvertdecimal,atrminmaxrange
	--ORDER BY tblAttributes.atrName,tblAttributes.AtrPriority
	
	SELECT atrID,atrName,atrPossibleValues,atrSortable,atrComparable,atrPhotoID,atrUnits,atrGroup,atrPriority,atrDescription,atrDescriptionImage,atrDisplayonSite,operator,formtype, atrconvertdecimal,atrminmaxrange
		,0.0
			<cfloop list="#attributes.criteria#" index="i" delimiters=" ">
				+ CASE WHEN atrName LIKE <cfqueryparam sqltype="VARCHAR" value="%#i#%"> THEN 1 ELSE 0 END
			</cfloop>
			
			<cfif listlen(attributes.criteria," ") GT 1>
				<cfloop index="i" from="1" to="#listlen(attributes.criteria,' ')#">
					<cfif i+1 LTE listlen(attributes.criteria,' ')>
						+ CASE WHEN CHARINDEX (<cfqueryparam sqltype="VARCHAR" value="#listgetat(attributes.criteria,i,' ')#">,atrName) <  CHARINDEX(<cfqueryparam sqltype="VARCHAR" value="#listgetat(attributes.criteria,i+1,' ')#">,atrName) THEN 0.5 ELSE 0 END
					</cfif>
				</cfloop>
			</cfif>
			as score
	FROM @temp
	ORDER BY score desc
	</cfquery>
	
	<!--- <cfdump var="#listattributes#"> --->
	
	<cfif listattributes.recordcount GT 0>
		<cfquery name="getattributevalues" datasource="#DSN#">
		SELECT DISTINCT prdAtrValue,prdatrID
		FROM tblProductAttributes
		WHERE prdatrID IN (<cfqueryparam sqltype="INT" list=true value="#valuelist(listattributes.atrID)#">)
		</cfquery>
	</cfif>
	
	<cfoutput>[<cfloop query="listattributes"><cfif listattributes.currentrow GT 1>,</cfif>{n:'#atrName#<cfif atrUnits NEQ ""> (#atrUnits#)</cfif>',i:'#atrID#',g:'#atrGroup#',s:'#atrSortable#',c:'#atrComparable#',p:'#atrPhotoID#',f:'#formtype#',v:[<cfquery name="thisattribute" dbtype="query">SELECT prdAtrValue FROM getattributevalues WHERE prdatrID = #atrID#</cfquery><cfloop query="thisattribute"><cfif thisattribute.currentrow GT 1>,</cfif>'#prdatrValue#'</cfloop>],cd:'#atrconvertdecimal#',mm:'#atrminmaxrange#'}</cfloop>]</cfoutput>
	
</cfif>

<!--- 
<cfif attributes.criteria EQ 'last7days'>
<cfoutput>[{n:'Height',i:'1',g:'group',s:'0',c:'0',v:['58inch','60inches','64inches']},{n:'Width',i:'2',g:'group',s:'0',c:'0',v:['58inch','60inches','64inches']},{n:'Length',i:'3',g:'group',s:'0',c:'0',v:['58inch','60inches','64inches']}]</cfoutput>
<cfelse>
<cfoutput>[{n:'Height',i:'1',g:'group',s:'0',c:'0',v:['58inch','60inches','64inches']},{n:'Width',i:'2',g:'group',s:'0',c:'0',v:['58inch','60inches','64inches']},{n:'Length',i:'3',g:'group',s:'0',c:'0',v:['58inch','60inches','64inches']},{n:'Height2', i:'4',g:'group2',s:'1',c:'1', v:['58inch','60inches','64inches']},{n:'Width2',i:'5',g:'group'2,s:'1',c:'1',v:['58inch','60inches','64inches']},{n:'Length2',i:'6',g:'group2',s:'1',c:'1',v:['58inch','60inches','64inches']}]</cfoutput>
</cfif>


 --->
