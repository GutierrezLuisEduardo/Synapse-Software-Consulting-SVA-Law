
--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 267
-- Name: alertas_alerta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.alertas_alerta_id_seq', 1, false);


--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 255
-- Name: clientes_cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.clientes_cliente_id_seq', 2, true);


--
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 261
-- Name: contratos_contrato_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.contratos_contrato_id_seq', 1, false);


--
-- TOC entry 5369 (class 0 OID 0)
-- Dependencies: 242
-- Name: criterios_criterio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.criterios_criterio_id_seq', 1, false);


--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 259
-- Name: documentos_documento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.documentos_documento_id_seq', 1, false);


--
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 244
-- Name: listas_riesgo_lista_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.listas_riesgo_lista_id_seq', 1, false);


--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 246
-- Name: logs_auditoria_id_accion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.logs_auditoria_id_accion_seq', 1, false);


--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 263
-- Name: operaciones_operacion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.operaciones_operacion_id_seq', 1, false);


--
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 257
-- Name: perfiles_cliente_perfiles_cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.perfiles_cliente_perfiles_cliente_id_seq', 1, false);


--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 248
-- Name: reglas_regla_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reglas_regla_id_seq', 1, false);


--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 265
-- Name: reportes_reporte_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reportes_reporte_id_seq', 1, false);


--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 251
-- Name: roles_rol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_rol_id_seq', 4, true);


--
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 240
-- Name: sofom_sofom_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sofom_sofom_id_seq', 2, true);


--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 238
-- Name: tf_catalogos_id_opcion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_catalogos_id_opcion_seq', 9349, true);


--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 232
-- Name: tf_operadores_id_operador_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_operadores_id_operador_seq', 1, false);


--
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 234
-- Name: tf_tipos_acciones_id_tipo_accion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_acciones_id_tipo_accion_seq', 1, false);


--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 226
-- Name: tf_tipos_alerta_tipo_alerta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_alerta_tipo_alerta_id_seq', 3, true);


--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 230
-- Name: tf_tipos_documento_tipo_documento_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_documento_tipo_documento_id_seq', 101, true);


--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 222
-- Name: tf_tipos_entidad_tipo_entidad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_entidad_tipo_entidad_id_seq', 2, true);


--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 228
-- Name: tf_tipos_persona_tipo_persona_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_persona_tipo_persona_id_seq', 1, false);


--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 224
-- Name: tf_tipos_regla_tipo_regla_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_regla_tipo_regla_id_seq', 3, true);


--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 236
-- Name: tf_tipos_reporte_tipo_reporte_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tf_tipos_reporte_tipo_reporte_id_seq', 4, true);


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 253
-- Name: usuarios_usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuarios_usuario_id_seq', 3, true);


--
-- TOC entry 5103 (class 2606 OID 34869)
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (alerta_id);


--
-- TOC entry 5091 (class 2606 OID 34697)
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (cliente_id);


--
-- TOC entry 5097 (class 2606 OID 34785)
-- Name: contratos contratos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT contratos_pkey PRIMARY KEY (contrato_id);


--
-- TOC entry 5071 (class 2606 OID 34519)
-- Name: criterios criterios_id_catalogo_id_operador_id_opcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterios
    ADD CONSTRAINT criterios_id_catalogo_id_operador_id_opcion_key UNIQUE (id_catalogo, id_operador, id_opcion);


--
-- TOC entry 5073 (class 2606 OID 34517)
-- Name: criterios criterios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterios
    ADD CONSTRAINT criterios_pkey PRIMARY KEY (criterio_id);


--
-- TOC entry 5095 (class 2606 OID 34752)
-- Name: documentos documentos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT documentos_pkey PRIMARY KEY (documento_id);


--
-- TOC entry 5075 (class 2606 OID 34539)
-- Name: listas_riesgo listas_riesgo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listas_riesgo
    ADD CONSTRAINT listas_riesgo_pkey PRIMARY KEY (lista_id);


