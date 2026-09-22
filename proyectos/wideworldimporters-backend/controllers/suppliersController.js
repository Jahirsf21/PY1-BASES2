import { paginatedResponse } from '../helpers/paginatedResponse.js'
import { getSuppliers } from '../services/suppliers.js'

/**
 * Obtiene una página de proveedores.
 *
 * Valida los parámetros de paginación recibidos por query string
 * (pageNumber y pageSize), llama al servicio y devuelve la
 * respuesta paginada con metadatos (total de registros y total de páginas).
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber y pageSize en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de proveedores.
 */
export async function listSuppliers(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({message: 'pageNumber y pageSize deben ser mayores a 0'})
        }
        if (pageSize > 100) {
            return res.status(400).json({message: 'pageSize no puede ser mayor a 100'})
        }
        const result = await getSuppliers(pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener proveedores'})
    }
}