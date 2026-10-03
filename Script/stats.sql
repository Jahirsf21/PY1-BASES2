/*
    Resume los montos de las líneas de órdenes de compra por proveedor y categoría,
    aplicando filtros opcionales por nombre y categoría. Incluye un resumen general.
    Devuelve: NombreProveedor, NombreCategoriaProveedor, MontoMaximo, MontoMinimo, MontoPromedio
*/
create or alter procedure Purchasing.GetSupplierPurchaseSummary
    @SupplierName nvarchar(100) = null,
    @SupplierCategoryID int = null
as
	begin
		set nocount on
		select
			isnull(sp.SupplierName, 'Resumen') as NombreProveedor,
			isnull(sg.SupplierCategoryName, ' ') as NombreCategoriaProveedor,
			max(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) as MontoMaximo,
			min(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) as MontoMinimo,
			avg(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) as MontoPromedio
		from PurchaseOrders po
		inner join PurchaseOrderLines pol on po.PurchaseOrderID = pol.PurchaseOrderID
		inner join Suppliers sp on po.SupplierID = sp.SupplierID
		inner join SupplierCategories sg on sp.SupplierCategoryID = sg.SupplierCategoryID
		where
            (@SupplierName is null or sp.SupplierName like '%' + @SupplierName + '%')
            and (@SupplierCategoryID is null or sp.SupplierCategoryID = @SupplierCategoryID)
		group by rollup ((sp.SupplierName, sg.SupplierCategoryName))
	end
go

/*
    Resume los montos de las facturas por cliente y categoría, aplicando filtros
    opcionales por nombre y categoría. Incluye un resumen general y pagina los resultados;
    @TotalCount devuelve la cantidad de clientes más la fila de resumen.
    Devuelve: NombreCliente, NombreCategoriaCliente, MontoMaximo, MontoMinimo, MontoPromedio
*/
create or alter procedure Sales.GetCustomerSalesSummary
	@CustomerName nvarchar(100) = null,
	@CustomerCategoryID int = null,
	@PageNumber int = 1,
	@PageSize int = 10,
	@TotalCount int = 0 output
as
	begin
		set nocount on
		select @TotalCount = count(*) + 1
		from Customers cs
		where (@CustomerName is null or cs.CustomerName like '%' + @CustomerName + '%')
			and (@CustomerCategoryID is null or cs.CustomerCategoryID = @CustomerCategoryID)
			and exists (select 1 from Invoices iv where iv.CustomerID = cs.CustomerID)
		select
			isnull(cs.CustomerName, 'Resumen') as NombreCliente,
			isnull(cg.CustomerCategoryName, ' ') as NombreCategoriaCliente,
			max(t.MontoFacturado) as MontoMaximo,
			min(t.MontoFacturado) as MontoMinimo,
			avg(t.MontoFacturado) as MontoPromedio
		from (
			select
				ivl.InvoiceID,
				sum(ivl.ExtendedPrice) as MontoFacturado
			from InvoiceLines ivl
			group by ivl.InvoiceID
		) t
		inner join Invoices iv on t.InvoiceID = iv.InvoiceID
		inner join Customers cs on iv.CustomerID = cs.CustomerID
		inner join CustomerCategories cg on cs.CustomerCategoryID = cg.CustomerCategoryID
		where (@CustomerName is null or cs.CustomerName like '%' + @CustomerName + '%')
			and (@CustomerCategoryID is null or cg.CustomerCategoryID = @CustomerCategoryID)
		group by rollup ((cs.CustomerName, cg.CustomerCategoryName))
		order by grouping(cs.CustomerName), cs.CustomerName
		offset (@PageNumber - 1) * @PageSize rows
		fetch next @PageSize rows only
	end
go

/*
    Devuelve los productos con los cinco primeros puestos por ganancia acumulada de cada año.
    Permite filtrar por un año específico (@Year).
    Devuelve: Año, NombreProducto, Ganancia, Ranking
*/
create or alter procedure Warehouse.GetTopProductsByYear
    @Year int = null
