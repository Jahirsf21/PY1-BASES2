import { Router } from 'express'
import { listCustomers } from '../controllers/customersController.js'

// Rutas de clientes.
const router = Router()

/**
 * GET /customers
 * Devuelve una página de clientes paginada.
 * Query params: pageNumber  y pageSize
 */
router.get('/customers', listCustomers)

export default router