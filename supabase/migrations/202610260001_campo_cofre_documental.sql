alter table public.campo_perfis drop constraint campo_perfis_papel_check;
alter table public.campo_perfis add constraint campo_perfis_papel_check check(papel in ('campo','gestor','superadmin','juridico'));
create function campo_private.pode_cofre(p_paciente uuid,p_envio boolean default false) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.campo_perfis u join public.campo_pacientes p on p.empresa_id=u.empresa_id where u.id=auth.uid() and u.ativo and p.id=p_paciente and (
 u.papel in ('superadmin','juridico') or (u.papel='gestor' and campo_private.acesso(p.empresa_id,p.responsavel_id))
 or (p_envio and u.papel='campo' and u.profissao in ('enfermeiro','fisioterapeuta','nutricionista') and p.responsavel_id=u.id)))
$$;
revoke all on function campo_private.pode_cofre(uuid,boolean) from public,anon;grant execute on function campo_private.pode_cofre(uuid,boolean) to authenticated;
create table public.campo_documentos_pessoais(
 id uuid primary key,paciente_id uuid not null references public.campo_pacientes(id),empresa_id uuid not null references public.campo_empresas(id),
 enviado_por uuid not null references auth.users(id),categoria text not null check(categoria in ('identidade','cpf','endereco','prescricao','relatorio','procuracao','decisao','outro')),
 nome text not null,mime text not null check(mime in ('application/pdf','image/jpeg','image/png')),tamanho bigint not null check(tamanho between 1 and 20971520),
 caminho text not null unique,status text not null default 'pendente' check(status in ('pendente','confirmado')),sha256 text,criado_em timestamptz not null default now(),confirmado_em timestamptz,
 homologacao boolean not null default true check(homologacao)
);
create index campo_doc_paciente on public.campo_documentos_pessoais(paciente_id);
create index campo_doc_empresa on public.campo_documentos_pessoais(empresa_id);
create index campo_doc_autor on public.campo_documentos_pessoais(enviado_por);
alter table public.campo_documentos_pessoais enable row level security;
revoke all on public.campo_documentos_pessoais from public,anon,authenticated;grant select on public.campo_documentos_pessoais to authenticated;
create policy campo_doc_ver on public.campo_documentos_pessoais for select to authenticated using(campo_private.pode_cofre(paciente_id,false));
create table public.campo_documentos_auditoria(id uuid primary key default gen_random_uuid(),documento_id uuid not null references public.campo_documentos_pessoais(id),empresa_id uuid not null,autor_id uuid not null references auth.users(id),acao text not null,criado_em timestamptz not null default now());
create index campo_doc_audit_doc on public.campo_documentos_auditoria(documento_id);
create index campo_doc_audit_autor on public.campo_documentos_auditoria(autor_id);
alter table public.campo_documentos_auditoria enable row level security;revoke all on public.campo_documentos_auditoria from public,anon,authenticated;grant select on public.campo_documentos_auditoria to authenticated;
create policy campo_doc_audit_ver on public.campo_documentos_auditoria for select to authenticated using(exists(select 1 from public.campo_documentos_pessoais d where d.id=documento_id and campo_private.pode_cofre(d.paciente_id,false)));
create trigger campo_doc_audit_imutavel before update or delete on public.campo_documentos_auditoria for each row execute function campo_private.prontuario_imutavel();
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('campo-documentos-pessoais','campo-documentos-pessoais',false,20971520,array['application/pdf','image/jpeg','image/png']);
create function campo_private.pode_enviar_documento(p_caminho text) returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.campo_documentos_pessoais d where d.caminho=p_caminho and d.enviado_por=auth.uid() and d.status='pendente' and campo_private.pode_cofre(d.paciente_id,true))$$;
revoke all on function campo_private.pode_enviar_documento(text) from public,anon;grant execute on function campo_private.pode_enviar_documento(text) to authenticated;
create policy campo_doc_upload on storage.objects for insert to authenticated with check(bucket_id='campo-documentos-pessoais' and campo_private.pode_enviar_documento(name));
-- Intencionalmente sem SELECT/UPDATE/DELETE de objetos para clientes neste bucket.
create function campo_private.reservar_documento(p_id uuid,p_paciente uuid,p_categoria text,p_nome text,p_mime text,p_tamanho bigint,p_homologacao boolean) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.campo_pacientes;d public.campo_documentos_pessoais;ext text;path text;
begin
 if not campo_private.pode_cofre(p_paciente,true) then raise exception 'Envio ao cofre nao autorizado' using errcode='42501';end if;
 select * into p from public.campo_pacientes where id=p_paciente;
 if p_homologacao is distinct from true or not p.homologacao then raise exception 'Somente arquivos ficticios de homologacao';end if;
 ext=case p_mime when 'application/pdf' then 'pdf' when 'image/jpeg' then 'jpg' when 'image/png' then 'png' end;
 if p_id is null or ext is null or p_categoria is null or p_categoria not in ('identidade','cpf','endereco','prescricao','relatorio','procuracao','decisao','outro') or p_nome is null or length(btrim(p_nome))<1 or length(p_nome)>150 or p_nome ~ '[/\\]' or p_tamanho is null or p_tamanho<1 or p_tamanho>20971520 then raise exception 'Documento invalido';end if;
 select * into d from public.campo_documentos_pessoais where id=p_id;
 if found then
  if d.paciente_id<>p.id or d.enviado_por<>auth.uid() or d.categoria<>p_categoria or d.nome<>p_nome or d.mime<>p_mime or d.tamanho<>p_tamanho then raise exception 'Identificador de documento em conflito';end if;
  return jsonb_build_object('id',d.id,'caminho',d.caminho,'status',d.status);
 end if;
 path=p.empresa_id::text||'/'||p.id::text||'/'||p_id::text||'.'||ext;
 insert into public.campo_documentos_pessoais(id,paciente_id,empresa_id,enviado_por,categoria,nome,mime,tamanho,caminho) values(p_id,p.id,p.empresa_id,auth.uid(),p_categoria,btrim(p_nome),p_mime,p_tamanho,path);
 insert into public.campo_documentos_auditoria(documento_id,empresa_id,autor_id,acao) values(p_id,p.empresa_id,auth.uid(),'reserva');
 return jsonb_build_object('id',p_id,'caminho',path,'status','pendente');
