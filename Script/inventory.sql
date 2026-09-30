use WideWorldImporters;
go
if db_name() <> N'WideWorldImporters' throw 50000, N'Base incorrecta', 1;
go

-- ======================================================================================
-- INVENTARIO (PRODUCTOS)
-- ======================================================================================

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
    Obtiene el detalle general de un producto: proveedor, color, empaques, marca, talla, precios, peso, palabras clave,
    cantidad disponible y ubicación en bodega.
    Devuelve: stockItemID, nombreProducto, nombreProveedor, color, unidadEmpaquetamiento, empaquetamiento, cantidadEmpaquetamiento,
    marca, talla, impuesto, precioUnitario, precioVenta, peso, palabrasClave, cantidadDisponible, ubicacion
*/
create or alter procedure Warehouse.GetStockItemDetail
    @StockItemID int
as
    begin
        set nocount on
        select
            si.StockItemID,
            si.StockItemName as NombreProducto,
            sp.SupplierName as NombreProveedor,
            co.ColorName as Color,
            pu.PackageTypeName as UnidadEmpaquetamiento,
            po.PackageTypeName as Empaquetamiento,
            si.QuantityPerOuter as CantidadEmpaquetamiento,
            si.Brand as Marca,
            si.Size as Talla,
            si.TaxRate as Impuesto,
            si.UnitPrice as PrecioUnitario,
            si.RecommendedRetailPrice as PrecioVenta,
            si.TypicalWeightPerUnit as Peso,
            si.SearchDetails as PalabrasClave,
            sih.QuantityOnHand as CantidadDisponible,
            sih.BinLocation as Ubicacion
        from StockItems si
        inner join Suppliers sp on si.SupplierID = sp.SupplierID
        left join Colors co on si.ColorID = co.ColorID
        inner join PackageTypes pu on si.UnitPackageID = pu.PackageTypeID
        inner join PackageTypes po on si.OuterPackageID = po.PackageTypeID
        inner join StockItemHoldings sih on si.StockItemID = sih.StockItemID
        where si.StockItemID = @StockItemID
    end
go

/*
    Obtiene todos los grupos asociados a un producto mediante StockItemStockGroups.
    Devuelve: StockGroupID, NombreGrupoProducto.
*/
create or alter procedure Warehouse.GetStockItemStockGroups
    @StockItemID int
as
    begin
        set nocount on
        select
            sg.StockGroupID,
            sg.StockGroupName as NombreGrupoProducto
        from StockItemStockGroups sig
        inner join StockGroups sg on sg.StockGroupID = sig.StockGroupID
        where sig.StockItemID = @StockItemID
    end
go

/* Obtiene los valores editables del producto */
create or alter procedure Warehouse.GetStockItemForEdit
    @StockItemID int
as
    begin
        set nocount on
        select
            si.StockItemID,
            si.StockItemName,
            si.SupplierID,
            sp.SupplierName,
            si.LastEditedBy,
            si.LeadTimeDays,
            si.IsChillerStock,
            si.ColorID,
            co.ColorName,
            si.UnitPackageID,
            pu.PackageTypeName as UnitPackageName,
            si.OuterPackageID,
            po.PackageTypeName as OuterPackageName,
            si.Brand,
            si.Size,
            si.QuantityPerOuter,
            si.Barcode,
            si.TaxRate,
            si.UnitPrice,
            si.RecommendedRetailPrice,
            si.TypicalWeightPerUnit,
            sih.LastCostPrice,
            sih.ReorderLevel,
            sih.TargetStockLevel,
            sih.QuantityOnHand,
            sih.BinLocation
        from StockItems si
        inner join Suppliers sp on sp.SupplierID = si.SupplierID
        left join Colors co on co.ColorID = si.ColorID
        inner join PackageTypes pu on pu.PackageTypeID = si.UnitPackageID
        inner join PackageTypes po on po.PackageTypeID = si.OuterPackageID
        inner join StockItemHoldings sih on sih.StockItemID = si.StockItemID
        where si.StockItemID = @StockItemID
    end
