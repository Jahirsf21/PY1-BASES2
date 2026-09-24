import {getPool} from '../config/database.js'
import sql from "mssql"

/**
 * Obtiene una página de productos junto con el total de registros.
 * Permite filtrar opcionalmente por nombre de producto y grupo.
 *
 * @param {string|null} stockItemName Nombre del producto (búsqueda parcial) o null para no filtrar.
 * @param {number|null} stockGroupID  ID del grupo de productos o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de productos por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y productos de la página.
 */
export async function getStockItems(stockItemName, stockGroupID, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('StockItemName', sql.Int, stockItemName)
    connection.input('StockGroupID', sql.Int, stockGroupID)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Warehouse.GetStockItems')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}

/**
 * Obtiene todos los grupos de productos.
 *
 * @returns {Promise<object[]>} Listado de grupos de productos.
 */
export async function getStockGroups() {
    const connection = (await getPool()).request()
    const result = await connection.execute('Warehouse.GetStockGroups')
    return result.recordset
}