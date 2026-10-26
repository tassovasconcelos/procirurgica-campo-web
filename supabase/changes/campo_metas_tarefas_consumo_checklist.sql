
create table public.campo_acoes_paciente (
 evento_id uuid primary key, item_id uuid not null, paciente_id uuid not null references public.campo_pacientes(id),
 empresa_id uuid not null references public.campo_empresas(id), tipo text not null check(tipo in ('meta','tarefa','consumo','juridico')),
 versao integer not null check(versao>0), dados jsonb not null, autor_id uuid not null references auth.users(id), criado_em timestamptz not null default now(),unique(item_id,versao)
);
create index campo_acoes_paciente_escopo on public.campo_acoes_paciente(paciente_id,tipo,item_id,versao desc);
alter table public.campo_acoes_paciente enable row level security;
revoke all on public.campo_acoes_paciente from public,anon,authenticated;
grant select on public.campo_acoes_paciente to authenticated;
create policy campo_acoes_ler on public.campo_acoes_paciente for select to authenticated using(
 (tipo='juridico' and campo_private.pode_cofre(paciente_id,false)) or (tipo<>'juridico' and campo_private.pode_prontuario(paciente_id,false)));
create trigger campo_acoes_imutavel before update or delete on public.campo_acoes_paciente for each row execute function campo_private.prontuario_imutavel();

