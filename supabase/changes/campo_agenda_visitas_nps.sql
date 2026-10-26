
create table public.campo_visitas (
 id uuid primary key, paciente_id uuid not null references public.campo_pacientes(id),
 empresa_id uuid not null references public.campo_empresas(id),
 profissional_id uuid not null references public.campo_perfis(id),
 inicio timestamptz not null, fim timestamptz not null,
 status text not null check(status in ('agendada','confirmada','realizada','reagendada','cancelada','nao_realizada')),
 objetivo text not null check(length(objetivo) between 3 and 1000), motivo text not null default '' check(length(motivo)<=1000),
 registro_id uuid references public.campo_prontuario(id), versao integer not null default 1,
 criado_em timestamptz not null default now(), atualizado_em timestamptz not null default now(),
 atualizado_por uuid not null references auth.users(id), homologacao boolean not null default true check(homologacao),
 check(fim>inicio and fim<=inicio+interval '12 hours')
);
create index campo_visitas_agenda on public.campo_visitas(empresa_id,inicio);
create index campo_visitas_profissional on public.campo_visitas(profissional_id,inicio);
create index campo_visitas_paciente on public.campo_visitas(paciente_id,inicio);
create table public.campo_visita_historico (
 request_id uuid primary key, visita_id uuid not null references public.campo_visitas(id),
 autor_id uuid not null references auth.users(id), entrada jsonb not null, estado jsonb not null,
 criado_em timestamptz not null default now()
);
create index campo_visita_historico_visita on public.campo_visita_historico(visita_id);
create trigger campo_visita_historico_imutavel before update or delete on public.campo_visita_historico for each row execute function campo_private.prontuario_imutavel();
create table public.campo_visita_nps (
 id uuid primary key, visita_id uuid not null unique references public.campo_visitas(id),
 nota integer not null check(nota between 0 and 10),
 respondente text not null check(respondente in ('paciente','familiar','cuidador')),
 comentario text not null default '' check(length(comentario)<=1000),
 coleta text not null default 'assistida' check(coleta='assistida'),
 autor_id uuid not null references auth.users(id), criado_em timestamptz not null default now()
);
create trigger campo_visita_nps_imutavel before update or delete on public.campo_visita_nps for each row execute function campo_private.prontuario_imutavel();
alter table public.campo_visitas enable row level security;
alter table public.campo_visita_historico enable row level security;
alter table public.campo_visita_nps enable row level security;
revoke all on public.campo_visitas,public.campo_visita_historico,public.campo_visita_nps from public,anon,authenticated;
grant select on public.campo_visitas,public.campo_visita_historico,public.campo_visita_nps to authenticated;
create policy campo_visitas_ler on public.campo_visitas for select to authenticated using(campo_private.pode_prontuario(paciente_id,false));
create policy campo_visita_historico_ler on public.campo_visita_historico for select to authenticated using(exists(select 1 from public.campo_visitas v where v.id=visita_id));
create policy campo_visita_nps_ler on public.campo_visita_nps for select to authenticated using(exists(select 1 from public.campo_visitas v where v.id=visita_id));

