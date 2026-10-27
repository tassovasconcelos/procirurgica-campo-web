
create table public.campo_convites (
 id uuid primary key, empresa_id uuid not null references public.campo_empresas(id),
 solicitado_por uuid not null references auth.users(id), email text not null,
 dados jsonb not null, status text not null default 'preparado' check(status in ('preparado','enviado','vinculo_pendente','erro')),
 auth_id uuid references auth.users(id), criado_em timestamptz not null default now(), concluido_em timestamptz
);
create index campo_convites_empresa on public.campo_convites(empresa_id,criado_em desc);
alter table public.campo_convites enable row level security;
revoke all on public.campo_convites from public,anon,authenticated;
grant select on public.campo_convites to authenticated;
create policy campo_convites_ler on public.campo_convites for select to authenticated using(exists(select 1 from public.campo_perfis u where u.id=auth.uid() and u.ativo and u.papel='superadmin' and u.empresa_id=campo_convites.empresa_id));
create or replace function campo_private.preparar_convite(p_id uuid,p_dados jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u public.campo_perfis;r public.campo_convites;v_email text;v_papel text;v_prof text;v_gestor uuid;
begin
 select f.* into u from public.campo_perfis f where f.id=auth.uid() and f.ativo and f.papel='superadmin';
 if u.id is null then raise exception 'Somente superadmin pode convidar' using errcode='42501';end if;
 if p_id is null or p_dados is null or jsonb_typeof(p_dados)<>'object' or octet_length(p_dados::text)>4000 then raise exception 'Convite invalido';end if;
 if exists(select 1 from jsonb_object_keys(p_dados) as x(k) where k not in ('email','nome','papel','profissao','gestor')) then raise exception 'Campo de convite invalido';end if;
 v_email=lower(btrim(p_dados->>'email'));v_papel=p_dados->>'papel';v_prof=nullif(p_dados->>'profissao','');v_gestor=nullif(p_dados->>'gestor','')::uuid;
 if v_email is null or v_email!~'^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(v_email)>254 or length(btrim(coalesce(p_dados->>'nome','')))<2 or length(p_dados->>'nome')>150 or v_papel is null or v_papel not in ('campo','gestor','juridico') then raise exception 'Dados de convite invalidos';end if;
 if v_prof is not null and v_prof not in ('enfermeiro','fisioterapeuta','nutricionista','comercial') then raise exception 'Profissao invalida';end if;
 if v_papel='campo' and (v_prof is null or v_gestor is null) then raise exception 'Selecione profissao e gestor';end if;
 if v_papel<>'campo' and v_gestor is not null or v_papel='juridico' and v_prof is not null then raise exception 'Vinculo de equipe invalido';end if;
 if v_gestor is not null and not exists(select 1 from public.campo_perfis g where g.id=v_gestor and g.ativo and g.empresa_id=u.empresa_id and g.papel='gestor') then raise exception 'Gestor invalido';end if;
 perform pg_advisory_xact_lock(hashtextextended(u.empresa_id::text,22));
 perform pg_advisory_xact_lock(hashtextextended(v_email,9));
 select * into r from public.campo_convites where id=p_id;
 if found then
 if r.solicitado_por<>u.id or r.empresa_id<>u.empresa_id or r.dados<>p_dados then raise exception 'Identificador de convite em conflito';end if;
 return jsonb_build_object('id',r.id,'novo',false,'status',r.status);end if;
 if exists(select 1 from auth.users a where lower(a.email)=v_email) then raise exception 'Conta ja existe. Vincule a conta confirmada; nao use convite para recuperar acesso';end if;
 if exists(select 1 from public.campo_convites c where c.email=v_email and c.status in ('preparado','enviado','vinculo_pendente')) then raise exception 'Ja existe convite em andamento para este email';end if;
 if (select count(*) from public.campo_convites c where c.empresa_id=u.empresa_id and c.criado_em>now()-interval '1 day')>=100 then raise exception 'Limite diario de convites atingido';end if;
 insert into public.campo_convites(id,empresa_id,solicitado_por,email,dados) values(p_id,u.empresa_id,u.id,v_email,p_dados);
 return jsonb_build_object('id',p_id,'novo',true,'status','preparado');
end$$;

revoke all on function campo_private.preparar_convite(uuid,jsonb) from public,anon;
grant execute on function campo_private.preparar_convite(uuid,jsonb) to authenticated;
create function public.campo_preparar_convite(p_id uuid,p_dados jsonb) returns jsonb language sql security invoker set search_path='' as $$select campo_private.preparar_convite(p_id,p_dados)$$;
revoke all on function public.campo_preparar_convite(uuid,jsonb) from public,anon;
grant execute on function public.campo_preparar_convite(uuid,jsonb) to authenticated;

create function campo_private.concluir_convite(p_id uuid,p_autor uuid,p_auth uuid,p_estado text) returns text language plpgsql security definer set search_path='' as $$
declare c public.campo_convites;u public.campo_perfis;g uuid;
begin
 select * into c from public.campo_convites where id=p_id for update;
 select * into u from public.campo_perfis where id=p_autor and ativo and papel='superadmin';
 if c.id is null or u.id is null or c.solicitado_por<>u.id or c.empresa_id<>u.empresa_id then raise exception 'Conclusao nao autorizada' using errcode='42501';end if;
 if p_estado is null or p_estado not in ('enviado','vinculo_pendente','erro') then raise exception 'Estado invalido';end if;
 if c.status<>'preparado' then return c.status;end if;
 if p_estado='enviado' then
 if not exists(select 1 from auth.users a where a.id=p_auth and lower(a.email)=c.email and a.invited_at is not null and a.created_at>=c.criado_em-interval '1 minute') then raise exception 'Conta convidada nao corresponde';end if;
 if exists(select 1 from public.campo_perfis where id=p_auth) then raise exception 'Perfil ja vinculado; revisao manual necessaria';end if;
 g=nullif(c.dados->>'gestor','')::uuid;
 if g is not null and not exists(select 1 from public.campo_perfis where id=g and empresa_id=c.empresa_id and papel='gestor' and ativo) then raise exception 'Gestor mudou; revisao manual necessaria';end if;
 insert into public.campo_perfis(id,empresa_id,nome,papel,ativo,profissao,gestor_id) values(p_auth,c.empresa_id,btrim(c.dados->>'nome'),c.dados->>'papel',true,nullif(c.dados->>'profissao',''),g);
 insert into public.campo_eventos(empresa_id,responsavel_id,registro_id,entidade,acao,status) values(c.empresa_id,p_autor,p_auth,'usuarios','CONVITE','aguardando_ativacao');
 end if;
 update public.campo_convites set status=p_estado,auth_id=p_auth,concluido_em=clock_timestamp() where id=p_id;
 return p_estado;
end$$;
revoke all on function campo_private.concluir_convite(uuid,uuid,uuid,text) from public,anon,authenticated;
grant execute on function campo_private.concluir_convite(uuid,uuid,uuid,text) to service_role;
create function public.campo_concluir_convite_servico(p_id uuid,p_autor uuid,p_auth uuid,p_estado text) returns text language sql security invoker set search_path='' as $$select campo_private.concluir_convite(p_id,p_autor,p_auth,p_estado)$$;
revoke all on function public.campo_concluir_convite_servico(uuid,uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.campo_concluir_convite_servico(uuid,uuid,uuid,text) to service_role;
create function public.campo_listar_convites() returns table(id uuid,email text,nome text,papel text,status text,criado_em timestamptz) language sql security invoker set search_path='' as $$select c.id,c.email,c.dados->>'nome',c.dados->>'papel',c.status,c.criado_em from public.campo_convites c order by c.criado_em desc limit 100$$;
revoke all on function public.campo_listar_convites() from public,anon;
grant execute on function public.campo_listar_convites() to authenticated;