as
    begin
        with Profits as (
            select  
                year(iv.InvoiceDate) as Año,
                s.StockItemName as NombreProducto,
                sum(ivl.LineProfit) as Ganancia,
                dense_rank() over(partition by year(iv.InvoiceDate) order by sum(ivl.LineProfit) desc) as Ranking
            from InvoiceLines ivl
            inner join Invoices iv on ivl.InvoiceID = iv.InvoiceID
            inner join StockItems s on ivl.StockItemID = s.StockItemID
            where year(iv.InvoiceDate) = isnull(@Year, year(iv.InvoiceDate))
            group by year(iv.InvoiceDate), s.StockItemID, s.StockItemName
        )
        select
            Año,
            NombreProducto,
            Ganancia,
            Ranking
        from Profits
        where Ranking <= 5
        order by Año, Ranking
    end
go

/*
    Devuelve hasta los cinco clientes con más facturas por año dentro del rango indicado.
    Valida que los años existan y que el año inicial no sea posterior al final; los empates
    en el quinto puesto también se incluyen.
    Devuelve: Año, NombreCliente, CantidadFacturas, MontoFacturado, Ranking
*/
create or alter procedure Sales.GetTopCustomersByYear
    @InvoiceYearFrom int = null,
    @InvoiceYearTo int = null
as
    begin
        if @InvoiceYearFrom is not null and not exists (select 1 from Invoices where year(InvoiceDate) = @InvoiceYearFrom)
            throw 50001, 'El año inicial indicado no existe en la base de datos.', 1;
        if @InvoiceYearTo is not null and not exists (select 1 from Invoices where year(InvoiceDate) = @InvoiceYearTo)
            throw 50002, 'El año final indicado no existe en la base de datos.', 1;
        if @InvoiceYearFrom is not null and @InvoiceYearTo is not null and @InvoiceYearFrom > @InvoiceYearTo
            throw 50003, 'El año inicial no puede ser mayor que el año final.', 1;
        with TopCustomers as (
            select
                year(iv.InvoiceDate) as Año,
                cs.CustomerName as NombreCliente,
                count(distinct iv.InvoiceID) as CantidadFacturas,
                sum(ivl.ExtendedPrice) as MontoFacturado,
                dense_rank() over (partition by year(iv.InvoiceDate) order by count(distinct iv.InvoiceID) desc) as Ranking
            from Invoices iv
            inner join Customers cs on iv.CustomerID = cs.CustomerID
            inner join InvoiceLines ivl on iv.InvoiceID = ivl.InvoiceID
            where 
                (@InvoiceYearFrom is null or year(iv.InvoiceDate) >= @InvoiceYearFrom)
                and (@InvoiceYearTo is null or year(iv.InvoiceDate) <= @InvoiceYearTo)
            group by year(iv.InvoiceDate), cs.CustomerID, cs.CustomerName
        )
        select
            Año,
            NombreCliente,
            CantidadFacturas,
            MontoFacturado,
            Ranking
        from TopCustomers
        where Ranking <= 5
        order by Año, Ranking
    end 
go

/*
    Devuelve hasta los cinco proveedores con más órdenes de compra por año dentro del rango
    indicado. Valida que los años existan y que el inicial no sea posterior al final; los
    empates en el quinto puesto también se incluyen.
    Devuelve: Año, NombreProveedor, CantidadCompras, MontoComprado, Ranking
*/
create or alter procedure Purchasing.GetTopSuppliersByYear
    @OrderYearFrom int = null,
    @OrderYearTo int = null
as
    begin
        if @OrderYearFrom is not null and not exists (select 1 from PurchaseOrders where year(OrderDate) = @OrderYearFrom)
            throw 50001, 'El año inicial indicado no existe en la base de datos.', 1;
        if @OrderYearTo is not null and not exists (select 1 from PurchaseOrders where year(OrderDate) = @OrderYearTo)
            throw 50002, 'El año final indicado no existe en la base de datos.', 1;
        if @OrderYearFrom is not null and @OrderYearTo is not null and @OrderYearFrom > @OrderYearTo
            throw 50003, 'El año inicial no puede ser mayor que el año final.', 1;
        with TopSuppliers as (
            select
                year(po.OrderDate) as Año,
                sp.SupplierName as NombreProveedor,
                count(distinct po.PurchaseOrderID) as CantidadCompras,
                sum(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) as MontoComprado,
                dense_rank() over (partition by year(po.OrderDate) order by count(distinct po.PurchaseOrderID) desc) as Ranking
            from PurchaseOrders po
            inner join PurchaseOrderLines pol on po.PurchaseOrderID = pol.PurchaseOrderID
            inner join Suppliers sp on po.SupplierID = sp.SupplierID
            where
                (@OrderYearFrom is null or year(po.OrderDate) >= @OrderYearFrom)
                and (@OrderYearTo is null or year(po.OrderDate) <= @OrderYearTo)
            group by year(po.OrderDate), sp.SupplierID, sp.SupplierName
        )
        select
            Año,
            NombreProveedor,
            CantidadCompras,
            MontoComprado,
            Ranking
        from TopSuppliers
        where Ranking <= 5
    end
