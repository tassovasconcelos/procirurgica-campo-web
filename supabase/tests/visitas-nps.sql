begin;
do $$
declare e uuid:=gen_random_uuid(); n uuid:=gen_random_uuid(); g uuid:=gen_random_uuid(); o uuid:=gen_random_uuid(); c uuid:=gen_random_uuid(); p uuid:=gen_random_uuid(); vid uuid:=gen_random_uuid(); rid uuid:=gen_random_uuid();
begin
 insert into public.campo_empresas(id,nome) values(e,'TESTE AGENDA');
 insert into auth.users(id) values(n),(g),(o),(c);
 insert into public.campo_perfis(id,empresa_id,nome,papel,profissao,gestor_id) values(g,e,'GESTOR FICTICIO','gestor',null,null),(n,e,'ENFERMEIRO FICTICIO','campo','enfermeiro',g),(o,e,'OUTRO GESTOR','gestor',null,null),(c,e,'COMERCIAL','campo','comercial',g);
 insert into public.campo_pacientes(id,empresa_id,responsavel_id,codigo,nome,linha,consentimento,termo_versao) values(p,e,n,'TESTE-VISITA','PACIENTE FICTICIO','stomapro',true,'homologacao-v1');
 perform set_config('test.nurse',n::text,true);perform set_config('test.other',o::text,true);perform set_config('test.commercial',c::text,true);perform set_config('test.patient',p::text,true);perform set_config('test.visit',vid::text,true);perform set_config('test.record',rid::text,true);
 perform set_config('request.jwt.claim.sub',n::text,true);
end$$;
set local role authenticated;
do $$
declare v jsonb;d jsonb;request uuid:=gen_random_uuid();result uuid;score uuid:=gen_random_uuid();p uuid:=current_setting('test.patient')::uuid;n uuid:=current_setting('test.nurse')::uuid;vid uuid:=current_setting('test.visit')::uuid;rid uuid:=current_setting('test.record')::uuid;
begin
 d=jsonb_build_object('id',vid,'paciente_id',p,'profissional_id',n,'inicio',now()-interval '1 day','fim',now()-interval '23 hours','status','agendada','objetivo','Visita ficticia','motivo','','registro_id',null,'versao',0,'homologacao',true);
 v=public.campo_salvar_visita(request,d);
 if v<>public.campo_salvar_visita(request,d) then raise exception 'FAIL idempotencia';end if;
 begin perform public.campo_salvar_visita(gen_random_uuid(),d||jsonb_build_object('id',gen_random_uuid()));raise exception 'FAIL conflito nao bloqueado';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;if sqlerrm not like 'Conflito%' then raise;end if;end;
 begin perform public.campo_salvar_visita(gen_random_uuid(),d||'{"versao":1,"status":"realizada"}');raise exception 'FAIL realizada sem prontuario';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 begin perform public.campo_registrar_prontuario(gen_random_uuid(),p,'evolucao',now(),'{"avaliacao":"Teste ficticio","situacao_evolucao":"melhora"}',null,true);raise exception 'FAIL melhora sem evidencia';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 perform public.campo_registrar_prontuario(rid,p,'evolucao',now()-interval '1 day','{"avaliacao":"Avaliacao ficticia"}',null,true);
 d=d||jsonb_build_object('versao',1,'status','realizada','registro_id',rid);
 v=public.campo_salvar_visita(gen_random_uuid(),d);
 if (v->>'versao')::integer<>2 then raise exception 'FAIL versao';end if;
 if (select count(*) from public.campo_visita_historico where visita_id=vid)<>2 then raise exception 'FAIL historico';end if;
 begin perform public.campo_salvar_visita(gen_random_uuid(),d||'{"versao":2,"status":"cancelada","motivo":"Teste"}');raise exception 'FAIL encerrada editavel';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 begin perform public.campo_registrar_nps(gen_random_uuid(),vid,11,'paciente','');raise exception 'FAIL nota';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 result=public.campo_registrar_nps(score,vid,10,'cuidador','Teste ficticio');
 if result<>public.campo_registrar_nps(score,vid,10,'cuidador','Teste ficticio') then raise exception 'FAIL pesquisa retry';end if;
 if has_table_privilege('authenticated','public.campo_visitas','insert') or has_table_privilege('authenticated','public.campo_visita_nps','update') or has_function_privilege('anon','public.campo_salvar_visita(uuid,jsonb)','execute') then raise exception 'FAIL grants';end if;
 perform set_config('request.jwt.claim.sub',current_setting('test.other'),true);
 if (select count(*) from public.campo_visitas where id=vid)<>0 or (select count(*) from public.campo_visita_nps where visita_id=vid)<>0 then raise exception 'FAIL RLS outro gestor';end if;
 begin perform public.campo_salvar_visita(gen_random_uuid(),d);raise exception 'FAIL outra equipe';exception when insufficient_privilege then null;end;
 perform set_config('request.jwt.claim.sub',current_setting('test.commercial'),true);
 if (select count(*) from public.campo_visitas where id=vid)<>0 then raise exception 'FAIL RLS comercial';end if;
end$$;
reset role;
rollback;