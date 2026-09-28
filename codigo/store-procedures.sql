use WideWorldImporters;
go
if db_name() <> N'WideWorldImporters' throw 50000, N'Base incorrecta', 1;
go

-- ======================================================================================
-- Sinonimos 
-- ======================================================================================
drop synonym if exists dbo.Customers;
create synonym dbo.Customers for Sales.Customers;
go
drop synonym if exists dbo.CustomerCategories;
create synonym dbo.CustomerCategories for Sales.CustomerCategories;
go
drop synonym if exists dbo.CustomerTransactions;
create synonym dbo.CustomerTransactions for Sales.CustomerTransactions;
go
drop synonym if exists dbo.BuyingGroups;
create synonym dbo.BuyingGroups for Sales.BuyingGroups;
go
drop synonym if exists dbo.DeliveryMethods;
create synonym dbo.DeliveryMethods for Application.DeliveryMethods;
go
drop synonym if exists dbo.Suppliers;
create synonym dbo.Suppliers for Purchasing.Suppliers;
go
drop synonym if exists dbo.SupplierCategories;
create synonym dbo.SupplierCategories for Purchasing.SupplierCategories;
go
drop synonym if exists dbo.StockItems;
create synonym dbo.StockItems for Warehouse.StockItems;
go
drop synonym if exists dbo.StockItemTransactions;
create synonym dbo.StockItemTransactions for Warehouse.StockItemTransactions;
go
drop synonym if exists dbo.StockItemHoldings;
create synonym dbo.StockItemHoldings for Warehouse.StockItemHoldings;
go
drop synonym if exists dbo.StockItemStockGroups;
create synonym dbo.StockItemStockGroups for Warehouse.StockItemStockGroups;
go
drop synonym if exists dbo.StockGroups;
create synonym dbo.StockGroups for Warehouse.StockGroups;
go
drop synonym if exists dbo.Colors;
create synonym dbo.Colors for Warehouse.Colors;
go
drop synonym if exists dbo.PackageTypes;
create synonym dbo.PackageTypes for Warehouse.PackageTypes;
go
drop synonym if exists dbo.Orders;
create synonym dbo.Orders for Sales.Orders;
go
drop synonym if exists dbo.OrderLines;
create synonym dbo.OrderLines for Sales.OrderLines;
go
drop synonym if exists dbo.Invoices;
create synonym dbo.Invoices for Sales.Invoices;
go
drop synonym if exists dbo.InvoiceLines;
create synonym dbo.InvoiceLines for Sales.InvoiceLines;
go
drop synonym if exists dbo.People;
create synonym dbo.People for Application.People;
go
drop synonym if exists dbo.Cities;
create synonym dbo.Cities for Application.Cities;
go
drop synonym if exists dbo.Countries;
create synonym dbo.Countries for Application.Countries;
go
drop synonym if exists dbo.StateProvinces;
create synonym dbo.StateProvinces for Application.StateProvinces;
go

-- ======================================================================================
-- Módulo de clientes 
-- ======================================================================================
/*
    Obtiene los clientes paginados, ordenados por identificador.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: CustomerID, NombreCliente, NombreCategoriaCliente, NombreMetodoEntrega
*/
create or alter procedure Sales.GetCustomers
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
create or alter procedure Sales.GetBillToCustomers
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
create or alter procedure Sales.GetCustomerDetail
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
create or alter procedure Sales.GetCustomerContacts
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
create or alter procedure Sales.GetCustomerAddress
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
create or alter procedure Sales.GetCustomerCategories
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
create or alter procedure Sales.GetBuyingGroups
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
create or alter procedure Application.GetDeliveryMethods
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
create or alter procedure Application.GetPeople
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
create or alter procedure Application.GetCities
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

