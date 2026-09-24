import { Router } from 'express'
import { listStockItems, listStockGroups } from '../controllers/stockItemsController.js'

// Rutas de Productos.
const router = Router()

/**
 * GET /stock-items
 * Devuelve una página de productos paginada.
 * Query params: pageNumber, pageSize, stockItemName, stockGroupID
 */
router.get('/stock-items', listStockItems)

/**
 * GET /stock-items/groups
 * Devuelve todos los grupos de productos para el combo de filtros.
 */
router.get('/stock-items/groups', listStockGroups)

export default router