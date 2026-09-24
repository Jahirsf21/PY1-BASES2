import { Router } from 'express'
import { listSuppliers, listSupplierCategories } from '../controllers/suppliersController.js'

// Rutas de Proveedores.
const router = Router()

/**
 * GET /suppliers
 * Devuelve una página de proveedores paginada.
 * Query params: pageNumber, pageSize, supplierName, supplierCategoryID, deliveryMethodID
 */
router.get('/suppliers', listSuppliers)

/**
 * GET /suppliers/categories
 * Devuelve todas las categorías de proveedor para el combo de filtros.
 */
router.get('/suppliers/categories', listSupplierCategories)

export default router