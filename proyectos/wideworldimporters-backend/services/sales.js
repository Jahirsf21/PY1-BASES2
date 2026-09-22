import {getPool} from '../config/database.js'
import sql from "mssql"

/**
 * Obtiene una página de ventas junto con el total de registros.
 *
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de ventas por página.
 * @returns {Promise<object[]>} Ventas devueltos por el procedimiento almacenado.
 */
export async function getInvoices(pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Sales.GetInvoices')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}
