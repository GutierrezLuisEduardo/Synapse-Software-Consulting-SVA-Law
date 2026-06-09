CREATE TABLE SOFOM (
    --PK
    sofom_id SMALLINT PRIMARY KEY,

    --Atributos
    tipo_entidad BOOLEAN,
    razon_social VARCHAR(150) NOT NULL,
    estatus BOOLEAN,
    canal_privado VARCHAR(150)
);

CREATE TABLE Clientes (
    --PK
    cliente_id SMALLINT PRIMARY KEY,

    --FK
    sofom_id SMALLINT NOT NULL,

    --Atributos
    nombre VARCHAR(100),
    telefono VARCHAR(15),
    correo_electronico VARCHAR(60),
    curp VARCHAR(18),
    domicilio_fiscal VARCHAR(150),

    --Constraints FK
    CONSTRAINT fk_clientes_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Roles (
    --PK
    rol_id SMALLINT PRIMARY KEY,

    --Atributos
    descripcion VARCHAR(70)
);

CREATE TABLE Usuarios (
    --PK
    usuario_id SMALLINT PRIMARY KEY,

    --FK
    rol_id SMALLINT NOT NULL, 
    sofom_id SMALLINT NOT NULL, 
    
    --Atributos
    nombre VARCHAR(100),
    correo_electronico VARCHAR(60),
    contrasena VARCHAR(24),

    --Constraints FK
    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (rol_id)
        REFERENCES Roles(rol_id),

    CONSTRAINT fk_usuarios_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Repositorios (
    --PK
    repositorio_id SMALLINT PRIMARY KEY,

    --FK
    cliente_id SMALLINT NOT NULL, 
    sofom_id SMALLINT NOT NULL, 
    
    --Atributos
    fecha_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    razon_social VARCHAR(150),
    ine VARCHAR(150),
    pasaporte VARCHAR(150),
    cedula_profesional VARCHAR(150),
    acta_constitutiva VARCHAR(150),
    comprobante_domicilio VARCHAR(150),
    comprobante_ingresos VARCHAR(150),
    historial_crediticio VARCHAR(150),

    --Constraints FK
    CONSTRAINT fk_repositorios_clientes
        FOREIGN KEY (cliente_id)
        REFERENCES Clientes(cliente_id),

    CONSTRAINT fk_repositorios_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Documentos (
    --PK
    documento_id SMALLINT PRIMARY KEY,

    --FK
    repositorio_id SMALLINT NOT NULL, 
    
    --Atributos
    tipo SMALLINT,
    fecha_carga TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    --Constraints FK
    CONSTRAINT fk_documentos_repositorios
        FOREIGN KEY (repositorio_id)
        REFERENCES Repositorios(repositorio_id)
);

CREATE TABLE Productos (
    --PK
    producto_id SMALLINT PRIMARY KEY,

    --FK
    sofom_id SMALLINT NOT NULL, 
    
    --Atributos
    descripcion VARCHAR(70),

    --Constraints FK
    CONSTRAINT fk_productos_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Contratos (
    --PK
    contrato_id SMALLINT PRIMARY KEY,

    --FK
    repositorio_id SMALLINT NOT NULL, 
    producto_id SMALLINT NOT NULL, 
    sofom_id SMALLINT NOT NULL,
    
    --Atributos
    saldo DECIMAL(12, 2),
    vigencia_inicio DATE,
    vigencia_final DATE,
    estatus BOOLEAN,
    instrumento_monetario VARCHAR(2),
    moneda VARCHAR(3),
    localidad VARCHAR(10),
    descripcion VARCHAR(70),

    --Constraints FK
    CONSTRAINT fk_contratos_repositorios
        FOREIGN KEY (repositorio_id)
        REFERENCES Repositorios(repositorio_id),

    CONSTRAINT fk_contratos_productos
        FOREIGN KEY (producto_id)
        REFERENCES Productos(producto_id),

    CONSTRAINT fk_contratos_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Operaciones (
    --PK
    operacion_id SMALLINT PRIMARY KEY,

    --FK
    contrato_id SMALLINT NOT NULL, 
    repositorio_id SMALLINT NOT NULL, 
    
    --Atributos
    tipo VARCHAR(2),
    instrumento_monetario VARCHAR(2),
    localidad VARCHAR(10),
    monto DECIMAL(12, 2),
    moneda VARCHAR(3),
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    pais_recursos VARCHAR(2),

    --Constraints FK
    CONSTRAINT fk_operaciones_contratos
        FOREIGN KEY (contrato_id)
        REFERENCES Contratos(contrato_id),

    CONSTRAINT fk_operaciones_repositorios
        FOREIGN KEY (repositorio_id)
        REFERENCES Repositorios(repositorio_id)
);

CREATE TABLE ListasRiesgo (
    --PK
    lista_id SMALLINT PRIMARY KEY,

    --FK
    sofom_id SMALLINT NOT NULL, 
    
    --Atributos
    origen VARCHAR(20),
    referencia_archivo VARCHAR(150),
    ultima_actualizacion DATE,

    --Constraints FK
    CONSTRAINT fk_listasriesgo_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Criterios (
    --PK
    criterio_id SMALLINT PRIMARY KEY,
    
    --Atributos
    nombre VARCHAR(50),
    valor VARCHAR(10),
    operador VARCHAR(10)

);

CREATE TABLE Reglas (
    --PK
    regla_id SMALLINT PRIMARY KEY,

    --FK
    sofom_id SMALLINT NOT NULL, 
    producto_id SMALLINT NOT NULL,
    criterio_id SMALLINT NOT NULL, 
    
    --Atributos
    tipo_regla SMALLINT,
    tipo_reporte SMALLINT,
    tipo_entidad SMALLINT,
    fecha_inicio DATE,
    tipo_periodicidad BOOLEAN,
    periodicidad SMALLINT,

    --Constraints FK
    CONSTRAINT fk_reglas_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id),

    CONSTRAINT fk_reglas_productos
        FOREIGN KEY (producto_id)
        REFERENCES Productos(producto_id),

    CONSTRAINT fk_reglas_criterio
        FOREIGN KEY (criterio_id)
        REFERENCES Criterios(criterio_id)
);

CREATE TABLE Alertas (
    --PK
    alerta_id SMALLINT PRIMARY KEY,

    --FK
    regla_id SMALLINT NOT NULL, 
    operacion_id SMALLINT NOT NULL,
    sofom_id SMALLINT NOT NULL, 
    
    --Atributos
    tipo_reporte SMALLINT,
    tipo SMALLINT,
    estado BOOLEAN,
    fecha_hora TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    plazo_resolucion SMALLINT,

    --Constraints FK
    CONSTRAINT fk_alertas_reglas
        FOREIGN KEY (regla_id)
        REFERENCES Reglas(regla_id),

    CONSTRAINT fk_alertas_operaciones
        FOREIGN KEY (operacion_id)
        REFERENCES Operaciones(operacion_id),

    CONSTRAINT fk_alertas_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

CREATE TABLE Reportes (
    --PK
    reporte_id SMALLINT PRIMARY KEY,

    --FK
    operacion_id SMALLINT NOT NULL, 
    sofom_id SMALLINT NOT NULL,
    
    --Atributos
    tipo_reporte SMALLINT,
    tipo_entidad SMALLINT, 
    motivo VARCHAR(400),
    fecha_generacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    plazo_envio DATE,
    estado_envio BOOLEAN,
    evidencia VARCHAR(150),

    --Constraints FK
    CONSTRAINT fk_reportes_operaciones
        FOREIGN KEY (operacion_id)
        REFERENCES Operaciones(operacion_id),

    CONSTRAINT fk_reportes_sofom
        FOREIGN KEY (sofom_id)
        REFERENCES SOFOM(sofom_id)
);

