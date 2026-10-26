import schema from './formularios-schema.js';
const root=document.querySelector('#formulario'),tabs=document.querySelector('#tabs');
function el(tag,text){const e=document.createElement(tag);if(text)e.textContent=text;return e;}
function render(form){root.replaceChildren();root.append(el('h2',form.title));
 const info=el('p','Rascunho de revisão. Campos sem alternativa legível usam texto livre; não substituem a ficha validada.');root.append(info);
 const grid=el('div');grid.className='grid';
 for(const f of form.fields){const wrap=el('div');if(f.type==='textarea')wrap.className='wide';const label=el('label',f.label);label.htmlFor=f.id;
 let input;if(f.type==='select'){input=el('select');input.append(new Option('Não informado',''));for(const option of f.options)input.append(new Option(option,option));}else{input=el(f.type==='textarea'?'textarea':'input');if(f.type!=='textarea')input.type=f.type;}
 input.id=f.id;input.name=f.id;input.autocomplete='off';if(f.type==='number'){input.min='0';input.step='1';}input.maxLength=4000;
 wrap.append(label,input,el('small',f.origin==='imagem_leitura_parcial'?'Fonte: '+f.source+' — leitura parcial':'Campo complementar proposto'));grid.append(wrap);}
 root.append(grid,el('h3','Pendências para validar esta ficha'));const ul=el('ul');for(const p of form.pending)ul.append(el('li',p));root.append(ul);
 for(const b of tabs.children)b.setAttribute('aria-pressed',String(b.dataset.id===form.id));
}
for(const form of schema.forms){const b=el('button',form.title);b.type='button';b.dataset.id=form.id;b.setAttribute('aria-pressed','false');b.addEventListener('click',()=>{if([...root.querySelectorAll('input,select,textarea')].some(i=>i.value)&&!confirm('Trocar de ficha descarta o preenchimento temporário. Continuar?'))return;render(form);});tabs.append(b);}
document.querySelector('#imprimir').addEventListener('click',()=>window.print());render(schema.forms[0]);
