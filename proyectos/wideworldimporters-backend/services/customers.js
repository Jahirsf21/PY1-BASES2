import {getPool} from '../config/database.js'
import sql from "mssql"

/**
 * Obtiene una página de clientes junto con el total de registros.
 * Permite filtrar opcionalmente por nombre de cliente, categoría y método de entrega.
 *
 * @param {string|null} customerName Nombre del cliente (búsqueda parcial) o null para no filtrar.
 * @param {number|null} customerCategoryID ID de la categoría del cliente o null para no filtrar.
 * @param {number|null} deliveryMethodID ID del método de entrega o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de clientes por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y clientes de la página.
 */
export async function getCustomers(customerName, customerCategoryID, deliveryMethodID, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('CustomerName', sql.NVarChar, customerName)
    connection.input('CustomerCategoryID', sql.Int, customerCategoryID)
    connection.input('DeliveryMethodID', sql.Int, deliveryMethodID)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Sales.GetCustomers')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}

/**
 * Obtiene una página de clientes (ID y nombre) para usar como "cliente por facturar" (BillToCustomerID).
 * Permite filtrar opcionalmente por nombre de cliente.
 *
 * @param {string|null} customerName Nombre del cliente (búsqueda parcial) o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de clientes por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y clientes de la página.
 */
export async function getBillToCustomers(customerName, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('CustomerName', sql.NVarChar, customerName)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Sales.GetBillToCustomers')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}

/**
 * Obtiene el detalle general de un cliente por su identificador.
 * Incluye nombre, categoría, grupo de compra, cliente por facturar,
 * método de entrega, días de gracia y sitio web.
 *
 * @param {number} customerID Identificador del cliente.
 * @returns {Promise<object>} Datos del cliente.
 */
export async function getCustomerDetail(customerID) {
    const connection = (await getPool()).request()
    connection.input('CustomerID', sql.Int, customerID)
    const result = await connection.execute('Sales.GetCustomerDetail')
    return result.recordset
}

/**
 * Obtiene los contactos (principal y alternativo) de un cliente por su identificador.
 * Devuelve nombre, teléfono, fax y correo de ambos contactos en una sola fila.
 *
 * @param {number} customerID Identificador del cliente.
 * @returns {Promise<object>} Datos de los contactos principal y alternativo.
 */
export async function getCustomerContacts(customerID) {
    const connection = (await getPool()).request()
    connection.input('CustomerID', sql.Int, customerID)
    const result = await connection.execute('Sales.GetCustomerContacts')
    return result.recordset
}

/**
 * Obtiene las direcciones de entrega y postal de un cliente,
 * junto con su ubicación geográfica (latitud/longitud).
 *
 * @param {number} customerID Identificador del cliente.
 * @returns {Promise<object>} Direcciones y coordenadas del cliente.
 */
export async function getCustomerAddress(customerID) {
    const connection = (await getPool()).request()
    connection.input('CustomerID', sql.Int, customerID)
    const result = await connection.execute('Sales.GetCustomerAddress')
    return result.recordset
}

/**
 * Obtiene todas las categorías de cliente ordenadas por su identificador.
 * Se usa para llenar el combo de filtros de la lista de clientes.
 *
 * @returns {Promise<object[]>} Listado de categorías de cliente.
 */
export async function getCustomerCategories() {
    const connection = (await getPool()).request()
    const result = await connection.execute('Sales.GetCustomerCategories')
    return result.recordset
}

/**
 * Obtiene todas las agrupaciones de compra (buying groups) ordenadas por su identificador.
 * Se usa para llenar el combo de buying group en el formulario de cliente.
 *
 * @returns {Promise<object[]>} Listado de buying groups.
 */
export async function getBuyingGroups() {
    const connection = (await getPool()).request()
    const result = await connection.execute('Sales.GetBuyingGroups')
    return result.recordset
}


