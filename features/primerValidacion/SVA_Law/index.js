require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const path = require('path');
const sessionConfig = require('./config/session');
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const clienteRoutes = require('./routes/cliente.routes');
const sofomRoutes = require('./routes/sofom.routes');
const { warmCatalogos } = require('./controllers/cliente.controller');

// Warm catalogue cache BEFORE opening the server to traffic
warmCatalogos()
    .then(() => {
        app.listen(PORT, () => {
            console.log(`Servidor corriendo en el puerto ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Error precargando catálogos:', err.message);
        // Start anyway — getCatalogos() will retry on first request
        app.listen(PORT, () => {
            console.log(`Servidor corriendo en el puerto ${PORT} (sin caché)`);
        });
    });

const app = express();
const PORT = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.set('views', 'views');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
app.use(session(sessionConfig));

app.use(authRoutes);
app.use(userRoutes);
app.use(clienteRoutes);
app.use(sofomRoutes);

app.listen(PORT, () => {
    console.log(`Servidor corriendo en el puerto ${PORT}`);
    warmCatalogos();
});