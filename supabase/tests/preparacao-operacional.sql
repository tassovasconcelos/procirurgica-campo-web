begin;
do $$
declare e uuid:=gen_random_uuid();adm uuid:=gen_random_uuid();gest uuid:=gen_random_uuid();n uuid:=gen_random_uuid();req uuid:=gen_random_uuid();nov uuid:=gen_random_uuid();
begin
 insert into public.campo_empresas(id,nome) values(e,'EMPRESA FICTICIA AUDITORIA');
 insert into auth.users(id,email,email_confirmed_at) values(adm,'adm-'||adm::text||'@example.invalid',now()),(gest,'gest-'||gest::text||'@example.invalid',now()),(n,'n-'||n::text||'@example.invalid',now());
 insert into public.campo_perfis(id,empresa_id,nome,papel,profissao,gestor_id) values(adm,e,'ADMIN FICTICIO','superadmin',null,null),(gest,e,'GESTOR FICTICIO','gestor',null,null),(n,e,'PROFISSIONAL FICTICIO','campo','enfermeiro',gest);
 perform set_config('test.adm',adm::text,true);perform set_config('test.gest',gest::text,true);perform set_config('test.nurse',n::text,true);perform set_config('test.empresa',e::text,true);perform set_config('test.convite',req::text,true);perform set_config('test.novo',nov::text,true);
 perform set_config('test.email','novo-'||nov::text||'@example.invalid',true);perform set_config('request.jwt.claim.sub',adm::text,true);
end$$;
set local role authenticated;
do $$
declare d jsonb;r jsonb;id uuid:=current_setting('test.convite')::uuid;v uuid:=gen_random_uuid();proto uuid:=gen_random_uuid();
begin
 d=jsonb_build_object('email',current_setting('test.email'),'nome','NOVA CONTA FICTICIA','papel','gestor','profissao','','gestor','');
 r=public.campo_preparar_convite(id,d);if r->>'novo'<>'true' then raise exception 'FAIL reserva';end if;
 if public.campo_preparar_convite(id,d)->>'novo'<>'false' then raise exception 'FAIL repetir convite';end if;
 if has_function_privilege('authenticated','public.campo_concluir_convite_servico(uuid,uuid,uuid,text)','execute') then raise exception 'FAIL privilegio servico';end if;
 begin perform public.campo_preparar_convite(gen_random_uuid(),d||jsonb_build_object('email','adm-'||current_setting('test.adm')||'@example.invalid'));raise exception 'FAIL convite conta existente';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 begin perform public.campo_salvar_cadastro_paciente(gen_random_uuid(),'{"codigo":"FICT-ADMIN","nome":"Paciente ficticio","linha":"stomapro","cidade":"","uf":"","telefone":""}','{"responsavel_tipo":"proprio","modalidade":"nao_informado","tem_plano":false,"etapa":"adaptacao","perfil_upsell":"nao_avaliado","produtos":[]}',current_setting('test.adm')::uuid,null,true);raise exception 'FAIL paciente com administrador nao assistencial';exception when insufficient_privilege then null;end;
 perform public.campo_salvar_cadastro_paciente(gen_random_uuid(),'{"codigo":"FICT-NURSE","nome":"Paciente ficticio","linha":"stomapro","cidade":"","uf":"","telefone":""}','{"responsavel_tipo":"proprio","modalidade":"nao_informado","tem_plano":false,"etapa":"adaptacao","perfil_upsell":"nao_avaliado","produtos":[]}',current_setting('test.nurse')::uuid,null,true);
 perform public.campo_registrar_validacao_operacional(v,'cadastro','em_teste','Cenario ficticio em teste',0);
 if public.campo_registrar_validacao_operacional(v,'cadastro','em_teste','Cenario ficticio em teste',0)<>v then raise exception 'FAIL validacao retry';end if;
 begin perform public.campo_registrar_validacao_operacional(gen_random_uuid(),'cadastro','aprovado','ok',1);raise exception 'FAIL aprovacao sem evidencia';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 insert into public.campo_testes(id,empresa_id,responsavel_id,instituicao,produto,objetivo,criterios,quantidade,status,homologacao) values(proto,current_setting('test.empresa')::uuid,current_setting('test.adm')::uuid,'INSTITUICAO FICTICIA','PRODUTO FICTICIO','Objetivo ficticio','Criterios ficticios',1,'planejado',true);
 update public.campo_testes set status='aprovado',resultado='Resultado ficticio justificado' where campo_testes.id=proto;
 if (select count(*) from public.campo_historico_teste(proto))<>2 then raise exception 'FAIL revisoes protocolo';end if;
 begin update public.campo_testes set resultado='Outra avaliacao' where campo_testes.id=proto;raise exception 'FAIL protocolo encerrado editavel';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 perform set_config('request.jwt.claim.sub',current_setting('test.gest'),true);
 begin perform public.campo_preparar_convite(gen_random_uuid(),d);raise exception 'FAIL gestor convidou';exception when insufficient_privilege then null;end;
 if exists(select 1 from public.campo_validacoes_operacionais where escopo='empresa') then raise exception 'FAIL gestor leu aprovacao global';end if;
 perform set_config('request.jwt.claim.sub',current_setting('test.nurse'),true);
 begin perform public.campo_diagnostico_operacional();raise exception 'FAIL campo diagnostico';exception when insufficient_privilege then null;end;
end$$;
reset role;
insert into auth.users(id,email,invited_at,created_at) values(current_setting('test.novo')::uuid,current_setting('test.email'),now(),now());
set local role service_role;
select public.campo_concluir_convite_servico(current_setting('test.convite')::uuid,current_setting('test.adm')::uuid,current_setting('test.novo')::uuid,'enviado');
reset role;
select set_config('request.jwt.claim.sub',current_setting('test.adm'),true);
set local role authenticated;
do $$declare d jsonb;begin
 d=public.campo_diagnostico_operacional();
 if (d->>'pendentes_ativacao')::integer<>1 then raise exception 'FAIL pendencia ativacao';end if;
 if has_table_privilege('authenticated','public.campo_validacoes_operacionais','update') or has_table_privilege('anon','public.campo_convites','select') then raise exception 'FAIL grants';end if;
end$$;
reset role;
rollback;