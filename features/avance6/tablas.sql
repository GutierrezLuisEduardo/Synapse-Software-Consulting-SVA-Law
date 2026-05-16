DROP TABLE IF EXISTS Reportes CASCADE;
DROP TABLE IF EXISTS Alertas CASCADE;
DROP TABLE IF EXISTS Reglas CASCADE;
DROP TABLE IF EXISTS Criterios CASCADE;
DROP TABLE IF EXISTS Listas_Riesgo CASCADE;
DROP TABLE IF EXISTS Operaciones CASCADE;
DROP TABLE IF EXISTS Contratos CASCADE;
DROP TABLE IF EXISTS Productos CASCADE;
DROP TABLE IF EXISTS Documentos CASCADE;
DROP TABLE IF EXISTS Repositorios CASCADE;
DROP TABLE IF EXISTS Usuarios CASCADE;
DROP TABLE IF EXISTS Clientes CASCADE;
DROP TABLE IF EXISTS SOFOM CASCADE;

DROP TABLE IF EXISTS Roles CASCADE;

DROP TABLE IF EXISTS tf_tipos_reporte CASCADE;
DROP TABLE IF EXISTS tf_tipos_regla CASCADE;
DROP TABLE IF EXISTS tf_tipos_alerta CASCADE;
DROP TABLE IF EXISTS tf_tipos_documento CASCADE;
DROP TABLE IF EXISTS tf_tipos_entidad CASCADE;

CREATE TABLE Roles (
    rol_id SMALLSERIAL PRIMARY KEY,
    descripcion VARCHAR(70) NOT NULL UNIQUE
);

