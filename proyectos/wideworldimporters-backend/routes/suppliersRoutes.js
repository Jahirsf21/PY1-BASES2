import { Router } from 'express'
import { listSuppliers } from '../controllers/suppliersController.js'

// Rutas de Proveedores.
const router = Router()

/**
 * GET /customers
 * Devuelve una página de Proveedores paginada.
 * Query params: pageNumber  y pageSize
 */
router.get('/suppliers', listSuppliers)

export default router