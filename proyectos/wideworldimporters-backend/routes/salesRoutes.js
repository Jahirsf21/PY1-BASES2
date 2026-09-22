import { Router } from 'express'
import { listInvoices } from '../controllers/salesController.js'

// Rutas de Ventas.
const router = Router()

/**
 * GET /sales
 * Devuelve una página de Ventas paginada.
 * Query params: pageNumber y pageSize
 */
router.get('/sales', listInvoices)

export default router