--
-- TOC entry 268 (class 1259 OID 34856)
-- Name: alertas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas (
    alerta_id integer NOT NULL,
    regla_id integer NOT NULL,
    operacion_id integer,
    sofom_id smallint NOT NULL,
    tipo_reporte_id smallint NOT NULL,
    tipo_alerta_id smallint NOT NULL,
    estado_revision boolean DEFAULT false NOT NULL,
    fecha_hora_alerta timestamp with time zone NOT NULL
);


--
-- TOC entry 267 (class 1259 OID 34855)
-- Name: alertas_alerta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alertas_alerta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5343 (class 0 OID 0)
-- Dependencies: 267
-- Name: alertas_alerta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alertas_alerta_id_seq OWNED BY public.alertas.alerta_id;


--
-- TOC entry 256 (class 1259 OID 34660)
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    cliente_id integer NOT NULL,
    sofom_id smallint NOT NULL,
    razon_social character varying(120) NOT NULL,
    telefono character varying(20) NOT NULL,
    correo_electronico character varying(100) NOT NULL,
    clabe character varying(18) NOT NULL,
    serie_efirma character varying(40) NOT NULL,
    geolocalizacion character varying(25) NOT NULL,
    estatus_alerta_historica boolean DEFAULT false NOT NULL,
    ha_sido_peps boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    id_tipo_persona smallint DEFAULT 0 NOT NULL,
    curp character varying(18),
    rfc character varying(15),
    genero character varying(20),
    fecha_nacimiento date,
    pais_nacimiento character varying(80),
    entidad_federativa_nacimiento character varying(100),
    nombre_apoderado_legal character varying(120),
    fecha_constitucion date,
    pais_origen smallint NOT NULL,
    nacionalidad smallint NOT NULL,
    domicilio smallint NOT NULL,
    actividad_economica smallint NOT NULL,
    vinculado_con_grupo smallint NOT NULL,
    estado_civil smallint NOT NULL,
    dependientes_economicos smallint NOT NULL,
    numero_hijos smallint NOT NULL,
    nivel_estudios smallint NOT NULL,
    tipo_vivienda smallint NOT NULL,
    tipo_empleo smallint NOT NULL,
    ingresos_mensuales smallint NOT NULL,
    valor_patrimonio smallint NOT NULL,
    pertenece_partido_politico smallint NOT NULL,
    peps smallint,
    edad smallint,
    cambio_estatus smallint,
    senial_alerta_historica smallint
);


--
-- TOC entry 255 (class 1259 OID 34659)
-- Name: clientes_cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5344 (class 0 OID 0)
-- Dependencies: 255
-- Name: clientes_cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_cliente_id_seq OWNED BY public.clientes.cliente_id;


--
-- TOC entry 262 (class 1259 OID 34764)
-- Name: contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contratos (
    contrato_id integer NOT NULL,
    perfiles_cliente_id integer NOT NULL,
    sofom_id smallint NOT NULL,
    id_ultima_operacion smallint NOT NULL,
    descripcion character varying(150),
    canal smallint NOT NULL,
    producto smallint NOT NULL,
    finalidad_credito smallint NOT NULL,
    frecuencia_pago smallint NOT NULL,
    frecuencia smallint NOT NULL,
    numero_pagos_acordados smallint NOT NULL,
    numero_pagos_hechos smallint NOT NULL,
    liquidacion_anticipada_ultimo_pago smallint NOT NULL,
    fecha_inicio date,
    fecha_finalizacion date,
    monto_total_pago numeric(14,2) DEFAULT 0.0 NOT NULL,
    monto_pagado numeric(14,2) DEFAULT 0.0,
    pago_por_operacion numeric(14,2) DEFAULT 0.0
);


--
-- TOC entry 261 (class 1259 OID 34763)
-- Name: contratos_contrato_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contratos_contrato_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 261
-- Name: contratos_contrato_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contratos_contrato_id_seq OWNED BY public.contratos.contrato_id;


--
-- TOC entry 243 (class 1259 OID 34508)
-- Name: criterios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criterios (
    criterio_id integer NOT NULL,
    id_catalogo smallint NOT NULL,
    id_operador smallint NOT NULL,
    id_opcion smallint NOT NULL
);


--
-- TOC entry 242 (class 1259 OID 34507)
-- Name: criterios_criterio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.criterios_criterio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 242
-- Name: criterios_criterio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.criterios_criterio_id_seq OWNED BY public.criterios.criterio_id;