--
-- TOC entry 5077 (class 2606 OID 34557)
-- Name: logs_auditoria logs_auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_auditoria
    ADD CONSTRAINT logs_auditoria_pkey PRIMARY KEY (id_accion);


--
-- TOC entry 5099 (class 2606 OID 34814)
-- Name: operaciones operaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT operaciones_pkey PRIMARY KEY (operacion_id);


--
-- TOC entry 5093 (class 2606 OID 34728)
-- Name: perfiles_cliente perfiles_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfiles_cliente
    ADD CONSTRAINT perfiles_cliente_pkey PRIMARY KEY (perfiles_cliente_id);


--
-- TOC entry 5081 (class 2606 OID 34608)
-- Name: regla_criterios regla_criterios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_criterios
    ADD CONSTRAINT regla_criterios_pkey PRIMARY KEY (regla_id, criterio_id);


--
-- TOC entry 5079 (class 2606 OID 34580)
-- Name: reglas reglas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas
    ADD CONSTRAINT reglas_pkey PRIMARY KEY (regla_id);


--
-- TOC entry 5101 (class 2606 OID 34834)
-- Name: reportes reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_pkey PRIMARY KEY (reporte_id);


--
-- TOC entry 5083 (class 2606 OID 34629)
-- Name: roles roles_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_descripcion_key UNIQUE (descripcion);


--
-- TOC entry 5085 (class 2606 OID 34627)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (rol_id);


--
-- TOC entry 5069 (class 2606 OID 34501)
-- Name: sofom sofom_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sofom
    ADD CONSTRAINT sofom_pkey PRIMARY KEY (sofom_id);


--
-- TOC entry 5065 (class 2606 OID 34051)
-- Name: tf_catalogos tf_catalogos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_catalogos
    ADD CONSTRAINT tf_catalogos_pkey PRIMARY KEY (id_opcion);


--
-- TOC entry 5035 (class 2606 OID 33949)
-- Name: tf_clasificaciones tf_clasificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_clasificaciones
    ADD CONSTRAINT tf_clasificaciones_pkey PRIMARY KEY (clasificacion_id);


--
-- TOC entry 5037 (class 2606 OID 33955)
-- Name: tf_criterios_ebr tf_criterios_ebr_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_criterios_ebr
    ADD CONSTRAINT tf_criterios_ebr_pkey PRIMARY KEY (id);


--
-- TOC entry 5059 (class 2606 OID 34024)
-- Name: tf_operadores tf_operadores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_operadores
    ADD CONSTRAINT tf_operadores_pkey PRIMARY KEY (id_operador);


--
-- TOC entry 5061 (class 2606 OID 34032)
-- Name: tf_tipos_acciones tf_tipos_acciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_acciones
    ADD CONSTRAINT tf_tipos_acciones_pkey PRIMARY KEY (id_tipo_accion);


--
-- TOC entry 5047 (class 2606 OID 33988)
-- Name: tf_tipos_alerta tf_tipos_alerta_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_alerta
    ADD CONSTRAINT tf_tipos_alerta_descripcion_key UNIQUE (descripcion);


--
-- TOC entry 5049 (class 2606 OID 33986)
-- Name: tf_tipos_alerta tf_tipos_alerta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_alerta
    ADD CONSTRAINT tf_tipos_alerta_pkey PRIMARY KEY (tipo_alerta_id);


--
-- TOC entry 5055 (class 2606 OID 41693)
-- Name: tf_tipos_documento tf_tipos_documento_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_documento
    ADD CONSTRAINT tf_tipos_documento_descripcion_key UNIQUE (descripcion);


--
-- TOC entry 5057 (class 2606 OID 34009)
-- Name: tf_tipos_documento tf_tipos_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_documento
    ADD CONSTRAINT tf_tipos_documento_pkey PRIMARY KEY (tipo_documento_id);


