/*
    Sinonimos
    CREATE SYNONYM Customers FOR Sales.Customers
    CREATE SYNONYM CustomerCategories FOR Sales.CustomerCategories
    CREATE SYNONYM CustomerTransactions FOR Sales.CustomerTransactions
    
    CREATE SYNONYM BuyingGroups FOR Sales.BuyingGroups

    CREATE SYNONYM DeliveryMethods FOR Application.DeliveryMethods

    CREATE SYNONYM Suppliers FOR Purchasing.Suppliers
    CREATE SYNONYM SupplierCategories FOR Purchasing.SupplierCategories

    CREATE SYNONYM StockItems FOR Warehouse.StockItems
    CREATE SYNONYM StockItemTransactions FOR Warehouse.StockItemTransactions
    CREATE SYNONYM StockItemHoldings FOR Warehouse.StockItemHoldings
    CREATE SYNONYM StockItemStockGroups FOR Warehouse.StockItemStockGroups
    CREATE SYNONYM StockGroups FOR Warehouse.StockGroups

    CREATE SYNONYM Orders FOR Sales.Orders
    CREATE SYNONYM OrderLines FOR Sales.OrderLines

    CREATE SYNONYM Invoices FOR Sales.Invoices
    CREATE SYNONYM InvoiceLines FOR Sales.InvoiceLines

    CREATE SYNONYM People FOR Application.People

    CREATE SYNONYM Cities FOR Application.Cities
    CREATE SYNONYM Countries FOR Application.Countries
    CREATE SYNONYM StateProvinces FOR Application.StateProvinces
*/

/*
    Obtiene los clientes paginados, ordenados por identificador.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: CustomerID, NombreCliente, NombreCategoriaCliente, NombreMetodoEntrega
*/
create procedure Sales.GetCustomers
    @CustomerName nvarchar(100) = null,
    @CustomerCategoryID int = null,
    @DeliveryMethodID int = null,
    @PageNumber int = 1,
    @PageSize   int = 10,
    @TotalCount int = 0 output
as
    begin
        set nocount on
        select @TotalCount = count(*) from Customers cs
        inner join CustomerCategories cg on cs.CustomerCategoryID = cg.CustomerCategoryID
        inner join DeliveryMethods dv on cs.DeliveryMethodID = dv.DeliveryMethodID
        where 
            (@CustomerName is null or cs.CustomerName like '%' + @CustomerName + '%')
            and (@CustomerCategoryID is null or cs.CustomerCategoryID = @CustomerCategoryID)
            and (@DeliveryMethodID is null or cs.DeliveryMethodID = @DeliveryMethodID)

        select
            cs.CustomerID,
            cs.CustomerName as NombreCliente,
            cg.CustomerCategoryName as NombreCategoriaCliente,
            dv.DeliveryMethodName as NombreMetodoEntrega
        from Customers cs
        inner join CustomerCategories cg on cs.CustomerCategoryID = cg.CustomerCategoryID
        inner join DeliveryMethods dv on cs.DeliveryMethodID = dv.DeliveryMethodID
        where 
            (@CustomerName is null or cs.CustomerName like '%' + @CustomerName + '%')
            and (@CustomerCategoryID is null or cs.CustomerCategoryID = @CustomerCategoryID)
            and (@DeliveryMethodID is null or cs.DeliveryMethodID = @DeliveryMethodID)
        order by cs.CustomerID
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go

/*
    Obtiene el listado de clientes (ID y nombre) paginado
    Permite filtrar opcionalmente por nombre de cliente.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: CustomerID, NombreCliente
*/
create procedure Sales.GetBillToCustomers
    @CustomerName nvarchar(100) = null,
    @PageNumber int = 1,
    @PageSize int = 10,
    @TotalCount int = 0 output
