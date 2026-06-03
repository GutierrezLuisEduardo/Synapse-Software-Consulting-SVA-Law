const ListaRiesgo = require('../models/listaRiesgo.model');
const ROLES = require('../config/roles');

function normalizarTexto(texto) {
    return texto
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .replace(/[^a-z\s]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

exports.getListasBloqueo = async (req, res) => {
    try {
        const sofomId = req.session.usuario.sofom_id;
        const puedeSubir = [ROLES.ADMIN, ROLES.OFICIAL, ROLES.EMPLEADO].includes(req.session.usuario.rol);

        const [tiposResult, listasResult] = await Promise.all([
            ListaRiesgo.fetchTiposOrigen(),
            ListaRiesgo.fetchBySofom(sofomId)
        ]);

        return res.render('listas-bloqueo/subir', {
            usuario: req.session.usuario,
            activePage: 'listas-bloqueo',
            tiposOrigen: tiposResult.rows,
            listas: listasResult.rows,
            puedeSubir,
            error: null,
            exito: null
        });
    } catch (err) {
        console.error('getListasBloqueo:', err);
        return res.status(500).send('Error interno del servidor.');
    }
};

exports.postListasBloqueo = async (req, res) => {
    const sofomId = req.session.usuario.sofom_id;
    const puedeSubir = [ROLES.ADMIN, ROLES.OFICIAL].includes(req.session.usuario.rol);

    const renderConError = async (mensaje) => {
        const [tiposResult, listasResult] = await Promise.all([
            ListaRiesgo.fetchTiposOrigen(),
            ListaRiesgo.fetchBySofom(sofomId)
        ]);
        return res.status(400).render('listas-bloqueo/subir', {
            usuario: req.session.usuario,
            activePage: 'listas-bloqueo',
            tiposOrigen: tiposResult.rows,
            listas: listasResult.rows,
            puedeSubir,
            error: mensaje,
            exito: null
        });
    };

    try {
        if (!puedeSubir) {
            return renderConError('No tienes permisos para subir listas de bloqueo.');
        }

        const { tipo_origen } = req.body;
        const archivo = req.file;

        if (!tipo_origen || !archivo) {
            return renderConError('Debes seleccionar un tipo de lista y adjuntar un archivo .txt.');
        }

        const tipoId = parseInt(tipo_origen, 10);
        if (isNaN(tipoId) || tipoId < 1) {
            return renderConError('Tipo de lista inválido.');
        }

        const textoRaw = archivo.buffer.toString('utf-8');
        if (!textoRaw.trim()) {
            return renderConError('El archivo .txt está vacío.');
        }

        const textNormalizado = normalizarTexto(textoRaw);
        const resultado = await ListaRiesgo.upsert(sofomId, tipoId, textNormalizado);

        const [tiposResult, listasResult] = await Promise.all([
            ListaRiesgo.fetchTiposOrigen(),
            ListaRiesgo.fetchBySofom(sofomId)
        ]);

        return res.render('listas-bloqueo/subir', {
            usuario: req.session.usuario,
            activePage:  'listas-bloqueo',
            tiposOrigen: tiposResult.rows,
            listas: listasResult.rows,
            puedeSubir,
            error: null,
            exito: `Lista ${resultado.accion} correctamente (${textNormalizado.length.toLocaleString()} caracteres almacenados).`
        });

    } catch (err) {
        console.error('postListasBloqueo:', err);
        return renderConError('Error interno al procesar la lista. Intenta de nuevo.');
    }
};