go

/*
    Resume por año el monto facturado para cada grupo de productos y presenta los grupos
    como columnas.
    Devuelve: Año, Novelty Items, Clothing, Mugs, T-Shirts, Airline Novelties, Computing Novelties, USB Novelties, Furry Footwear, Toys, Packaging Materials
*/
create or alter procedure Sales.GetProductCategorySalesByYear
as 
    begin
        select
            Año,
            [Novelty Items], [Clothing], [Mugs], [T-Shirts], [Airline Novelties],
            [Computing Novelties], [USB Novelties], [Furry Footwear], [Toys], [Packaging Materials]
        from (
            select year(iv.InvoiceDate) as Año,
                    sg.StockGroupName,
                    ivl.ExtendedPrice
            from Invoices iv
            inner join InvoiceLines ivl on ivl.InvoiceID = iv.InvoiceID
            inner join StockItems s on s.StockItemID = ivl.StockItemID
            inner join StockItemStockGroups sig on sig.StockItemID = s.StockItemID
            inner join StockGroups sg on sg.StockGroupID = sig.StockGroupID
        ) as src
        pivot (
            sum(ExtendedPrice) for StockGroupName in (
                [Novelty Items], [Clothing], [Mugs], [T-Shirts], [Airline Novelties],
                [Computing Novelties], [USB Novelties], [Furry Footwear], [Toys], [Packaging Materials]
            )
        ) as pvt
        order by Año
    end
go

/*
    Resume por cliente, año y mes los montos de sus facturas, con filtros opcionales por año,
    mes y una lista JSON de IDs de categorías de productos (@StockGroupIDsJson, por ejemplo [1, 3, 5]).
    Si la lista es null o está vacía, incluye todas las categorías; ignora los IDs repetidos.
    Combina los filtros con AND y calcula los montos solo con líneas cuyo producto pertenezca
    a todas las categorías seleccionadas. Incluye sus nombres concatenados por período.
    Valida que el año y las categorías existan, que el mes esté entre 1 y 12 y que la lista
    sea un arreglo JSON de números enteros positivos. Pagina los resultados y asigna a @TotalCount la cantidad
    de combinaciones de cliente, año y mes que cumplen los filtros.
    Devuelve: NombreCliente, Año, Mes, MontoPrimeraFactura, MontoUltimaFactura, MontoTotalMes, MontoMaximo, MontoMinimo, Categorias
*/
create or alter procedure Sales.GetCustomerSalesTracking
	@Year int = null,
	@Month int = null,
	@StockGroupIDsJson nvarchar(max) = null,
	@PageNumber int = 1,
	@PageSize int = 10,
	@TotalCount int = 0 output