CREATE TABLE tf_tipos_entidad (
    tipo_entidad_id SMALLSERIAL PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE tf_tipos_reporte (
    tipo_reporte_id SMALLSERIAL PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE tf_tipos_regla (
    tipo_regla_id SMALLSERIAL PRIMARY KEY,
    descripcion VARCHAR(70) NOT NULL UNIQUE
);

CREATE TABLE tf_tipos_alerta (
    tipo_alerta_id SMALLSERIAL PRIMARY KEY,
    descripcion VARCHAR(70) NOT NULL UNIQUE
);

CREATE TABLE tf_tipos_documento (
    tipo_documento_id SMALLSERIAL PRIMARY KEY,
    descripcion VARCHAR(70) NOT NULL UNIQUE
);

CREATE TABLE SOFOM (

    sofom_id SMALLSERIAL PRIMARY KEY,

    tipo_entidad_id SMALLINT NOT NULL,

    razon_social VARCHAR(150) NOT NULL,
    canal_privado VARCHAR(150),
    estatus BOOLEAN NOT NULL DEFAULT true,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_sofom_tipo_entidad
        FOREIGN KEY (tipo_entidad_id)
        REFERENCES tf_tipos_entidad(tipo_entidad_id)
);

CREATE TABLE Clientes (

    cliente_id SERIAL PRIMARY KEY,

    sofom_id SMALLINT NOT NULL,

    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    correo_electronico VARCHAR(100),
    curp VARCHAR(18),
    domicilio_fiscal VARCHAR(250),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estatus BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT fk_clientes_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Usuarios (

    usuario_id SERIAL PRIMARY KEY,

    rol_id SMALLINT NOT NULL,
    sofom_id SMALLINT NOT NULL,

    nombre VARCHAR(120) NOT NULL,
    correo_electronico VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ultimo_acceso TIMESTAMPTZ,
    estatus BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (rol_id)
        REFERENCES Roles(rol_id),

    CONSTRAINT fk_usuarios_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Repositorios (

    repositorio_id SERIAL PRIMARY KEY,

    cliente_id INT NOT NULL,
    sofom_id SMALLINT NOT NULL,

    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ine VARCHAR(200),
    pasaporte VARCHAR(200),
    acta_constitutiva VARCHAR(200),
    comprobante_domicilio VARCHAR(200),
    comprobante_ingresos VARCHAR(200),
    historial_crediticio VARCHAR(200),

    CONSTRAINT fk_repositorio_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES Clientes(cliente_id),

    CONSTRAINT fk_repositorio_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Documentos (

    documento_id SERIAL PRIMARY KEY,

    tipo_documento_id SMALLINT NOT NULL,

    repositorio_id INT NOT NULL,
    referencia_archivo VARCHAR(200) NOT NULL,
    fecha_carga TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_documentos_tipo
        FOREIGN KEY (tipo_documento_id)
        REFERENCES tf_tipos_documento(tipo_documento_id),

    CONSTRAINT fk_documentos_repositorio
        FOREIGN KEY (repositorio_id)
        REFERENCES Repositorios(repositorio_id)
);

CREATE TABLE Productos (

    producto_id SMALLSERIAL PRIMARY KEY,

    sofom_id SMALLINT NOT NULL,

    descripcion VARCHAR(100) NOT NULL,
    estatus BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT fk_productos_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Contratos (

    contrato_id SERIAL PRIMARY KEY,

    repositorio_id INT NOT NULL,
    producto_id SMALLINT NOT NULL,
    sofom_id SMALLINT NOT NULL,

    saldo DECIMAL(14,2) NOT NULL,
    vigencia_inicio DATE NOT NULL,
    vigencia_final DATE,
    instrumento_monetario VARCHAR(10),
    moneda VARCHAR(10),
    localidad VARCHAR(100),
    descripcion VARCHAR(150),
    estatus BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT fk_contratos_repositorio
        FOREIGN KEY (repositorio_id)
        REFERENCES Repositorios(repositorio_id),

    CONSTRAINT fk_contratos_producto
        FOREIGN KEY (producto_id)
        REFERENCES Productos(producto_id),

    CONSTRAINT fk_contratos_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Operaciones (

    operacion_id SERIAL PRIMARY KEY,

    contrato_id INT NOT NULL,
    repositorio_id INT NOT NULL,

    tipo VARCHAR(50) NOT NULL,
    instrumento_monetario VARCHAR(10),
    localidad VARCHAR(100),
    monto DECIMAL(14,2) NOT NULL,
    moneda VARCHAR(10),
    pais_recursos VARCHAR(100),
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_operaciones_contrato
        FOREIGN KEY (contrato_id)
        REFERENCES Contratos(contrato_id),

    CONSTRAINT fk_operaciones_repositorio
        FOREIGN KEY (repositorio_id)
        REFERENCES Repositorios(repositorio_id)
);

CREATE TABLE Listas_Riesgo (

    lista_id SMALLSERIAL PRIMARY KEY,

    sofom_id SMALLINT NOT NULL,

    origen VARCHAR(50) NOT NULL,
    referencia_archivo VARCHAR(200),
    ultima_actualizacion DATE,

    CONSTRAINT fk_listas_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Criterios (

    criterio_id SERIAL PRIMARY KEY,

    nombre VARCHAR(50) NOT NULL,
    operador VARCHAR(20) NOT NULL,
    valor VARCHAR(50) NOT NULL
);

CREATE TABLE Reglas (

    regla_id SERIAL PRIMARY KEY,
    tipo_regla_id SMALLINT NOT NULL,
    tipo_reporte_id SMALLINT NOT NULL,
    tipo_entidad_id SMALLINT NOT NULL,
    sofom_id SMALLINT NOT NULL,
    producto_id SMALLINT NOT NULL,
    criterio_id INT NOT NULL,

    fecha_inicio DATE NOT NULL,
    periodicidad INT NOT NULL,
    estatus BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT fk_reglas_tipo_regla
        FOREIGN KEY (tipo_regla_id)
        REFERENCES tf_tipos_regla(tipo_regla_id),

    CONSTRAINT fk_reglas_tipo_reporte
        FOREIGN KEY (tipo_reporte_id)
        REFERENCES tf_tipos_reporte(tipo_reporte_id),

    CONSTRAINT fk_reglas_tipo_entidad
        FOREIGN KEY (tipo_entidad_id)
        REFERENCES tf_tipos_entidad(tipo_entidad_id),

    CONSTRAINT fk_reglas_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id),

    CONSTRAINT fk_reglas_producto
        FOREIGN KEY (producto_id)
        REFERENCES Productos(producto_id),

    CONSTRAINT fk_reglas_criterio
        FOREIGN KEY (criterio_id)
        REFERENCES Criterios(criterio_id)
);

CREATE TABLE Alertas (

    alerta_id SERIAL PRIMARY KEY,

    regla_id INT NOT NULL,
    operacion_id INT,
    sofom_id SMALLINT NOT NULL,
    tipo_reporte_id SMALLINT NOT NULL,
    tipo_alerta_id SMALLINT NOT NULL,

    estado BOOLEAN NOT NULL DEFAULT false,
    plazo_resolucion INT,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_alertas_regla
        FOREIGN KEY (regla_id)
        REFERENCES Reglas(regla_id),

    CONSTRAINT fk_alertas_operacion
        FOREIGN KEY (operacion_id)
        REFERENCES Operaciones(operacion_id),

    CONSTRAINT fk_alertas_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id),

    CONSTRAINT fk_alertas_tipo_reporte
        FOREIGN KEY (tipo_reporte_id)
        REFERENCES tf_tipos_reporte(tipo_reporte_id),

    CONSTRAINT fk_alertas_tipo_alerta
        FOREIGN KEY (tipo_alerta_id)
        REFERENCES tf_tipos_alerta(tipo_alerta_id)
);

CREATE TABLE Reportes (

    reporte_id SERIAL PRIMARY KEY,

    tipo_reporte_id SMALLINT NOT NULL,
    operacion_id INT,
    tipo_entidad_id SMALLINT NOT NULL,
    sofom_id SMALLINT NOT NULL,

    motivo VARCHAR(400),
    fecha_generacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    plazo_envio DATE,
    estado_envio BOOLEAN NOT NULL DEFAULT false,
    evidencia VARCHAR(200),

    CONSTRAINT fk_reportes_tipo_reporte
        FOREIGN KEY (tipo_reporte_id)
        REFERENCES tf_tipos_reporte(tipo_reporte_id),

    CONSTRAINT fk_reportes_operacion
        FOREIGN KEY (operacion_id)
        REFERENCES Operaciones(operacion_id),

    CONSTRAINT fk_reportes_tipo_entidad
        FOREIGN KEY (tipo_entidad_id)
        REFERENCES tf_tipos_entidad(tipo_entidad_id),

    CONSTRAINT fk_reportes_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

-- =========================================================
-- INSERTS BASE
-- =========================================================

INSERT INTO Roles (
    descripcion
)
VALUES
('Administrador'),
('Oficial de cumplimiento'),
('Empleado'),
('Auditor');

INSERT INTO tf_tipos_entidad (
    descripcion
)
VALUES
('SOFOM E.N.R.'),
('SOFOM E.R.');

INSERT INTO tf_tipos_reporte (
    descripcion
)
VALUES
('ROR'),
('ROI'),
('ROIP'),
('ROI-24');

INSERT INTO tf_tipos_regla (
    descripcion
)
VALUES
('Monto relevante'),
('Operación inusual'),
('Lista restringida');

INSERT INTO tf_tipos_alerta (
    descripcion
)
VALUES
('Recordatorio'),
('Dictamen'),
('Generación de reporte');

INSERT INTO tf_tipos_documento (
    descripcion
)
VALUES
('INE'),
('Pasaporte'),
('Acta constitutiva'),
('Comprobante de domicilio');

-- =========================================================
-- SOFOMES
-- =========================================================

INSERT INTO SOFOM (
    tipo_entidad_id,
    razon_social,
    canal_privado
)
VALUES
(
    1,
    'Financiera Integral del Bajío S.A. de C.V.',
    'canal.oc@finbajio.mx'
),
(
    1,
    'Crédito Empresarial del Centro S.A. de C.V.',
    'oc@credicentro.mx'
);

-- =========================================================
-- USUARIO ADMINISTRADOR INICIAL
-- Correo:
-- admin@svalaw.mx
--
-- Contraseña:
-- Clave01Segura
-- =========================================================

INSERT INTO Usuarios (
    rol_id,
    sofom_id,
    nombre,
    correo_electronico,
    contrasena
)
VALUES (
    1,
    1,
    'Administrador General',
    'admin@svalaw.mx',
    '$2b$10$unby6t0T7yUfAc.DDRjmFO/jpG4vkySDcsLmmXDzJemyEbHMKoFsu'
);  