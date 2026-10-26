export const STATUS_VISITA={agendada:'Agendada',confirmada:'Confirmada',realizada:'Realizada',reagendada:'Reagendada',cancelada:'Cancelada',nao_realizada:'Não realizada'};
export const ABERTAS=['agendada','confirmada','reagendada'];
export function indicadoresVisitas(visitas,pesquisas,agora=Date.now()){
 const encerradas=visitas.filter(v=>v.status==='realizada').length,previstas=visitas.filter(v=>new Date(v.inicio).getTime()<=agora).length;
 const ids=new Set(visitas.map(v=>v.id)),notas=pesquisas.filter(n=>ids.has(n.visita_id)&&Number.isInteger(n.nota)&&n.nota>=0&&n.nota<=10);
 const promotores=notas.filter(n=>n.nota>=9).length,detratores=notas.filter(n=>n.nota<=6).length;
 return {total:visitas.length,realizadas:encerradas,previstas,cumprimento:previstas?100*visitas.filter(v=>v.status==='realizada'&&new Date(v.inicio).getTime()<=agora).length/previstas:null,
 atrasadas:visitas.filter(v=>ABERTAS.includes(v.status)&&new Date(v.fim).getTime()<agora).length,
 canceladas:visitas.filter(v=>v.status==='cancelada').length,reagendadas:visitas.filter(v=>v.status==='reagendada').length,
 respostas:notas.length,promotores,detratores,passivos:notas.length-promotores-detratores,
 nps:notas.length?100*(promotores-detratores)/notas.length:null,cobertura:encerradas?100*notas.length/encerradas:null};
}
export function validarVisita(d){
 if(!d.paciente_id||!d.profissional_id||!d.objetivo?.trim()||d.objetivo.trim().length<3)throw Error('Informe paciente, profissional e objetivo.');
 const i=new Date(d.inicio).getTime(),f=new Date(d.fim).getTime();
 if(!Number.isFinite(i)||!Number.isFinite(f)||f<=i||f-i>43200000)throw Error('Informe um intervalo válido de até 12 horas.');
 if(!Object.hasOwn(STATUS_VISITA,d.status))throw Error('Status inválido.');
 if(['cancelada','reagendada','nao_realizada'].includes(d.status)&&d.motivo?.trim().length<3)throw Error('Informe o motivo.');
 if(d.status==='realizada'&&!d.registro_id)throw Error('Vincule a anamnese ou evolução realizada.');
 return d;
}
export function formatarConsumo(produtos){
 return produtos.map(p=>{const fatores={dia:30,semana:30/7,mes:1},q=Number(p.quantidade);return {...p,mensalEstimado:Number.isFinite(q)&&q>0&&fatores[p.periodo]?q*fatores[p.periodo]:null};});
}
