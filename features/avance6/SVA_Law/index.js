require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const path = require('path');
const sessionConfig = require('./config/session');
const authRoutes = require('./routes/auth.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const userRoutes = require('./routes/user.routes');
const app = express();
const PORT = process.env.PORT;

app.set('view engine','ejs');
app.set('views','views');

app.use(bodyParser.urlencoded({
        extended: false
    })
);

app.use(express.static(path.join(__dirname,'public')));

app.use(session(sessionConfig));

app.use(authRoutes);
app.use(dashboardRoutes);
app.use(userRoutes);

app.listen(PORT, () => {
    console.log('Servidor corriendo correctamente');
});