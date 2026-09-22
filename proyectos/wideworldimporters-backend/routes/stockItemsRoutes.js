import { Router } from 'express'
import { listStockItems } from '../controllers/stockItemsController.js'

// Rutas de Productos.
const router = Router()

/**
 * GET /stockItems
 * Devuelve una página de Productos paginada.
 * Query params: pageNumber y pageSize
 */
router.get('/stockItems', listStockItems)

export default router