as
	begin
		set nocount on;
        if @Year is not null and not exists (select 1 from Invoices where year(InvoiceDate) = @Year)
            throw 50001, 'El año indicado no existe en la base de datos.', 1;
		if @Month is not null and @Month not between 1 and 12
			throw 50002, 'El mes debe estar entre 1 y 12.', 1;
		declare @SelectedStockGroups table (StockGroupID int primary key);
		if @StockGroupIDsJson is not null
		    begin
		        if isjson(@StockGroupIDsJson, array) <> 1
		            throw 50003, 'StockGroupIDsJson debe ser un arreglo JSON de IDs de categorías.', 1;
		        if exists (
		            select 1
		            from openjson(@StockGroupIDsJson)
		            where [type] <> 2 or try_convert(int, [value]) is null or try_convert(int, [value]) < 1
		        )
		            throw 50004, 'Los IDs de categorías deben ser números enteros positivos.', 1;
		        insert into @SelectedStockGroups (StockGroupID)
		        select distinct convert(int, [value])
		        from openjson(@StockGroupIDsJson);
		        if exists (
		            select 1
		            from @SelectedStockGroups selected
		            where not exists (select 1 from StockGroups sg where sg.StockGroupID = selected.StockGroupID)
		        )
		            throw 50005, 'Una o más categorías indicadas no existen en la base de datos.', 1;
		    end
		select @TotalCount = count(*)
		from (
			select
				iv.CustomerID,
				year(iv.InvoiceDate) as Año,
				month(iv.InvoiceDate) as Mes
			from Invoices iv
			inner join Customers cs on iv.CustomerID = cs.CustomerID
			where 
				year(iv.InvoiceDate) = isnull(@Year, year(iv.InvoiceDate))
				and month(iv.InvoiceDate) = isnull(@Month, month(iv.InvoiceDate))
				and exists (
					select 1
					from InvoiceLines ivl
					inner join StockItemStockGroups sig on ivl.StockItemID = sig.StockItemID
					inner join StockGroups sg on sig.StockGroupID = sg.StockGroupID
					where ivl.InvoiceID = iv.InvoiceID
						and not exists (
							select 1
							from @SelectedStockGroups selected
							where not exists (
								select 1
								from StockItemStockGroups membership
								where membership.StockItemID = ivl.StockItemID
									and membership.StockGroupID = selected.StockGroupID
							)
						)
				)
			group by iv.CustomerID, year(iv.InvoiceDate), month(iv.InvoiceDate)
		) t;
		with AmountPerInvoice as (
			select
				iv.CustomerID,
				iv.InvoiceID,
				iv.InvoiceDate,
				year(iv.InvoiceDate) as Año,
				month(iv.InvoiceDate) as Mes,
				sum(ivl.ExtendedPrice) as MontoFacturado,
				first_value(sum(ivl.ExtendedPrice)) over (partition by iv.CustomerID, year(iv.InvoiceDate), month(iv.InvoiceDate) order by iv.InvoiceDate, iv.InvoiceID) as PrimeraFactura,
				last_value(sum(ivl.ExtendedPrice)) over (partition by iv.CustomerID, year(iv.InvoiceDate), month(iv.InvoiceDate) order by iv.InvoiceDate, iv.InvoiceID rows between unbounded preceding and unbounded following) as UltimaFactura
			from Invoices iv
			inner join InvoiceLines ivl on iv.InvoiceID = ivl.InvoiceID
			where 
				year(iv.InvoiceDate) = isnull(@Year, year(iv.InvoiceDate))
				and month(iv.InvoiceDate) = isnull(@Month, month(iv.InvoiceDate))
				and not exists (
					select 1
					from @SelectedStockGroups selected
					where not exists (
						select 1
						from StockItemStockGroups membership
						where membership.StockItemID = ivl.StockItemID
							and membership.StockGroupID = selected.StockGroupID
					)
				)
			group by iv.CustomerID, iv.InvoiceID, iv.InvoiceDate
		),
		StockGroupsByPeriod as (
		    select
				t2.CustomerID,
				t2.Año,
				t2.Mes,
				string_agg(t2.StockGroupName, ', ') as Categorias
			from (
			    select distinct
					iv.CustomerID,
					year(iv.InvoiceDate) as Año,
					month(iv.InvoiceDate) as Mes,
					sg.StockGroupName
				from Invoices iv
				inner join InvoiceLines ivl on iv.InvoiceID = ivl.InvoiceID
				inner join StockItemStockGroups sig on ivl.StockItemID = sig.StockItemID
				inner join StockGroups sg on sig.StockGroupID = sg.StockGroupID
				where 
					year(iv.InvoiceDate) = isnull(@Year, year(iv.InvoiceDate))
					and month(iv.InvoiceDate) = isnull(@Month, month(iv.InvoiceDate))
					and not exists (
						select 1
						from @SelectedStockGroups selected
						where not exists (
							select 1
							from StockItemStockGroups membership
							where membership.StockItemID = ivl.StockItemID
								and membership.StockGroupID = selected.StockGroupID
						)
					)
					and sig.StockGroupID in (
						select StockGroupID from @SelectedStockGroups
						union all
						select sig.StockGroupID where not exists (select 1 from @SelectedStockGroups)
					)
			) t2
			group by t2.CustomerID, t2.Año, t2.Mes
		)
		select
			cs.CustomerName as NombreCliente,
			apv.Año,
			apv.Mes,
			max(apv.PrimeraFactura) as MontoPrimeraFactura,
			max(apv.UltimaFactura) as MontoUltimaFactura,
			sum(apv.MontoFacturado) as MontoTotalMes,
			max(apv.MontoFacturado) as MontoMaximo,
			min(apv.MontoFacturado) as MontoMinimo,
		    max(sgbp.Categorias) as Categorias
		from AmountPerInvoice apv
		inner join Customers cs on apv.CustomerID = cs.CustomerID
		inner join StockGroupsByPeriod sgbp on apv.CustomerID = sgbp.CustomerID and apv.Año = sgbp.Año and apv.Mes = sgbp.Mes
		group by cs.CustomerID, cs.CustomerName, apv.Año, apv.Mes
		order by cs.CustomerName, apv.Año, apv.Mes
		offset (@PageNumber - 1) * @PageSize rows
		fetch next @PageSize rows only
	end