--
-- TOC entry 5039 (class 2606 OID 33966)
-- Name: tf_tipos_entidad tf_tipos_entidad_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_entidad
    ADD CONSTRAINT tf_tipos_entidad_descripcion_key UNIQUE (descripcion);


--
-- TOC entry 5041 (class 2606 OID 33964)
-- Name: tf_tipos_entidad tf_tipos_entidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_entidad
    ADD CONSTRAINT tf_tipos_entidad_pkey PRIMARY KEY (tipo_entidad_id);


--
-- TOC entry 5051 (class 2606 OID 33999)
-- Name: tf_tipos_persona tf_tipos_persona_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_persona
    ADD CONSTRAINT tf_tipos_persona_descripcion_key UNIQUE (descripcion);


--
-- TOC entry 5053 (class 2606 OID 33997)
-- Name: tf_tipos_persona tf_tipos_persona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_persona
    ADD CONSTRAINT tf_tipos_persona_pkey PRIMARY KEY (tipo_persona_id);


--
-- TOC entry 5033 (class 2606 OID 33943)
-- Name: tf_tipos tf_tipos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos
    ADD CONSTRAINT tf_tipos_pkey PRIMARY KEY (tipo_id);


--
-- TOC entry 5043 (class 2606 OID 33977)
-- Name: tf_tipos_regla tf_tipos_regla_descripcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_regla
    ADD CONSTRAINT tf_tipos_regla_descripcion_key UNIQUE (descripcion);


--
-- TOC entry 5045 (class 2606 OID 33975)
-- Name: tf_tipos_regla tf_tipos_regla_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_regla
    ADD CONSTRAINT tf_tipos_regla_pkey PRIMARY KEY (tipo_regla_id);


--
-- TOC entry 5063 (class 2606 OID 34043)
-- Name: tf_tipos_reporte tf_tipos_reporte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_reporte
    ADD CONSTRAINT tf_tipos_reporte_pkey PRIMARY KEY (tipo_reporte_id);


--
-- TOC entry 5067 (class 2606 OID 34053)
-- Name: tf_catalogos uq_tf_catalogos_catalogo_opcion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_catalogos
    ADD CONSTRAINT uq_tf_catalogos_catalogo_opcion UNIQUE (catalogo_id, opciones);


--
-- TOC entry 5087 (class 2606 OID 34648)
-- Name: usuarios usuarios_correo_electronico_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_electronico_key UNIQUE (correo_electronico);


--
-- TOC entry 5089 (class 2606 OID 34646)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (usuario_id);


--
-- TOC entry 5109 (class 2606 OID 34520)
-- Name: criterios criterios_id_catalogo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterios
    ADD CONSTRAINT criterios_id_catalogo_fkey FOREIGN KEY (id_catalogo) REFERENCES public.tf_tipos(tipo_id);


--
-- TOC entry 5110 (class 2606 OID 34525)
-- Name: criterios criterios_id_operador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criterios
    ADD CONSTRAINT criterios_id_operador_fkey FOREIGN KEY (id_operador) REFERENCES public.tf_operadores(id_operador);


--
-- TOC entry 5112 (class 2606 OID 34558)
-- Name: logs_auditoria fk_acciones_logs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_auditoria
    ADD CONSTRAINT fk_acciones_logs FOREIGN KEY (id_tipo_accion) REFERENCES public.tf_tipos_acciones(id_tipo_accion);


--
-- TOC entry 5135 (class 2606 OID 34875)
-- Name: alertas fk_alertas_operacion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alertas_operacion FOREIGN KEY (operacion_id) REFERENCES public.operaciones(operacion_id);


--
-- TOC entry 5136 (class 2606 OID 34870)
-- Name: alertas fk_alertas_regla; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alertas_regla FOREIGN KEY (regla_id) REFERENCES public.reglas(regla_id);