end$$;
create function campo_private.autorizar_documento(p_id uuid,p_operacao text) returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.campo_documentos_pessoais;
begin
 select * into d from public.campo_documentos_pessoais where id=p_id;
 if d.id is null then raise exception 'Documento nao autorizado' using errcode='42501';end if;
 if p_operacao='confirmar' then
  if d.enviado_por<>auth.uid() or not campo_private.pode_cofre(d.paciente_id,true) then raise exception 'Documento nao autorizado' using errcode='42501';end if;
 elsif p_operacao='baixar' then
  if d.status<>'confirmado' or not campo_private.pode_cofre(d.paciente_id,false) then raise exception 'Documento nao autorizado' using errcode='42501';end if;
  insert into public.campo_documentos_auditoria(documento_id,empresa_id,autor_id,acao) values(d.id,d.empresa_id,auth.uid(),'download_autorizado');
 else raise exception 'Operacao invalida';end if;
 return jsonb_build_object('id',d.id,'caminho',d.caminho,'nome',d.nome,'mime',d.mime,'tamanho',d.tamanho,'status',d.status);
end$$;
create function campo_private.confirmar_documento_servico(p_id uuid,p_autor uuid,p_sha text) returns uuid language plpgsql security definer set search_path='' as $$
declare d public.campo_documentos_pessoais;m jsonb;u public.campo_perfis;
begin
 select * into d from public.campo_documentos_pessoais where id=p_id for update;
 select * into u from public.campo_perfis where id=p_autor and ativo;
 if d.id is null or u.id is null or d.enviado_por<>u.id or u.empresa_id<>d.empresa_id or p_sha is null or p_sha!~'^[a-f0-9]{64}$' then raise exception 'Confirmacao invalida';end if;
 if d.status='confirmado' then if d.sha256<>p_sha then raise exception 'Integridade divergente';end if;return d.id;end if;
 select metadata into m from storage.objects where bucket_id='campo-documentos-pessoais' and name=d.caminho;
 if m is null or coalesce((m->>'size')::bigint,0)<>d.tamanho or coalesce(m->>'mimetype','')<>d.mime then raise exception 'Arquivo incompleto';end if;
 update public.campo_documentos_pessoais set status='confirmado',sha256=p_sha,confirmado_em=now() where id=d.id;
 insert into public.campo_documentos_auditoria(documento_id,empresa_id,autor_id,acao) values(d.id,d.empresa_id,u.id,'envio_confirmado');
 return d.id;
end$$;
revoke all on function campo_private.reservar_documento(uuid,uuid,text,text,text,bigint,boolean),campo_private.autorizar_documento(uuid,text),campo_private.confirmar_documento_servico(uuid,uuid,text) from public,anon,authenticated;
grant execute on function campo_private.reservar_documento(uuid,uuid,text,text,text,bigint,boolean),campo_private.autorizar_documento(uuid,text) to authenticated;
grant execute on function campo_private.confirmar_documento_servico(uuid,uuid,text) to service_role;
create function public.campo_reservar_documento(p_id uuid,p_paciente uuid,p_categoria text,p_nome text,p_mime text,p_tamanho bigint,p_homologacao boolean default false) returns jsonb language sql security invoker set search_path='' as $$select campo_private.reservar_documento(p_id,p_paciente,p_categoria,p_nome,p_mime,p_tamanho,p_homologacao)$$;
create function public.campo_documento_autorizar(p_id uuid,p_operacao text) returns jsonb language sql security invoker set search_path='' as $$select campo_private.autorizar_documento(p_id,p_operacao)$$;
create function public.campo_documento_confirmar_servico(p_id uuid,p_autor uuid,p_sha text) returns uuid language sql security invoker set search_path='' as $$select campo_private.confirmar_documento_servico(p_id,p_autor,p_sha)$$;
create function public.campo_listar_documentos(p_paciente uuid) returns setof public.campo_documentos_pessoais language sql stable security invoker set search_path='' as $$select * from public.campo_documentos_pessoais where paciente_id=p_paciente order by criado_em desc limit 200$$;
revoke all on function public.campo_reservar_documento(uuid,uuid,text,text,text,bigint,boolean),public.campo_documento_autorizar(uuid,text),public.campo_documento_confirmar_servico(uuid,uuid,text),public.campo_listar_documentos(uuid) from public,anon,authenticated;
grant execute on function public.campo_reservar_documento(uuid,uuid,text,text,text,bigint,boolean),public.campo_documento_autorizar(uuid,text),public.campo_listar_documentos(uuid) to authenticated;
grant execute on function public.campo_documento_confirmar_servico(uuid,uuid,text) to service_role;
