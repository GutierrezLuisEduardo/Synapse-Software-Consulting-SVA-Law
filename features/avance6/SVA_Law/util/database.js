const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

pool.connect().then(() => {
        console.log('Conectado a Supabase PostgreSQL');
    }).catch((err) => {
        console.log('Error de conexión');
        console.log(err);
    });

module.exports = pool;