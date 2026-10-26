begin;
do $$
declare e uuid:=gen_random_uuid();n uuid:=gen_random_uuid();j uuid:=gen_random_uuid();p uuid:=gen_random_uuid();v uuid:=gen_random_uuid();doc uuid:=gen_random_uuid();
begin
 insert into public.campo_empresas(id,nome) values(e,'TESTE QUATRO FRENTES');
 insert into auth.users(id) values(n),(j);
 insert into public.campo_perfis(id,empresa_id,nome,papel,profissao) values(n,e,'ENFERMEIRO FICTICIO','campo','enfermeiro'),(j,e,'JURIDICO FICTICIO','juridico',null);
 insert into public.campo_pacientes(id,empresa_id,responsavel_id,codigo,nome,linha,consentimento,termo_versao) values(p,e,n,'FICTICIO-11','PACIENTE FICTICIO','stomapro',true,'homologacao-v1');
 insert into public.campo_visitas(id,paciente_id,empresa_id,profissional_id,inicio,fim,status,objetivo,atualizado_por) values(v,p,e,n,now()-interval '2 hours',now()-interval '1 hour','realizada','Visita ficticia',n);
 insert into public.campo_documentos_pessoais(id,paciente_id,empresa_id,enviado_por,categoria,nome,mime,tamanho,caminho,status,sha256,confirmado_em) values(doc,p,e,n,'identidade','FICTICIO.png','image/png',8,e::text||'/'||p::text||'/'||doc::text||'.png','confirmado',repeat('a',64),now());
 perform set_config('test.nurse',n::text,true);perform set_config('test.legal',j::text,true);perform set_config('test.patient',p::text,true);perform set_config('test.visit',v::text,true);perform set_config('test.doc',doc::text,true);
 perform set_config('test.meta',gen_random_uuid()::text,true);perform set_config('test.task',gen_random_uuid()::text,true);
 perform set_config('request.jwt.claim.sub',n::text,true);
end$$;
set local role authenticated;
do $$
declare p uuid:=current_setting('test.patient')::uuid;m uuid:=current_setting('test.meta')::uuid;t uuid:=current_setting('test.task')::uuid;ev uuid:=gen_random_uuid();c uuid:=gen_random_uuid();r jsonb;d jsonb;
begin
 d='{"titulo":"Meta ficticia","criterio":"Criterio informado","prazo":"2030-01-01","status":"aberta","evidencia":"","observacao":""}';
 r=public.campo_registrar_acao(ev,m,p,'meta',0,d);
 if r<>public.campo_registrar_acao(ev,m,p,'meta',0,d) then raise exception 'FAIL idempotencia';end if;
 perform public.campo_registrar_acao(gen_random_uuid(),t,p,'tarefa',0,jsonb_build_object('titulo','Tarefa ficticia','meta_id',m,'prazo','2030-01-01','status','aberta','executor','cuidador','evidencia','','observacao',''));
 begin perform public.campo_registrar_acao(gen_random_uuid(),m,p,'meta',1,d||'{"status":"concluida","evidencia":"Teste informado"}');raise exception 'FAIL meta com tarefa aberta';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 begin perform public.campo_registrar_acao(gen_random_uuid(),t,p,'tarefa',1,jsonb_build_object('titulo','Tarefa ficticia','meta_id',m,'prazo','2030-01-01','status','concluida','executor','cuidador','evidencia','','observacao',''));raise exception 'FAIL tarefa sem evidencia';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 perform public.campo_registrar_acao(gen_random_uuid(),t,p,'tarefa',1,jsonb_build_object('titulo','Tarefa ficticia','meta_id',m,'prazo','2030-01-01','status','concluida','executor','cuidador','evidencia','Conclusao ficticia','observacao',''));
 perform public.campo_registrar_acao(gen_random_uuid(),m,p,'meta',1,d||'{"status":"concluida","evidencia":"Criterio ficticio atingido"}');
 d=jsonb_build_object('produto','Produto ficticio','referencia','T1','unidade','unidade','consumo_dia','4','estoque','24','data_referencia',(now() at time zone 'America/Sao_Paulo')::date::text,'origem','cuidador','observacao','Ficticio');
 begin perform public.campo_registrar_acao(gen_random_uuid(),c,p,'consumo',0,d||'{"estoque":"-1"}');raise exception 'FAIL estoque negativo';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 perform public.campo_registrar_acao(gen_random_uuid(),c,p,'consumo',0,d);
 begin perform public.campo_registrar_acao(gen_random_uuid(),c,p,'consumo',1,d);raise exception 'FAIL alteracao consumo';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 begin perform public.campo_registrar_acao(gen_random_uuid(),gen_random_uuid(),p,'juridico',0,'{}');raise exception 'FAIL clinico revisou juridico';exception when insufficient_privilege then null;end;
 perform public.campo_emitir_pesquisa(gen_random_uuid(),current_setting('test.visit')::uuid,repeat('a',64));
 perform set_config('test.linkb',gen_random_uuid()::text,true);
 perform public.campo_emitir_pesquisa(current_setting('test.linkb')::uuid,current_setting('test.visit')::uuid,repeat('b',64));