go

/*
    Obtiene los colores disponibles para asignar a un producto.
    Devuelve: ColorID, ColorName.
*/
create or alter procedure Warehouse.GetColors
as
    begin
        set nocount on
        select
            ColorID,
            ColorName
        from Colors
    end
go

/*
    Obtiene los tipos de empaque disponibles para asignar a un producto.
    Devuelve: PackageTypeID, PackageTypeName.
*/
create or alter procedure Warehouse.GetPackageTypes
as
    begin
        set nocount on
        select
            PackageTypeID,
            PackageTypeName
        from PackageTypes
    end
go

/*
   Inserta un nuevo producto en las tablas StockItems, StockItemHoldings y
   StockItemStockGroups. Recibe datos generales, existencias iniciales y grupos del
   producto; devuelve el StockItemID generado a través de @NewStockItemID.
*/
create or alter procedure Warehouse.InsertStockItem
    @StockItemName nvarchar(100),
    @SupplierID int,
    @LastEditedBy int,
    @LeadTimeDays int = 1,
    @IsChillerStock bit = 0,
    @LastCostPrice decimal(18,2) = 0,
    @ReorderLevel int = 0,
    @TargetStockLevel int = 0,
    @ColorID int = null,
    @UnitPackageID int,
    @OuterPackageID int,
    @Brand nvarchar(50) = null,
    @Size nvarchar(20) = null,
    @QuantityPerOuter int = 1,
    @Barcode nvarchar(50) = null,
    @TaxRate decimal(18, 3),
    @UnitPrice decimal(18, 2),
    @RecommendedRetailPrice decimal(18, 2) = null,
    @TypicalWeightPerUnit decimal(18, 3) = null,
    @StockGroupIDsJson nvarchar(max),
    @QuantityOnHand int = 0,
    @BinLocation nvarchar(20) = null,
    @NewStockItemID int output
as
    begin
        set nocount on
        begin try
            begin transaction
                declare @InsertedIDs table (StockItemID int)
                insert into StockItems (
                    StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID,
                    Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode,
                    TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, LastEditedBy
                )
                output inserted.StockItemID into @InsertedIDs
                values (
                    @StockItemName, @SupplierID, @ColorID, @UnitPackageID, @OuterPackageID,
                    @Brand, @Size, @LeadTimeDays, @QuantityPerOuter, @IsChillerStock, @Barcode,
                    @TaxRate, @UnitPrice, @RecommendedRetailPrice, coalesce(@TypicalWeightPerUnit,0), @LastEditedBy
                )
                select @NewStockItemID = StockItemID from @InsertedIDs
                insert into StockItemHoldings
                    (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
                     LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy)
                values (@NewStockItemID, @QuantityOnHand, coalesce(@BinLocation,N''), 0,
                        @LastCostPrice, @ReorderLevel, @TargetStockLevel, @LastEditedBy)
                insert into StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy)
                select @NewStockItemID, g.[value], @LastEditedBy
                from openjson(@StockGroupIDsJson) g
            commit transaction
            print 'Producto insertado correctamente. Nuevo StockItemID = ' + cast(@NewStockItemID as varchar(20)) + ' (' + @StockItemName + ')';
        end try
        begin catch
            if @@trancount > 0
                rollback transaction;
            ;throw;
        end catch
    end
go

