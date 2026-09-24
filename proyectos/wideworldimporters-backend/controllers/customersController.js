import { paginatedResponse } from '../helpers/paginatedResponse.js'
import { getBillToCustomers, getBuyingGroups, getCustomerAddress, getCustomerCategories, getCustomerContacts, getCustomerDetail, getCustomers } from '../services/customers.js'

/**
 * Obtiene una página de clientes.
 * Permite filtrar opcionalmente por nombre, categoría y método de entrega.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize, customerName, customerCategoryID y deliveryMethodID en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de clientes.
 */
export async function listCustomers(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({message: 'pageNumber y pageSize deben ser mayores a 0'})
        }
        if (pageSize > 100) {
            return res.status(400).json({message: 'pageSize no puede ser mayor a 100'})
        }
        const customerName = req.query.customerName
        const customerCategoryID = req.query.customerCategoryID
        const deliveryMethodID = req.query.deliveryMethodID
        const result = await getCustomers(customerName, customerCategoryID, deliveryMethodID, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener clientes'})
    }
}

/**
 * Obtiene una página de clientes (ID y nombre) para usar como "cliente por facturar" (BillToCustomerID).
 * Permite filtrar opcionalmente por nombre de cliente.
 *
 * @param {import('express').Request} req Petición HTTP. Espera pageNumber, pageSize y customerName en req.query.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con la página de clientes.
 */
export async function listBillToCustomers(req, res) {
    try {
        const pageNumber = parseInt(req.query.pageNumber, 10)
        const pageSize = parseInt(req.query.pageSize, 10)
        if (pageNumber < 1 || pageSize < 1) {
            return res.status(400).json({message: 'pageNumber y pageSize deben ser mayores a 0'})
        }
        if (pageSize > 100) {
            return res.status(400).json({message: 'pageSize no puede ser mayor a 100'})
        }
        const customerName = req.query.customerName
        const result = await getBillToCustomers(customerName, pageNumber, pageSize)
        return paginatedResponse(res, pageNumber, pageSize, result)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener clientes para facturar'})
    }
}

/**
 * Obtiene todas las categorías de cliente.
 * Se usa para llenar el combo de filtros de la lista de clientes.
 *
 * @param {import('express').Request} req Petición HTTP.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con las categorías.
 */
export async function listCustomerCategories(req, res) {
    try {
        const categories = await getCustomerCategories()
        return res.json(categories)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener categorías de cliente'})
    }
}

/**
 * Obtiene todas las agrupaciones de compra (buying groups).
 * Se usa para llenar el combo de buying group en el formulario de cliente.
 *
 * @param {import('express').Request} req Petición HTTP.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con los buying groups.
 */
export async function listBuyingGroups(req, res) {
    try {
        const groups = await getBuyingGroups()
        return res.json(groups)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener los grupos de compra'})
    }
}

/**
 * Obtiene el detalle general de un cliente por su identificador.
 * Incluye nombre, categoría, grupo de compra, cliente por facturar,
 * método de entrega, días de gracia y sitio web.
 *
 * @param {import('express').Request} req Petición HTTP. Espera customerID en req.params.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con el detalle del cliente.
 */
export async function getCustomerById(req, res) {
    try {
        const customerID = parseInt(req.params.customerID, 10)
        const customer = await getCustomerDetail(customerID)
        if (!customer) {
            return res.status(404).json({message: 'Cliente no encontrado'})
        }
        return res.json(customer)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener al cliente'})
    }
}

/**
 * Obtiene los contactos (principal y alternativo) de un cliente por su identificador.
 * Devuelve nombre, teléfono, fax y correo de ambos contactos.
 *
 * @param {import('express').Request} req Petición HTTP. Espera customerID en req.params.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con los contactos del cliente.
 */
export async function getCustomerContactsById(req, res) {
    try {
        const customerID = parseInt(req.params.customerID, 10)
        const contacts = await getCustomerContacts(customerID)
        if (!contacts) {
            return res.status(404).json({message: 'Contactos no encontrados'})
        }
        return res.json(contacts)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener los contactos del cliente'})
    }
}

/**
 * Obtiene las direcciones de entrega y postal de un cliente,
 * junto con su ubicación geográfica (latitud/longitud).
 *
 * @param {import('express').Request} req Petición HTTP. Espera customerID en req.params.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Respuesta JSON con las direcciones del cliente.
 */
export async function getCustomerAddressById(req, res) {
    try {
        const customerID = parseInt(req.params.customerID, 10)
        const address = await getCustomerAddress(customerID)
        if (!address) {
            return res.status(404).json({message: 'Direccion no encontrada'})
        }
        return res.json(address)
    } catch (error) {
        res.status(500).json({message: 'Error al obtener la dirección del cliente'})
    }
}