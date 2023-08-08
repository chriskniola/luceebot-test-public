<cfset XPOserver = APPLICATION.APIKeys.XPO.serverloc>
<cfset XPOuser 	 = APPLICATION.APIKeys.XPO.username>
<cfset XPOpass 	 = APPLICATION.APIKeys.XPO.password>
<cfset XPODir  	 = APPLICATION.APIKeys.XPO.directory>
<cfset fileloc 	 = "#expandPath('/partnernet/transfers_inbound/localuser/XPOFreight')#"> 

<cfftp action = "listDir"
	port="22"
	secure="true" 
	server="#XPOserver#"
	username="#XPOuser#"
	password="#XPOpass#"
	name="filesQuery"
	directory="#XPODir#"
/>
<cfset files = filesQuery.reduce(function(arr,row){
	if(!row.isDirectory){
		arr.append(row.name);
	}
	return arr;
	},[])>

<cfloop array="#files#" index="i" item="file">
	<cfftp 
		action="getfile"
		port="22"
		server="#XPOserver#"
		username="#XPOuser#"
		password="#XPOpass#"
		timeout="2400"
		name="sshgetfile"		
		remoteFile="#XPODir#/#file#"
		localFile="#fileloc#/#file#"
	/>
	<cfftp 
		action="remove"
		port="22"
		server="#XPOserver#"
		username="#XPOuser#"
		password="#XPOpass#"
		timeout="2400"
		name="removeFile"
		item="#XPODir#/#file#"
	/>
</cfloop>

<cfscript>
	for(var file in directoryList(path=fileloc,listinfo='name',filter='*.csv')){
		if(fileExists("#fileloc#/imported/#file#")){
			fileDelete("#fileloc#/#file#");
			continue;
		}

		for(var invoice in CSVToQuery(fileRead("#fileloc#/#file#"))){
			billAlreadyImported = queryExecute("
										SELECT *
										FROM tblFreightBills
										WHERE pronumber = :proNumber AND weight = :weight AND consigneezip = :consigneeZip AND CONVERT(MONEY,amountbilled) = :totalcharge
									"
									,{    proNumber: {sqltype="VARCHAR",value=REReplace(invoice["Pro ##"],'\D','','all')}
										, weight: {sqltype="NUMERIC",value=invoice['Total Weight']}
										, consigneeZip: {sqltype="VARCHAR",value=invoice['Consignee Zip']}
										, totalcharge: {sqltype="MONEY",value=REReplace(invoice['Total Amount Due'],'[^0-9\.]','','all')}
									}
									,{datasource: DSN}).recordCount;

			if(!billAlreadyImported){
				freightbill = createObject('objects.freightbill');
				freightbill.init();
				freightbill.proNumber = reReplace(invoice["Pro ##"],'\D','','all');
				freightbill.freightCompany = 206;
				freightbill.BOLNumber = invoice['SR Value1'];
				freightbill.POID = invoice['SR Value1'];
				freightbill.PONumber = invoice['SR Value1'];
				freightbill.orderID = invoice['SR Value1'].split('-')[1];
				freightbill.pickupDatetime = invoice['Ship Date'];
				freightbill.pieces = invoice['Total Pieces'];
				freightbill.Weight = invoice['Total Weight'];
				freightbill.shippername = trim(invoice['Shipper Name 1'] & ' ' & invoice['Shipper Name 2']);
				freightbill.shipperCity = invoice['Shipper City'];
				freightbill.shipperState = invoice['Shipper State'];
				freightbill.shipperzip = invoice['Shipper Zip'];
				freightbill.consigneename = trim(invoice['Consignee Name 1'] & ' ' & invoice['Consignee Name 2']);
				freightbill.consigneeCity = invoice['Consignee City'];
				freightbill.consigneeState = invoice['Consignee State'];
				freightbill.consigneeZip = invoice['Consignee Zip'];
				freightbill.amountBilled = REReplace(invoice['Total Amount Due'],'[^0-9\.]','','all');
				freightbill.NetCharge = freightbill.amountBilled;
				freightbill.terms = invoice['FRT Terms'];

				for(var i=1; i<=5; i++){
					if(lenTrim(invoice['Acc Code#i#'])){
						freightbill.insertAccessorial(code=invoice['Acc Code#i#'], cost=REReplace(invoice['Acc Charge#i#'],'[^0-9\.]','','all'));
					}
				}

				freightbill.estweight = queryExecute("
						SELECT ISNULL(SUM(vp.weight * vap.Quantity * o.quantity),0) AS 'estWeight'
						FROM checkouts c
						INNER JOIN orders o ON o.sessionID = c.sessionID
						INNER JOIN InventoryItemLink vap ON o.productnumber = vap.productID
						INNER JOIN InventoryItems vp ON vp.ID = vap.InventoryItemID
						WHERE c.sessionID = :orderID
					"
					,{orderID: {sqltype='VARCHAR', value=freightbill.orderID}}
					,{datasource: DSN}).estWeight;

				freightbill.put();
			}								
		}
		file action="move" source="#fileloc#/#file#" destination="imported" nameconflict="MAKEUNIQUE";
	}
</cfscript>
