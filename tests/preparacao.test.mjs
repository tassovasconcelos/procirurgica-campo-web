import assert from 'node:assert/strict';import schema from '../procuidar-formularios-schema.js';import {conteudoFicha} from '../procuidar-formularios-ui.js';import {ETAPAS} from '../operacao-ui.js';import {MODELOS_PROTOCOLO} from '../protocolos-modelos.js';
assert.equal(schema.forms.length,7);assert.equal(new Set(ETAPAS.map(e=>e[0])).size,14);assert.equal(MODELOS_PROTOCOLO.length,3);
const plan=schema.forms.find(f=>f.id==='planejamento_teste');
assert.throws(()=>conteudoFicha(plan,{produto_referencia:'Produto fictício'}));
assert.match(conteudoFicha(plan,{produto_referencia:'Produto fictício',objetivo_teste:'Objetivo fictício',criterios_teste:'Critérios fictícios'}).avaliacao,/1.3.0/);
for(const f of schema.forms){assert.ok(f.pending.length);assert.equal(new Set(f.fields.map(x=>x.id)).size,f.fields.length);assert.ok(['stomapro','confortcath','geral'].includes(f.linha));}
console.log('Preparação: catálogo de modelos, critérios e roteiro de homologação aprovados');
