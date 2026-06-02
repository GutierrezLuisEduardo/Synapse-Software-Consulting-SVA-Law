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
const operacionRoutes = require('./routes/operacion.routes');
const alertaRoutes = require('./routes/alerta.routes');
const documentoRoutes = require('./routes/documento.routes');
const noAuditor = require('./middleware/no-auditor');
const contratoRoutes = require('./routes/contrato.routes');
const { warmCatalogos } = require('./controllers/cliente.controller');
const { warmCatalogosOperacion } = require('./controllers/operacion.controller');
const listaRiesgoRoutes = require('./routes/listaRiesgo.routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.set('views', 'views');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));
app.use(session(sessionConfig));

app.use(authRoutes);
app.use(noAuditor);
app.use(userRoutes);
app.use(clienteRoutes);
app.use(sofomRoutes);
app.use(operacionRoutes);
app.use(alertaRoutes);
app.use(documentoRoutes);
app.use(contratoRoutes);
app.use(listaRiesgoRoutes);

app.get('/', (req, res) => {
    res.redirect('/login');
});

warmCatalogos()
    .then(() => {
        app.listen(PORT, () => {
            console.log(`Servidor corriendo en el puerto ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Error precargando catálogos:', err.message);
        app.listen(PORT, () => {
            console.log(`Servidor corriendo en el puerto ${PORT} (sin caché)`);
        });
    });

warmCatalogosOperacion();
