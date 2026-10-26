CREATE OR REPLACE FUNCTION campo_private.campo_salvar_usuario(p_email text, p_nome text, p_papel text, p_ativo boolean, p_profissao text, p_gestor uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare adm public.campo_perfis; lider public.campo_perfis; destino uuid; antigo public.campo_perfis;
begin
 select * into adm from public.campo_perfis where id=auth.uid() and ativo;
 if adm.id is null or adm.papel not in ('gestor','superadmin') then raise exception 'Acesso negado' using errcode='42501'; end if;
 if p_papel not in ('campo','gestor','superadmin','juridico') or p_ativo is null or length(btrim(p_nome))<2 or length(p_nome)>150 then raise exception 'Dados de usuario invalidos'; end if;
 select u.id into destino from auth.users u where lower(u.email)=lower(btrim(p_email)) and u.email_confirmed_at is not null;
 if destino is null then raise exception 'Conta Auth confirmada nao encontrada. Ative a conta antes de vincular o acesso.'; end if;
 select * into antigo from public.campo_perfis where id=destino;
 if antigo.id is not null and antigo.empresa_id<>adm.empresa_id then raise exception 'Usuario ja vinculado a outra empresa' using errcode='42501'; end if;
 if adm.papel='gestor' and (p_papel<>'campo' or coalesce(antigo.papel,'campo')<>'campo') then raise exception 'Somente superadmin pode administrar gestores' using errcode='42501'; end if;
 if p_profissao is not null and p_profissao not in ('enfermeiro','fisioterapeuta','nutricionista','comercial') then raise exception 'Profissao invalida'; end if;
 if p_papel='juridico' and (p_profissao is not null or p_gestor is not null) then raise exception 'Juridico nao recebe profissao assistencial ou gestor de campo';end if;
 if p_papel='campo' and p_profissao is null then raise exception 'Selecione a profissao'; end if;
 if adm.papel='gestor' and antigo.id is not null and antigo.gestor_id is distinct from adm.id then raise exception 'Profissional nao pertence a sua equipe' using errcode='42501'; end if;
 if adm.papel='gestor' and p_gestor is distinct from adm.id then raise exception 'Gestor so pode vincular profissionais a propria equipe' using errcode='42501'; end if;
 if p_gestor is not null then
  select * into lider from public.campo_perfis where id=p_gestor and empresa_id=adm.empresa_id and ativo and papel='gestor';
  if lider.id is null or p_papel<>'campo' or p_gestor=destino then raise exception 'Gestor responsavel invalido'; end if;
 end if;
 if antigo.papel='gestor' and (p_papel<>'gestor' or not p_ativo) and exists(select 1 from public.campo_perfis where gestor_id=destino) then raise exception 'Reatribua a equipe antes de desativar ou alterar o gestor'; end if;
 if destino=adm.id and (not p_ativo or p_papel<>adm.papel) then raise exception 'Nao altere seu proprio nivel ou desative seu proprio acesso'; end if;
 insert into public.campo_perfis(id,empresa_id,nome,papel,ativo,profissao,gestor_id) values(destino,adm.empresa_id,btrim(p_nome),p_papel,p_ativo,p_profissao,p_gestor)
 on conflict(id) do update set nome=excluded.nome,papel=excluded.papel,ativo=excluded.ativo,profissao=excluded.profissao,gestor_id=excluded.gestor_id;
 insert into public.campo_eventos(empresa_id,responsavel_id,registro_id,entidade,acao,status) values(adm.empresa_id,adm.id,destino,'usuarios','CONFIGURACAO',case when p_ativo then p_papel else 'desativado' end);
 return destino;
end $function$
;
create or replace function campo_private.acesso(p_empresa uuid,p_dono uuid default null) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.campo_perfis p where p.id=auth.uid() and p.empresa_id=p_empresa and p.ativo and p.papel<>'juridico' and (p_dono is null or p_dono=p.id or p.papel='superadmin' or (p.papel='gestor' and exists(select 1 from public.campo_perfis membro where membro.id=p_dono and membro.empresa_id=p.empresa_id and membro.gestor_id=p.id))))
$$;
grant usage on schema campo_private to service_role;
create function campo_private.cofre_pacientes() returns table(id uuid,nome text,codigo text) language sql stable security definer set search_path='' as $$select p.id,p.nome,p.codigo from public.campo_pacientes p where campo_private.pode_cofre(p.id,true) order by p.nome limit 2000$$;
revoke all on function campo_private.cofre_pacientes() from public,anon;grant execute on function campo_private.cofre_pacientes() to authenticated;
create function public.campo_cofre_pacientes() returns table(id uuid,nome text,codigo text) language sql stable security invoker set search_path='' as $$select * from campo_private.cofre_pacientes()$$;
revoke all on function public.campo_cofre_pacientes() from public,anon;grant execute on function public.campo_cofre_pacientes() to authenticated;
