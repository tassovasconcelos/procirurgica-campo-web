
alter table public.campo_visita_nps drop constraint campo_visita_nps_coleta_check;
alter table public.campo_visita_nps alter column autor_id drop not null;
alter table public.campo_visita_nps add constraint campo_visita_nps_coleta_check check((coleta='assistida' and autor_id is not null) or (coleta='direta' and autor_id is null));
create table public.campo_pesquisa_links (
 id uuid primary key, visita_id uuid not null references public.campo_visitas(id),
 token_hash text not null unique, criado_por uuid not null references auth.users(id), criado_em timestamptz not null default now(),
 expira_em timestamptz not null, revogado_em timestamptz, revogado_por uuid references auth.users(id), respondido_em timestamptz
);
create index campo_pesquisa_links_visita on public.campo_pesquisa_links(visita_id,criado_em desc);
alter table public.campo_pesquisa_links enable row level security;
revoke all on public.campo_pesquisa_links from public,anon,authenticated;
grant select(id,visita_id,criado_por,criado_em,expira_em,revogado_em,revogado_por,respondido_em) on public.campo_pesquisa_links to authenticated;
create policy campo_pesquisa_links_ler on public.campo_pesquisa_links for select to authenticated using(exists(select 1 from public.campo_visitas v where v.id=visita_id));
create function campo_private.emitir_pesquisa(p_id uuid,p_visita uuid,p_token text) returns jsonb language plpgsql security definer set search_path='' as $$
declare v public.campo_visitas;l public.campo_pesquisa_links;h text;
begin
 select * into v from public.campo_visitas where id=p_visita for update;
 if v.id is null or not campo_private.pode_prontuario(v.paciente_id,false) then raise exception 'Pesquisa nao autorizada' using errcode='42501';end if;
 if v.status<>'realizada' or not v.homologacao or p_id is null or p_token is null or p_token!~'^[a-f0-9]{64}$' then raise exception 'Pesquisa exige visita realizada e token valido';end if;
 h=encode(sha256(convert_to(p_token,'UTF8')),'hex');
 select * into l from public.campo_pesquisa_links where id=p_id;
 if found then
 if l.visita_id=p_visita and l.criado_por=auth.uid() and l.token_hash=h then return jsonb_build_object('id',l.id,'expira_em',l.expira_em,'revogado_em',l.revogado_em,'respondido_em',l.respondido_em);end if;
 raise exception 'Identificador de pesquisa em conflito';end if;
 if exists(select 1 from public.campo_visita_nps where visita_id=p_visita) then raise exception 'Visita ja possui resposta';end if;
 if (select count(*) from public.campo_pesquisa_links where visita_id=p_visita and criado_em>now()-interval '1 day')>=10 then raise exception 'Limite diario de links atingido';end if;
 update public.campo_pesquisa_links set revogado_em=clock_timestamp(),revogado_por=auth.uid() where visita_id=p_visita and revogado_em is null and respondido_em is null;
 insert into public.campo_pesquisa_links(id,visita_id,token_hash,criado_por,expira_em) values(p_id,p_visita,h,auth.uid(),now()+interval '72 hours') returning * into l;
 return jsonb_build_object('id',l.id,'expira_em',l.expira_em,'revogado_em',l.revogado_em,'respondido_em',l.respondido_em);
