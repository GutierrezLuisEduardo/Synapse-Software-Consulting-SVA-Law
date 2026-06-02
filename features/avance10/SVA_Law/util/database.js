const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
});

pool.connect()
    .then(client => {
        console.log('Conectado a PostgreSQL');
        client.release();
    })
    .catch(err => console.error('Error de conexión:', err.message));
    
module.exports = pool;