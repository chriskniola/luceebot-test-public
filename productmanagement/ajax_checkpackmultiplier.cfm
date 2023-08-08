<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfparam name="attributes.vendorID" default="">
<cfparam name="attributes.productID">
<cfparam name="attributes.retailpackquantity" default="">
<cfparam name="attributes.packmultiplier" default="">
<cfparam name="attributes.vendorpackquantity" default="">

<cfobject component="alpine-objects.product" name="product">
<cfinvoke component="#product#" method="get" objID="#attributes.productID#"></cfinvoke>
<cfinvoke component="#product#" method="checkpackmultiplier" returnvariable="checkvendor" vendorID="#attributes.vendorID#" retailpackquantity="#attributes.retailpackquantity#" packmultiplier="#attributes.packmultiplier#" vendorpackquantity="#attributes.vendorpackquantity#"></cfinvoke>

<cfoutput>
	<cfif checkvendor.errorcode EQ 1>
		<div class="alertbox">Retail pack quantity conflicts with vendor pack multipliers.<br>Product will be deactivated unless this is corrected.</div>
	<cfelse>
		<div class="successbox">Retail pack quantity is okay.</div>
	</cfif>
</cfoutput>