--
-- TOC entry 5137 (class 2606 OID 34880)
-- Name: alertas fk_alertas_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alertas_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5138 (class 2606 OID 34890)
-- Name: alertas fk_alertas_tipo_alerta; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alertas_tipo_alerta FOREIGN KEY (tipo_alerta_id) REFERENCES public.tf_tipos_alerta(tipo_alerta_id);


--
-- TOC entry 5139 (class 2606 OID 34885)
-- Name: alertas fk_alertas_tipo_reporte; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT fk_alertas_tipo_reporte FOREIGN KEY (tipo_reporte_id) REFERENCES public.tf_tipos_reporte(tipo_reporte_id);


--
-- TOC entry 5121 (class 2606 OID 34703)
-- Name: clientes fk_clientes_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_clientes_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5122 (class 2606 OID 34698)
-- Name: clientes fk_clientes_tipo_persona; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_clientes_tipo_persona FOREIGN KEY (id_tipo_persona) REFERENCES public.tf_tipos_persona(tipo_persona_id);


--
-- TOC entry 5127 (class 2606 OID 34895)
-- Name: contratos fk_contratos_id_ultima_operacion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT fk_contratos_id_ultima_operacion FOREIGN KEY (id_ultima_operacion) REFERENCES public.operaciones(operacion_id);


--
-- TOC entry 5128 (class 2606 OID 34786)
-- Name: contratos fk_contratos_perfiles_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT fk_contratos_perfiles_cliente FOREIGN KEY (perfiles_cliente_id) REFERENCES public.perfiles_cliente(perfiles_cliente_id);


--
-- TOC entry 5129 (class 2606 OID 34791)
-- Name: contratos fk_contratos_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT fk_contratos_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5125 (class 2606 OID 34758)
-- Name: documentos fk_documentos_perfiles_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT fk_documentos_perfiles_cliente FOREIGN KEY (perfiles_cliente_id) REFERENCES public.perfiles_cliente(perfiles_cliente_id);


--
-- TOC entry 5126 (class 2606 OID 34753)
-- Name: documentos fk_documentos_tipo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos
    ADD CONSTRAINT fk_documentos_tipo FOREIGN KEY (tipo_documento_id) REFERENCES public.tf_tipos_documento(tipo_documento_id);


--
-- TOC entry 5111 (class 2606 OID 34540)
-- Name: listas_riesgo fk_listas_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listas_riesgo
    ADD CONSTRAINT fk_listas_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5130 (class 2606 OID 34815)
-- Name: operaciones fk_operaciones_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operaciones
    ADD CONSTRAINT fk_operaciones_contrato FOREIGN KEY (contrato_id) REFERENCES public.contratos(contrato_id);


--
-- TOC entry 5123 (class 2606 OID 34729)
-- Name: perfiles_cliente fk_perfiles_cliente_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfiles_cliente
    ADD CONSTRAINT fk_perfiles_cliente_cliente FOREIGN KEY (cliente_id) REFERENCES public.clientes(cliente_id);


--
-- TOC entry 5124 (class 2606 OID 34734)
-- Name: perfiles_cliente fk_perfiles_cliente_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfiles_cliente
    ADD CONSTRAINT fk_perfiles_cliente_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5113 (class 2606 OID 34596)
-- Name: reglas fk_reglas_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas
    ADD CONSTRAINT fk_reglas_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5114 (class 2606 OID 34591)
-- Name: reglas fk_reglas_tipo_entidad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas
    ADD CONSTRAINT fk_reglas_tipo_entidad FOREIGN KEY (tipo_entidad_id) REFERENCES public.tf_tipos_entidad(tipo_entidad_id);


--
-- TOC entry 5115 (class 2606 OID 34581)
-- Name: reglas fk_reglas_tipo_regla; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas
    ADD CONSTRAINT fk_reglas_tipo_regla FOREIGN KEY (tipo_regla_id) REFERENCES public.tf_tipos_regla(tipo_regla_id);