go

/*
    Resume por proveedor, año y mes los montos de sus órdenes de compra, con filtros opcionales por año,
    mes y una lista JSON de IDs de categorías de productos (@StockGroupIDsJson, por ejemplo [1, 3, 5]).
    Si la lista es null o está vacía, incluye todas las categorías; ignora los IDs repetidos.
    Combina los filtros con AND y calcula los montos solo con líneas cuyo producto pertenezca
    a todas las categorías seleccionadas. Incluye sus nombres concatenados por período.
    Valida que el año y las categorías existan, que el mes esté entre 1 y 12 y que la lista
    sea un arreglo JSON de números enteros positivos. Pagina los resultados y asigna a @TotalCount la cantidad
    de combinaciones de proveedor, año y mes que cumplen los filtros.
    Devuelve: NombreProveedor, Año, Mes, MontoPrimeraCompra, MontoUltimaCompra, MontoTotalMes, MontoMaximo, MontoMinimo, Categorias
*/
create or alter procedure Purchasing.GetSupplierPurchaseTracking
	@Year int = null,
	@Month int = null,
	@StockGroupIDsJson nvarchar(max) = null,
	@PageNumber int = 1,
	@PageSize int = 10,
	@TotalCount int = 0 output
as
	begin
		set nocount on;
        if @Year is not null and not exists (select 1 from PurchaseOrders where year(OrderDate) = @Year)
            throw 50001, 'El año indicado no existe en la base de datos.', 1;
		if @Month is not null and @Month not between 1 and 12
			throw 50002, 'El mes debe estar entre 1 y 12.', 1;
		declare @SelectedStockGroups table (StockGroupID int primary key);
		if @StockGroupIDsJson is not null
		    begin
		        if isjson(@StockGroupIDsJson, array) <> 1
		            throw 50003, 'StockGroupIDsJson debe ser un arreglo JSON de IDs de categorías.', 1;
		        if exists (
		            select 1
		            from openjson(@StockGroupIDsJson)
		            where [type] <> 2 or try_convert(int, [value]) is null or try_convert(int, [value]) < 1
		        )
		            throw 50004, 'Los IDs de categorías deben ser números enteros positivos.', 1;
		        insert into @SelectedStockGroups (StockGroupID)
		        select distinct convert(int, [value])
		        from openjson(@StockGroupIDsJson);
		        if exists (
		            select 1
		            from @SelectedStockGroups selected
		            where not exists (select 1 from StockGroups sg where sg.StockGroupID = selected.StockGroupID)
		        )
		            throw 50005, 'Una o más categorías indicadas no existen en la base de datos.', 1;
		    end
		select @TotalCount = count(*)
		from (
			select
				po.SupplierID,
				year(po.OrderDate) as Año,
				month(po.OrderDate) as Mes
			from PurchaseOrders po
			inner join Suppliers sp on po.SupplierID = sp.SupplierID
			where 
				year(po.OrderDate) = isnull(@Year, year(po.OrderDate))
				and month(po.OrderDate) = isnull(@Month, month(po.OrderDate))
				and exists (
					select 1
					from PurchaseOrderLines pol
					inner join StockItemStockGroups sig on pol.StockItemID = sig.StockItemID
					inner join StockGroups sg on sig.StockGroupID = sg.StockGroupID
					where pol.PurchaseOrderID = po.PurchaseOrderID
						and not exists (
							select 1
							from @SelectedStockGroups selected
							where not exists (
								select 1
								from StockItemStockGroups membership
								where membership.StockItemID = pol.StockItemID
									and membership.StockGroupID = selected.StockGroupID
							)
						)
				)
			group by po.SupplierID, year(po.OrderDate), month(po.OrderDate)
		) t;
		with AmountPerPurchase as (
			select
				po.SupplierID,
				po.PurchaseOrderID,
				po.OrderDate,
				year(po.OrderDate) as Año,
				month(po.OrderDate) as Mes,
				sum(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter) as MontoComprado,
				first_value(sum(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter)) over (partition by po.SupplierID, year(po.OrderDate), month(po.OrderDate) order by po.OrderDate, po.PurchaseOrderID) as PrimeraCompra,
				last_value(sum(pol.OrderedOuters * pol.ExpectedUnitPricePerOuter)) over (partition by po.SupplierID, year(po.OrderDate), month(po.OrderDate) order by po.OrderDate, po.PurchaseOrderID rows between unbounded preceding and unbounded following) as UltimaCompra
			from PurchaseOrders po
			inner join PurchaseOrderLines pol on po.PurchaseOrderID = pol.PurchaseOrderID
			where 
				year(po.OrderDate) = isnull(@Year, year(po.OrderDate))
				and month(po.OrderDate) = isnull(@Month, month(po.OrderDate))
				and not exists (
					select 1
					from @SelectedStockGroups selected
					where not exists (
						select 1
						from StockItemStockGroups membership
						where membership.StockItemID = pol.StockItemID
							and membership.StockGroupID = selected.StockGroupID
					)
				)
			group by po.SupplierID, po.PurchaseOrderID, po.OrderDate
		),
		StockGroupsByPeriod as (
		    select
				t2.SupplierID,
				t2.Año,
				t2.Mes,
				string_agg(t2.StockGroupName, ', ') as Categorias
			from (
			    select distinct
					po.SupplierID,
					year(po.OrderDate) as Año,
					month(po.OrderDate) as Mes,
					sg.StockGroupName
				from PurchaseOrders po
				inner join PurchaseOrderLines pol on po.PurchaseOrderID = pol.PurchaseOrderID
				inner join StockItemStockGroups sig on pol.StockItemID = sig.StockItemID
				inner join StockGroups sg on sig.StockGroupID = sg.StockGroupID
				where 
					year(po.OrderDate) = isnull(@Year, year(po.OrderDate))
					and month(po.OrderDate) = isnull(@Month, month(po.OrderDate))
					and not exists (
						select 1
						from @SelectedStockGroups selected
						where not exists (
							select 1
							from StockItemStockGroups membership
							where membership.StockItemID = pol.StockItemID
								and membership.StockGroupID = selected.StockGroupID
						)
					)
					and sig.StockGroupID in (
						select StockGroupID from @SelectedStockGroups
						union all
						select sig.StockGroupID where not exists (select 1 from @SelectedStockGroups)
					)
			) t2
			group by t2.SupplierID, t2.Año, t2.Mes
		)
		select
			sp.SupplierName as NombreProveedor,
			app.Año,
			app.Mes,
			max(app.PrimeraCompra) as MontoPrimeraCompra,
			max(app.UltimaCompra) as MontoUltimaCompra,
			sum(app.MontoComprado) as MontoTotalMes,
			max(app.MontoComprado) as MontoMaximo,
			min(app.MontoComprado) as MontoMinimo,
		    max(sgbp.Categorias) as Categorias
		from AmountPerPurchase app
		inner join Suppliers sp on app.SupplierID = sp.SupplierID
		inner join StockGroupsByPeriod sgbp on app.SupplierID = sgbp.SupplierID and app.Año = sgbp.Año and app.Mes = sgbp.Mes
		group by sp.SupplierID, sp.SupplierName, app.Año, app.Mes
		order by sp.SupplierName, app.Año, app.Mes
		offset (@PageNumber - 1) * @PageSize rows
		fetch next @PageSize rows only
	end
go