-- ======================================================================================
-- CRUD de clientes 
-- ======================================================================================
/*
    Inserta un nuevo cliente en la tabla Customers. Recibe todos los datos obligatorios y opcionales del cliente, 
    maneja valores por defecto (fecha de apertura de cuenta, fax, web, ubicación geográfica), y devuelve el CustomerID 
    generado a través del parámetro de salida @NewCustomerID
*/
create or alter procedure Sales.InsertCustomer
    @CustomerName nvarchar(100),
    @CustomerCategoryID int,
    @BillToCustomerID int,
    @LastEditedBy int,
    @AccountOpenedDate date = null,
    @StandardDiscountPercentage decimal(18,3) = 0,
    @IsStatementSent bit = 0,
    @IsOnCreditHold bit = 0,
    @BuyingGroupID int = null,
    @PrimaryContactPersonID int,
    @AlternateContactPersonID int = null,
    @DeliveryMethodID int,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20) = null,
    @WebsiteURL nvarchar(256) = null,
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryAddressLine2 nvarchar(60) = null,
    @DeliveryCityID int,
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalAddressLine2 nvarchar(60) = null,
    @PostalCityID int,
    @PostalPostalCode nvarchar(10),
    @Latitude float = null,
    @Longitude float = null,
    @NewCustomerID int output
as
    begin
        set nocount on
        begin try
            begin transaction
                declare @InsertedIDs table (CustomerID int)

                insert into Customers (
                    CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID,
                    PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
                    AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold,
                    PaymentDays, PhoneNumber, FaxNumber, WebsiteURL,
                    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode,
                    PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode,
                    DeliveryLocation, LastEditedBy
                )
                output inserted.CustomerID into @InsertedIDs
                values (
                    @CustomerName, @BillToCustomerID, @CustomerCategoryID, @BuyingGroupID,
                    @PrimaryContactPersonID, @AlternateContactPersonID, @DeliveryMethodID,
                    coalesce(@AccountOpenedDate, convert(date, sysdatetime())),
                    @StandardDiscountPercentage, @IsStatementSent, @IsOnCreditHold,
                    @PaymentDays, @PhoneNumber, coalesce(@FaxNumber,N''), coalesce(@WebsiteURL,N''),
                    @DeliveryAddressLine1, @DeliveryAddressLine2, @DeliveryCityID, @DeliveryPostalCode,
                    @PostalAddressLine1, @PostalAddressLine2, @PostalCityID, @PostalPostalCode,
                    case when @Latitude is not null and @Longitude is not null
                         then geography::Point(@Latitude, @Longitude, 4326)
                         else null end, @LastEditedBy
                )

                select @NewCustomerID = CustomerID from @InsertedIDs
            commit transaction
            print 'Cliente insertado correctamente. Nuevo CustomerID = '  + cast(@NewCustomerID as varchar(20)) + ' (' + @CustomerName + ')';
        end try
        begin catch
            if @@trancount > 0
                rollback transaction;
            ;throw;
        end catch
    end
go

/*
    Actualiza la información de un cliente existente. Recibe el @CustomerID y todos los campos editables. 
    Si el cliente no existe, lanza un error personalizado (51000). La columna DeliveryLocation solo se actualiza 
    si se envían latitud y longitud; de lo contrario, conserva el valor previo.
*/
create or alter procedure Sales.UpdateCustomer
    @CustomerID int,
    @CustomerName nvarchar(100),
    @CustomerCategoryID int,
    @BillToCustomerID int,
    @LastEditedBy int,
    @AccountOpenedDate date = null,
    @StandardDiscountPercentage decimal(18,3) = 0,
    @IsStatementSent bit = 0,
    @IsOnCreditHold bit = 0,
    @BuyingGroupID int = null,
    @PrimaryContactPersonID int,
    @AlternateContactPersonID int = null,
    @DeliveryMethodID int,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20) = null,
    @WebsiteURL nvarchar(256) = null,
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryAddressLine2 nvarchar(60) = null,
    @DeliveryCityID int,
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalAddressLine2 nvarchar(60) = null,
    @PostalCityID int,
    @PostalPostalCode nvarchar(10),
    @Latitude float = null,
    @Longitude float = null
