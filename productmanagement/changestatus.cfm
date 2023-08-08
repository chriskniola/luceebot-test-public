<cfsetting enablecfoutputonly="Yes" showdebugoutput="No">
<cfparam name="attributes.productID" default="">
<cfparam name="attributes.categoryID" default="">
<cfparam name="attributes.column"> <!--- active or obsolete --->
<cfparam name="attributes.switch" default=""> <!--- not used --->


<cfinvoke component="#APPLICATION.user#" method="returnpermission" returnvariable="isadmin">
	<cfinvokeargument name="screenID" value="995">
</cfinvoke>


<cfinvoke component="#APPLICATION.user#" method="returnpermission" returnvariable="isactivator">
	<cfinvokeargument name="screenID" value="1005">
</cfinvoke>


<cfif attributes.productID IS NOT "">
		
	<cfif attributes.column IS "isapproved" AND isadmin>
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isapproved
		FROM products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		</cfquery>
		
		<cfif val(getproduct.isapproved)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Products
				SET isapproved = 0
				,prdmodified = getdate()
				,prdmodifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Product marked unapproved (mgmt tool)"/>
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Products
				SET isapproved = 1
				,isreadyforapproval = 1
				,ishidden = 0
				,prdmodified = getdate()
				,prdmodifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Product marked approved (mgmt tool)"/>
		</cfif>

		<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
		<cfset productUpdatedPublisher.publish({ 'id': attributes.productID })>
		
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isapproved
		FROM products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.isapproved)><font color="green">yes</font><cfelse><font color="red">no</font></cfif></cfoutput>
	
	<cfelseif attributes.column IS "isreadyforapproval">
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isreadyforapproval
		FROM products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		</cfquery>
		
		<cfif val(getproduct.isreadyforapproval)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Products
				SET isreadyforapproval = 0
				,prdmodifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,prdmodified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Product marked not ready for approval (mgmt tool)"/>
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Products
				SET isreadyforapproval = 1
				,ishidden = 0
				,prdmodifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,prdmodified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.productID#" value="Product marked ready for approval (mgmt tool)"/>
		</cfif>

		<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
		<cfset productUpdatedPublisher.publish({ 'id': attributes.productID })>
		
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isreadyforapproval
		FROM products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.isreadyforapproval)><font color="green">yes</font><cfelse><font color="red">no</font></cfif></cfoutput>

	<cfelseif attributes.column IS "isHidden">
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isHidden
		FROM products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		</cfquery>
		
		<cfif val(getproduct.isHidden)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Products
				SET isHidden = 0
				,prdmodifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,prdmodified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
			</cfquery>
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Products
				SET isHidden = 1
				,prdmodifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,prdmodified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
			</cfquery>
		</cfif>
		
		<cfset productUpdatedPublisher = application.wirebox.getInstance('ProductUpdatedPublisher')>
		<cfset productUpdatedPublisher.publish({ 'id': attributes.productID })>

		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isHidden
		FROM products
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.isHidden)><font color="green">unhide</font><cfelse><font color="red">hide</font></cfif></cfoutput>
	
	<cfelseif attributes.column IS "reqtype">
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT CASE 
				WHEN a.productStateID < 6 THEN 'Deactivate' 
				WHEN p.prdactivedays > 0 THEN 'Activate'
				ELSE 'Activate New'
				END AS type
		FROM Products p
		INNER JOIN tblProductStateAssociations a ON a.productID = p.ID
		WHERE p.ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.productID#">
		AND p.isreadyforapproval = 1
		</cfquery>
		
		<cfoutput>#getproduct.type#</cfoutput>
		
	<cfelseif attributes.column IS "none">
		<cfquery name="getproduct" datasource="#DSN#" dbtype="ODBC">
		SELECT TOP 1 manufacturer + ' ' + modelnumber as product
		FROM products
		WHERE ID = '#attributes.productID#'
		ORDER BY ID desc
		</cfquery>
		
		<cfoutput>#getproduct.recordcount ? getproduct.product : 'Product Not Found'#</cfoutput>

	</cfif>
</cfif>

<cfif attributes.categoryID IS NOT "">
	<cfif attributes.column IS "active" AND (isadmin OR isactivator)>
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT active
		FROM productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfif val(getproduct.active)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET active = 0,isapproved = 0,isreadyforapproval = 0
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.categoryID#" value="Category marked inactive (mgmt tool)" />	
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET active = 1,isapproved = 0,isreadyforapproval = 0,ishidden = 1
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.categoryID#" value="Category marked active (mgmt tool)" />	
		</cfif>
		
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT active
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.active)><font color="green">active</font><cfelse><font color="red">inactive</font></cfif></cfoutput>
		
	
	<cfelseif attributes.column IS "isapproved" AND (isadmin OR isactivator)>
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isapproved
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfif val(getproduct.isapproved)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET isapproved = 0
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.categoryID#" value="Category marked unapproved (mgmt tool)" />	
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET isapproved = 1,isreadyforapproval = 1
				,ishidden = 0
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.categoryID#" value="Category marked approved (mgmt tool)" />	
		</cfif>
		
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isapproved
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.isapproved)><font color="green">yes</font><cfelse><font color="red">no</font></cfif></cfoutput>
	
	<cfelseif attributes.column IS "isreadyforapproval">
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isreadyforapproval
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfif val(getproduct.isreadyforapproval)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET isreadyforapproval = 0
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.categoryID#" value="Category marked not ready for approval (mgmt tool)" />	
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET isreadyforapproval = 1
				,ishidden = 0
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
			
			<cfinvoke component="alpine-objects.objectutils" method="putlog" objID="#attributes.categoryID#" value="Category marked ready for approval (mgmt tool)" />
		</cfif>
		
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isreadyforapproval
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.isreadyforapproval)><font color="green">yes</font><cfelse><font color="red">no</font></cfif></cfoutput>
		
	<cfelseif attributes.column IS "isHidden">
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isHidden
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfif val(getproduct.isHidden)>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET isHidden = 0
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
		<cfelse>
			<cfquery name="updatestatus" dbtype="ODBC" datasource="#DSN#">
			UPDATE Productcategories
				SET isHidden = 1
				,modifiedby = <cfqueryparam cfsqltype="cf_sql_integer" value="#session.user.ID#">
				,modified = getdate()
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
			</cfquery>
		</cfif>
		
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT isHidden
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfoutput><cfif val(getproduct.isHidden)><font color="green">unhide</font><cfelse><font color="red">hide</font></cfif></cfoutput>
	
	<cfelseif attributes.column IS "reqtype">
		<cfquery name="getproduct" dbtype="ODBC" datasource="#DSN#">
		SELECT Active,isreadyforapproval
		FROM Productcategories
		WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.categoryID#">
		</cfquery>
		
		<cfif getproduct.isreadyforapproval>
			<cfoutput>#getproduct.active ? 'Deactivate' : 'Activate'#</cfoutput>
		</cfif>
	</cfif>
</cfif>

