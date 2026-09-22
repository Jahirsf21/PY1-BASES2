/*
    Sinonimos
    CREATE SYNONYM Customers FOR Sales.Customers
    CREATE SYNONYM CustomerCategories FOR Sales.CustomerCategories

    CREATE SYNONYM DeliveryMethods FOR Application.DeliveryMethods

    CREATE SYNONYM Suppliers FOR Purchasing.Suppliers
    CREATE SYNONYM SupplierCategories FOR Purchasing.SupplierCategories

    CREATE SYNONYM StockItems FOR Warehouse.StockItems
    CREATE SYNONYM StockItemHoldings FOR Warehouse.StockItemHoldings
    CREATE SYNONYM StockItemStockGroups FOR Warehouse.StockItemStockGroups
    CREATE SYNONYM StockGroups FOR Warehouse.StockGroups

    CREATE SYNONYM Invoices FOR Sales.Invoices;
    CREATE SYNONYM InvoiceLines FOR Sales.InvoiceLines;
*/


/*
    Obtiene los clientes en páginas ordenadas por identificador
    Incluye TotalCount para poder calcular la paginación en el cliente
*/

create procedure Sales.GetCustomers
    @PageNumber int = 1,
    @PageSize int = 10
as 
    begin
        set nocount on
        select
            cs.CustomerID,
            cs.CustomerName as NombreCliente,
            cg.CustomerCategoryName as CategoriaCliente,
            dv.DeliveryMethodName as MetodoEntrega,
            count(*) over() as TotalCount
            from Customers cs
            inner join CustomerCategories cg on cs.CustomerCategoryID = cg.CustomerCategoryID
            inner join DeliveryMethods dv on cs.DeliveryMethodID = dv.DeliveryMethodID
            order by cs.CustomerID
            offset(@PageNumber -1) * @PageSize rows
            fetch next @PageSize rows only
    end
go

/*
    Obtiene los proveedores en páginas ordenadas por identificador
    Incluye TotalCount para poder calcular la paginación en el cliente
*/  

create procedure Purchasing.GetSuppliers
    @PageNumber int = 1,
    @PageSize int = 10
as 
    begin
        set nocount on
        select
            sp.SupplierID,
            sp.SupplierName as NombreProveedor,
            sg.SupplierCategoryName as CategoriaProveedor,
            dv.DeliveryMethodName as MetodoEntrega,
            count(*) over() as TotalCount
            from Suppliers sp
            inner join SupplierCategories sg on sp.SupplierCategoryID = sg.SupplierCategoryID
            left join DeliveryMethods dv on sp.DeliveryMethodID = dv.DeliveryMethodID
            order by sp.SupplierID
            offset(@PageNumber -1) * @PageSize rows
            fetch next @PageSize rows only
    end
go

/*
    Obtiene los productos en páginas ordenadas por identificador
    Incluye TotalCount para poder calcular la paginación en el cliente
*/  

create or alter procedure Warehouse.GetStockItems
    @PageNumber int = 1,
    @PageSize int = 10
as
    begin
        set nocount on
        select 
            s.StockItemID,
            s.StockItemName as NombreProducto,
            sg.StockGroupName as GrupoProducto,
            sih.QuantityOnHand as CantidadTotalEnInventarios,
            count(*) over() as TotalCount
            from StockItems s
            inner join StockItemHoldings sih on s.StockItemID = sih.StockItemID
            inner join StockItemStockGroups sig on s.StockItemID = sig.StockItemID
            inner join StockGroups sg on sig.StockGroupID = sg.StockGroupID
            order by StockItemID
            offset(@PageNumber -1) * @PageSize rows
            fetch next @PageSize rows only
    end
go

/*
    Obtiene las facturas en páginas ordenadas por identificador
    Incluye TotalCount para poder calcular la paginación en el cliente
*/  
create or alter procedure Sales.GetInvoices
    @PageNumber int = 1,
    @PageSize int = 10
as
    begin
        set nocount on
        select
            iv.InvoiceID as NumeroFactura,
            iv.InvoiceDate as FechaFactura,
            cs.CustomerName as NombreCliente,
            dv.DeliveryMethodName as MetodoEntrega,
            ivl.ExtendedPrice as MontoFacturado,
            count(*) over() as TotalCount
            from Invoices iv
            inner join Customers cs on iv.CustomerID = cs.CustomerID
            inner join DeliveryMethods dv on iv.DeliveryMethodID = dv.DeliveryMethodID
            inner join InvoiceLines ivl on iv.InvoiceID = ivl.InvoiceID
            order by iv.InvoiceID
            offset(@PageNumber -1) * @PageSize rows
            fetch next @PageSize rows only
    end
go
