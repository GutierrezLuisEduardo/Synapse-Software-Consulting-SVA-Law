# Synapse-Software-Consulting---SVA-Law

## Convenciones del proyecto


### Estrategia de ramas

- `main`: rama principal estable
- `develop`: rama de integración de cambios
- `features`: ramas temporales para tareas específicas

Formato de ramas:

Ejemplos:

- victor/avance1
- luis/avance2


### Formato de commits

Tipos:

- feat: nueva funcionalidad
- fix: corrección de errores
- docs: documentación
- refactor: reorganización del código
- test: pruebas
- chore: mantenimiento

Ejemplos:

- feat: agrega página principal
- fix: corrige error en formulario
- docs: actualiza README


### Pull Requests

- No se permiten commits directos a main ni develop
- Todo cambio debe hacerse mediante Pull Request
- Las ramas personales se eliminan después del merge

En Synapse Software Consulting ofrecemos servicios de consultoría orientados al desarrollo de sistemas y bases de datos.


### Como correr el proyecto

Requisitos previos

- Node.js >= 18.x (recomendado 20.x LTS)
- npm >= 9.x
- Acceso a PostgreSQL (Supabase en este proyecto)
- Buckets de Supabase Storage para documentos y evidencias
- node -v
- npm -v

Generación de un archivo .env con los siguientes campos

- SESSION_SECRET (Secreto para encriptado, puede ser una frase)
- DATABASE_URL (URL de base de datos en supabas)
- SUPABASE_SERVICE_ROLE_KEY (Llave de rol de servicio)
- SUPABASE_URL (URL de proyecto en supabase)
- SUPABASE_BUCKET (Nombre de bucket en supabase para los documentos)
- SUPABASE_EVIDENCES_BUCKET (Nombre de bucket en supabase para las evidencias)

Los campos de SUPABASE y DATABASE deben ser seguidos de un = y el valor correspondiente a cada uno en supabase, mientras que el SESSION_SECRET puede ser cualquier frase.

Instalar dependencias

`npm install`
Esto instala: express, express-session, body-parser, ejs, pg, connect-pg-simple, @supabase/supabase-js, bcryptjs, multer, archiver, dotenv.


Arrancar
`npm start`
Equivale a `node index.js`. El servidor queda disponible en http://localhost:3000 (redirige a /login).
