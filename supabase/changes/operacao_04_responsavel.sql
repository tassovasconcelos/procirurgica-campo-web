CREATE OR REPLACE FUNCTION campo_private.salvar_cadastro_paciente(p_id uuid, p_base jsonb, p_dados jsonb, p_responsavel uuid, p_versao timestamp with time zone, p_homologacao boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u public.campo_perfis;r public.campo_pacientes;d public.campo_paciente_perfil;dest public.campo_perfis;novo boolean;
begin
 select * into u from public.campo_perfis where id=auth.uid() and ativo and coalesce(profissao,'')<>'comercial';
 if u.id is null or p_id is null or p_homologacao is distinct from true then raise exception 'Acesso ao cadastro negado' using errcode='42501';end if;
 perform campo_private.validar_cadastro(p_dados);
 if p_base is null or jsonb_typeof(p_base)<>'object' or length(btrim(coalesce(p_base->>'nome','')))<2 or length(p_base->>'nome')>150 or length(btrim(coalesce(p_base->>'codigo','')))<1 or length(p_base->>'codigo')>80 or coalesce(p_base->>'linha','') not in ('stomapro','confortcath') or length(coalesce(p_base->>'cidade',''))>150 or coalesce(p_base->>'uf','')!~'^([A-Z]{2})?$' or length(coalesce(p_base->>'telefone',''))>30 then raise exception 'Identificacao invalida';end if;
 select * into r from public.campo_pacientes where id=p_id for update;novo=not found;
 if not novo and not campo_private.pode_prontuario(r.id,false) then raise exception 'Paciente fora do seu acesso' using errcode='42501';end if;
 if novo and u.papel not in ('gestor','superadmin') and u.profissao not in ('enfermeiro','fisioterapeuta','nutricionista') then raise exception 'Acesso negado' using errcode='42501';end if;
 select * into dest from public.campo_perfis where id=p_responsavel and empresa_id=u.empresa_id and ativo and profissao in ('enfermeiro','fisioterapeuta','nutricionista') and exists(select 1 from auth.users a where a.id=p_responsavel and a.email_confirmed_at is not null);
 if dest.id is null or (u.papel<>'superadmin' and dest.id<>u.id and (u.papel<>'gestor' or dest.gestor_id is distinct from u.id)) or (not novo and u.papel not in ('superadmin','gestor') and p_responsavel<>r.responsavel_id) then raise exception 'Responsavel profissional invalido' using errcode='42501';end if;
 select * into d from public.campo_paciente_perfil where paciente_id=p_id for update;
 if d.paciente_id is not null and d.atualizado_em is distinct from p_versao then raise exception 'Cadastro alterado. Atualize e tente novamente';end if;
 if not novo and r.linha<>p_base->>'linha' and (exists(select 1 from public.campo_atendimentos where paciente_id=r.id) or exists(select 1 from public.campo_prontuario where paciente_id=r.id)) then raise exception 'Linha de cuidado vinculada ao historico; mantenha a linha atual';end if;
 if novo then
  insert into public.campo_pacientes(id,empresa_id,responsavel_id,codigo,nome,linha,cidade,uf,telefone,consentimento,termo_versao,homologacao) values(p_id,u.empresa_id,dest.id,btrim(p_base->>'codigo'),btrim(p_base->>'nome'),p_base->>'linha',p_base->>'cidade',nullif(p_base->>'uf',''),p_base->>'telefone',true,'homologacao-v1',true);
 else
  update public.campo_pacientes set responsavel_id=dest.id,codigo=btrim(p_base->>'codigo'),nome=btrim(p_base->>'nome'),linha=p_base->>'linha',cidade=p_base->>'cidade',uf=nullif(p_base->>'uf',''),telefone=p_base->>'telefone' where id=r.id;
 end if;
 insert into public.campo_paciente_perfil(paciente_id,empresa_id,dados,atualizado_por) values(p_id,u.empresa_id,p_dados,u.id)
 on conflict(paciente_id) do update set dados=excluded.dados,atualizado_em=clock_timestamp(),atualizado_por=u.id;
 insert into public.campo_eventos(empresa_id,responsavel_id,registro_id,entidade,acao,status) values(u.empresa_id,u.id,p_id,'paciente_cadastro','CADASTRO',p_dados->>'etapa');
 return p_id;
end $function$
;