create function campo_private.salvar_visita(p_request uuid,p_dados jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.campo_pacientes;u public.campo_perfis;v public.campo_visitas;h public.campo_visita_historico;
 vid uuid;pid uuid;prof uuid;ini timestamptz;fin timestamptz;st text;obj text;mot text;reg uuid;prev integer;
begin
 if p_request is null or p_dados is null or jsonb_typeof(p_dados)<>'object' or octet_length(p_dados::text)>10000 then raise exception 'Dados de visita invalidos';end if;
 pid=(p_dados->>'paciente_id')::uuid;vid=(p_dados->>'id')::uuid;prof=(p_dados->>'profissional_id')::uuid;
 if not campo_private.pode_prontuario(pid,false) then raise exception 'Visita nao autorizada' using errcode='42501';end if;
 select * into p from public.campo_pacientes where id=pid;
 select * into u from public.campo_perfis where id=auth.uid() and ativo;
 if not p.homologacao or p_dados->>'homologacao' is distinct from 'true' then raise exception 'Somente homologacao ficticia';end if;
 if prof is distinct from p.responsavel_id or not exists(select 1 from public.campo_perfis a where a.id=prof and a.ativo and a.empresa_id=p.empresa_id and a.profissao in ('enfermeiro','fisioterapeuta','nutricionista')) then raise exception 'Profissional deve ser o responsavel assistencial ativo do paciente';end if;
 select * into h from public.campo_visita_historico where request_id=p_request;
 if found then
 if h.autor_id=auth.uid() and h.entrada=p_dados then return h.estado;end if;
 raise exception 'Identificador em conflito';end if;
 ini=(p_dados->>'inicio')::timestamptz;fin=(p_dados->>'fim')::timestamptz;
 st=p_dados->>'status';obj=btrim(coalesce(p_dados->>'objetivo',''));mot=btrim(coalesce(p_dados->>'motivo',''));
 reg=nullif(p_dados->>'registro_id','')::uuid;prev=coalesce((p_dados->>'versao')::integer,0);
 if vid is null or ini is null or fin is null or fin<=ini or fin>ini+interval '12 hours' or st is null or st not in ('agendada','confirmada','realizada','reagendada','cancelada','nao_realizada') or length(obj)<3 or length(obj)>1000 or length(mot)>1000 then raise exception 'Dados de visita invalidos';end if;
 if st in ('reagendada','cancelada','nao_realizada') and length(mot)<3 then raise exception 'Informe o motivo';end if;
 if st='realizada' then
 if ini>now()+interval '5 minutes' or not exists(select 1 from public.campo_prontuario r where r.id=reg and r.paciente_id=pid and r.responsavel_id=prof and r.tipo in ('anamnese','evolucao')) then raise exception 'Vincule uma anamnese ou evolucao do profissional para realizar a visita';end if;
 elsif reg is not null then raise exception 'Registro somente para visita realizada';end if;
 perform pg_advisory_xact_lock(hashtextextended(prof::text,0));
 select * into v from public.campo_visitas where id=vid for update;
 if found then
 if v.paciente_id<>pid or v.empresa_id<>p.empresa_id then raise exception 'Visita nao autorizada' using errcode='42501';end if;
 if v.versao<>prev then raise exception 'Visita alterada. Recarregue a agenda';end if;
 if v.status in ('realizada','cancelada','nao_realizada') then raise exception 'Visita encerrada preservada no historico';end if;
 elsif prev<>0 then raise exception 'Visita inexistente';end if;
 if st in ('agendada','confirmada','reagendada') and exists(select 1 from public.campo_visitas a where a.id<>vid and a.profissional_id=prof and a.status in ('agendada','confirmada','reagendada') and tstzrange(a.inicio,a.fim,'[)') && tstzrange(ini,fin,'[)')) then raise exception 'Conflito de horario do profissional';end if;
 if v.id is null then
 insert into public.campo_visitas(id,paciente_id,empresa_id,profissional_id,inicio,fim,status,objetivo,motivo,registro_id,atualizado_por) values(vid,pid,p.empresa_id,prof,ini,fin,st,obj,mot,reg,auth.uid()) returning * into v;
 else
 update public.campo_visitas set profissional_id=prof,inicio=ini,fim=fin,status=st,objetivo=obj,motivo=mot,registro_id=reg,versao=versao+1,atualizado_em=clock_timestamp(),atualizado_por=auth.uid() where id=vid returning * into v;
 end if;
 insert into public.campo_visita_historico(request_id,visita_id,autor_id,entrada,estado) values(p_request,vid,auth.uid(),p_dados,to_jsonb(v));
 return to_jsonb(v);
end $$;
revoke all on function campo_private.salvar_visita(uuid,jsonb) from public,anon;
grant execute on function campo_private.salvar_visita(uuid,jsonb) to authenticated;
create function public.campo_salvar_visita(p_request uuid,p_dados jsonb) returns jsonb language sql security invoker set search_path='' as $$ select campo_private.salvar_visita(p_request,p_dados) $$;
revoke all on function public.campo_salvar_visita(uuid,jsonb) from public,anon;
grant execute on function public.campo_salvar_visita(uuid,jsonb) to authenticated;

create function public.campo_listar_visitas(p_de date,p_ate date) returns setof public.campo_visitas language plpgsql security invoker set search_path='' as $$
begin
 if p_de is null or p_ate is null or p_ate<p_de or p_ate-p_de>92 then raise exception 'Consulte ate 93 dias por vez';end if;
 return query select v.* from public.campo_visitas v where v.inicio >= (p_de::timestamp at time zone 'America/Sao_Paulo') and v.inicio < ((p_ate+1)::timestamp at time zone 'America/Sao_Paulo') order by v.inicio,v.id;
end $$;
revoke all on function public.campo_listar_visitas(date,date) from public,anon;
grant execute on function public.campo_listar_visitas(date,date) to authenticated;

create function campo_private.registrar_nps(p_id uuid,p_visita uuid,p_nota integer,p_respondente text,p_comentario text) returns uuid language plpgsql security definer set search_path='' as $$
declare v public.campo_visitas;r public.campo_visita_nps;
begin
 select * into v from public.campo_visitas where id=p_visita;
 if v.id is null or not campo_private.pode_prontuario(v.paciente_id,false) then raise exception 'Pesquisa nao autorizada' using errcode='42501';end if;
 if v.status<>'realizada' then raise exception 'Pesquisa exige visita realizada';end if;
 if p_id is null or p_nota is null or p_nota not between 0 and 10 or p_respondente is null or p_respondente not in ('paciente','familiar','cuidador') or p_comentario is null or length(p_comentario)>1000 then raise exception 'Pesquisa invalida';end if;
 select * into r from public.campo_visita_nps where visita_id=p_visita for update;
 if found then
 if r.id=p_id and r.nota=p_nota and r.respondente=p_respondente and r.comentario=p_comentario and r.autor_id=auth.uid() then return r.id;end if;
 raise exception 'Visita ja possui pesquisa';end if;
 insert into public.campo_visita_nps(id,visita_id,nota,respondente,comentario,autor_id) values(p_id,p_visita,p_nota,p_respondente,p_comentario,auth.uid());
 return p_id;
end $$;
revoke all on function campo_private.registrar_nps(uuid,uuid,integer,text,text) from public,anon;
grant execute on function campo_private.registrar_nps(uuid,uuid,integer,text,text) to authenticated;
create function public.campo_registrar_nps(p_id uuid,p_visita uuid,p_nota integer,p_respondente text,p_comentario text) returns uuid language sql security invoker set search_path='' as $$select campo_private.registrar_nps(p_id,p_visita,p_nota,p_respondente,p_comentario)$$;
revoke all on function public.campo_registrar_nps(uuid,uuid,integer,text,text) from public,anon;
grant execute on function public.campo_registrar_nps(uuid,uuid,integer,text,text) to authenticated;
create function public.campo_listar_nps(p_de date,p_ate date) returns setof public.campo_visita_nps language sql security invoker set search_path='' as $$select n.* from public.campo_visita_nps n join public.campo_listar_visitas(p_de,p_ate) v on v.id=n.visita_id$$;
revoke all on function public.campo_listar_nps(date,date) from public,anon;
grant execute on function public.campo_listar_nps(date,date) to authenticated;

create function public.campo_historico_visita(p_visita uuid) returns setof public.campo_visita_historico language sql security invoker set search_path='' as $$select h.* from public.campo_visita_historico h where h.visita_id=p_visita order by h.criado_em,h.request_id$$;revoke all on function public.campo_historico_visita(uuid) from public,anon;grant execute on function public.campo_historico_visita(uuid) to authenticated;