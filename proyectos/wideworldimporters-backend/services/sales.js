import {getPool} from '../config/database.js'
import sql from "mssql"

/**
 * Obtiene una página de facturas junto con el total de registros.
 * Permite filtrar opcionalmente por número de factura, rango de fechas, nombre de cliente, método de entrega y rango de monto facturado.
 *
 * @param {number|null} invoiceID Número de factura o null para no filtrar.
 * @param {string|null} invoiceDateFrom Fecha desde (YYYY-MM-DD) o null para no filtrar.
 * @param {string|null} invoiceDateTo Fecha hasta (YYYY-MM-DD) o null para no filtrar.
 * @param {string|null} customerName Nombre del cliente (búsqueda parcial) o null para no filtrar.
 * @param {number|null} deliveryMethodID ID del método de entrega o null para no filtrar.
 * @param {number|null} minInvoiceAmount Monto mínimo o null para no filtrar.
 * @param {number|null} maxInvoiceAmount Monto máximo o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de facturas por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y facturas de la página.
 */
export async function getInvoices(invoiceID, invoiceDateFrom, invoiceDateTo, customerName, deliveryMethodID, minInvoiceAmount, maxInvoiceAmount, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('InvoiceID', sql.Int, invoiceID)
    connection.input('InvoiceDateFrom', sql.Date, invoiceDateFrom)
    connection.input('InvoiceDateTo', sql.Date, invoiceDateTo)
    connection.input('CustomerName', sql.NVarChar, customerName)
    connection.input('DeliveryMethodID', sql.Int, deliveryMethodID)
    connection.input('MinInvoiceAmount', sql.Decimal(18, 2), minInvoiceAmount)
    connection.input('MaxInvoiceAmount', sql.Decimal(18, 2), maxInvoiceAmount)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Sales.GetInvoices')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}
