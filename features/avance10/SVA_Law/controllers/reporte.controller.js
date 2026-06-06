const Reporte  = require('../models/reporte.model');
const ROLES    = require('../config/roles');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

const EVIDENCIAS_BUCKET = process.env.SUPABASE_EVIDENCES_BUCKET || 'evidencias';

// Roles que pueden crear un ROIP
const ROLES_ROIP = [ROLES.OFICIAL, ROLES.ADMIN, ROLES.EMPLEADO];

// GET reportes/crear, muestra formulario de creación de ROIP
exports.getCrearROIP = async (req, res) => {
    try {
        const tipoResult = await Reporte.fetchTipoROIP();
        const tipoROIP   = tipoResult.rows[0] || null;

        return res.render('reportes/crear', {
            usuario:    req.session.usuario,
            activePage: 'reportes',
            tipoROIP,
            error:  req.query.error  || null,
            exito:  req.query.exito  ? 'Reporte ROIP registrado correctamente.' : null,
            valores: null
        });
    } catch (err) {
        console.error('getCrearROIP:', err);
        return res.status(500).send('Error interno del servidor.');
    }
};

// POST reportes/crear Procesa el formulario y sube archivo a Supabase
// Luego inserta el reporte en la tabla `reportes`
exports.postCrearROIP = async (req, res) => {
    const sofomId = req.session.usuario.sofom_id;
    const { asunto, descripcion } = req.body;
    const archivo = req.file; // por multer 

    const tipoResult = await Reporte.fetchTipoROIP().catch(() => ({ rows: [] }));
    const tipoROIP   = tipoResult.rows[0] || null;

    const renderError = (msg) => res.render('/reportes/crear', {
        usuario:    req.session.usuario,
        activePage: 'reportes',
        tipoROIP,
        error:  msg,
        exito:  null,
        valores: req.body
    });

    // ── Validaciones
    if (!asunto || !asunto.trim()) {
        return renderError('El asunto es obligatorio.');
    }
    if (!descripcion || !descripcion.trim()) {
        return renderError('La descripción es obligatoria.');
    }

    let rutaEvidencia = null;

    // ── Subida opcional dee evidencia
    if (archivo) {
        if (archivo.mimetype !== 'application/pdf') {
            return renderError('Solo se permiten archivos PDF como evidencia.');
        }

        const nombreLimpio = archivo.originalname
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-zA-Z0-9._-]/g, '_')
            .toLowerCase();

        rutaEvidencia = `sofom_${sofomId}/roip/${Date.now()}_${nombreLimpio}`;

        const { error: storageError } = await supabase.storage
            .from(EVIDENCIAS_BUCKET)
            .upload(rutaEvidencia, archivo.buffer, {
                contentType: 'application/pdf',
                upsert: false
            });

        if (storageError) {
            console.error('Supabase Storage error (ROIP):', storageError);
            return renderError('Error al subir el archivo de evidencia. Intenta de nuevo.');
        }
    }

    // Inserción del reporte 
    try {
        await Reporte.createROIP({
            sofomId,
            asunto:      asunto.trim(),
            descripcion: descripcion.trim(),
            evidencia:   rutaEvidencia
        });

        return res.redirect('/reportes/crear?exito=1');
    } catch (err) {
        console.error('postCrearROIP (INSERT):', err);

        return renderError('Error al registrar el reporte. Intenta de nuevo.');
    }
};
