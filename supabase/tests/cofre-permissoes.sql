begin;
do $test$
declare e uuid:=gen_random_uuid(); patient uuid:=gen_random_uuid(); nurse uuid:=gen_random_uuid(); manager uuid:=gen_random_uuid(); legal uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid(); commercial uuid:=gen_random_uuid();
begin
 insert into public.campo_empresas(id,nome) values(e,'TESTE COFRE TRANSACAO');
 insert into auth.users(id) values(nurse),(manager),(legal),(outsider),(admin),(commercial);
 insert into public.campo_perfis(id,empresa_id,nome,papel,profissao,gestor_id) values(manager,e,'TESTE','gestor',null,null),(nurse,e,'TESTE','campo','enfermeiro',manager),(legal,e,'TESTE','juridico',null,null),(outsider,e,'TESTE','gestor',null,null),(admin,e,'TESTE','superadmin',null,null),(commercial,e,'TESTE','campo','comercial',manager);
 insert into public.campo_pacientes(id,empresa_id,responsavel_id,codigo,nome,linha,consentimento,termo_versao) values(patient,e,nurse,'TESTE-COFRE','PACIENTE FICTICIO','stomapro',true,'homologacao-v1');
 perform set_config('request.jwt.claim.sub',nurse::text,true);
 if not campo_private.pode_cofre(patient,true) or campo_private.pode_cofre(patient,false) then raise exception 'FAIL enfermeiro';end if;
 perform set_config('request.jwt.claim.sub',manager::text,true);
 if not campo_private.pode_cofre(patient,false) then raise exception 'FAIL gestor equipe';end if;
 perform set_config('request.jwt.claim.sub',outsider::text,true);
 if campo_private.pode_cofre(patient,false) then raise exception 'FAIL gestor outra equipe';end if;
 perform set_config('request.jwt.claim.sub',legal::text,true);
 if not campo_private.pode_cofre(patient,false) or campo_private.acesso(e,nurse) then raise exception 'FAIL juridico isolamento';end if;
 perform set_config('request.jwt.claim.sub',admin::text,true);
 if not campo_private.pode_cofre(patient,false) then raise exception 'FAIL superadmin';end if;
 perform set_config('request.jwt.claim.sub',commercial::text,true);
 if campo_private.pode_cofre(patient,true) or campo_private.pode_cofre(patient,false) then raise exception 'FAIL comercial';end if;
 update public.campo_perfis set ativo=false where id=legal;
 perform set_config('request.jwt.claim.sub',legal::text,true);
 if campo_private.pode_cofre(patient,false) then raise exception 'FAIL inativo';end if;
 perform set_config('request.jwt.claim.sub','',true);
 if campo_private.pode_cofre(patient,false) then raise exception 'FAIL anonimo';end if;
 if has_function_privilege('authenticated','public.campo_documento_confirmar_servico(uuid,uuid,text)','execute') or has_function_privilege('anon','public.campo_documento_confirmar_servico(uuid,uuid,text)','execute') then raise exception 'FAIL confirmacao privilegiada';end if;
end $test$;
rollback;