as
    begin
        set nocount on
        begin try
            begin transaction
                update Customers
                set
                    CustomerName = @CustomerName,
                    BillToCustomerID = @BillToCustomerID,
                    LastEditedBy = @LastEditedBy,
                    CustomerCategoryID = @CustomerCategoryID,
                    BuyingGroupID = @BuyingGroupID,
                    PrimaryContactPersonID = @PrimaryContactPersonID,
                    AlternateContactPersonID = @AlternateContactPersonID,
                    DeliveryMethodID = @DeliveryMethodID,
                    PaymentDays = @PaymentDays,
                    PhoneNumber = @PhoneNumber,
                    FaxNumber = coalesce(@FaxNumber,N''),
                    WebsiteURL = coalesce(@WebsiteURL,N''),
                    DeliveryAddressLine1 = @DeliveryAddressLine1,
                    DeliveryAddressLine2 = @DeliveryAddressLine2,
                    DeliveryCityID = @DeliveryCityID,
                    DeliveryPostalCode = @DeliveryPostalCode,
                    PostalAddressLine1 = @PostalAddressLine1,
                    PostalAddressLine2 = @PostalAddressLine2,
                    PostalCityID = @PostalCityID,
                    PostalPostalCode = @PostalPostalCode,
                    DeliveryLocation = case when @Latitude is not null and @Longitude is not null
                                             then geography::Point(@Latitude, @Longitude, 4326)
                                             else DeliveryLocation end
                where CustomerID = @CustomerID

                if @@rowcount = 0
                    throw 51000, 'El cliente indicado no existe.', 1
            commit transaction
            print 'Cliente actualizado correctamente. CustomerID = ' + cast(@CustomerID as varchar(20)) + ' (' + @CustomerName + ')';
        end try
        begin catch
            if @@trancount > 0
                rollback transaction;
            ;throw;
        end catch
    end
go

/*
    Elimina un cliente por su CustomerID. Solo permite la eliminación si el cliente no tiene facturas ni otros registros 
    relacionados (FK). Si no existe, lanza error 51001; si hay violación de integridad referencial (error 547), lanza error 
    51002 con un mensaje más claro.
*/
create or alter procedure Sales.DeleteCustomer
    @CustomerID int
as
    begin
        set nocount on
        begin try
            begin transaction
                delete from Customers
                where CustomerID = @CustomerID

                if @@rowcount = 0
                    throw 51001, 'El cliente indicado no existe.', 1
            commit transaction
            print 'Cliente eliminado correctamente. CustomerID = ' + cast(@CustomerID as varchar(20));
        end try
        begin catch
            if @@trancount > 0
                rollback transaction

            if error_number() = 547
                throw 51002, 'No se puede eliminar el cliente porque tiene facturas u otros registros asociados.', 1
            else
                throw
        end catch
    end
go

-- ======================================================================================
-- Módulo de proveedores 
-- ======================================================================================
/*
    Obtiene los proveedores paginados, ordenados por identificador.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: SupplierID, NombreProveedor, NombreCategoriaProveedor, NombreMetodoEntrega
*/ 
create or alter procedure Purchasing.GetSuppliers
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
create or alter procedure Purchasing.GetSupplierCategories
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
    Obtiene el detalle general de un proveedor: código de referencia, nombre, categoría, método de entrega, días de gracia y datos bancarios.
    Devuelve: SupplierID, CodigoProveedor, NombreProveedor, NombreCategoriaProveedor, NombreMetodoEntrega, DiasGraciaPago, SitioWeb,
    NombreBanco, SucursalBanco, NumeroCuentaBancaria, CodigoSwift
*/
create or alter procedure Purchasing.GetSupplierDetail
    @SupplierID int
