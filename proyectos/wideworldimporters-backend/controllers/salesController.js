import { paginatedResponse } from '../helpers/paginatedResponse.js'
import { getInvoices } from '../services/sales.js'

/**
 * Obtiene una página de facturas.
 * Permite filtrar opcionalmente por número de factura, rango de fechas, nombre de cliente, método de entrega y rango de monto.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize, invoiceID, invoiceDateFrom, invoiceDateTo, customerName, deliveryMethodID, minInvoiceAmount y maxInvoiceAmount en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de facturas.
 */
export async function listInvoices(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({message: 'pageNumber y pageSize deben ser mayores a 0'})
        }
        if (pageSize > 100) {
            return res.status(400).json({message: 'pageSize no puede ser mayor a 100'})
        }
        const invoiceID = req.query.invoiceID
        const invoiceDateFrom = req.query.invoiceDateFrom
        const invoiceDateTo = req.query.invoiceDateTo
        const customerName = req.query.customerName
        const deliveryMethodID = req.query.deliveryMethodID
        const minInvoiceAmount = req.query.minInvoiceAmount
        const maxInvoiceAmount = req.query.maxInvoiceAmount
        const result = await getInvoices(invoiceID, invoiceDateFrom, invoiceDateTo, customerName, deliveryMethodID, minInvoiceAmount, maxInvoiceAmount, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener facturas'})
    }
}