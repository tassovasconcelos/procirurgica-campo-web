import schema from './procuidar-formularios-schema.js';
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function conteudoFicha(form,values){
 if(!values.produto_referencia?.trim())throw Error('Informe o produto / referência.');
 for(const f of form.fields){const v=values[f.id]??'';if(typeof v!=='string'||v.length>4000)throw Error('Conteúdo inválido.');
 if(f.type==='select'&&v&&!f.options.includes(v))throw Error('Alternativa inválida.');
 if(f.type==='number'&&v&&(!Number.isInteger(Number(v))||Number(v)<0||Number(v)>100000))throw Error('Quantidade inválida.');}
 if(values.data_inicio&&values.data_retorno&&values.data_retorno<values.data_inicio)throw Error('Retorno anterior ao início.');
 if(form.id==='conclusao_teste'&&(!values.resultado||!values.evidencias?.trim()))throw Error('Informe resultado e justificativa.');
 const conduta=form.fields.filter(f=>values[f.id]?.trim()).map(f=>f.label+': '+values[f.id].trim()).join('\n\n');
 if(conduta.length>8000)throw Error('Ficha muito extensa. Limite total de 8.000 caracteres.');
 return {avaliacao:'ProCuidar · '+form.title+' · versão '+schema.schemaVersion,conduta,plano:'Teste individual. Ficha provisória com alternativas pendentes de validação. Não constitui homologação institucional.'};
}
export function abrirFormularioProCuidar(p,ctx,voltar){
 if(!['enfermeiro','fisioterapeuta','nutricionista'].includes(ctx.perfil.profissao)){ctx.notify('Registro exige perfil assistencial habilitado.');return;}
 let selected=schema.forms.find(f=>f.id===(p.linha==='confortcath'?'confortcath':'atendimento_ostomia')),busy=false,payload=null,id=crypto.randomUUID();
 function draw(){
 const n=new Date(),local=new Date(n.getTime()-n.getTimezoneOffset()*60000).toISOString().slice(0,16);
 ctx.dialogo('ProCuidar · ficha do paciente','<form id="procuidar-ficha"><div class="notice"><b>Somente dados fictícios.</b> Fichas provisórias baseadas em leitura parcial das imagens. Revise antes de salvar.</div><p><b>Paciente:</b> '+esc(p.nome)+' · '+esc(p.codigo)+'<br><b>Autor:</b> '+esc(ctx.perfil.nome)+'</p><label class="field">Ficha<select id="procuidar-tipo">'+schema.forms.map(f=>'<option value="'+f.id+'" '+(f.id===selected.id?'selected':'')+'>'+esc(f.title)+'</option>').join('')+'</select></label><label class="field">Data e hora do atendimento (horário deste aparelho)<input name="atendimento" type="datetime-local" value="'+local+'" required></label><div class="form-grid">'+selected.fields.map(f=>'<label class="field">'+esc(f.label)+(f.id==='produto_referencia'?' *':'')+(f.type==='select'?'<select name="'+f.id+'"><option value="">Não informado</option>'+f.options.map(o=>'<option>'+esc(o)+'</option>').join('')+'</select>':f.type==='textarea'?'<textarea name="'+f.id+'" maxlength="4000" rows="3"></textarea>':'<input name="'+f.id+'" type="'+f.type+'" '+(f.type==='number'?'min="0" max="100000" step="1"':'maxlength="4000"')+' '+(f.id==='produto_referencia'?'required':'')+'>')+'</label>').join('')+'</div><details><summary>Revisões pendentes</summary><ul>'+selected.pending.map(x=>'<li>'+esc(x)+'</li>').join('')+'</ul></details><p class="small">A conclusão refere-se ao paciente. Homologação institucional: módulo Padronização. Após salvar, anexe fotos e vídeos clínicos no registro. Documentos pessoais: cofre.</p><label class="check"><input type="checkbox" required>Revisei o conteúdo e confirmo que os dados são fictícios.</label><p id="procuidar-erro" role="alert"></p><div class="modal-actions"><button class="btn" id="procuidar-voltar" type="button">Voltar</button><button class="btn primary" type="submit">Salvar ficha no prontuário</button></div></form>');
 const f=document.querySelector('#procuidar-ficha'),dlg=f.closest('dialog'),close=dlg?.querySelector('#close-modal');
 const guard=e=>{if(busy)e.preventDefault();};dlg?.addEventListener('cancel',guard);dlg?.addEventListener('close',()=>dlg.removeEventListener('cancel',guard),{once:true});
 f.querySelector('#procuidar-voltar').onclick=()=>{if(!busy){dlg?.removeEventListener('cancel',guard);voltar();}};
 f.querySelector('#procuidar-tipo').onchange=ev=>{if(busy)return;if([...f.querySelectorAll('[name]')].some(i=>i.name!=='atendimento'&&i.value)&&!confirm('Trocar de ficha descarta o preenchimento. Continuar?')){ev.target.value=selected.id;return;}selected=schema.forms.find(x=>x.id===ev.target.value);payload=null;id=crypto.randomUUID();dlg?.removeEventListener('cancel',guard);draw();};
 f.onsubmit=async ev=>{ev.preventDefault();if(busy)return;
 try{if(!payload){const values=Object.fromEntries(selected.fields.map(x=>[x.id,f.elements[x.id].value.trim()])),date=new Date(f.elements.atendimento.value);if(!Number.isFinite(date.getTime())||date.getTime()>Date.now()+300000)throw Error('Data inválida ou futura.');
 payload={p_id:id,p_paciente:p.id,p_tipo:'evolucao',p_atendimento:date.toISOString(),p_conteudo:conteudoFicha(selected,values),p_referencia:null,p_homologacao:true};}
 busy=true;f.querySelectorAll('button,input,select,textarea').forEach(x=>x.disabled=true);if(close)close.disabled=true;
 await ctx.salvar(payload);busy=false;dlg?.removeEventListener('cancel',guard);if(close)close.disabled=false;ctx.notify('Ficha salva com autoria e data no prontuário.');await voltar();
 }catch(error){if(f.isConnected){f.querySelector('#procuidar-erro').textContent=error.message+(payload?' Nova tentativa reenviará exatamente o registro anterior.':'');if(payload)f.querySelector('[type=submit]').textContent='Reenviar o mesmo registro';}}
 finally{busy=false;if(close)close.disabled=false;if(f.isConnected){f.querySelectorAll('button').forEach(x=>x.disabled=false);if(!payload)f.querySelectorAll('input,select,textarea').forEach(x=>x.disabled=false);}}
 };
 }
 draw();
}