as
    begin
        set nocount on
        select
            sp.SupplierID,
            sp.SupplierReference as CodigoProveedor,
            sp.SupplierName as NombreProveedor,
            sg.SupplierCategoryName as NombreCategoriaProveedor,
            dv.DeliveryMethodName as NombreMetodoEntrega,
            sp.PaymentDays as DiasGraciaPago,
            sp.PhoneNumber as Telefono,
            sp.FaxNumber as Fax,
            sp.WebSiteURL as SitioWeb,
            sp.BankAccountName as NombreBanco,
            sp.BankAccountBranch as SucursalBanco,
            sp.BankAccountNumber as NumeroCuentaBancaria,
            sp.BankInternationalCode as CodigoSwift
        from Suppliers sp
        inner join SupplierCategories sg on sp.SupplierCategoryID = sg.SupplierCategoryID
        left join DeliveryMethods dv on sp.DeliveryMethodID = dv.DeliveryMethodID
        where sp.SupplierID = @SupplierID
    end
go

/*
    Obtiene los contactos (principal y alternativo) de un proveedor específico.
    Devuelve: una fila con el nombre, teléfono, fax y correo de ambos contactos.
*/
create or alter procedure Purchasing.GetSupplierContacts
    @SupplierID int
as 
    begin
        set nocount on
        select 
            pp.FullName as NombreContactoPrincipal,
            pp.PhoneNumber as TelefonoPrincipal,
            pp.FaxNumber as FaxPrincipal,
            pp.EmailAddress as CorreoPrincipal,
            pa.FullName as NombreContactoAlternativo,
            pa.PhoneNumber as TelefonoAlternativo,
            pa.FaxNumber as FaxAlternativo,
            pa.EmailAddress as CorreoAlternativo
        from Suppliers sp
        left join People pp on sp.PrimaryContactPersonID = pp.PersonID
        left join People pa on sp.AlternateContactPersonID = pa.PersonID
        where sp.SupplierID = @SupplierID
    end
go

/*
    Obtiene las direcciones de entrega y postal de un proveedor,
    junto con su ubicación geográfica (latitud/longitud) para el mapa.
    Devuelve: una fila con ambas direcciones y las coordenadas.
*/
create or alter procedure Purchasing.GetSupplierAddress
    @SupplierID int
as
    begin
        set nocount on
        select  
            sp.DeliveryAddressLine1 as DireccionEntrega1,
            sp.DeliveryAddressLine2 as DireccionEntrega2,
            ci.CityName as CiudadEntrega,
            spv.StateProvinceName as ProvinciaEntrega,
            co.CountryName as PaisEntrega,
            sp.DeliveryPostalCode as CodigoPostalEntrega,
            sp.PostalAddressLine1 as DireccionPostal1,
            sp.PostalAddressLine2 as DireccionPostal2,
            ci2.CityName as CiudadPostal,
            spv2.StateProvinceName as ProvinciaPostal,
            co2.CountryName as PaisPostal,
            sp.PostalPostalCode as CodigoPostalPostal,
            sp.DeliveryLocation.Lat as Latitud,
            sp.DeliveryLocation.Long as Longitud
        from Suppliers sp
        inner join Cities ci on sp.DeliveryCityID = ci.CityID
        inner join StateProvinces spv on ci.StateProvinceID = spv.StateProvinceID
        inner join Countries co on spv.CountryID = co.CountryID
        inner join Cities ci2 on sp.PostalCityID = ci2.CityID
        inner join StateProvinces spv2 on ci2.StateProvinceID = spv2.StateProvinceID
        inner join Countries co2 on spv2.CountryID = co2.CountryID
        where sp.SupplierID = @SupplierID
    end
go

