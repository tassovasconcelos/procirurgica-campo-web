export const TIPOS_ACAO={
 meta:{titulo:'Meta de cuidado',campos:[['titulo','Meta','text'],['criterio','Critério verificável','textarea'],['prazo','Prazo de reavaliação','date'],['status','Situação','select',['aberta','em_andamento','concluida','cancelada']],['evidencia','Evidência de conclusão','textarea'],['observacao','Justificativa / reavaliação','textarea']]},
 tarefa:{titulo:'Tarefa de cuidado',campos:[['titulo','Tarefa','text'],['meta_id','Meta vinculada','meta'],['executor','Quem executará','select',['profissional','paciente','familiar','cuidador']],['prazo','Prazo','date'],['status','Situação','select',['aberta','em_andamento','concluida','cancelada']],['evidencia','Evidência de conclusão','textarea'],['observacao','Justificativa / orientação','textarea']]},
 consumo:{titulo:'Consumo e estoque informado',campos:[['produto','Produto','text'],['referencia','Referência / modelo','text'],['unidade','Unidade (não misturar caixa e unidade)','text'],['consumo_dia','Consumo diário informado (opcional)','number'],['estoque','Estoque informado na mesma unidade (opcional)','number'],['data_referencia','Data da informação','date'],['origem','Quem informou','select',['paciente','cuidador','familiar','profissional']],['observacao','Contexto / correção de informação anterior','textarea']]},
 juridico:{titulo:'Item do checklist jurídico',campos:[['titulo','Documento ou necessidade','text'],['categoria','Categoria','select',['identidade','cpf','endereco','prescricao','relatorio','procuracao','decisao','outro']],['status','Revisão jurídica','select',['pendente','em_analise','aprovado','complemento','dispensado']],['documento_id','Original recebido para revisar','documento'],['prazo','Prazo de complemento (opcional)','date'],['observacao','Parecer / complemento solicitado / dispensa','textarea']]}
};
export function validarAcao(tipo,d){
 if(!TIPOS_ACAO[tipo])throw Error('Tipo inválido.');
 for(const [k,,type,options] of TIPOS_ACAO[tipo].campos){if(typeof d[k]!=='string'||d[k].length>2000)throw Error('Campo inválido.');if(type==='select'&&!options.includes(d[k]))throw Error('Alternativa inválida.');}
 if(tipo!=='consumo'&&d.titulo.trim().length<3)throw Error('Informe um título.');
 if(['meta','tarefa'].includes(tipo)){
 if(!d.prazo||tipo==='meta'&&d.criterio.trim().length<3||tipo==='tarefa'&&!d.meta_id)throw Error('Informe prazo e critério/meta.');
 if(d.status==='concluida'&&d.evidencia.trim().length<3)throw Error('Informe evidência de conclusão.');
 if(d.status==='cancelada'&&d.observacao.trim().length<3)throw Error('Justifique o cancelamento.');}
 if(tipo==='consumo'){if(d.produto.trim().length<2||!d.unidade.trim()||!d.data_referencia||(d.consumo_dia===''&&d.estoque===''))throw Error('Informe produto, unidade, data e consumo ou estoque.');
 for(const k of ['consumo_dia','estoque'])if(d[k]!==''&&(!Number.isFinite(Number(d[k]))||Number(d[k])<0||Number(d[k])>1000000))throw Error('Quantidade inválida.');}
 if(tipo==='juridico'){if(d.status==='aprovado'&&!d.documento_id)throw Error('Vincule o original recebido para aprovar.');if(['complemento','dispensado'].includes(d.status)&&d.observacao.trim().length<3)throw Error('Descreva o complemento ou a dispensa.');}
 return d;
}
export function autonomiaInformada(d){const q=Number(d.consumo_dia),s=Number(d.estoque);return d.consumo_dia!==''&&d.estoque!==''&&Number.isFinite(q)&&Number.isFinite(s)&&q>0&&s>=0?s/q:null;}
export function tokenPesquisa(){return [...crypto.getRandomValues(new Uint8Array(32))].map(n=>n.toString(16).padStart(2,'0')).join('');}