create function campo_private.registrar_acao(p_evento uuid,p_item uuid,p_paciente uuid,p_tipo text,p_versao integer,p_dados jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.campo_pacientes;r public.campo_acoes_paciente;old public.campo_acoes_paciente;meta public.campo_acoes_paciente;k text;v jsonb;allowed text[];q numeric;s numeric;
begin
 if p_tipo='juridico' then
 if not campo_private.pode_cofre(p_paciente,false) then raise exception 'Acao juridica nao autorizada' using errcode='42501';end if;
 elsif not campo_private.pode_prontuario(p_paciente,true) then raise exception 'Acao assistencial nao autorizada' using errcode='42501';end if;
 select * into p from public.campo_pacientes where id=p_paciente;
 if not p.homologacao then raise exception 'Somente homologacao ficticia';end if;
 if p_evento is null or p_item is null or p_tipo is null or p_tipo not in ('meta','tarefa','consumo','juridico') or p_versao is null or p_versao<0 or p_dados is null or jsonb_typeof(p_dados)<>'object' or octet_length(p_dados::text)>16000 then raise exception 'Acao invalida';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_paciente::text,1));
 select * into r from public.campo_acoes_paciente where evento_id=p_evento;
 if found then
 if r.item_id=p_item and r.paciente_id=p_paciente and r.tipo=p_tipo and r.versao=p_versao+1 and r.dados=p_dados and r.autor_id=auth.uid() then return to_jsonb(r);end if;
 raise exception 'Identificador de acao em conflito';end if;
 select * into old from public.campo_acoes_paciente where item_id=p_item order by versao desc limit 1;
 if found then
 if old.paciente_id<>p_paciente or old.tipo<>p_tipo then raise exception 'Acao nao autorizada' using errcode='42501';end if;
 if old.versao<>p_versao then raise exception 'Acao alterada. Recarregue';end if;
 if p_tipo='consumo' then raise exception 'Consumo preservado. Registre nova observacao';end if;
 elsif p_versao<>0 then raise exception 'Acao inexistente';end if;
 allowed=case p_tipo when 'meta' then array['titulo','criterio','prazo','status','evidencia','observacao']
 when 'tarefa' then array['titulo','meta_id','prazo','status','evidencia','observacao','executor']
 when 'consumo' then array['produto','referencia','unidade','consumo_dia','estoque','data_referencia','origem','observacao']
 else array['titulo','categoria','status','documento_id','prazo','observacao'] end;
 for k,v in select * from jsonb_each(p_dados) loop
 if not k=any(allowed) or jsonb_typeof(v)<>'string' or length(v#>>'{}')>2000 then raise exception 'Campo de acao invalido';end if;end loop;
 if coalesce(p_dados->>'prazo','')<>'' then perform (p_dados->>'prazo')::date;end if;
 if p_tipo in ('meta','tarefa','juridico') and length(btrim(coalesce(p_dados->>'titulo','')))<3 then raise exception 'Informe titulo';end if;
 if p_tipo='meta' then
 if length(btrim(coalesce(p_dados->>'criterio','')))<3 or coalesce(p_dados->>'prazo','')='' or coalesce(p_dados->>'status','') not in ('aberta','em_andamento','concluida','cancelada') then raise exception 'Informe criterio, prazo e status da meta';end if;
 if p_dados->>'status'='concluida' and exists(select 1 from (select distinct on(item_id) * from public.campo_acoes_paciente where paciente_id=p_paciente and tipo='tarefa' order by item_id,versao desc) t where t.dados->>'meta_id'=p_item::text and t.dados->>'status' not in ('concluida','cancelada')) then raise exception 'Conclua ou cancele as tarefas antes da meta';end if;
 elsif p_tipo='tarefa' then
 select * into meta from public.campo_acoes_paciente where item_id=nullif(p_dados->>'meta_id','')::uuid and paciente_id=p_paciente and tipo='meta' order by versao desc limit 1;
 if meta.item_id is null or coalesce(p_dados->>'prazo','')='' or coalesce(p_dados->>'executor','') not in ('profissional','paciente','familiar','cuidador') or coalesce(p_dados->>'status','') not in ('aberta','em_andamento','concluida','cancelada') then raise exception 'Tarefa invalida';end if;
 if old.item_id is not null and old.dados->>'meta_id' is distinct from p_dados->>'meta_id' then raise exception 'Mantenha a meta original';end if;
 if meta.dados->>'status' in ('concluida','cancelada') then raise exception 'Meta encerrada. Reavalie a meta antes da tarefa';end if;
 elsif p_tipo='consumo' then
 if length(btrim(coalesce(p_dados->>'produto','')))<2 or length(btrim(coalesce(p_dados->>'unidade','')))<1 or coalesce(p_dados->>'origem','') not in ('paciente','cuidador','familiar','profissional') or coalesce(p_dados->>'data_referencia','')='' then raise exception 'Consumo invalido';end if;
 if (p_dados->>'data_referencia')::date>(now() at time zone 'America/Sao_Paulo')::date or (p_dados->>'data_referencia')::date<date '1900-01-01' then raise exception 'Data de consumo invalida';end if;
 q=nullif(p_dados->>'consumo_dia','')::numeric;s=nullif(p_dados->>'estoque','')::numeric;
 if q is null and s is null or q is not null and (q<0 or q>1000000) or s is not null and (s<0 or s>1000000) then raise exception 'Informe consumo ou estoque valido';end if;
 elsif p_tipo='juridico' then
 if coalesce(p_dados->>'categoria','') not in ('identidade','cpf','endereco','prescricao','relatorio','procuracao','decisao','outro') or coalesce(p_dados->>'status','') not in ('pendente','em_analise','aprovado','complemento','dispensado') then raise exception 'Checklist invalido';end if;
 if coalesce(p_dados->>'documento_id','')<>'' and not exists(select 1 from public.campo_documentos_pessoais d where d.id=(p_dados->>'documento_id')::uuid and d.paciente_id=p_paciente and d.categoria=p_dados->>'categoria' and d.status='confirmado') then raise exception 'Documento confirmado da mesma categoria e paciente necessario';end if;
 if p_dados->>'status'='aprovado' and coalesce(p_dados->>'documento_id','')='' then raise exception 'Vincule o documento para aprovar';end if;
 if p_dados->>'status' in ('complemento','dispensado') and length(btrim(coalesce(p_dados->>'observacao','')))<3 then raise exception 'Justifique complemento ou dispensa';end if;
 end if;
 if p_tipo in ('meta','tarefa') then
 if p_dados->>'status'='concluida' and length(btrim(coalesce(p_dados->>'evidencia','')))<3 then raise exception 'Registre evidencia de conclusao';end if;
 if (p_dados->>'status'='cancelada' or old.dados->>'status' in ('concluida','cancelada')) and length(btrim(coalesce(p_dados->>'observacao','')))<3 then raise exception 'Justifique cancelamento ou reabertura';end if;
 end if;
 insert into public.campo_acoes_paciente(evento_id,item_id,paciente_id,empresa_id,tipo,versao,dados,autor_id) values(p_evento,p_item,p_paciente,p.empresa_id,p_tipo,p_versao+1,p_dados,auth.uid()) returning * into r;
 return to_jsonb(r);
end$$;
revoke all on function campo_private.registrar_acao(uuid,uuid,uuid,text,integer,jsonb) from public,anon;
grant execute on function campo_private.registrar_acao(uuid,uuid,uuid,text,integer,jsonb) to authenticated;
create function public.campo_registrar_acao(p_evento uuid,p_item uuid,p_paciente uuid,p_tipo text,p_versao integer,p_dados jsonb) returns jsonb language sql security invoker set search_path='' as $$select campo_private.registrar_acao(p_evento,p_item,p_paciente,p_tipo,p_versao,p_dados)$$;
revoke all on function public.campo_registrar_acao(uuid,uuid,uuid,text,integer,jsonb) from public,anon;
grant execute on function public.campo_registrar_acao(uuid,uuid,uuid,text,integer,jsonb) to authenticated;
create function public.campo_listar_acoes(p_paciente uuid,p_tipo text default null) returns setof public.campo_acoes_paciente language sql security invoker set search_path='' as $$select distinct on(a.item_id) a.* from public.campo_acoes_paciente a where a.paciente_id=p_paciente and (p_tipo is null or a.tipo=p_tipo) order by a.item_id,a.versao desc$$;
revoke all on function public.campo_listar_acoes(uuid,text) from public,anon;
grant execute on function public.campo_listar_acoes(uuid,text) to authenticated;
create function public.campo_historico_acao(p_item uuid) returns setof public.campo_acoes_paciente language sql security invoker set search_path='' as $$select a.* from public.campo_acoes_paciente a where a.item_id=p_item order by a.versao$$;
revoke all on function public.campo_historico_acao(uuid) from public,anon;
grant execute on function public.campo_historico_acao(uuid) to authenticated;
