import http from 'node:http';
import {readFile} from 'node:fs/promises';import {resolve,extname} from 'node:path';
import assert from 'node:assert/strict';import {chromium} from 'playwright';
const base=process.cwd(),server=http.createServer(async(req,res)=>{try{let path=new URL(req.url,'http://localhost').pathname;if(path==='/'||path==='/campo/'||path==='/gerencial/')path='/index.html';const file=resolve(base,'.'+path);if(!file.startsWith(base+'/'))throw Error();res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.json':'application/json'})[extname(file)]??'text/html');res.end(await readFile(file));}catch{res.statusCode=404;res.end();}});
await new Promise(r=>server.listen(8100,'127.0.0.1',r));let browser;
try{browser=await chromium.launch();const page=await browser.newPage({viewport:{width:390,height:844}});let errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.goto('http://127.0.0.1:8100/tests/procuidar-evolucao-harness.html');
await page.evaluate(async()=>{const {paginaVisitas,ativarVisitas}=await import('/visitas-ui.js');window.rows=[];window.scores=[];window.sent=[];document.querySelector('#app').innerHTML=paginaVisitas();const p={id:'patient',nome:'Paciente fictício',codigo:'F1',responsavel_id:'nurse',cidade:'Fortaleza'};
const ctx={perfil:{papel:'gestor'},hoje:()=>new Date().toISOString().slice(0,10),pacientes:()=>[p],equipe:async()=>[{id:'nurse',nome:'Enfermeiro fictício',profissao:'enfermeiro'}],listar:async()=>window.rows,pesquisas:async()=>window.scores,notify:()=>{},fechar:()=>document.querySelector('dialog').close(),abrirPaciente:()=>{},historico:async()=>[],prontuario:async()=>[{id:'record',responsavel_id:'nurse',tipo:'evolucao',atendimento_em:new Date().toISOString()}],
dialogo:(t,b)=>{const d=document.querySelector('dialog');d.innerHTML='<button id="close-modal">Fechar</button>'+b;d.querySelector('button').onclick=()=>d.close();d.showModal();},
salvar:async payload=>{window.sent.push(structuredClone(payload));if(window.sent.length===1)throw Error('Falha simulada');const d={...payload.p_dados,versao:payload.p_dados.versao+1};const old=window.rows.findIndex(x=>x.id===d.id);if(old>=0)window.rows[old]=d;else window.rows.push(d);return d;},
registrarNps:async p=>{window.scores.push({visita_id:p.p_visita,nota:p.p_nota,respondente:p.p_respondente});}};await ativarVisitas(ctx);});
await page.locator('#visita-nova').click();await page.locator('[name=objetivo]').fill('Avaliação fictícia');await page.locator('input[type=checkbox]').check();await page.locator('[type=submit]').click();await page.locator('#visita-erro').filter({hasText:'Falha simulada'}).waitFor();assert.equal(await page.locator('[name=objetivo]').isDisabled(),true);await page.locator('[type=submit]').click();await page.locator('[data-v-edit]').waitFor();
assert.deepEqual(await page.evaluate(()=>window.sent[0]),await page.evaluate(()=>window.sent[1]));
await page.locator('[data-v-edit]').click();await page.locator('[name=status]').selectOption('realizada');await page.locator('[name=registro]').selectOption('record');await page.locator('input[type=checkbox]').check();await page.locator('[type=submit]').click();await page.locator('[data-v-nps]').waitFor();await page.locator('[data-v-nps]').click();await page.locator('[name=nota]').selectOption('10');await page.locator('[name=respondente]').selectOption('cuidador');await page.locator('input[type=checkbox]').check();await page.locator('[type=submit]').click();await page.waitForFunction(()=>window.scores.length===1);assert.match(await page.locator('#visita-indicadores').innerText(),/100/);
await page.evaluate(async()=>{const {paginaCofre,ativarCofre}=await import('/cofre-ui.js');document.querySelector('#app').innerHTML=paginaCofre();await ativarCofre({perfil:{papel:'campo'},pacientesCofre:async()=>[{id:'p',nome:'Fictício',codigo:'F1'}],notify:()=>{},enviarDocumento:async(p,f)=>{window.fileBytes=[...new Uint8Array(await f.arrayBuffer())];return {sha256:'teste-ficticio'};}});});
await page.locator('#cofre-paciente').selectOption('p');await page.locator('#cofre-form').waitFor();assert.match(await page.locator('#cofre-conteudo').innerText(),/Consulta restrita/);const bytes=Buffer.from([137,80,78,71,13,10,26,10]);await page.locator('[name=arquivo]').setInputFiles({name:'ficticio.png',mimeType:'image/png',buffer:bytes});await page.locator('input[type=checkbox]').check();await page.locator('[type=submit]').click();await page.waitForFunction(()=>!!window.fileBytes);assert.deepEqual(await page.evaluate(()=>window.fileBytes),[...bytes]);assert.deepEqual(errors,[]);
await page.goto('http://127.0.0.1:8100/campo/');
await page.locator('#demo').click();await page.locator('#visita-nova').waitFor();
assert.equal(await page.locator('.field-bottom-nav').isVisible(),true);
assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth),true);
await page.locator('.field-bottom-nav a').filter({hasText:'Pacientes'}).click();
await page.locator('[data-open="pacientes"]').first().click();await page.locator('#editar-cadastro-paciente').click();
await page.locator('[name=responsavel_tipo]').selectOption('cuidador');await page.locator('[name=responsavel_nome]').fill('Cuidador fictício');
await page.locator('[name=responsavel_telefone]').fill('00000000000');await page.locator('[name=tem_plano]').check();await page.locator('[name=plano_nome]').fill('Plano fictício');
await page.locator('[name=endereco]').fill('Rua fictícia');await page.locator('[name=liminar_situacao]').selectOption('preparacao');
await page.locator('#cadastro-paciente input[type=checkbox][required]').check();await page.locator('#cadastro-paciente [type=submit]').click();
await page.locator('#cadastro-resumo').filter({hasText:'Cuidador fictício'}).waitFor();assert.match(await page.locator('#cadastro-resumo').innerText(),/Plano fictício/);
assert.match(await page.locator('#cadastro-resumo').innerText(),/Rua fictícia/);
await page.locator('#nova-anamnese').click();await page.locator('[name=queixa]').fill('Avaliação inicial fictícia');await page.locator('[name=mobilidade]').fill('Mobilidade informada fictícia');await page.locator('[name=objetivo_cuidado]').fill('Meta fictícia');
await page.locator('#prontuario-form input[type=checkbox]').check();await page.locator('#prontuario-form [type=submit]').click();
await page.locator('#prontuario-historico').filter({hasText:'Meta fictícia'}).waitFor();assert.deepEqual(errors,[]);
console.log('Browser mobile: agenda, retry, conclusão, NPS e envio sem transformação aprovados (APIs simuladas).');
}finally{await browser?.close();server.close();}
