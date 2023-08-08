<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfparam name="url.categoryIDs" default="67">
<cfparam name="url.productIDs" default="">
<cfparam name="url.resourceIDs" default="">

<cfquery name="data" datasource="ahapdb" returnType="array">
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@categoryIDs varchar(1500) = <cfqueryparam sqltype="VARCHAR" value="#url.categoryIDs#">,
		@productIDs varchar(1500) = <cfqueryparam sqltype="VARCHAR" value="#url.productIDs#">,
		@resourceIDs varchar(1500) = <cfqueryparam sqltype="VARCHAR" value="#url.resourceIDs#">

	DECLARE @tmp TABLE (categoryID smallint)
	INSERT INTO @tmp
		SELECT [value]
		FROM STRING_SPLIT(@categoryIDs,',')
		UNION
		SELECT p.category
		FROM products p
		INNER JOIN STRING_SPLIT(@productIDs,',') ids ON p.id = ids.[value]
		-- UNION
		-- SELECT p.category
		-- FROM products p
		-- INNER JOIN tblProductResources pr ON pr.prdID = p.ID
		-- INNER JOIN STRING_SPLIT(@resourceIDs,',') ids ON pr.resourceID = ids.[value]
			
		-- UNION 
		-- SELECT cr.categoryID
		-- FROM tblproductcategoryresources cr
		-- INNER JOIN STRING_SPLIT(@resourceIDs,',') ids ON cr.resourceID = ids.[value]

	DECLARE @tmpcat TABLE (categoryID SMALLINT, parentID SMALLINT, parentlevel SMALLINT, [name] VARCHAR(75), active SMALLINT)
	INSERT INTO @tmpcat
		SELECT h.categoryID, h.parent, MAX(h2.parentlevel)+1, [name], pc.active
		FROM @tmp c
		INNER JOIN productcategories_parentshierarchy h ON h.parent = c.categoryID
		INNER JOIN productcategories pc ON h.categoryID = pc.ID
		INNER JOIN productcategories_parentshierarchy h2 ON h.categoryID = h2.categoryID
		GROUP BY h.categoryID,h.parent,[name],pc.active
		UNION
		SELECT h.parent, pc.parent, parentlevel, [name], pc.active
		FROM @tmp c
		INNER JOIN productcategories_parentshierarchy h ON h.categoryID = c.categoryID
		INNER JOIN productcategories pc ON h.parent = pc.ID

	DECLARE @final TABLE (categoryID SMALLINT, parent SMALLINT, parentlevel SMALLINT, [name] VARCHAR(75), active SMALLINT)
	INSERT INTO @final
		SELECT pc.ID, pc.parent, ISNULL((SELECT MAX(parentlevel) FROM @tmpcat WHERE categoryID = pc.ID),0)+1, pc.[name], pc.active
		FROM @tmp c
		INNER JOIN productcategories pc ON pc.ID = c.categoryID
			AND pc.parent = 0
		UNION
		SELECT t.categoryID, t.parentID, parentlevel, [name], active
		FROM @tmpcat t
		UNION
		SELECT pc.ID, pc.parent, ISNULL((SELECT MAX(parentlevel) FROM @tmpcat WHERE categoryID = pc.parent),0)+1, pc.[name], pc.active
		FROM @tmp c
		INNER JOIN productcategories pc ON pc.ID = c.categoryID
			AND pc.parent <> 0

	SELECT 
		c.categoryID,
		c.parent,
		c.parentlevel,
		c.[name],
		c.active,
		'[' + ISNULL((
			SELECT STRING_AGG(r.resourceID,',') 
			FROM tblProductCategoryResources r 
			INNER JOIN STRING_SPLIT(@resourceIDs,',') ids ON r.resourceID = ids.[value] 
			WHERE c.categoryID = r.categoryID
		),'') + ']' AS 'resources',
		ISNULL((
			SELECT 
				p.manufacturer + ' ' + p.modelnumber AS 'name', 
				p.ID, 
				p.active,
				'[' + ISNULL((
					SELECT STRING_AGG(r.resourceID,',') 
					FROM tblProductResources r 
					INNER JOIN STRING_SPLIT(@resourceIDs,',') ids ON r.resourceID = ids.[value] 
					WHERE r.prdID = p.ID
				),'') + ']' AS 'resources'
			FROM products p
			WHERE p.Category = c.categoryID				
			FOR JSON PATH
		),'[]') AS 'products'
	FROM @final c
	ORDER BY c.parentlevel, c.parent, c.[name]
</cfquery>


<cfscript>
	function getChildrenArray(array data, numeric parent) {
		var result = [];
		var parent = arguments.parent;

		for(var child in arguments.data.filter((e) => arguments.e.parent == parent)) {
			result.append({
				'n': child.name,
				'i': child.categoryID,
				't': 'c',
				'r': deserializeJSON(child.resources),
				'a': child.active,
				'c': getChildrenArray(arguments.data, child.categoryID).merge(formatProductArray(child.products))
			});
		}
		return result;
	}

	function formatProductArray(products) {
		var products = deserializeJSON(arguments.products);

		return products.map(function(e) {
			return {
				'n': arguments.e.name,
				'i': arguments.e.ID,
				't': 'p',
				'r': deserializeJSON(arguments.e.resources),
				'a': arguments.e.active,
				'c': []
			};
		});
	}
</cfscript>

<cfoutput>#serializeJSON(getChildrenArray(data,0))#</cfoutput>
