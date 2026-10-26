create or replace function campo_private.autorizar_documento(p_id uuid,p_operacao text) returns jsonb language plpgsql security definer set search_path='' as $$
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
 return jsonb_build_object('id',d.id,'caminho',d.caminho,'nome',d.nome,'mime',d.mime,'tamanho',d.tamanho,'status',d.status,'sha256',d.sha256);
end$$;