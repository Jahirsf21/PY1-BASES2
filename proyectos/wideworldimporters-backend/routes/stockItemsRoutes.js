import { Router } from 'express'
import { listStockItems } from '../controllers/stockItemsController.js'

// Rutas de Productos.
const router = Router()

/**
 * GET /stock-items
 * Devuelve una página de productos paginada.
 * Query params: pageNumber, pageSize, stockItemName, stockGroupID
 */
router.get('/stockItems', listStockItems)

export default router