-- ======================================================================================
-- CRUD de proveedores
-- ======================================================================================
/* 
   Inserta un nuevo proveedor en la tabla Suppliers. Recibe todos los datos obligatorios 
   y opcionales del proveedor, maneja valores por defecto (fax, web, ubicación geográfica), 
   y devuelve el SupplierID generado a través del parámetro de salida @NewSupplierID.
*/
create or alter procedure Purchasing.InsertSupplier
    @SupplierName nvarchar(100),
    @SupplierCategoryID int,
    @LastEditedBy int,
    @SupplierReference nvarchar(20) = null,
    @PrimaryContactPersonID int,
    @AlternateContactPersonID int = null,
    @DeliveryMethodID int,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20) = null,
    @WebsiteURL nvarchar(256) = null,
    @BankAccountName nvarchar(50) = null,
    @BankAccountBranch nvarchar(50) = null,
    @BankAccountCode nvarchar(20) = null,
    @BankAccountNumber nvarchar(20) = null,
    @BankInternationalCode nvarchar(20) = null,
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryAddressLine2 nvarchar(60) = null,
    @DeliveryCityID int,
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalAddressLine2 nvarchar(60) = null,
    @PostalCityID int,
    @PostalPostalCode nvarchar(10),
    @Latitude float = null,
    @Longitude float = null,
    @NewSupplierID int output
as
    begin
        set nocount on
        begin try
            begin transaction
                declare @InsertedIDs table (SupplierID int)

                insert into Suppliers (
                    SupplierName, SupplierCategoryID, SupplierReference,
                    PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID,
                    PaymentDays, PhoneNumber, FaxNumber, WebsiteURL,
                    BankAccountName, BankAccountBranch, BankAccountCode,
                    BankAccountNumber, BankInternationalCode,
                    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode,
                    PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode,
                    DeliveryLocation, LastEditedBy
                )
                output inserted.SupplierID into @InsertedIDs
                values (
                    @SupplierName, @SupplierCategoryID, @SupplierReference,
                    @PrimaryContactPersonID, coalesce(@AlternateContactPersonID,@PrimaryContactPersonID), @DeliveryMethodID,
                    @PaymentDays, @PhoneNumber, coalesce(@FaxNumber,N''), coalesce(@WebsiteURL,N''),
                    @BankAccountName, @BankAccountBranch, @BankAccountCode,
                    @BankAccountNumber, @BankInternationalCode,
                    @DeliveryAddressLine1, @DeliveryAddressLine2, @DeliveryCityID, @DeliveryPostalCode,
                    @PostalAddressLine1, @PostalAddressLine2, @PostalCityID, @PostalPostalCode,
                    case when @Latitude is not null and @Longitude is not null
                         then geography::Point(@Latitude, @Longitude, 4326)
                         else null end, @LastEditedBy
                )

                select @NewSupplierID = SupplierID from @InsertedIDs
            commit transaction
            print 'Proveedor insertado correctamente. Nuevo SupplierID = ' + cast(@NewSupplierID as varchar(20)) + ' (' + @SupplierName + ')';
        end try
        begin catch
            if @@trancount > 0
                rollback transaction;
            ;throw;
        end catch
    end
go

/*
   Actualiza la información de un proveedor existente. Recibe el @SupplierID y todos los 
   campos editables. Si el proveedor no existe, lanza un error personalizado (52000). 
   La columna DeliveryLocation solo se actualiza si se envían latitud y longitud; de lo 
   contrario, conserva el valor previo.
*/
create or alter procedure Purchasing.UpdateSupplier
    @SupplierID int,
    @SupplierName nvarchar(100),
    @SupplierCategoryID int,
    @LastEditedBy int,
    @SupplierReference nvarchar(20) = null,
    @PrimaryContactPersonID int,
    @AlternateContactPersonID int = null,
    @DeliveryMethodID int,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20) = null,
    @WebsiteURL nvarchar(256) = null,
    @BankAccountName nvarchar(50) = null,
    @BankAccountBranch nvarchar(50) = null,
    @BankAccountCode nvarchar(20) = null,
    @BankAccountNumber nvarchar(20) = null,
    @BankInternationalCode nvarchar(20) = null,
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryAddressLine2 nvarchar(60) = null,
    @DeliveryCityID int,
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalAddressLine2 nvarchar(60) = null,
    @PostalCityID int,
    @PostalPostalCode nvarchar(10),
    @Latitude float = null,
    @Longitude float = null
