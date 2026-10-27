
create table public.campo_teste_revisoes (
 id uuid primary key default gen_random_uuid(),teste_id uuid not null references public.campo_testes(id),empresa_id uuid not null references public.campo_empresas(id),
 autor_id uuid references auth.users(id),estado jsonb not null,criado_em timestamptz not null default clock_timestamp()
);
create index campo_teste_revisoes_teste on public.campo_teste_revisoes(teste_id,criado_em);
alter table public.campo_teste_revisoes enable row level security;
revoke all on public.campo_teste_revisoes from public,anon,authenticated;
grant select on public.campo_teste_revisoes to authenticated;
create policy campo_teste_revisoes_ver on public.campo_teste_revisoes for select to authenticated using(exists(select 1 from public.campo_testes t where t.id=teste_id));
create trigger campo_teste_revisoes_imutavel before update or delete on public.campo_teste_revisoes for each row execute function campo_private.prontuario_imutavel();
create function campo_private.validar_teste_operacional() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='UPDATE' and old.status in ('aprovado','reprovado') then raise exception 'Protocolo encerrado preservado. Abra novo protocolo com referencia ao anterior';end if;
 if length(btrim(coalesce(new.objetivo,'')))<3 or length(btrim(coalesce(new.criterios,'')))<3 then raise exception 'Informe objetivo e criterios de avaliacao';end if;
 if new.status in ('aprovado','reprovado') and length(btrim(coalesce(new.resultado,'')))<3 then raise exception 'Registre resultado justificado para concluir o protocolo';end if;
 if new.inicio is not null and new.retorno is not null and new.retorno<new.inicio then raise exception 'Retorno anterior ao inicio do teste';end if;
 return new;
end$$;
revoke all on function campo_private.validar_teste_operacional() from public,anon,authenticated;
create trigger campo_teste_validar before insert or update on public.campo_testes for each row execute function campo_private.validar_teste_operacional();
create function campo_private.auditar_teste_operacional() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.campo_teste_revisoes(teste_id,empresa_id,autor_id,estado) values(new.id,new.empresa_id,auth.uid(),to_jsonb(new));return new;
end$$;
revoke all on function campo_private.auditar_teste_operacional() from public,anon,authenticated;
create trigger campo_teste_revisao_snapshot after insert or update on public.campo_testes for each row execute function campo_private.auditar_teste_operacional();
insert into public.campo_teste_revisoes(teste_id,empresa_id,autor_id,estado) select id,empresa_id,null,to_jsonb(t) from public.campo_testes t;
create function public.campo_historico_teste(p_id uuid) returns setof public.campo_teste_revisoes language sql security invoker set search_path='' as $$select r.* from public.campo_teste_revisoes r where r.teste_id=p_id order by r.criado_em,r.id$$;
revoke all on function public.campo_historico_teste(uuid) from public,anon;
grant execute on function public.campo_historico_teste(uuid) to authenticated;
