import assert from 'node:assert/strict';import {TIPOS_ACAO,validarAcao,autonomiaInformada,tokenPesquisa} from '../acompanhamento-utils.js';
const blank=t=>Object.fromEntries(TIPOS_ACAO[t].campos.map(([k,,type,opts])=>[k,type==='select'?opts[0]:'']));
let d={...blank('meta'),titulo:'Meta ficticia',criterio:'Criterio ficticio',prazo:'2030-01-01',status:'concluida'};
assert.throws(()=>validarAcao('meta',d));d.evidencia='Evidencia ficticia';assert.equal(validarAcao('meta',d),d);
d={...blank('consumo'),produto:'Produto ficticio',unidade:'unidade',data_referencia:'2026-10-26',consumo_dia:'4',estoque:'24'};assert.equal(autonomiaInformada(d),6);
assert.equal(autonomiaInformada({...d,consumo_dia:'0'}),null);assert.equal(autonomiaInformada({...d,estoque:''}),null);assert.throws(()=>validarAcao('consumo',{...d,estoque:'-1'}));
assert.throws(()=>validarAcao('juridico',{...blank('juridico'),titulo:'Documento ficticio',status:'aprovado'}));
const tokens=Array.from({length:20},tokenPesquisa);assert.equal(new Set(tokens).size,20);assert.ok(tokens.every(t=>/^[a-f0-9]{64}$/.test(t)));console.log('Quatro frentes: validações, estimativa informada e tokens aprovados');