/*
   Actualiza un producto existente en StockItems, StockItemHoldings y
   StockItemStockGroups. Si el producto no existe, lanza error 53000. Los grupos del
   producto se reemplazan por los recibidos en @StockGroupIDsJson.

*/
create or alter procedure Warehouse.UpdateStockItem
    @StockItemID int,
    @StockItemName nvarchar(100),
    @SupplierID int,
    @LastEditedBy int,
    @LeadTimeDays int = 1,
    @IsChillerStock bit = 0,
    @LastCostPrice decimal(18,2) = 0,
    @ReorderLevel int = 0,
    @TargetStockLevel int = 0,
    @ColorID int = null,
    @UnitPackageID int,
    @OuterPackageID int,
    @Brand nvarchar(50) = null,
    @Size nvarchar(20) = null,
    @QuantityPerOuter int = 1,
    @Barcode nvarchar(50) = null,
    @TaxRate decimal(18, 3),
    @UnitPrice decimal(18, 2),
    @RecommendedRetailPrice decimal(18, 2) = null,
    @TypicalWeightPerUnit decimal(18, 3) = null,
    @StockGroupIDsJson nvarchar(max),
    @QuantityOnHand int,
    @BinLocation nvarchar(20) = null
as
    begin
        set nocount on
        begin try
            begin transaction
                update StockItems
                set
                    StockItemName = @StockItemName,
                    LeadTimeDays = @LeadTimeDays,
                    IsChillerStock = @IsChillerStock,
                    LastEditedBy = @LastEditedBy,
                    SupplierID = @SupplierID,
                    ColorID = @ColorID,
                    UnitPackageID = @UnitPackageID,
                    OuterPackageID = @OuterPackageID,
                    Brand = @Brand,
                    Size = @Size,
                    QuantityPerOuter = @QuantityPerOuter,
                    Barcode = @Barcode,
                    TaxRate = @TaxRate,
                    UnitPrice = @UnitPrice,
                    RecommendedRetailPrice = @RecommendedRetailPrice,
                    TypicalWeightPerUnit = coalesce(@TypicalWeightPerUnit,0)
                where StockItemID = @StockItemID
                if @@rowcount = 0
                    throw 53000, 'El producto indicado no existe.', 1
                update StockItemHoldings
                set QuantityOnHand = @QuantityOnHand,
                    BinLocation = coalesce(@BinLocation,N''),
                    LastCostPrice = @LastCostPrice,
                    ReorderLevel = @ReorderLevel,
                    TargetStockLevel = @TargetStockLevel,
                    LastEditedBy = @LastEditedBy
                where StockItemID = @StockItemID
                if @@rowcount = 0
                    insert into StockItemHoldings
                        (StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
                         LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy)
                    values (@StockItemID, @QuantityOnHand, coalesce(@BinLocation,N''), 0,
                            @LastCostPrice, @ReorderLevel, @TargetStockLevel, @LastEditedBy)
                delete from StockItemStockGroups
                where StockItemID = @StockItemID

                insert into StockItemStockGroups (StockItemID, StockGroupID, LastEditedBy)
                select @StockItemID, g.[value], @LastEditedBy
                from openjson(@StockGroupIDsJson) g
            commit transaction
            print 'Producto actualizado correctamente. StockItemID = ' + cast(@StockItemID as varchar(20)) + ' (' + @StockItemName + ')';
        end try
        begin catch
            if @@trancount > 0
                rollback transaction;
            ;throw;
        end catch
    end
go

/*
   Elimina un producto por su StockItemID, borrando primero las tablas dependientes
   (StockItemStockGroups y StockItemHoldings) y luego StockItems. Si no existe, lanza
   error 53001; si hay violación de integridad referencial (error 547), lanza error
   53002 con un mensaje más claro.
*/
create or alter procedure Warehouse.DeleteStockItem
    @StockItemID int
as
    begin
        set nocount on
        begin try
            begin transaction
                delete from StockItemStockGroups
                where StockItemID = @StockItemID

                delete from StockItemHoldings
                where StockItemID = @StockItemID

                delete from StockItems
                where StockItemID = @StockItemID

                if @@rowcount = 0
                    throw 53001, 'El producto indicado no existe.', 1
            commit transaction
            print 'Producto eliminado correctamente. StockItemID = ' + cast(@StockItemID as varchar(20));
        end try
        begin catch
            if @@trancount > 0
                rollback transaction
            if error_number() = 547
                throw 53002, 'No se puede eliminar el producto porque tiene ventas u órdenes de compra asociadas.', 1
            else
                throw
        end catch
    end
go