as
    begin
        set nocount on
        select @TotalCount = count(*) from Customers
        where @CustomerName is null or CustomerName like '%' + @CustomerName + '%'
        select 
            CustomerID,
            CustomerName as NombreCliente
        from Customers
        where @CustomerName is null or CustomerName like '%' + @CustomerName + '%'
        order by CustomerID
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go

/*
    Obtiene el detalle general de un cliente:
    nombre, categoría, buying group, cliente por facturar, método de entrega, días de gracia, sitio web.
    Devuelve: CustomerID, NombreCliente, NombreCategoriaCliente, NombreGrupoCompra, NombreClientePorFacturar, NombreMetodoEntrega, DiasGraciaPago, SitioWeb
*/
create procedure Sales.GetCustomerDetail
    @CustomerID int
as  
    begin
        set nocount on
        select
            cs.CustomerID,
            cs.CustomerName as NombreCliente,
            cg.CustomerCategoryName as NombreCategoriaCliente,
            bg.BuyingGroupName as NombreGrupoCompra,
            bill.CustomerName as NombreClientePorFacturar,
            dv.DeliveryMethodName as NombreMetodoEntrega,
            cs.PaymentDays as DiasGraciaPago,
            cs.WebSiteURL as SitioWeb
        from Customers cs
        inner join CustomerCategories cg on cs.CustomerCategoryID = cg.CustomerCategoryID
        left join BuyingGroups bg on cs.BuyingGroupID = bg.BuyingGroupID
        inner join DeliveryMethods dv on cs.DeliveryMethodID = dv.DeliveryMethodID
        inner join Customers bill on bill.CustomerID = cs.BillToCustomerID
        where cs.CustomerID = @CustomerID
    end
go

/*
    Obtiene los contactos (principal y alternativo) de un cliente específico.
    Devuelve: una fila con el nombre, teléfono, fax y correo de ambos contactos.
*/
create procedure Sales.GetCustomerContacts
    @CustomerID int
as 
    begin
        set nocount on
        select 
            pp.FullName as NombreContactoPrincipal,
            pp.PhoneNumber as TelefonoPrincipal,
            pp.FaxNumber AS FaxPrincipal,
            pp.EmailAddress as CorreoPrincipal,
            pa.FullName as NombreContactoAlternativo,
            pa.PhoneNumber as TelefonoAlternativo,
            pa.FaxNumber as FaxAlternativo,
            pa.EmailAddress as CorreoAlternativo
        from Customers cs
        left join People pp on cs.PrimaryContactPersonID = pp.PersonID
        left join People pa on cs.AlternateContactPersonID = pa.PersonID
        where cs.CustomerID = @CustomerID
    end
go

/*
    Obtiene las direcciones de entrega y postal de un cliente,
    junto con su ubicación geográfica (latitud/longitud) para el mapa.
    Devuelve: una fila con ambas direcciones y las coordenadas.
*/
create procedure Sales.GetCustomerAddress
    @CustomerID int
as
    begin
        set nocount on
        select  
            cs.DeliveryAddressLine1 as DireccionEntrega1,
            cs.DeliveryAddressLine2 as DireccionEntrega2,
            ci.CityName as CiudadEntrega,
            sp.StateProvinceName as ProvinciaEntrega,
            co.CountryName as PaisEntrega,
            cs.DeliveryPostalCode as CodigoPostalEntrega,
            cs.PostalAddressLine1 as DireccionPostal1,
            cs.PostalAddressLine2 as DireccionPostal2,
            ci2.CityName as CiudadPostal,
            sp2.StateProvinceName as ProvinciaPostal,
            co2.CountryName as PaisPostal,
            cs.PostalPostalCode as CodigoPostalPostal,
            cs.DeliveryLocation.Lat as Latitud,
            cs.DeliveryLocation.Long as Longitud
        from Customers cs
        inner join Cities ci on cs.DeliveryCityID = ci.CityID
        inner join StateProvinces sp on ci.StateProvinceID = sp.StateProvinceID
        inner join Countries co on sp.CountryID = co.CountryID
        inner join Cities ci2 on cs.PostalCityID = ci2.CityID
        inner join StateProvinces sp2 on ci2.StateProvinceID = sp2.StateProvinceID
        inner join Countries co2 on sp2.CountryID = co2.CountryID
        where cs.CustomerID = @CustomerID
    end