end$$;
reset role;
update public.campo_pesquisa_links set expira_em=now()-interval '1 second' where id=current_setting('test.linkb')::uuid;
set local role anon;
do $$begin
 if has_table_privilege('anon','public.campo_acoes_paciente','select') or has_table_privilege('anon','public.campo_pesquisa_links','select') or has_table_privilege('anon','public.campo_visita_nps','select') then raise exception 'FAIL anon SELECT';end if;
 begin perform public.campo_responder_pesquisa(repeat('a',64),10,'paciente','');raise exception 'FAIL link revogado';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 begin perform public.campo_responder_pesquisa(repeat('b',64),10,'paciente','');raise exception 'FAIL link expirado';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
end$$;
reset role;
select set_config('request.jwt.claim.sub',current_setting('test.nurse'),true);
set local role authenticated;
select public.campo_emitir_pesquisa(gen_random_uuid(),current_setting('test.visit')::uuid,repeat('c',64));
reset role;
set local role anon;
do $$begin
 if not public.campo_responder_pesquisa(repeat('c',64),10,'cuidador','Teste ficticio') then raise exception 'FAIL resposta direta';end if;
 if not public.campo_responder_pesquisa(repeat('c',64),10,'cuidador','Teste ficticio') then raise exception 'FAIL retry resposta';end if;
 begin perform public.campo_responder_pesquisa(repeat('c',64),9,'cuidador','Teste ficticio');raise exception 'FAIL segunda resposta';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
end$$;
reset role;
select set_config('request.jwt.claim.sub',current_setting('test.legal'),true);
set local role authenticated;
do $$
declare p uuid:=current_setting('test.patient')::uuid;i uuid:=gen_random_uuid();d jsonb;
begin
 if exists(select 1 from public.campo_acoes_paciente where paciente_id=p and tipo<>'juridico') then raise exception 'FAIL juridico acessou cuidados';end if;
 d='{"titulo":"Identificacao ficticia","categoria":"identidade","status":"aprovado","documento_id":"","prazo":"","observacao":""}';
 begin perform public.campo_registrar_acao(gen_random_uuid(),i,p,'juridico',0,d);raise exception 'FAIL aprovacao sem original';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 perform public.campo_registrar_acao(gen_random_uuid(),i,p,'juridico',0,d||jsonb_build_object('documento_id',current_setting('test.doc')));
 begin perform public.campo_registrar_acao(gen_random_uuid(),i,p,'juridico',1,d||jsonb_build_object('documento_id',current_setting('test.doc'),'status','complemento'));raise exception 'FAIL complemento sem motivo';exception when raise_exception then if sqlerrm like 'FAIL%' then raise;end if;end;
 perform public.campo_registrar_acao(gen_random_uuid(),i,p,'juridico',1,d||jsonb_build_object('documento_id',current_setting('test.doc'),'status','complemento','observacao','Complemento ficticio necessario'));
 if (select count(*) from public.campo_historico_acao(i))<>2 then raise exception 'FAIL historico juridico';end if;
end$$;
reset role;
rollback;