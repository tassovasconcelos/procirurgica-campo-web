CREATE OR REPLACE FUNCTION campo_private.validar_cadastro(d jsonb)
 RETURNS void
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
declare k text;v jsonb;r jsonb;dt text;
begin
 if d is null or jsonb_typeof(d)<>'object' or octet_length(d::text)>80000 then raise exception 'Cadastro invalido';end if;
 for k,v in select * from jsonb_each(d) loop
  if k not in ('responsavel_tipo','responsavel_nome','responsavel_vinculo','responsavel_telefone','modalidade','liminar_numero','liminar_orgao','liminar_validade','tem_plano','plano_nome','etapa','perfil_upsell','motivo_upsell','produtos','liminar_situacao','endereco','numero','bairro','cep','complemento') then raise exception 'Campo de cadastro invalido';end if;
  if k not in ('tem_plano','produtos') and (jsonb_typeof(v)<>'string' or length(v#>>'{}')>1000) then raise exception 'Texto de cadastro invalido';end if;
 end loop;
 if coalesce(d->>'responsavel_tipo','') not in ('proprio','familiar','cuidador','outro') or coalesce(d->>'modalidade','') not in ('nao_informado','particular','liminar','outro') or coalesce(d->>'etapa','') not in ('adaptacao','padronizacao','uso_continuo') or coalesce(d->>'perfil_upsell','') not in ('nao_avaliado','em_avaliacao','potencial','nao_indicado') or jsonb_typeof(d->'tem_plano') is distinct from 'boolean' then raise exception 'Classificacao invalida';end if;
 if d ? 'liminar_situacao' then
 if coalesce(d->>'liminar_situacao','') not in ('nao_informado','nao','preparacao','sim') then raise exception 'Situacao de liminar invalida';end if;
 if d->>'modalidade'='liminar' and d->>'liminar_situacao'<>'sim' then raise exception 'Identifique a liminar na situacao do paciente';end if;
 if d->>'liminar_situacao'='sim' and length(btrim(coalesce(d->>'liminar_numero','')))<2 then raise exception 'Identifique a liminar';end if;
 end if;
 if d->>'responsavel_tipo'<>'proprio' and length(btrim(coalesce(d->>'responsavel_nome','')))<2 then raise exception 'Informe familiar ou cuidador';end if;
 if d->>'modalidade'='liminar' and length(btrim(coalesce(d->>'liminar_numero','')))<2 then raise exception 'Identifique a liminar';end if;
 if (d->>'tem_plano')::boolean and length(btrim(coalesce(d->>'plano_nome','')))<2 then raise exception 'Informe o plano de saude';end if;
 if d->>'perfil_upsell'='potencial' and length(btrim(coalesce(d->>'motivo_upsell','')))<3 then raise exception 'Justifique o potencial de up sell';end if;
 if coalesce(d->>'liminar_validade','')<>'' then perform (d->>'liminar_validade')::date;end if;
 if jsonb_typeof(d->'produtos') is distinct from 'array' or jsonb_array_length(d->'produtos')>50 then raise exception 'Lista de produtos invalida';end if;
 for r in select value from jsonb_array_elements(d->'produtos') loop
  if jsonb_typeof(r)<>'object' then raise exception 'Produto invalido';end if;
  for k,v in select * from jsonb_each(r) loop
   if k not in ('nome','marca','modelo','quantidade','periodo','unidade','finalidade','teste_status','homologacao_status','inicio','retorno','conclusao','resultado','cross','up','oportunidade_status','justificativa') or (k<>'quantidade' and (jsonb_typeof(v)<>'string' or length(v#>>'{}')>1000)) then raise exception 'Campo de produto invalido';end if;
  end loop;
  if length(btrim(coalesce(r->>'nome','')))<2 or length(btrim(coalesce(r->>'unidade','')))<1 or jsonb_typeof(r->'quantidade') is distinct from 'number' or (r->>'quantidade')::numeric<=0 or (r->>'quantidade')::numeric>100000 then raise exception 'Nome ou consumo invalido';end if;
  if coalesce(r->>'periodo','') not in ('dia','semana','mes') or coalesce(r->>'finalidade','') not in ('adaptacao','padronizacao','uso_continuo') or coalesce(r->>'teste_status','') not in ('nao_iniciado','em_teste','aprovado','reprovado','suspenso') or coalesce(r->>'homologacao_status','') not in ('nao_iniciada','em_homologacao','aprovada','reprovada') or coalesce(r->>'oportunidade_status','') not in ('identificada','em_avaliacao','aprovada','descartada') then raise exception 'Status de produto invalido';end if;
  foreach dt in array array['inicio','retorno','conclusao'] loop if coalesce(r->>dt,'')<>'' then perform (r->>dt)::date;end if;end loop;
  if (r->>'teste_status' in ('aprovado','reprovado') or r->>'homologacao_status' in ('aprovada','reprovada')) and length(btrim(coalesce(r->>'resultado','')))<3 then raise exception 'Registre resultado da avaliacao';end if;
 end loop;
end $function$
;