go

/*
    Obtiene todas las categorías de cliente ordenadas por su ID.
    Devuelve: CustomerCategoryID, NombreCategoria
*/
create procedure Sales.GetCustomerCategories
as
    begin
        set nocount on
        select
            CustomerCategoryID,
            CustomerCategoryName as NombreCategoria
        from CustomerCategories
        order by CustomerCategoryID
    end
go

/*
    Obtiene todas las agrupaciones de compra (buying groups)
    ordenadas por su identificador.
    Devuelve: BuyingGroupID, NombreGrupoCompra
*/
create procedure Sales.GetBuyingGroups
as
    begin
        set nocount on
        select
            BuyingGroupID,
            BuyingGroupName as NombreGrupoCompra
        from BuyingGroups
        order by BuyingGroupID
    end
go

/*
    Obtiene todos los métodos de entrega ordenados por su identificador.
    Devuelve: DeliveryMethodID, NombreMetodoEntrega
*/
create procedure Application.GetDeliveryMethods
as
    begin
        set nocount on
        select
            DeliveryMethodID,
            DeliveryMethodName as NombreMetodoEntrega
        from DeliveryMethods
        order by DeliveryMethodID
    end
go

/*
    Obtiene las personas paginadas, opcionalmente filtradas por nombre.
    Si @FullName es NULL o vacío, devuelve todas las personas.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: PersonID, NombreCompleto
*/
create procedure Application.GetPeople
    @FullName nvarchar(100) = null,
    @PageNumber int = 1,
    @PageSize int = 10,
    @TotalCount int = 0 output
as
    begin
        set nocount on
        select @TotalCount = count(*) from People
        where @FullName is null or FullName like '%' + @FullName + '%'
        select
            PersonID,
            FullName as NombreCompleto
        from People
        where @FullName is null or FullName like '%' + @FullName + '%'
        order by PersonID
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go

/*
    Obtiene las ciudades paginadas, ordenadas por identificador.
    Permite filtrar opcionalmente por nombre de ciudad, provincia y país.
    Si un filtro es NULL, no se aplica.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: CityID, NombreCiudad, Provincia, NombrePais
*/
create procedure Application.GetCities
    @CityName nvarchar(100) = null,
    @ProvinceName nvarchar(100) = null,
    @CountryName nvarchar(100) = null,
    @PageNumber int = 1,
    @PageSize int = 10,
    @TotalCount int = 0 output
as
    begin
        set nocount on
        select @TotalCount = count(*) from Cities ci
        inner join StateProvinces sp on ci.StateProvinceID = sp.StateProvinceID
        inner join Countries co on sp.CountryID = co.CountryID
        where 
            (@CityName is null or ci.CityName like '%' + @CityName + '%')
            and (@ProvinceName is null or sp.StateProvinceName like '%' + @ProvinceName + '%')
            and (@CountryName   is null or co.CountryName like '%' + @CountryName + '%')
        select
            ci.CityID,
            ci.CityName as NombreCiudad,
            sp.StateProvinceName as Provincia,
            co.CountryName as NombrePais
        from Cities ci
        inner join StateProvinces sp on ci.StateProvinceID = sp.StateProvinceID
        inner join Countries co on sp.CountryID = co.CountryID
        where 
            (@CityName is null or ci.CityName like '%' + @CityName + '%')
            and (@ProvinceName is null or sp.StateProvinceName like '%' + @ProvinceName + '%')
            and (@CountryName   is null or co.CountryName like '%' + @CountryName + '%')
        order by ci.CityID
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go

