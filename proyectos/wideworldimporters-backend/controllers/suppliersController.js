import { paginatedResponse } from '../helpers/paginatedResponse.js'
import { getSupplierCategories, getSuppliers } from '../services/suppliers.js'

/**
 * Obtiene una página de proveedores.
 * Permite filtrar opcionalmente por nombre, categoría y método de entrega.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize, supplierName, supplierCategoryID y deliveryMethodID en req.query.
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
        const supplierName = req.query.supplierName
        const supplierCategoryID = req.query.supplierCategoryID
        const deliveryMethodID = req.query.deliveryMethodID
        const result = await getSuppliers(supplierName, supplierCategoryID, deliveryMethodID, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener proveedores'})
    }
}

/**
 * Obtiene todas las categorías de proveedor.
 * Se usa para llenar el combo de filtros de la lista de proveedores.
 *
 * @param {import('express').Request} req Petición HTTP.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con las categorías de proveedor.
 */
export async function listSupplierCategories(req, res) {
    try {
        const categories = await getSupplierCategories()
        return res.json(categories)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener categorías de proveedor'})
    }
}