--
-- TOC entry 260 (class 1259 OID 34740)
-- Name: documentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documentos (
    documento_id integer NOT NULL,
    sofom_id smallint NOT NULL,
    perfiles_cliente_id integer NOT NULL,
    tipo_documento_id smallint NOT NULL,
    referencia_archivo character varying(200) NOT NULL,
    fecha_carga timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 259 (class 1259 OID 34739)
-- Name: documentos_documento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documentos_documento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 259
-- Name: documentos_documento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documentos_documento_id_seq OWNED BY public.documentos.documento_id;


--
-- TOC entry 245 (class 1259 OID 34531)
-- Name: listas_riesgo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listas_riesgo (
    lista_id smallint NOT NULL,
    sofom_id smallint NOT NULL,
    origen character varying(50) NOT NULL,
    referencia_archivo character varying(200),
    ultima_actualizacion date
);


--
-- TOC entry 244 (class 1259 OID 34530)
-- Name: listas_riesgo_lista_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listas_riesgo_lista_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 244
-- Name: listas_riesgo_lista_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listas_riesgo_lista_id_seq OWNED BY public.listas_riesgo.lista_id;


--
-- TOC entry 247 (class 1259 OID 34546)
-- Name: logs_auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs_auditoria (
    id_accion integer NOT NULL,
    sofom_id smallint NOT NULL,
    id_usuario smallint NOT NULL,
    id_tipo_accion smallint NOT NULL,
    hora_accion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 246 (class 1259 OID 34545)
-- Name: logs_auditoria_id_accion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_auditoria_id_accion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 246
-- Name: logs_auditoria_id_accion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_auditoria_id_accion_seq OWNED BY public.logs_auditoria.id_accion;


--
-- TOC entry 264 (class 1259 OID 34797)
-- Name: operaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operaciones (
    operacion_id integer NOT NULL,
    contrato_id integer NOT NULL,
    origen_recursos smallint NOT NULL,
    origen_operacion smallint NOT NULL,
    destino_operacion smallint NOT NULL,
    instrumento_monetario smallint NOT NULL,
    incremento_monto_vs_anterior smallint NOT NULL,
    pago_excedido smallint NOT NULL,
    monto numeric(14,2) DEFAULT 0.0 NOT NULL,
    emision_operacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 263 (class 1259 OID 34796)
-- Name: operaciones_operacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.operaciones_operacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 263
-- Name: operaciones_operacion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.operaciones_operacion_id_seq OWNED BY public.operaciones.operacion_id;


--
-- TOC entry 258 (class 1259 OID 34709)
-- Name: perfiles_cliente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfiles_cliente (
    perfiles_cliente_id integer NOT NULL,
    cliente_id integer NOT NULL,
    sofom_id smallint NOT NULL,
    prioridad smallint DEFAULT 0 NOT NULL,
    ultima_revision timestamp with time zone,
    operaciones_en_cola integer DEFAULT 0 NOT NULL,
    puntaje numeric(4,2) DEFAULT 0 NOT NULL,
    clasif_monitoreo numeric(4,2) DEFAULT 0.0 NOT NULL,
    clasif_cliente numeric(4,2) DEFAULT 0.0 NOT NULL,
    riesgo_final smallint GENERATED ALWAYS AS (
CASE
    WHEN (puntaje <= 1.9) THEN 1
    WHEN (puntaje <= 2.5) THEN 2
    ELSE 3
END) STORED
);


--
-- TOC entry 257 (class 1259 OID 34708)
-- Name: perfiles_cliente_perfiles_cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfiles_cliente_perfiles_cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 257
-- Name: perfiles_cliente_perfiles_cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfiles_cliente_perfiles_cliente_id_seq OWNED BY public.perfiles_cliente.perfiles_cliente_id;


--
-- TOC entry 250 (class 1259 OID 34601)
-- Name: regla_criterios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regla_criterios (
    regla_id smallint NOT NULL,
    criterio_id smallint NOT NULL,
    orden smallint DEFAULT 1
);


--
-- TOC entry 249 (class 1259 OID 34564)
-- Name: reglas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reglas (
    regla_id smallint NOT NULL,
    tipo_regla_id smallint NOT NULL,
    tipo_reporte_id smallint NOT NULL,
    tipo_entidad_id smallint NOT NULL,
    sofom_id smallint NOT NULL,
    fecha_inicio timestamp with time zone NOT NULL,
    periodicidad smallint NOT NULL,
    periodo_en_dias boolean DEFAULT false NOT NULL,
    ultima_revision timestamp with time zone NOT NULL,
    proxima_revision timestamp with time zone NOT NULL
);


--
-- TOC entry 248 (class 1259 OID 34563)
-- Name: reglas_regla_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reglas_regla_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 248
-- Name: reglas_regla_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reglas_regla_id_seq OWNED BY public.reglas.regla_id;


--
-- TOC entry 266 (class 1259 OID 34821)
-- Name: reportes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reportes (
    reporte_id integer NOT NULL,
    tipo_reporte_id smallint NOT NULL,
    operacion_id integer,
    tipo_entidad_id smallint NOT NULL,
    sofom_id smallint NOT NULL,
    fecha_generacion timestamp with time zone DEFAULT now() NOT NULL,
    dictamen character varying(400),
    plazo_dictamen date,
    ha_sido_descargado boolean DEFAULT false NOT NULL
);


--
-- TOC entry 265 (class 1259 OID 34820)
-- Name: reportes_reporte_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reportes_reporte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 265
-- Name: reportes_reporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reportes_reporte_id_seq OWNED BY public.reportes.reporte_id;


--
-- TOC entry 252 (class 1259 OID 34620)
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    rol_id smallint NOT NULL,
    descripcion character varying(70) NOT NULL
);


--
-- TOC entry 251 (class 1259 OID 34619)
-- Name: roles_rol_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_rol_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 251
-- Name: roles_rol_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_rol_id_seq OWNED BY public.roles.rol_id;


--
-- TOC entry 241 (class 1259 OID 34485)
-- Name: sofom; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sofom (
    sofom_id smallint NOT NULL,
    tipo_entidad_id smallint NOT NULL,
    razon_social character varying(150) NOT NULL,
    canal_privado character varying(150),
    estatus boolean DEFAULT true NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    enfoque_riesgos jsonb DEFAULT '{"1": 0.1, "2": 0.1, "3": 0.2, "4": 0.2, "5": 0.2, "6": 0.2, "7": 0.2, "8": 0.1, "9": 0.4, "10": 0.1, "11": 0.2, "12": 0.1, "13": 0.1, "14": 0, "15": 0, "16": 0, "17": 0, "18": 0, "19": 0, "20": 0, "21": 0, "22": 0, "23": 0, "24": 0, "25": 0.2, "26": 0.3, "27": 0.2, "28": 0.1, "29": 0.1, "30": 0.4, "31": 0.1}'::jsonb NOT NULL
);


--
-- TOC entry 240 (class 1259 OID 34484)
-- Name: sofom_sofom_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sofom_sofom_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 240
-- Name: sofom_sofom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sofom_sofom_id_seq OWNED BY public.sofom.sofom_id;


--
-- TOC entry 239 (class 1259 OID 34045)
-- Name: tf_catalogos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_catalogos (
    id_opcion integer NOT NULL,
    catalogo_id integer,
    opciones character varying(255),
    valores integer,
    tipo_id integer,
    clasificacion_id integer,
    frecuencia_de_pago_acordada numeric(18,6),
    frecuencia numeric(18,6),
    liquidacion_anticipada numeric(18,6),
    pago_excedido numeric(18,6),
    incremento_vs_monto_anterior boolean,
    senial_alerta_historica boolean,
    cambio_listas_peps boolean
);


--
-- TOC entry 238 (class 1259 OID 34044)
-- Name: tf_catalogos_id_opcion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_catalogos_id_opcion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 238
-- Name: tf_catalogos_id_opcion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_catalogos_id_opcion_seq OWNED BY public.tf_catalogos.id_opcion;


--
-- TOC entry 220 (class 1259 OID 33944)
-- Name: tf_clasificaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_clasificaciones (
    clasificacion_id smallint NOT NULL,
    descripcion character varying(255)
);


--
-- TOC entry 221 (class 1259 OID 33950)
-- Name: tf_criterios_ebr; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_criterios_ebr (
    id smallint NOT NULL,
    catalogo_id integer,
    descripcion character varying(255),
    tipo_id integer,
    clasificacion_id integer
);


--
-- TOC entry 233 (class 1259 OID 34018)
-- Name: tf_operadores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_operadores (
    id_operador smallint NOT NULL,
    operador character varying(5),
    descripcion character varying(25)
);


--
-- TOC entry 232 (class 1259 OID 34017)
-- Name: tf_operadores_id_operador_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_operadores_id_operador_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 232
-- Name: tf_operadores_id_operador_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_operadores_id_operador_seq OWNED BY public.tf_operadores.id_operador;


--
-- TOC entry 219 (class 1259 OID 33938)
-- Name: tf_tipos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos (
    tipo_id smallint NOT NULL,
    descripcion character varying(255)
);


--
-- TOC entry 235 (class 1259 OID 34026)
-- Name: tf_tipos_acciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_acciones (
    id_tipo_accion smallint NOT NULL,
    descripcion character varying(50)
);


--
-- TOC entry 234 (class 1259 OID 34025)
-- Name: tf_tipos_acciones_id_tipo_accion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_acciones_id_tipo_accion_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 234
-- Name: tf_tipos_acciones_id_tipo_accion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_acciones_id_tipo_accion_seq OWNED BY public.tf_tipos_acciones.id_tipo_accion;


--
-- TOC entry 227 (class 1259 OID 33979)
-- Name: tf_tipos_alerta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_alerta (
    tipo_alerta_id smallint NOT NULL,
    descripcion character varying(70) NOT NULL
);


--
-- TOC entry 226 (class 1259 OID 33978)
-- Name: tf_tipos_alerta_tipo_alerta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_alerta_tipo_alerta_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 226
-- Name: tf_tipos_alerta_tipo_alerta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_alerta_tipo_alerta_id_seq OWNED BY public.tf_tipos_alerta.tipo_alerta_id;


--
-- TOC entry 231 (class 1259 OID 34001)
-- Name: tf_tipos_documento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_documento (
    tipo_documento_id smallint NOT NULL,
    descripcion character varying(200) NOT NULL,
    tipo_persona_id smallint NOT NULL
);


--
-- TOC entry 230 (class 1259 OID 34000)
-- Name: tf_tipos_documento_tipo_documento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_documento_tipo_documento_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 230
-- Name: tf_tipos_documento_tipo_documento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_documento_tipo_documento_id_seq OWNED BY public.tf_tipos_documento.tipo_documento_id;


--
-- TOC entry 223 (class 1259 OID 33957)
-- Name: tf_tipos_entidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_entidad (
    tipo_entidad_id smallint NOT NULL,
    descripcion character varying(50) NOT NULL
);


--
-- TOC entry 222 (class 1259 OID 33956)
-- Name: tf_tipos_entidad_tipo_entidad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_entidad_tipo_entidad_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 222
-- Name: tf_tipos_entidad_tipo_entidad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_entidad_tipo_entidad_id_seq OWNED BY public.tf_tipos_entidad.tipo_entidad_id;


--
-- TOC entry 229 (class 1259 OID 33990)
-- Name: tf_tipos_persona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_persona (
    tipo_persona_id smallint NOT NULL,
    descripcion character varying(25) NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 33989)
-- Name: tf_tipos_persona_tipo_persona_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_persona_tipo_persona_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 228
-- Name: tf_tipos_persona_tipo_persona_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_persona_tipo_persona_id_seq OWNED BY public.tf_tipos_persona.tipo_persona_id;


--
-- TOC entry 225 (class 1259 OID 33968)
-- Name: tf_tipos_regla; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_regla (
    tipo_regla_id smallint NOT NULL,
    descripcion character varying(70) NOT NULL
);


--
-- TOC entry 224 (class 1259 OID 33967)
-- Name: tf_tipos_regla_tipo_regla_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_regla_tipo_regla_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 224
-- Name: tf_tipos_regla_tipo_regla_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_regla_tipo_regla_id_seq OWNED BY public.tf_tipos_regla.tipo_regla_id;


--
-- TOC entry 237 (class 1259 OID 34034)
-- Name: tf_tipos_reporte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tf_tipos_reporte (
    tipo_reporte_id smallint NOT NULL,
    descripcion character varying(50) NOT NULL,
    requiere_dictamen boolean NOT NULL,
    dias_hasta_dictamen smallint NOT NULL
);


--
-- TOC entry 236 (class 1259 OID 34033)
-- Name: tf_tipos_reporte_tipo_reporte_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tf_tipos_reporte_tipo_reporte_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 236
-- Name: tf_tipos_reporte_tipo_reporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tf_tipos_reporte_tipo_reporte_id_seq OWNED BY public.tf_tipos_reporte.tipo_reporte_id;


--
-- TOC entry 254 (class 1259 OID 34631)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    usuario_id integer NOT NULL,
    rol_id smallint,
    sofom_id smallint NOT NULL,
    nombre character varying(120) NOT NULL,
    correo_electronico character varying(100) NOT NULL,
    contrasena character varying(255) NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    ultimo_acceso timestamp with time zone,
    estatus boolean DEFAULT true NOT NULL
);


--
-- TOC entry 253 (class 1259 OID 34630)
-- Name: usuarios_usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 253
-- Name: usuarios_usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_usuario_id_seq OWNED BY public.usuarios.usuario_id;


--
-- TOC entry 5030 (class 2604 OID 34859)
-- Name: alertas alerta_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas ALTER COLUMN alerta_id SET DEFAULT nextval('public.alertas_alerta_id_seq'::regclass);


--
-- TOC entry 5006 (class 2604 OID 34663)
-- Name: clientes cliente_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN cliente_id SET DEFAULT nextval('public.clientes_cliente_id_seq'::regclass);


--
-- TOC entry 5020 (class 2604 OID 34767)
-- Name: contratos contrato_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos ALTER COLUMN contrato_id SET DEFAULT nextval('public.contratos_contrato_id_seq'::regclass);


--
-- TOC entry 4995 (class 2604 OID 34511)
-- Name: criterios criterio_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterios ALTER COLUMN criterio_id SET DEFAULT nextval('public.criterios_criterio_id_seq'::regclass);


--
-- TOC entry 5018 (class 2604 OID 34743)
-- Name: documentos documento_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos ALTER COLUMN documento_id SET DEFAULT nextval('public.documentos_documento_id_seq'::regclass);


--
-- TOC entry 4996 (class 2604 OID 34534)
-- Name: listas_riesgo lista_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listas_riesgo ALTER COLUMN lista_id SET DEFAULT nextval('public.listas_riesgo_lista_id_seq'::regclass);


--
-- TOC entry 4997 (class 2604 OID 34549)
-- Name: logs_auditoria id_accion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_auditoria ALTER COLUMN id_accion SET DEFAULT nextval('public.logs_auditoria_id_accion_seq'::regclass);


--
-- TOC entry 5024 (class 2604 OID 34800)
-- Name: operaciones operacion_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones ALTER COLUMN operacion_id SET DEFAULT nextval('public.operaciones_operacion_id_seq'::regclass);


--
-- TOC entry 5011 (class 2604 OID 34712)
-- Name: perfiles_cliente perfiles_cliente_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfiles_cliente ALTER COLUMN perfiles_cliente_id SET DEFAULT nextval('public.perfiles_cliente_perfiles_cliente_id_seq'::regclass);


--
-- TOC entry 4999 (class 2604 OID 34567)
-- Name: reglas regla_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas ALTER COLUMN regla_id SET DEFAULT nextval('public.reglas_regla_id_seq'::regclass);


--
-- TOC entry 5027 (class 2604 OID 34824)
-- Name: reportes reporte_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes ALTER COLUMN reporte_id SET DEFAULT nextval('public.reportes_reporte_id_seq'::regclass);


--
-- TOC entry 5002 (class 2604 OID 34623)
-- Name: roles rol_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN rol_id SET DEFAULT nextval('public.roles_rol_id_seq'::regclass);


--
-- TOC entry 4991 (class 2604 OID 34488)
-- Name: sofom sofom_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sofom ALTER COLUMN sofom_id SET DEFAULT nextval('public.sofom_sofom_id_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 34048)
-- Name: tf_catalogos id_opcion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_catalogos ALTER COLUMN id_opcion SET DEFAULT nextval('public.tf_catalogos_id_opcion_seq'::regclass);


--
-- TOC entry 4987 (class 2604 OID 34021)
-- Name: tf_operadores id_operador; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_operadores ALTER COLUMN id_operador SET DEFAULT nextval('public.tf_operadores_id_operador_seq'::regclass);


--
-- TOC entry 4988 (class 2604 OID 34029)
-- Name: tf_tipos_acciones id_tipo_accion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_acciones ALTER COLUMN id_tipo_accion SET DEFAULT nextval('public.tf_tipos_acciones_id_tipo_accion_seq'::regclass);


--
-- TOC entry 4984 (class 2604 OID 33982)
-- Name: tf_tipos_alerta tipo_alerta_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_alerta ALTER COLUMN tipo_alerta_id SET DEFAULT nextval('public.tf_tipos_alerta_tipo_alerta_id_seq'::regclass);


--
-- TOC entry 4986 (class 2604 OID 34004)
-- Name: tf_tipos_documento tipo_documento_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_documento ALTER COLUMN tipo_documento_id SET DEFAULT nextval('public.tf_tipos_documento_tipo_documento_id_seq'::regclass);


--
-- TOC entry 4982 (class 2604 OID 33960)
-- Name: tf_tipos_entidad tipo_entidad_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_entidad ALTER COLUMN tipo_entidad_id SET DEFAULT nextval('public.tf_tipos_entidad_tipo_entidad_id_seq'::regclass);


--
-- TOC entry 4985 (class 2604 OID 33993)
-- Name: tf_tipos_persona tipo_persona_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_persona ALTER COLUMN tipo_persona_id SET DEFAULT nextval('public.tf_tipos_persona_tipo_persona_id_seq'::regclass);


--
-- TOC entry 4983 (class 2604 OID 33971)
-- Name: tf_tipos_regla tipo_regla_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_regla ALTER COLUMN tipo_regla_id SET DEFAULT nextval('public.tf_tipos_regla_tipo_regla_id_seq'::regclass);


--
-- TOC entry 4989 (class 2604 OID 34037)
-- Name: tf_tipos_reporte tipo_reporte_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_reporte ALTER COLUMN tipo_reporte_id SET DEFAULT nextval('public.tf_tipos_reporte_tipo_reporte_id_seq'::regclass);


--
-- TOC entry 5003 (class 2604 OID 34634)
-- Name: usuarios usuario_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN usuario_id SET DEFAULT nextval('public.usuarios_usuario_id_seq'::regclass);


--
-- TOC entry 5336 (class 0 OID 34856)
-- Dependencies: 268
-- Data for Name: alertas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5324 (class 0 OID 34660)
-- Dependencies: 256
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.clientes VALUES (1, 1, 'María Fernanda López García', '4421234567', 'maria.lopez@email.com', '032180000118359719', 'EFIRMA123456789ABC', '20.5888,-100.3899', false, false, '2026-05-21 11:15:52.267273-06', 0, 'LOGM990315MQTRRR09', 'LOGM990315H12', 'Femenino', '1999-03-15', 'México', 'Querétaro', NULL, NULL, 1, 1, 3, 5, 2, 1, 1, 0, 4, 2, 1, 3, 3, 2, NULL, NULL, NULL, NULL);
INSERT INTO public.clientes VALUES (2, 2, 'Constructora Horizonte S.A. de C.V.', '5519876543', 'contacto@constructorahorizonte.com', '032180000118359720', 'EFIRMA987654321XYZ', '19.4326,-99.1332', false, false, '2026-05-21 11:16:01.336944-06', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'Carlos Alberto Ramírez Torres', '2016-08-22', 1, 1, 2, 8, 1, 0, 0, 0, 0, 0, 3, 5, 5, 0, NULL, NULL, NULL, NULL);


--
-- TOC entry 5330 (class 0 OID 34764)
-- Dependencies: 262
-- Data for Name: contratos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5311 (class 0 OID 34508)
-- Dependencies: 243
-- Data for Name: criterios; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5328 (class 0 OID 34740)
-- Dependencies: 260
-- Data for Name: documentos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5313 (class 0 OID 34531)
-- Dependencies: 245
-- Data for Name: listas_riesgo; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5315 (class 0 OID 34546)
-- Dependencies: 247
-- Data for Name: logs_auditoria; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5332 (class 0 OID 34797)
-- Dependencies: 264
-- Data for Name: operaciones; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5326 (class 0 OID 34709)
-- Dependencies: 258
-- Data for Name: perfiles_cliente; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5318 (class 0 OID 34601)
-- Dependencies: 250
-- Data for Name: regla_criterios; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5317 (class 0 OID 34564)
-- Dependencies: 249
-- Data for Name: reglas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5334 (class 0 OID 34821)
-- Dependencies: 266
-- Data for Name: reportes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5320 (class 0 OID 34620)
-- Dependencies: 252
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--
