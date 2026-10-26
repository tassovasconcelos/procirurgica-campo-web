import {autonomiaInformada} from './acompanhamento-utils.js';
const FECHADAS=['concluida','cancelada','aprovado','dispensado'];
const ABERTAS_VISITA=['agendada','confirmada','reagendada'];
function diaValido(v){if(!/^\d{4}-\d{2}-\d{2}$/.test(v??''))return false;const d=new Date(v+'T12:00:00Z');return Number.isFinite(d.getTime())&&d.toISOString().slice(0,10)===v;}
export function filtrarAcompanhamento(rows,f={},hoje){
 return rows.filter(r=>(!f.tipo||r.tipo===f.tipo)&&(!f.status||r.dados.status===f.status)&&(!f.busca||[r.dados.titulo,r.dados.produto,r.dados.referencia,r.dados.unidade,r.dados.observacao].join(' ').toLocaleLowerCase('pt-BR').includes(f.busca.toLocaleLowerCase('pt-BR')))&&(!f.vencidas||!FECHADAS.includes(r.dados.status)&&diaValido(r.dados.prazo)&&r.dados.prazo<hoje))
 .sort((a,b)=>{const vence=r=>!FECHADAS.includes(r.dados.status)&&diaValido(r.dados.prazo)&&r.dados.prazo<hoje;return Number(vence(b))-Number(vence(a))||(a.dados.prazo||'9999').localeCompare(b.dados.prazo||'9999')||b.criado_em.localeCompare(a.criado_em)||a.item_id.localeCompare(b.item_id);});
}
export function resumirConsumo(rows,hoje,revisarDias=7){
 if(!diaValido(hoje))throw Error('Data de referência inválida.');
 const groups=new Map();
 for(const r of rows.filter(r=>r.tipo==='consumo')){const d=r.dados,key=JSON.stringify([d.produto.trim().toLocaleLowerCase('pt-BR'),(d.referencia??'').trim().toLocaleLowerCase('pt-BR'),d.unidade.trim().toLocaleLowerCase('pt-BR')]);if(!groups.has(key))groups.set(key,[]);groups.get(key).push(r);}
 return [...groups.values()].map(registros=>{registros.sort((a,b)=>b.dados.data_referencia.localeCompare(a.dados.data_referencia)||b.criado_em.localeCompare(a.criado_em)||b.evento_id.localeCompare(a.evento_id));
 const ultimo=registros[0],d=ultimo.dados,autonomia=autonomiaInformada(d),dias=diaValido(d.data_referencia)?Math.floor((new Date(hoje+'T12:00:00Z')-new Date(d.data_referencia+'T12:00:00Z'))/86400000):null;
 return {ultimo,anterior:registros[1]??null,observacoes:registros.length,autonomia,dias,desatualizado:dias!==null&&dias>=revisarDias,autonomiaCurta:autonomia!==null&&autonomia<=revisarDias};
 }).sort((a,b)=>Number(b.desatualizado||b.autonomiaCurta)-Number(a.desatualizado||a.autonomiaCurta)||a.ultimo.dados.produto.localeCompare(b.ultimo.dados.produto,'pt-BR'));
}
export function filtrarPrioridadeVisitas(rows,prioridade,hoje,agora=Date.now()){
 return rows.filter(v=>{const aberta=ABERTAS_VISITA.includes(v.status),inicio=new Date(v.inicio),fim=new Date(v.fim);if(!Number.isFinite(inicio.getTime())||!Number.isFinite(fim.getTime()))return false;
 if(prioridade==='atrasadas')return aberta&&fim.getTime()<agora;
 if(prioridade==='hoje')return new Intl.DateTimeFormat('en-CA',{timeZone:'America/Sao_Paulo'}).format(inicio)===hoje;
 if(prioridade==='proximas')return aberta&&fim.getTime()>=agora;
 return true;
 }).sort((a,b)=>{const vencida=v=>ABERTAS_VISITA.includes(v.status)&&new Date(v.fim).getTime()<agora;return Number(vencida(b))-Number(vencida(a))||a.inicio.localeCompare(b.inicio)||a.id.localeCompare(b.id);});
}