as
    begin
        set nocount on
        begin try
            begin transaction
                update Suppliers
                set
                    SupplierName = @SupplierName,
                    LastEditedBy = @LastEditedBy,
                    SupplierCategoryID = @SupplierCategoryID,
                    SupplierReference = @SupplierReference,
                    PrimaryContactPersonID = @PrimaryContactPersonID,
                    AlternateContactPersonID = coalesce(@AlternateContactPersonID,@PrimaryContactPersonID),
                    DeliveryMethodID = @DeliveryMethodID,
                    PaymentDays = @PaymentDays,
                    PhoneNumber = @PhoneNumber,
                    FaxNumber = coalesce(@FaxNumber,N''),
                    WebsiteURL = coalesce(@WebsiteURL,N''),
                    BankAccountName = @BankAccountName,
                    BankAccountBranch = @BankAccountBranch,
                    BankAccountCode = @BankAccountCode,
                    BankAccountNumber = @BankAccountNumber,
                    BankInternationalCode = @BankInternationalCode,
                    DeliveryAddressLine1 = @DeliveryAddressLine1,
                    DeliveryAddressLine2 = @DeliveryAddressLine2,
                    DeliveryCityID = @DeliveryCityID,
                    DeliveryPostalCode = @DeliveryPostalCode,
                    PostalAddressLine1 = @PostalAddressLine1,
                    PostalAddressLine2 = @PostalAddressLine2,
                    PostalCityID = @PostalCityID,
                    PostalPostalCode = @PostalPostalCode,
                    DeliveryLocation = case when @Latitude is not null and @Longitude is not null
                                             then geography::Point(@Latitude, @Longitude, 4326)
                                             else DeliveryLocation end
                where SupplierID = @SupplierID

                if @@rowcount = 0
                    throw 52000, 'El proveedor indicado no existe.', 1
            commit transaction
            print 'Proveedor actualizado correctamente. SupplierID = ' + cast(@SupplierID as varchar(20)) + ' (' + @SupplierName + ')';
        end try
        begin catch
            if @@trancount > 0
                rollback transaction;
            ;throw;
        end catch
    end
go

/*
   Elimina un proveedor por su SupplierID. Solo permite la eliminación si el proveedor 
   no tiene productos, órdenes de compra ni otros registros relacionados (FK). Si no 
   existe, lanza error 52001; si hay violación de integridad referencial (error 547), 
   lanza error 52002 con un mensaje más claro. 
*/
create or alter procedure Purchasing.DeleteSupplier
    @SupplierID int
as
    begin
        set nocount on
        begin try
            begin transaction
                delete from Suppliers
                where SupplierID = @SupplierID

                if @@rowcount = 0
                    throw 52001, 'El proveedor indicado no existe.', 1
            commit transaction
            print 'Proveedor eliminado correctamente. SupplierID = ' + cast(@SupplierID as varchar(20));
        end try
        begin catch
            if @@trancount > 0
                rollback transaction
            if error_number() = 547
                throw 52002, 'No se puede eliminar el proveedor porque tiene productos, órdenes de compra u otros registros asociados.', 1
            else
                throw
        end catch
    end
go

/*
    Obtiene los productos (stock items) paginados, ordenados alfabéticamente por nombre.
    Si un producto pertenece a varios grupos, se concatenan sus nombres en una sola columna.
    Permite filtrar opcionalmente por nombre de producto y por grupo.
    Incluye el total de registros (TotalCount) para calcular la paginación en el cliente.
    Devuelve: StockItemID, NombreProducto, NombreGrupoProducto, CantidadTotalEnInventarios
*/
create or alter procedure Warehouse.GetStockItems
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
create or alter procedure Warehouse.GetStockGroups
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
create or alter procedure Sales.GetInvoices
    @InvoiceID int = null,
    @InvoiceDateFrom date = null,
    @InvoiceDateTo date = null,
    @CustomerName nvarchar(100) = null,
    @DeliveryMethodID int = null,
    @MinInvoiceAmount decimal(18, 2) = null,
    @MaxInvoiceAmount decimal(18, 2) = null,
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
