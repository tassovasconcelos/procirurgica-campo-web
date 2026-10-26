import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,extname} from 'node:path';
import assert from 'node:assert/strict';
import {chromium} from 'playwright';
const base=process.cwd();
const server=http.createServer(async(req,res)=>{try{const name=resolve(base,'.'+new URL(req.url,'http://localhost').pathname);if(!name.startsWith(base+'/'))throw Error();const data=await readFile(name);res.setHeader('Content-Type',extname(name)==='.js'?'text/javascript':'text/html');res.end(data);}catch{res.statusCode=404;res.end();}});
await new Promise(r=>server.listen(8099,'127.0.0.1',r));
let browser;
try{browser=await chromium.launch();const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('http://127.0.0.1:8099/tests/procuidar-harness.html');
await page.evaluate(async()=>{const {abrirFormularioProCuidar}=await import('/procuidar-formularios-ui.js');window.sent=[];window.returned=0;
const ctx={perfil:{id:'synthetic',nome:'Profissional fictício',profissao:'enfermeiro'},notify:()=>{},dialogo:(t,b)=>{const d=document.querySelector('dialog');d.innerHTML='<button id="close-modal" type="button">Fechar</button>'+b;d.querySelector('#close-modal').onclick=()=>d.close();if(!d.open)d.showModal();},salvar:async p=>{window.sent.push(structuredClone(p));if(window.sent.length===1)throw Error('Falha de rede simulada');}};
abrirFormularioProCuidar({id:'ficticio',nome:'Paciente fictício',codigo:'T-001',linha:'confortcath'},ctx,()=>{window.returned++;document.querySelector('dialog').close();});});
await page.locator('[name=produto_referencia]').fill('Cateter fictício');await page.locator('input[type=checkbox]').check();await page.locator('[type=submit]').click();await page.locator('#procuidar-erro').filter({hasText:'Falha de rede'}).waitFor();
assert.equal(await page.locator('[name=produto_referencia]').isDisabled(),true);
await page.locator('[type=submit]').click();assert.equal(await page.evaluate(()=>window.returned),1);
const sent=await page.evaluate(()=>window.sent);assert.equal(sent.length,2);assert.deepEqual(sent[0],sent[1]);assert.equal(sent[0].p_tipo,'evolucao');assert.match(sent[0].p_conteudo.conduta,/Cateter fictício/);assert.deepEqual(errors,[]);
console.log('Navegador: formulário, gravação, autoria contextual e reenvio idempotente aprovados');
}finally{await browser?.close();server.close();}
