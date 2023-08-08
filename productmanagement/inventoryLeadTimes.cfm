<cfset screenid = "1090">

<cfinclude template="/partnernet/shared/_header.cfm">

<link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">
<link href="https://gitcdn.github.io/bootstrap-toggle/2.2.0/css/bootstrap-toggle.min.css" rel="stylesheet">
<link href="https://cdn.datatables.net/1.10.10/css/jquery.dataTables.min.css" rel="stylesheet">

<script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
<script src="https://gitcdn.github.io/bootstrap-toggle/2.2.0/js/bootstrap-toggle.min.js"></script>
<script src="https://cdn.datatables.net/1.10.10/js/jquery.dataTables.min.js"></script>

<style>
	input[type=number] { width: 50px; }
	.alert { display: none; }
	.clearfix { margin-top: 10px; }
	table.dataTable thead td { padding: 10px; }
	.inactive { font-style: italic; color: #b8b8b8; }
	table.dataTable th:nth-child(3), table.dataTable td:nth-child(n+4) { width: 50px !important; }
	table.dataTable th:nth-child(4), table.dataTable td:nth-child(n+4) { width: 10px !important; }
	label { font-size: inherit; font-weight: 400; }
	.panel { min-width: 400px; }
	.clearfix { margin-top: 0; height: 63px; }
	.form-submit { margin-top: 10px; }
</style>
<script>
	var j$ = jQuery.noConflict();

	j$(function() {
		initDataTables();

		j$('#template').on('change','input[type="number"]', function() {
			var ids = j$('#ids').val();
			ids = ids.split(',');
			if(!ids.length) ids = [];

			var currentValue = j$(this).val();
			var defaultValue = j$(this).prop('defaultValue');
			var id = j$(this).data('id');

			var changed = currentValue != defaultValue;
			var changedCount = j$('input[data-id="' + id +'"].changed').length;
			if(changed) {
				if(changedCount == 0) {
					ids.push(id);
					j$('#ids').val(ids.join(','));
				}
				j$('input[data-id="' + id +'"]').addClass('changed');
			} else {
				j$(this).removeClass('changed');
			}
			changedCount = j$('input[data-id="' + id +'"].changed').length;
				if(changedCount == 1) {
					var index = ids.indexOf(id);
					ids.splice(index,1);
					j$('#ids').val(ids.join(','));
					j$('input[data-id="' + id +'"]').removeClass('changed');
				}
		});

		j$('.form-submit').click(function() {
			submitForm();
		});
	});

	/* Create an array with the values of all the input boxes in a column, parsed as numbers */
	j$.fn.dataTable.ext.order['dom-text-numeric'] = function  ( settings, col )
	{
	    return this.api().column( col, {order:'index'} ).nodes().map( function ( td, i ) {
	        return j$('input', td).val() * 1;
	    } );
	}

	function initDataTables() {
		j$('.data-table').DataTable({
			"columns": [
	            null,
	            { "orderDataType": "dom-text-numeric" },
	            { "orderable" : false}
	        ],
	        columnDefs: [ {
            targets: [ 0 ],
            orderData: [ 0, 0 ]
	        }]
		});
	}

	function submitForm() {
		var table = j$('.data-table').DataTable();
		var avgLeadTimeEmpty = j$('input.avgLeadTime.changed').filter(function() {return !j$(this).val();}).length;
		if(avgLeadTimeEmpty) {
			j$('#notification').removeClass('alert-success').addClass('alert-warning').text('The maximum date field is obligatory!').slideDown().delay(3000).slideUp();
			return false;
		}
		var nochanges = j$('input.changed').length;
		if(!nochanges) {
			j$('#notification').removeClass(function(index,css) {return (css.match  (/(^|\s)alert-\S+/g) || []).join(' ');}).addClass('alert-warning').text('You haven\'t made any changes!').slideDown().delay(3000).slideUp();
			return false;
		}
		var data = table.$('input.changed').serialize();
		data += '&' + j$('.default').find('input.changed').serialize();
		data += '&ids=' + j$('input#ids').val();
		var url = '/alpine-objects/inventoryLeadTimes.cfc?method=setLeadTimes';
		j$('.form-submit').addClass('disabled');
		j$.post(url, data, function(data) {
			if(data == 'true') {
				j$('#ids').val('');
				j$('#notification').removeClass(function(index,css) {return (css.match  (/(^|\s)alert-\S+/g) || []).join(' ');}).addClass('alert-success').text('Success!').slideDown().delay(3000).slideUp();
				j$('#template').fadeOut().load('/partnernet/productmanagement/_inventoryLeadTimes.cfm',function() {
					initDataTables();
				}).fadeIn();
			} else {
				j$('#notification').removeClass(function(index,css) {return (css.match  (/(^|\s)alert-\S+/g) || []).join(' ');}).addClass('alert-danger').text('Error!').slideDown().delay(3000).slideUp();
			}
			j$('.form-submit').removeClass('disabled');
		});
		return false;
	}
</script>

<div class="container">
	<div class="row">
		<div class="col-lg-12">
			<div class="panel panel-default">
				<div class="panel-heading">
					Inventory Lead Times
				</div>
				<div class="panel-body">
					<div class="clearfix">
						<div class="alert" id="notification"></div>
					</div>
					<form role="form">
						<input type="hidden" id="ids" value="" name="ids" />
						<div class="form-group">
							<div id="template">
								<cfinclude template="/partnernet/productmanagement/_inventoryLeadTimes.cfm" />
							</div>
							<div class="clearfix">
								<div class="btn btn-primary pull-right form-submit">Submit</div>
							</div>
						</div>
					</form>
					<p class="text-muted"><i class="fa fa-info-circle"></i> <em>To remove the lead times for a manufacturer, type 0 in the maximum date field.</em></p>
				</div>
			</div>
		</div>
	</div>
</div>

<cfinclude template="/partnernet/shared/_footer.cfm">