--
-- TOC entry 5116 (class 2606 OID 34586)
-- Name: reglas fk_reglas_tipo_reporte; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reglas
    ADD CONSTRAINT fk_reglas_tipo_reporte FOREIGN KEY (tipo_reporte_id) REFERENCES public.tf_tipos_reporte(tipo_reporte_id);


--
-- TOC entry 5131 (class 2606 OID 34840)
-- Name: reportes fk_reportes_operacion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_reportes_operacion FOREIGN KEY (operacion_id) REFERENCES public.operaciones(operacion_id);


--
-- TOC entry 5132 (class 2606 OID 34850)
-- Name: reportes fk_reportes_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_reportes_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5133 (class 2606 OID 34845)
-- Name: reportes fk_reportes_tipo_entidad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_reportes_tipo_entidad FOREIGN KEY (tipo_entidad_id) REFERENCES public.tf_tipos_entidad(tipo_entidad_id);


--
-- TOC entry 5134 (class 2606 OID 34835)
-- Name: reportes fk_reportes_tipo_reporte; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT fk_reportes_tipo_reporte FOREIGN KEY (tipo_reporte_id) REFERENCES public.tf_tipos_reporte(tipo_reporte_id);


--
-- TOC entry 5108 (class 2606 OID 34502)
-- Name: sofom fk_sofom_tipo_entidad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sofom
    ADD CONSTRAINT fk_sofom_tipo_entidad FOREIGN KEY (tipo_entidad_id) REFERENCES public.tf_tipos_entidad(tipo_entidad_id);


--
-- TOC entry 5105 (class 2606 OID 34064)
-- Name: tf_catalogos fk_tf_catalogos_clasificacion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_catalogos
    ADD CONSTRAINT fk_tf_catalogos_clasificacion FOREIGN KEY (clasificacion_id) REFERENCES public.tf_clasificaciones(clasificacion_id);


--
-- TOC entry 5106 (class 2606 OID 34054)
-- Name: tf_catalogos fk_tf_catalogos_criterio; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_catalogos
    ADD CONSTRAINT fk_tf_catalogos_criterio FOREIGN KEY (catalogo_id) REFERENCES public.tf_criterios_ebr(id);


--
-- TOC entry 5107 (class 2606 OID 34059)
-- Name: tf_catalogos fk_tf_catalogos_tipo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_catalogos
    ADD CONSTRAINT fk_tf_catalogos_tipo FOREIGN KEY (tipo_id) REFERENCES public.tf_tipos(tipo_id);


--
-- TOC entry 5104 (class 2606 OID 34012)
-- Name: tf_tipos_documento fk_tiposdocumento_tipopersona; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tf_tipos_documento
    ADD CONSTRAINT fk_tiposdocumento_tipopersona FOREIGN KEY (tipo_persona_id) REFERENCES public.tf_tipos_persona(tipo_persona_id);


--
-- TOC entry 5119 (class 2606 OID 34649)
-- Name: usuarios fk_usuarios_roles; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT fk_usuarios_roles FOREIGN KEY (rol_id) REFERENCES public.roles(rol_id);


--
-- TOC entry 5120 (class 2606 OID 34654)
-- Name: usuarios fk_usuarios_sofom; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT fk_usuarios_sofom FOREIGN KEY (sofom_id) REFERENCES public.sofom(sofom_id);


--
-- TOC entry 5117 (class 2606 OID 34614)
-- Name: regla_criterios regla_criterios_criterio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_criterios
    ADD CONSTRAINT regla_criterios_criterio_id_fkey FOREIGN KEY (criterio_id) REFERENCES public.criterios(criterio_id) ON DELETE CASCADE;


--
-- TOC entry 5118 (class 2606 OID 34609)
-- Name: regla_criterios regla_criterios_regla_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_criterios
    ADD CONSTRAINT regla_criterios_regla_id_fkey FOREIGN KEY (regla_id) REFERENCES public.reglas(regla_id) ON DELETE CASCADE;


-- Completed on 2026-05-22 19:31:33

--
-- PostgreSQL database dump complete
--

