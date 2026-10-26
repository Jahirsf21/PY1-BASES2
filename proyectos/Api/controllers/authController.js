import { validateLogin } from '../helpers/entityValidation.js'
import { loginUser } from '../services/auth.js'

/**
 * Comprueba las credenciales de un usuario activo.
 *
 * @param {import('express').Request} req Petición HTTP con userName y password en req.body.
 * @param {import('express').Response} res Respuesta HTTP.
 * @returns {Promise<import('express').Response>} Datos del usuario o 401 si las credenciales no son válidas.
 */
export async function login(req, res) {
    const credentials = req.body
    if (!credentials || typeof credentials !== 'object' || Array.isArray(credentials)) {
        return res.status(400).json({message: 'Indique los datos de inicio de sesión'})
    }
    const {fields, errors} = validateLogin(credentials)
    if (fields.length > 0) {
        return res.status(400).json({message: errors[fields[0]], fields, errors})
    }
    try {
        const users = await loginUser(credentials.userName, credentials.password)
        if (users.length === 0) {
            return res.status(401).json({message: 'Credenciales inválidas'})
        }
        return res.json(users[0])
    } catch (error) {
        return res.status(500).json({message: 'Error al iniciar sesión'})
    }
}
