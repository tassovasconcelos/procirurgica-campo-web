export const ETAPAS={adaptacao:'Adaptação',padronizacao:'Padronização',uso_continuo:'Uso contínuo'};
export const TESTES={nao_iniciado:'Não iniciado',em_teste:'Em teste',aprovado:'Aprovado',reprovado:'Reprovado',suspenso:'Suspenso'};
export const HOMOLOGACOES={nao_iniciada:'Não iniciada',em_homologacao:'Em homologação',aprovada:'Aprovada',reprovada:'Reprovada'};
export function cadastroVazio(){return{responsavel_tipo:'proprio',responsavel_nome:'',responsavel_vinculo:'',responsavel_telefone:'',modalidade:'nao_informado',liminar_numero:'',liminar_orgao:'',liminar_validade:'',tem_plano:false,plano_nome:'',etapa:'adaptacao',perfil_upsell:'nao_avaliado',motivo_upsell:'',produtos:[]};}
export function produtoVazio(){return{nome:'',marca:'',modelo:'',quantidade:1,periodo:'mes',unidade:'unidade',finalidade:'uso_continuo',teste_status:'nao_iniciado',homologacao_status:'nao_iniciada',inicio:'',retorno:'',conclusao:'',resultado:'',cross:'',up:'',oportunidade_status:'identificada',justificativa:''};}
export function consumoMensal(p){const n=Number(p.quantidade);return Number.isFinite(n)&&n>0?n*({dia:30,semana:30/7,mes:1}[p.periodo]??0):0;}
export function validarCadastro(d){
 if(d.responsavel_tipo!=='proprio'&&d.responsavel_nome.trim().length<2)throw Error('Informe o familiar ou cuidador responsável.');
 if(d.modalidade==='liminar'&&d.liminar_numero.trim().length<2)throw Error('Identifique a liminar.');
 if(d.tem_plano&&d.plano_nome.trim().length<2)throw Error('Informe o plano de saúde.');
 if(d.perfil_upsell==='potencial'&&d.motivo_upsell.trim().length<3)throw Error('Justifique o potencial de up sell para avaliação profissional.');
 if(d.produtos.length>50)throw Error('Limite de 50 produtos por paciente.');
 for(const p of d.produtos){if(p.nome.trim().length<2||!p.unidade.trim()||!Number.isFinite(p.quantidade)||p.quantidade<=0||p.quantidade>100000)throw Error('Confira o nome, a unidade e o consumo de cada produto.');if((['aprovado','reprovado'].includes(p.teste_status)||['aprovada','reprovada'].includes(p.homologacao_status))&&p.resultado.trim().length<3)throw Error('Registre o resultado dos testes ou homologações concluídos.');}
 return d;
}
export function indicadoresCadastros(rows){
 const produtos=rows.flatMap(r=>r.dados.produtos??[]),count=(key,v)=>produtos.filter(p=>p[key]===v).length;
 const aprovadas=count('homologacao_status','aprovada'),reprovadas=count('homologacao_status','reprovada');
 return{pacientes:rows.length,produtos:produtos.length,testes:count('teste_status','em_teste'),testesAprovados:count('teste_status','aprovado'),testesReprovados:count('teste_status','reprovado'),homologacoes:count('homologacao_status','em_homologacao'),aprovadas,reprovadas,taxa:aprovadas+reprovadas?100*aprovadas/(aprovadas+reprovadas):null,cross:produtos.filter(p=>p.cross?.trim()&&p.oportunidade_status!=='descartada').length,up:rows.filter(r=>r.dados.perfil_upsell==='potencial').length,liminares:rows.filter(r=>r.dados.modalidade==='liminar').length,particulares:rows.filter(r=>r.dados.modalidade==='particular').length,comPlano:rows.filter(r=>r.dados.tem_plano).length};
}