end$$;
revoke all on function campo_private.emitir_pesquisa(uuid,uuid,text) from public,anon;
grant execute on function campo_private.emitir_pesquisa(uuid,uuid,text) to authenticated;
create function public.campo_emitir_pesquisa(p_id uuid,p_visita uuid,p_token text) returns jsonb language sql security invoker set search_path='' as $$select campo_private.emitir_pesquisa(p_id,p_visita,p_token)$$;
revoke all on function public.campo_emitir_pesquisa(uuid,uuid,text) from public,anon;
grant execute on function public.campo_emitir_pesquisa(uuid,uuid,text) to authenticated;
create function campo_private.revogar_pesquisa(p_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare l public.campo_pesquisa_links;v public.campo_visitas;
begin
 select * into l from public.campo_pesquisa_links where id=p_id for update;select * into v from public.campo_visitas where id=l.visita_id;
 if l.id is null or not campo_private.pode_prontuario(v.paciente_id,false) then raise exception 'Pesquisa nao autorizada' using errcode='42501';end if;
 update public.campo_pesquisa_links set revogado_em=coalesce(revogado_em,clock_timestamp()),revogado_por=coalesce(revogado_por,auth.uid()) where id=p_id;
 return true;
end$$;
revoke all on function campo_private.revogar_pesquisa(uuid) from public,anon;
grant execute on function campo_private.revogar_pesquisa(uuid) to authenticated;
create function public.campo_revogar_pesquisa(p_id uuid) returns boolean language sql security invoker set search_path='' as $$select campo_private.revogar_pesquisa(p_id)$$;
revoke all on function public.campo_revogar_pesquisa(uuid) from public,anon;
grant execute on function public.campo_revogar_pesquisa(uuid) to authenticated;
create function public.campo_listar_links_pesquisa(p_visita uuid) returns table(id uuid,expira_em timestamptz,revogado_em timestamptz,respondido_em timestamptz) language sql security invoker set search_path='' as $$select l.id,l.expira_em,l.revogado_em,l.respondido_em from public.campo_pesquisa_links l where l.visita_id=p_visita order by l.criado_em desc limit 20$$;
revoke all on function public.campo_listar_links_pesquisa(uuid) from public,anon;
grant execute on function public.campo_listar_links_pesquisa(uuid) to authenticated;

create schema campo_pesquisa_privada;
revoke all on schema campo_pesquisa_privada from public;
grant usage on schema campo_pesquisa_privada to anon,authenticated;
create function campo_pesquisa_privada.responder(p_token text,p_nota integer,p_respondente text,p_comentario text) returns boolean language plpgsql security definer set search_path='' as $$
declare l public.campo_pesquisa_links;r public.campo_visita_nps;
begin
 if p_token is null or p_token!~'^[a-f0-9]{64}$' or p_nota is null or p_nota not between 0 and 10 or p_respondente is null or p_respondente not in ('paciente','familiar','cuidador') or p_comentario is null or length(p_comentario)>1000 then raise exception 'Link ou resposta invalida';end if;
 select * into l from public.campo_pesquisa_links where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
 if l.id is null or l.revogado_em is not null or l.expira_em<now() then raise exception 'Link invalido, expirado ou encerrado';end if;
 select * into r from public.campo_visita_nps where visita_id=l.visita_id;
 if found then
 if l.respondido_em is not null and r.coleta='direta' and r.nota=p_nota and r.respondente=p_respondente and r.comentario=p_comentario then return true;end if;
 raise exception 'Link invalido, expirado ou encerrado';end if;
 insert into public.campo_visita_nps(id,visita_id,nota,respondente,comentario,coleta,autor_id) values(gen_random_uuid(),l.visita_id,p_nota,p_respondente,p_comentario,'direta',null);
 update public.campo_pesquisa_links set respondido_em=clock_timestamp() where id=l.id;
 return true;
end$$;
revoke all on function campo_pesquisa_privada.responder(text,integer,text,text) from public;
grant execute on function campo_pesquisa_privada.responder(text,integer,text,text) to anon,authenticated;
create function public.campo_responder_pesquisa(p_token text,p_nota integer,p_respondente text,p_comentario text) returns boolean language sql security invoker set search_path='' as $$select campo_pesquisa_privada.responder(p_token,p_nota,p_respondente,p_comentario)$$;
revoke all on function public.campo_responder_pesquisa(text,integer,text,text) from public;
grant execute on function public.campo_responder_pesquisa(text,integer,text,text) to anon,authenticated;

create function campo_private.encerrar_links_nps_assistido() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.coleta='assistida' then update public.campo_pesquisa_links set revogado_em=clock_timestamp(),revogado_por=new.autor_id where visita_id=new.visita_id and revogado_em is null and respondido_em is null;end if;
 return new;
end$$;
revoke all on function campo_private.encerrar_links_nps_assistido() from public,anon,authenticated;
create trigger campo_nps_encerrar_links after insert on public.campo_visita_nps for each row execute function campo_private.encerrar_links_nps_assistido();