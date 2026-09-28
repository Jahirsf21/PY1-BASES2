import {getPool} from '../config/database.js'
import sql from "mssql"

/**
 * Obtiene una página de proveedores junto con el total de registros.
 * Permite filtrar opcionalmente por nombre de proveedor, categoría y método de entrega.
 *
 * @param {string|null} supplierName Nombre del proveedor (búsqueda parcial) o null para no filtrar.
 * @param {number|null} supplierCategoryID ID de la categoría del proveedor o null para no filtrar.
 * @param {number|null} deliveryMethodID ID del método de entrega o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de proveedores por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y proveedores de la página.
 */
export async function getSuppliers(supplierName, supplierCategoryID, deliveryMethodID, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('SupplierName', sql.NVarChar, supplierName)
    connection.input('SupplierCategoryID', sql.Int, supplierCategoryID)
    connection.input('DeliveryMethodID', sql.Int, deliveryMethodID)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Purchasing.GetSuppliers')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}

/**
 * Obtiene todas las categorías de proveedor ordenadas por su identificador.
 * Se usa para llenar el combo de filtros de la lista de proveedores.
 *
 * @returns {Promise<object[]>} Listado de categorías de proveedor.
 */
export async function getSupplierCategories() {
    const connection = (await getPool()).request()
    const result = await connection.execute('Purchasing.GetSupplierCategories')
    return result.recordset
}