const Documento = require('../models/documento.model');
const Cliente   = require('../models/cliente.model');
const ROLES = require('../config/roles');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

const BUCKET_NAME = process.env.SUPABASE_BUCKET || 'documentos';

exports.getSubirDocumento = async (req, res) => {
    try {
        const tiposDocumentoResult = await Documento.fetchTiposDocumento();
        const puedeSubir = [ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO]
            .includes(req.session.usuario.rol);

        return res.render('documentos/subir', {
            usuario: req.session.usuario,
            activePage: 'documentos',
            tiposDocumento: tiposDocumentoResult.rows,
            puedeSubir,
            error: null,
            exito: null
        });
    } catch (err) {
        console.error('getSubirDocumento:', err);
        return res.status(500).send('Error interno del servidor.');
    }
};

exports.postSubirDocumento = async (req, res) => {
    try {
        const { tipo_documento_id, cliente_id } = req.body;
        const archivo = req.file;

        if (!tipo_documento_id || !cliente_id || !archivo) {
            return res.status(400).json({ error: 'Faltan campos obligatorios.' });
        }

        const sofomId = req.session.usuario.sofom_id;

        const clienteResult = await Cliente.fetchPerfilByClienteIdAndSofom(
            parseInt(cliente_id),
            sofomId
        );
        if (!clienteResult.rows.length) {
            return res.status(404).json({ error: 'Cliente no encontrado en esta SOFOM.' });
        }
        const perfilClienteId = clienteResult.rows[0].perfiles_cliente_id;

        const extension = 'pdf';
        const timestamp = Date.now();

        const nombreLimpio = archivo.originalname
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-zA-Z0-9._-]/g, '_')
            .toLowerCase();

        const rutaArchivo = `sofom_${sofomId}/cliente_${cliente_id}/${Date.now()}_${nombreLimpio}`;

        const { error: storageError } = await supabase.storage
            .from(BUCKET_NAME)
            .upload(rutaArchivo, archivo.buffer, {
                contentType: 'application/pdf',
                upsert: false
            });

        if (storageError) {
            console.error('Supabase Storage error:', storageError);
            return res.status(500).json({ error: 'Error al subir el archivo al almacenamiento.' });
        }

        const referenciaArchivo = rutaArchivo;

        await Documento.create(
            sofomId,
            perfilClienteId,
            parseInt(tipo_documento_id),
            referenciaArchivo
        );

        return res.status(201).json({
            exito: true,
            mensaje: 'Documento subido y registrado correctamente.'
        });

    } catch (err) {
        console.error('postSubirDocumento:', err);
        return res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.getUrlDocumento = async (req, res) => {
    try {
        const rutaArchivo = req.query.ruta;

        if (!rutaArchivo) {
            return res.status(400).json({ error: 'Ruta no especificada.' });
        }

        const sofomId = req.session.usuario.sofom_id;
        if (!rutaArchivo.startsWith(`sofom_${sofomId}/`)) {
            return res.status(403).json({ error: 'Acceso no permitido.' });
        }

        const { data, error } = await supabase.storage
            .from(BUCKET_NAME)
            .createSignedUrl(rutaArchivo, 60 * 60);

        if (error) {
            console.error('Error generando signed URL:', error);
            return res.status(500).json({ error: 'Error al generar la URL del documento.' });
        }

        return res.redirect(data.signedUrl);
    } catch (err) {
        console.error('getUrlDocumento:', err);
        return res.status(500).json({ error: 'Error interno del servidor.' });
    }
};