/*
    Obtiene los proveedores paginados, ordenados por identificador.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: SupplierID, NombreProveedor, NombreCategoriaProveedor, NombreMetodoEntrega
*/ 
create procedure Purchasing.GetSuppliers
    @SupplierName nvarchar(100) = null,
    @SupplierCategoryID int = null,
    @DeliveryMethodID int = null,
    @PageNumber int = 1,
    @PageSize int = 10,
    @TotalCount int = 0 output
as 
    begin
        set nocount on
        select @TotalCount = count(*) from Suppliers sp
        inner join SupplierCategories sg on sp.SupplierCategoryID = sg.SupplierCategoryID
        left join DeliveryMethods dv on sp.DeliveryMethodID = dv.DeliveryMethodID
        where 
            (@SupplierName is null or sp.SupplierName like '%' + @SupplierName + '%')
            and (@SupplierCategoryID is null or sp.SupplierCategoryID = @SupplierCategoryID)
            and (@DeliveryMethodID is null or sp.DeliveryMethodID = @DeliveryMethodID)
        select
            sp.SupplierID,
            sp.SupplierName as NombreProveedor,
            sg.SupplierCategoryName as NombreCategoriaProveedor,
            dv.DeliveryMethodName as NombreMetodoEntrega
        from Suppliers sp
        inner join SupplierCategories sg on sp.SupplierCategoryID = sg.SupplierCategoryID
        left join DeliveryMethods dv on sp.DeliveryMethodID = dv.DeliveryMethodID
        where 
            (@SupplierName is null or sp.SupplierName like '%' + @SupplierName + '%')
            and (@SupplierCategoryID is null or sp.SupplierCategoryID = @SupplierCategoryID)
            and (@DeliveryMethodID is null or sp.DeliveryMethodID = @DeliveryMethodID)
        order by sp.SupplierID
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go

/*
    Obtiene todas las categorías de proveedor ordenadas por su ID.
    Devuelve: SupplierCategoryID, NombreCategoriaProveedor
*/
create procedure Purchasing.GetSupplierCategories
as
    begin
        set nocount on
        select
            SupplierCategoryID,
            SupplierCategoryName as NombreCategoriaProveedor
        from SupplierCategories
        order by SupplierCategoryID
    end
go

/*
    Obtiene los productos (stock items) paginados, ordenados alfabéticamente por nombre.
    Si un producto pertenece a varios grupos, se concatenan sus nombres en una sola columna.
    Permite filtrar opcionalmente por nombre de producto y por grupo.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: StockItemID, NombreProducto, NombreGrupoProducto, CantidadTotalEnInventarios
*/
create procedure Warehouse.GetStockItems
    @StockItemName nvarchar(100) = null,
    @StockGroupID int = null,
    @PageNumber int = 1,
    @PageSize int = 10,
    @TotalCount int = 0 output 
as
    begin
        set nocount on
        select @TotalCount = count(*) from StockItems s
        where
            (@StockItemName is null or s.StockItemName like '%' + @StockItemName + '%')
            and (@StockGroupID is null or exists(
                select 1
                from StockItemStockGroups sig
                where sig.StockItemID = s.StockItemID and sig.StockGroupID = @StockGroupID
            ))
        select 
            s.StockItemID,
            s.StockItemName as NombreProducto,
            string_agg(sg.StockGroupName, ', ') as NombreGrupoProducto,
            sih.QuantityOnHand as CantidadTotalEnInventarios
        from StockItems s
        inner join StockItemHoldings sih on s.StockItemID = sih.StockItemID
        inner join StockItemStockGroups sig on s.StockItemID = sig.StockItemID
        inner join StockGroups sg on sig.StockGroupID = sg.StockGroupID
        where
            (@StockItemName is null or s.StockItemName like '%' + @StockItemName + '%')
            and (@StockGroupID is null or exists(
                select 1
                from StockItemStockGroups sig2
                where sig2.StockItemID = s.StockItemID and sig2.StockGroupID = @StockGroupID
            ))
        group by s.StockItemID, s.StockItemName, sih.QuantityOnHand
        order by s.StockItemName
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go

