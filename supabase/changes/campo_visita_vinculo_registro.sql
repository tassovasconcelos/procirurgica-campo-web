CREATE OR REPLACE FUNCTION campo_private.salvar_visita(p_request uuid, p_dados jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 if ini>now()+interval '5 minutes' or not exists(select 1 from public.campo_prontuario r where r.id=reg and r.paciente_id=pid and r.responsavel_id=prof and r.tipo in ('anamnese','evolucao') and (r.atendimento_em at time zone 'America/Sao_Paulo')::date=(ini at time zone 'America/Sao_Paulo')::date) then raise exception 'Vincule uma anamnese ou evolucao do profissional para realizar a visita';end if;
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
end $function$
;
create unique index campo_visita_registro_unico on public.campo_visitas(registro_id) where registro_id is not null;