import { paginatedResponse } from '../helpers/paginatedResponse.js'
import { getPeople, getCities, getDeliveryMethods } from '../services/application.js'

/**
 * Obtiene una página de personas, opcionalmente filtradas por nombre.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize y fullName en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de personas.
 */
export async function listPeople(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({ message: 'pageNumber y pageSize deben ser mayores a 0' })
        }
        if (pageSize > 100) {
            return res.status(400).json({ message: 'pageSize no puede ser mayor a 100' })
        }

        const fullName = req.query.fullName
        const result = await getPeople(fullName, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener personas' })
    }
}

/**
 * Obtiene una página de ciudades, opcionalmente filtradas por nombre de ciudad, provincia y país.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize, cityName, provinceName y countryName en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de ciudades.
 */
export async function listCities(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({ message: 'pageNumber y pageSize deben ser mayores a 0' })
        }
        if (pageSize > 100) {
            return res.status(400).json({ message: 'pageSize no puede ser mayor a 100' })
        }
        const cityName = req.query.cityName
        const provinceName = req.query.provinceName
        const countryName = req.query.countryName
        const result = await getCities(cityName, provinceName, countryName, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener ciudades' })
    }
}

/**
 * Obtiene todos los métodos de entrega.
 * Se usa para llenar los combos de filtros y formularios de clientes y proveedores.
 *
 * @param {import('express').Request} req Petición HTTP.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con los métodos de entrega.
 */
export async function listDeliveryMethods(req, res) {
    try {
        const methods = await getDeliveryMethods()
        return res.json(methods)
    } catch (error) {
        res.status(500).json({ message: 'Error al obtener los métodos de entrega' })
    }
}