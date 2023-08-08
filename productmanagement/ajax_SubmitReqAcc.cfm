<cfsetting showdebugoutput="false" enablecfoutputonly="true">

<!--- Params from Jquery --->
<cfscript> 
	param check = ""; 
	param product = ""; 
	param addon = "";
	param popup = "";
</cfscript>

<!--- Going to put my query here! --->
<cfif len(product) > 0>
	<cfquery name="updateReqAcc" datasource="#DSN#">
		--Set all product required to 0
		UPDATE tblProductAssociations SET accRequired = 0, isAddOn = 0, isPopUp = 0  WHERE prdID = <cfqueryPARAM value="#product#" CFSQLType='cf_sql_integer'/>
	</cfquery>

	<cfif len(check) > 0>
		<cfquery name="updateReqAcc" datasource="#DSN#">
			-- Set accReq to 1 Where checked
			UPDATE tblProductAssociations SET accRequired = 1  WHERE prdID = <cfqueryPARAM value="#product#" CFSQLType='cf_sql_integer'/> AND prdRelative IN(<cfqueryPARAM value="#check#" CFSQLType='CF_SQL_INTEGER' list="yes"/>)
		</cfquery>
	</cfif>

	<cfif len(addon) > 0>
		<cfquery name="updateReqAcc" datasource="#DSN#">
			-- Set isAddOn to 1 Where checked
			UPDATE tblProductAssociations SET isAddOn = 1  WHERE prdID = <cfqueryPARAM value="#product#" CFSQLType='cf_sql_integer'/> AND prdRelative IN(<cfqueryPARAM value="#addon#" CFSQLType='CF_SQL_INTEGER' list="yes"/>)
		</cfquery>
	</cfif>

	<cfif len(popup) > 0>
		<cfquery name="updateReqAcc" datasource="#DSN#">
		-- Set isPopUp to 1 Where checked
			UPDATE tblProductAssociations SET isPopUp = 1  WHERE prdID = <cfqueryPARAM value="#product#" CFSQLType='cf_sql_integer'/> AND prdRelative IN(<cfqueryPARAM value="#popup#" CFSQLType='CF_SQL_INTEGER' list="yes"/>)
		</cfquery>
	</cfif>
</cfif>


<cfscript>	
	writeOutput("Sean you gave me this data: Product: #product# requires these: #check# ty!");
</cfscript>


