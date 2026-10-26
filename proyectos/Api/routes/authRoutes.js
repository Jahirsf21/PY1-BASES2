import { Router } from 'express'
import { login } from '../controllers/authController.js'

// Rutas de autenticación.
const router = Router()

/**
 * POST /auth/login
 * Comprueba las credenciales y devuelve los datos del usuario activo.
 * Body: userName, password
 */
router.post('/auth/login', login)

export default router