/*
    Obtiene todos los grupos de productos ordenados por su identificador.
    Devuelve: StockGroupID, NombreGrupoProducto
*/
create procedure Warehouse.GetStockGroups
as
    begin
        set nocount on
        select
            StockGroupID,
            StockGroupName as NombreGrupoProducto
        from StockGroups
        order by StockGroupID
    end
go

/*
    Obtiene las facturas paginadas, ordenadas por identificador.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: NumeroFactura, FechaFactura, NombreCliente, NombreMetodoEntrega, MontoFacturado
*/
create procedure Sales.GetInvoices
    @InvoiceID int = null,
    @InvoiceDateFrom date = null,
    @InvoiceDateTo date = null,
    @CustomerName nvarchar(100) = null,
    @DeliveryMethodID int = null,
    @MinInvoiceAmount decimal(18,2) = null,
    @MaxInvoiceAmount decimal(18,2) = null,
    @PageNumber int = 1,
    @PageSize int = 10,
    @TotalCount int = 0 output
as
    begin
        set nocount on
        select @TotalCount = count(*)
        from (
            select iv.InvoiceID
            from Invoices iv
            inner join Customers cs on iv.CustomerID = cs.CustomerID
            inner join DeliveryMethods dv on iv.DeliveryMethodID = dv.DeliveryMethodID
            inner join InvoiceLines ivl on iv.InvoiceID = ivl.InvoiceID
            where (@InvoiceID is null or iv.InvoiceID = @InvoiceID)
              and (@InvoiceDateFrom  is null or iv.InvoiceDate >= @InvoiceDateFrom)
              and (@InvoiceDateTo is null or iv.InvoiceDate < dateadd(day, 1, @InvoiceDateTo))
              and (@CustomerName  is null or cs.CustomerName like '%' + @CustomerName + '%')
              and (@DeliveryMethodID is null or iv.DeliveryMethodID = @DeliveryMethodID)
            group by iv.InvoiceID
            having (@MinInvoiceAmount is null or sum(ivl.ExtendedPrice) >= @MinInvoiceAmount)
               and (@MaxInvoiceAmount is null or sum(ivl.ExtendedPrice) <= @MaxInvoiceAmount)
        ) t

        select
            iv.InvoiceID as NumeroFactura,
            iv.InvoiceDate as FechaFactura,
            cs.CustomerName as NombreCliente,
            dv.DeliveryMethodName as NombreMetodoEntrega,
            sum(ivl.ExtendedPrice) as MontoFacturado
        from Invoices iv
        inner join Customers cs on iv.CustomerID = cs.CustomerID
        inner join DeliveryMethods dv on iv.DeliveryMethodID = dv.DeliveryMethodID
        inner join InvoiceLines ivl on iv.InvoiceID = ivl.InvoiceID
        where (@InvoiceID is null or iv.InvoiceID = @InvoiceID)
            and (@InvoiceDateFrom  is null or iv.InvoiceDate >= @InvoiceDateFrom)
            and (@InvoiceDateTo is null or iv.InvoiceDate < dateadd(day, 1, @InvoiceDateTo))
            and (@CustomerName  is null or cs.CustomerName like '%' + @CustomerName + '%')
            and (@DeliveryMethodID is null or iv.DeliveryMethodID = @DeliveryMethodID)
        group by iv.InvoiceID, iv.InvoiceDate, cs.CustomerName, dv.DeliveryMethodName
        having (@MinInvoiceAmount is null or sum(ivl.ExtendedPrice) >= @MinInvoiceAmount)
            and (@MaxInvoiceAmount is null or sum(ivl.ExtendedPrice) <= @MaxInvoiceAmount)
        order by iv.InvoiceID
        offset(@PageNumber - 1) * @PageSize rows
        fetch next @PageSize rows only
    end
go
