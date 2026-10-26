import {CONFIG} from './config.js';
let token=new URLSearchParams(location.hash.slice(1)).get('token')??'';history.replaceState(null,'',location.pathname);
const form=document.querySelector('#pesquisa-direta'),status=document.querySelector('#pesquisa-status');
if(!/^[a-f0-9]{64}$/.test(token)){form.hidden=true;status.textContent='Abra o link individual recebido para responder. Não é necessário entrar na plataforma.';}
let busy=false,payload;
form.onsubmit=async ev=>{ev.preventDefault();if(busy)return;
 payload??={p_token:token,p_nota:Number(form.elements.nota.value),p_respondente:form.elements.respondente.value,p_comentario:form.elements.comentario.value.trim()};
 busy=true;form.querySelectorAll('input,select,textarea,button').forEach(x=>x.disabled=true);status.textContent='Enviando…';
 try{const r=await fetch(CONFIG.url+'/rest/v1/rpc/campo_responder_pesquisa',{method:'POST',headers:{apikey:CONFIG.key,'Content-Type':'application/json'},body:JSON.stringify(payload),cache:'no-store',credentials:'omit',referrerPolicy:'no-referrer'});if(!r.ok)throw Error(r.status===400?'Link inválido, expirado, revogado ou já respondido.':'Não foi possível enviar. Tente novamente.');if(await r.json()!==true)throw Error('Não foi possível confirmar a resposta.');
 token='';payload=null;form.reset();form.hidden=true;status.textContent='Obrigado! Sua avaliação foi registrada.';
 }catch(err){status.textContent=err.message;form.querySelector('[type=submit]').disabled=false;}finally{busy=false;}};
