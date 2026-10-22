import {validarMidia} from './media-utils.js';
export function dimensoesOtimizadas(w,h,max=2048){if(!Number.isFinite(w)||!Number.isFinite(h)||w<=0||h<=0)throw Error('Dimensões inválidas.');const escala=Math.min(1,max/Math.max(w,h));return{largura:Math.max(1,Math.round(w*escala)),altura:Math.max(1,Math.round(h*escala))};}
function menor(original,blob,ext,msg){return blob?.size>0&&blob.size<original.size?{arquivo:new File([blob],original.name.replace(/\.[^.]+$/,'').slice(0,110)+'-otimizado.'+ext,{type:blob.type}),original:original.size,otimizado:true,mensagem:msg}:{arquivo:original,original:original.size,otimizado:false,mensagem:'O original já é menor; mantido sem recompressão.'};}
export async function otimizarMidia(original,{progresso=()=>{}}={}){
 await validarMidia(original);progresso('Otimizando no aparelho…');
 if(original.type.startsWith('image/')){
  let bitmap;try{
   const cab=new TextDecoder('latin1').decode(await original.slice(0,1024).arrayBuffer());if(cab.includes('ANIM')||cab.includes('acTL'))return{arquivo:original,original:original.size,otimizado:false,mensagem:'Imagem animada preservada no original.'};
   bitmap=await createImageBitmap(original);const tam=dimensoesOtimizadas(bitmap.width,bitmap.height),canvas=document.createElement('canvas');canvas.width=tam.largura;canvas.height=tam.altura;canvas.getContext('2d').drawImage(bitmap,0,0,canvas.width,canvas.height);const blob=await new Promise(resolve=>canvas.toBlob(resolve,'image/webp',0.86));return menor(original,blob,blob?.type==='image/png'?'png':'webp','Foto otimizada para até 2.048 px; metadados da imagem removidos na conversão.');
  }catch{return{arquivo:original,original:original.size,otimizado:false,mensagem:'O aparelho não conseguiu otimizar a foto; original preservado.'};}finally{bitmap?.close();}
 }
 const video=document.createElement('video'),canvas=document.createElement('canvas'),url=URL.createObjectURL(original);let capturado,stream,rec,timer,raf,onhide;
 try{
  const mime=['video/webm;codecs=vp8,opus','video/webm'].find(t=>globalThis.MediaRecorder?.isTypeSupported(t));
  if(!mime||!video.captureStream||!canvas.captureStream)throw Error('Sem suporte');
  video.muted=true;video.playsInline=true;video.preload='auto';video.src=url;
  await new Promise((resolve,reject)=>{const t=setTimeout(()=>reject(Error('Tempo excedido')),10000);video.onloadeddata=()=>{clearTimeout(t);resolve();};video.onerror=()=>{clearTimeout(t);reject(Error('Vídeo inválido'));};});
  if(!Number.isFinite(video.duration)||video.duration>120||video.duration<=0)return{arquivo:original,original:original.size,otimizado:false,mensagem:'Vídeos acima de 2 minutos são mantidos no original. Use trechos curtos para maior economia.'};
  const tam=dimensoesOtimizadas(video.videoWidth,video.videoHeight,1280);canvas.width=tam.largura;canvas.height=tam.altura;const desenho=canvas.getContext('2d');
  await video.play();video.pause();video.currentTime=0;capturado=video.captureStream();stream=canvas.captureStream(24);capturado.getAudioTracks().forEach(t=>stream.addTrack(t));
  const chunks=[];rec=new MediaRecorder(stream,{mimeType:mime,videoBitsPerSecond:1200000,audioBitsPerSecond:64000});
  const blob=await new Promise((resolve,reject)=>{
   rec.ondataavailable=ev=>{if(ev.data.size)chunks.push(ev.data);};rec.onerror=()=>reject(Error('Falha na compressão'));rec.onstop=()=>resolve(new Blob(chunks,{type:'video/webm'}));
   const stop=()=>{if(rec.state!=='inactive')rec.stop();};video.onended=stop;video.onerror=()=>reject(Error('Falha de reprodução'));onhide=()=>{if(document.hidden)reject(Error('Tela em segundo plano'));};document.addEventListener('visibilitychange',onhide);
   timer=setTimeout(()=>reject(Error('Tempo excedido')),(video.duration+20)*1000);
   function draw(){desenho.drawImage(video,0,0,canvas.width,canvas.height);progresso('Comprimindo vídeo: '+Math.min(99,Math.round(video.currentTime/video.duration*100))+'%. Mantenha a tela aberta.');if(!video.ended)raf=requestAnimationFrame(draw);}
   rec.start(1000);draw();video.play().catch(reject);
  });
  if(blob.size<original.size){const teste=document.createElement('video'),u=URL.createObjectURL(blob);try{teste.src=u;await new Promise((resolve,reject)=>{const t=setTimeout(()=>reject(Error('Vídeo final inválido')),5000);teste.onloadedmetadata=()=>{clearTimeout(t);resolve();};teste.onerror=()=>{clearTimeout(t);reject(Error('Vídeo final inválido'));};});}finally{teste.removeAttribute('src');teste.load();URL.revokeObjectURL(u);}}
  return menor(original,blob,'webm','Vídeo convertido para WebM, até 1.280 px e 24 quadros/s. Confira a reprodução após anexar.');
 }catch{return{arquivo:original,original:original.size,otimizado:false,mensagem:'Compressão de vídeo indisponível ou interrompida neste aparelho; original preservado.'};}
 finally{clearTimeout(timer);cancelAnimationFrame(raf);if(onhide)document.removeEventListener('visibilitychange',onhide);video.pause();video.onended=null;video.onerror=null;if(rec&&rec.state!=='inactive')rec.stop();stream?.getTracks().forEach(t=>t.stop());capturado?.getTracks().forEach(t=>t.stop());video.removeAttribute('src');video.load();URL.revokeObjectURL(url);}
}

