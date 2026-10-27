
create table public.campo_validacoes_operacionais(
 id uuid primary key,empresa_id uuid not null references public.campo_empresas(id),escopo text not null,
 etapa text not null,versao integer not null,estado text not null check(estado in ('em_teste','aprovado','reprovado')),
 evidencia text not null check(length(evidencia) between 3 and 2000),autor_id uuid not null references auth.users(id),
 autor_nome text not null,criado_em timestamptz not null default now(),unique(empresa_id,escopo,etapa,versao)
);
alter table public.campo_validacoes_operacionais enable row level security;
revoke all on public.campo_validacoes_operacionais from public,anon,authenticated;
grant select on public.campo_validacoes_operacionais to authenticated;
create policy campo_validacoes_ver on public.campo_validacoes_operacionais for select to authenticated using(exists(select 1 from public.campo_perfis u where u.id=auth.uid() and u.ativo and u.empresa_id=campo_validacoes_operacionais.empresa_id and (u.papel='superadmin' or u.papel='gestor' and campo_validacoes_operacionais.escopo=u.id::text)));
create trigger campo_validacoes_imutavel before update or delete on public.campo_validacoes_operacionais for each row execute function campo_private.prontuario_imutavel();
create function campo_private.diagnostico_operacional() returns jsonb language plpgsql security definer set search_path='' as $$
declare u public.campo_perfis;res jsonb;
begin
 select * into u from public.campo_perfis where id=auth.uid() and ativo and papel in ('superadmin','gestor');
 if u.id is null then raise exception 'Diagnostico administrativo restrito' using errcode='42501';end if;
 select jsonb_build_object(
 'escopo',case when u.papel='superadmin' then 'empresa' else u.id::text end,
 'usuarios',count(*),'gestores_ativos',count(*) filter(where p.ativo and p.papel='gestor' and a.email_confirmed_at is not null),
 'assistenciais_ativos',count(*) filter(where p.ativo and p.profissao in ('enfermeiro','fisioterapeuta','nutricionista') and a.email_confirmed_at is not null),
 'pendentes_ativacao',count(*) filter(where p.ativo and a.email_confirmed_at is null),
 'ativacoes',coalesce(jsonb_agg(jsonb_build_object('id',p.id,'confirmado',a.email_confirmed_at is not null)),'[]'::jsonb)
 ) into res from public.campo_perfis p left join auth.users a on a.id=p.id where p.empresa_id=u.empresa_id and (u.papel='superadmin' or p.id=u.id or p.gestor_id=u.id);
 return res||jsonb_build_object(
 'pacientes',(select count(*) from public.campo_pacientes p where p.empresa_id=u.empresa_id and campo_private.acesso(p.empresa_id,p.responsavel_id)),
 'pacientes_sem_assistencial',(select count(*) from public.campo_pacientes p where p.empresa_id=u.empresa_id and campo_private.acesso(p.empresa_id,p.responsavel_id) and not exists(select 1 from public.campo_perfis f join auth.users a on a.id=f.id where f.id=p.responsavel_id and f.ativo and f.profissao in ('enfermeiro','fisioterapeuta','nutricionista') and a.email_confirmed_at is not null)),
 'visitas',(select count(*) from public.campo_visitas v where v.empresa_id=u.empresa_id and campo_private.pode_prontuario(v.paciente_id,false)),
 'prontuarios',(select count(*) from public.campo_prontuario r where r.empresa_id=u.empresa_id and campo_private.pode_prontuario(r.paciente_id,false)),
 'capturado_em',clock_timestamp());
end$$;
revoke all on function campo_private.diagnostico_operacional() from public,anon;
grant execute on function campo_private.diagnostico_operacional() to authenticated;
create function public.campo_diagnostico_operacional() returns jsonb language sql security invoker set search_path='' as $$select campo_private.diagnostico_operacional()$$;
revoke all on function public.campo_diagnostico_operacional() from public,anon;
grant execute on function public.campo_diagnostico_operacional() to authenticated;
create function campo_private.registrar_validacao_operacional(p_id uuid,p_etapa text,p_estado text,p_evidencia text,p_versao integer) returns uuid language plpgsql security definer set search_path='' as $$
declare u public.campo_perfis;r public.campo_validacoes_operacionais;s text;v integer;
begin
 select * into u from public.campo_perfis where id=auth.uid() and ativo and papel in ('superadmin','gestor');
 if u.id is null then raise exception 'Validacao administrativa restrita' using errcode='42501';end if;
 s=case when u.papel='superadmin' then 'empresa' else u.id::text end;
 if p_id is null or p_etapa is null or p_etapa not in ('acessos','equipe','cadastro','importacao','ostomia','cateter','visita','documentos','pesquisa','android','ios','backup','revisao_clinica','revisao_juridica') or p_estado is null or p_estado not in ('em_teste','aprovado','reprovado') or p_versao is null or p_versao<0 or p_evidencia is null or length(btrim(p_evidencia))<3 or length(p_evidencia)>2000 then raise exception 'Validacao invalida';end if;
 if p_estado='aprovado' and length(btrim(p_evidencia))<10 then raise exception 'Descreva evidencia verificavel da aprovacao';end if;
 perform pg_advisory_xact_lock(hashtextextended(u.empresa_id::text||s||p_etapa,11));
 select * into r from public.campo_validacoes_operacionais where id=p_id;
 if found then
 if r.autor_id=u.id and r.escopo=s and r.etapa=p_etapa and r.estado=p_estado and r.evidencia=btrim(p_evidencia) and r.versao=p_versao+1 then return r.id;end if;raise exception 'Identificador em conflito';end if;
 select coalesce(max(versao),0) into v from public.campo_validacoes_operacionais where empresa_id=u.empresa_id and escopo=s and etapa=p_etapa;
 if v<>p_versao then raise exception 'Validacao alterada. Atualize';end if;
 insert into public.campo_validacoes_operacionais(id,empresa_id,escopo,etapa,versao,estado,evidencia,autor_id,autor_nome) values(p_id,u.empresa_id,s,p_etapa,v+1,p_estado,btrim(p_evidencia),u.id,u.nome);
 return p_id;
end$$;
revoke all on function campo_private.registrar_validacao_operacional(uuid,text,text,text,integer) from public,anon;
grant execute on function campo_private.registrar_validacao_operacional(uuid,text,text,text,integer) to authenticated;
create function public.campo_registrar_validacao_operacional(p_id uuid,p_etapa text,p_estado text,p_evidencia text,p_versao integer) returns uuid language sql security invoker set search_path='' as $$select campo_private.registrar_validacao_operacional(p_id,p_etapa,p_estado,p_evidencia,p_versao)$$;
revoke all on function public.campo_registrar_validacao_operacional(uuid,text,text,text,integer) from public,anon;
grant execute on function public.campo_registrar_validacao_operacional(uuid,text,text,text,integer) to authenticated;
create function public.campo_listar_validacoes_operacionais() returns setof public.campo_validacoes_operacionais language sql security invoker set search_path='' as $$select r.* from public.campo_validacoes_operacionais r order by r.criado_em desc limit 1000$$;
revoke all on function public.campo_listar_validacoes_operacionais() from public,anon;
grant execute on function public.campo_listar_validacoes_operacionais() to authenticated;
