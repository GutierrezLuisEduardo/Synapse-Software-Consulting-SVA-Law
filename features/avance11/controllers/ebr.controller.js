const Ebr   = require('../models/ebr.model');
const ROLES = require('../config/roles');

// GET /ebr/parametrizacion
exports.getParametrizacion = async (req, res) => {
    try {
        const usuario = req.session.usuario;

        const sofomId = usuario.sofom_id;

        const [criteriosResult, enfoqueResult] = await Promise.all([
            Ebr.fetchCriterios(),
            Ebr.fetchEnfoque(sofomId)
        ]);

        if (enfoqueResult.rows.length === 0) {
            return res.status(404).render('error/404', { usuario });
        }

        const sofom = enfoqueResult.rows[0];
        const criterios = criteriosResult.rows;
        const enfoque = sofom.enfoque_riesgos; // objeto JS ya parseado por pg

        // Agrupar criterios por clasificación
        const grupos = {};
        for (const c of criterios) {
            if (!grupos[c.clasificacion]) grupos[c.clasificacion] = [];
            grupos[c.clasificacion].push({
                ...c,
                peso: parseFloat(enfoque[String(c.id)] ?? 0)
            });
        }

        // Suma de pesos por grupo (informativo)
        const totales = {};
        for (const [clas, items] of Object.entries(grupos)) {
            totales[clas] = items.reduce((s, i) => s + i.peso, 0);
        }

        res.render('ebr/parametrizacion', {
            usuario,
            activePage: 'ebr',
            sofom,
            grupos,
            totales,
            error:   req.query.error   || null,
            success: req.query.success || null
        });

    } catch (error) {
        console.error('EBR getParametrizacion:', error);
        res.status(500).send('Error interno del servidor');
    }
};

// POST /ebr/parametrizacion                                            */

exports.postParametrizacion = async (req, res) => {
    try {
        const usuario = req.session.usuario;

        const sofomId = (usuario.rol === ROLES.ROOT && req.body.sofom_id)
            ? parseInt(req.body.sofom_id, 10)
            : usuario.sofom_id;

        // Reconstruir objeto de pesos desde el formulario
        // Los inputs se llaman  peso_1 … peso_31
        const nuevoEnfoque = {};
        let hayError = false;

        for (let i = 1; i <= 31; i++) {
            const raw = req.body[`peso_${i}`];
            const val = parseFloat(raw);

            if (isNaN(val) || val < 0 || val > 1) {
                hayError = true;
                break;
            }
            nuevoEnfoque[String(i)] = val;
        }

        if (hayError) {
            return res.redirect(
                `/ebr/parametrizacion?sofom_id=${sofomId}&error=` +
                encodeURIComponent('Los pesos deben ser valores entre 0 y 1.')
            );
        }

        await Ebr.updateEnfoque(sofomId, nuevoEnfoque);

        res.redirect(
            `/ebr/parametrizacion?sofom_id=${sofomId}&success=` +
            encodeURIComponent('Parametrización actualizada correctamente.')
        );

    } catch (error) {
        console.error('EBR postParametrizacion:', error);
        res.status(500).send('Error interno del servidor');
    }
};
