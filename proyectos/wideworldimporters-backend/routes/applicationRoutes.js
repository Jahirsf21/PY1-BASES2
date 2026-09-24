import { Router } from 'express'
import { listPeople, listCities, listDeliveryMethods } from '../controllers/applicationController.js'

// Rutas de Application (datos de referencia compartidos).
const router = Router()

/**
 * GET /people
 * Devuelve una página de personas paginada.
 * Query params: pageNumber, pageSize, fullName
 */
router.get('/people', listPeople)

/**
 * GET /cities
 * Devuelve una página de ciudades paginada.
 * Query params: pageNumber, pageSize, cityName, provinceName, countryName
 */
router.get('/cities', listCities)

/**
 * GET /delivery-methods
 * Devuelve todos los métodos de entrega para los combos de filtros.
 */
router.get('/delivery-methods', listDeliveryMethods)

export default router