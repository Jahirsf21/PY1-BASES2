import { Router } from 'express'
import { listInvoices } from '../controllers/salesController.js'

// Rutas de Ventas (facturas).
const router = Router()

/**
 * GET /sales
 * Devuelve una página de facturas (módulo de ventas) paginada.
 * Query params: pageNumber, pageSize, invoiceID, invoiceDateFrom, invoiceDateTo, customerName, deliveryMethodID, minInvoiceAmount, maxInvoiceAmount
 */
router.get('/sales', listInvoices)

export default router