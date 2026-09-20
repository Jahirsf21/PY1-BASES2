import express from 'express'
import cors from 'cors'
import {env} from './config/env.js'

const app = express()
app.use(cors({origin:`http://localhost:${env.APP_PORT}`}), express.json())


app.use((error, req, res, next) => {
    console.error(error)
    res.status(500).json({message: 'Error interno del servidor.'})
})

app.listen(env.API_PORT, ()=>{
    console.log(`app listening at http://localhost:${env.API_PORT}`)
})