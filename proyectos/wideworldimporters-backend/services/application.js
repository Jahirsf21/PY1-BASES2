import {getPool} from '../config/database.js'
import sql from "mssql"

/**
 * Obtiene una página de personas, opcionalmente filtradas por nombre.
 *
 * @param {string|null} fullName Nombre completo (búsqueda parcial) o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de personas por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y personas de la página.
 */
export async function getPeople(fullName, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('FullName', sql.NVarChar, fullName)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Application.GetPeople')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}

/**
 * Obtiene una página de ciudades, opcionalmente filtradas por nombre de ciudad,
 * provincia y país.
 *
 * @param {string|null} cityName Nombre de ciudad (búsqueda parcial) o null para no filtrar.
 * @param {string|null} provinceName Nombre de provincia (búsqueda parcial) o null para no filtrar.
 * @param {string|null} countryName Nombre de país (búsqueda parcial) o null para no filtrar.
 * @param {number} pageNumber Número de página solicitado.
 * @param {number} pageSize Cantidad de ciudades por página.
 * @returns {Promise<{totalCount: number, data: object[]}>} Total de registros y ciudades de la página.
 */
export async function getCities(cityName, provinceName, countryName, pageNumber, pageSize) {
    const connection = (await getPool()).request()
    connection.input('CityName', sql.NVarChar, cityName)
    connection.input('ProvinceName', sql.NVarChar, provinceName)
    connection.input('CountryName', sql.NVarChar, countryName)
    connection.input('PageNumber', sql.Int, pageNumber)
    connection.input('PageSize', sql.Int, pageSize)
    connection.output('TotalCount', sql.Int)
    const result = await connection.execute('Application.GetCities')
    return {
        totalCount: result.output.TotalCount,
        data: result.recordset
    }
}

/**
 * Obtiene todos los métodos de entrega.
 * Se usa para llenar los combos de filtros y formularios de clientes y proveedores.
 *
 * @returns {Promise<object[]>} Listado de métodos de entrega.
 */
export async function getDeliveryMethods() {
    const connection = (await getPool()).request()
    const result = await connection.execute('Application.GetDeliveryMethods')
    return result.recordset
}