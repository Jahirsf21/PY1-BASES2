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
