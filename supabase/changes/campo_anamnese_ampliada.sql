CREATE OR REPLACE FUNCTION campo_private.registrar_prontuario(p_id uuid, p_paciente uuid, p_tipo text, p_atendimento timestamp with time zone, p_conteudo jsonb, p_referencia uuid, p_homologacao boolean)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u public.campo_perfis;p public.campo_pacientes;r public.campo_prontuario;k text;v jsonb;
begin
 if not campo_private.pode_prontuario(p_paciente,true) then raise exception 'Acesso clinico necessario' using errcode='42501';end if;
 select * into u from public.campo_perfis where id=auth.uid() and ativo;
 select * into p from public.campo_pacientes where id=p_paciente;
 if p_homologacao is distinct from true or not p.homologacao then raise exception 'Somente homologacao ficticia';end if;
 if p_id is null or p_tipo is null or p_tipo not in ('anamnese','evolucao','adendo') or p_atendimento is null or p_atendimento>now()+interval '5 minutes' or p_atendimento<timestamp '1900-01-01' then raise exception 'Tipo ou data invalida';end if;
 if p_conteudo is null or jsonb_typeof(p_conteudo)<>'object' or octet_length(p_conteudo::text)>50000 then raise exception 'Conteudo invalido';end if;
 if p_conteudo ? 'situacao_evolucao' then
 if p_conteudo->>'situacao_evolucao' is null or p_conteudo->>'situacao_evolucao' not in ('nao_avaliado','melhora','estavel','piora') then raise exception 'Situacao de evolucao invalida';end if;
 if p_conteudo->>'situacao_evolucao'<>'nao_avaliado' and length(btrim(coalesce(p_conteudo->>'justificativa_evolucao','')))<3 then raise exception 'Justifique a avaliacao da evolucao';end if;
 end if;
 for k,v in select * from jsonb_each(p_conteudo) loop
  if k not in ('queixa','historico','alergias','medicamentos','contexto','avaliacao','conduta','plano','texto','mobilidade','limitacoes','avaliacao_inicial','necessidades','objetivo_cuidado','criterio_reavaliacao','situacao_evolucao','justificativa_evolucao','treinamento','proximo_passo') or jsonb_typeof(v)<>'string' or length(v#>>'{}')>8000 then raise exception 'Campo invalido';end if;
 end loop;
 if (p_tipo='anamnese' and length(btrim(coalesce(p_conteudo->>'queixa','')))<3) or (p_tipo='evolucao' and length(btrim(coalesce(p_conteudo->>'avaliacao','')))<3) or (p_tipo='adendo' and length(btrim(coalesce(p_conteudo->>'texto','')))<3) then raise exception 'Preencha o registro obrigatorio';end if;
 if p_tipo='adendo' then
  if not exists(select 1 from public.campo_prontuario where id=p_referencia and paciente_id=p.id and empresa_id=p.empresa_id) then raise exception 'Registro de referencia invalido';end if;
 elsif p_referencia is not null then raise exception 'Referencia somente para adendo';end if;
 select * into r from public.campo_prontuario where id=p_id;
 if found then
  if r.paciente_id=p.id and r.responsavel_id=u.id and r.tipo=p_tipo and r.atendimento_em=p_atendimento and r.conteudo=p_conteudo and r.referencia_id is not distinct from p_referencia then return r.id;end if;
  raise exception 'Identificador em conflito';
 end if;
 insert into public.campo_prontuario(id,paciente_id,empresa_id,responsavel_id,responsavel_nome,profissao,tipo,atendimento_em,conteudo,referencia_id,homologacao)
 values(p_id,p.id,p.empresa_id,u.id,u.nome,u.profissao,p_tipo,p_atendimento,p_conteudo,p_referencia,true);
 insert into public.campo_eventos(empresa_id,responsavel_id,registro_id,entidade,acao,status) values(p.empresa_id,u.id,p_id,'prontuario','REGISTRO',p_tipo);
 return p_id;
end $function$
;