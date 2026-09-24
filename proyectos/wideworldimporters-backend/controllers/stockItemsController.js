import { paginatedResponse } from '../helpers/paginatedResponse.js'
import { getStockItems } from '../services/stockItems.js'

/**
 * Obtiene una página de productos.
 * Permite filtrar opcionalmente por nombre de producto y grupo.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize, stockItemName y stockGroupID en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de productos.
 */
export async function listStockItems(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({message: 'pageNumber y pageSize deben ser mayores a 0'})
        }
        if (pageSize > 100) {
            return res.status(400).json({message: 'pageSize no puede ser mayor a 100'})
        }
        const stockItemName = req.query.stockItemName
        const stockGroupID = req.query.stockGroupID
        const result = await getStockItems(stockItemName, stockGroupID, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener productos'})
    }
}