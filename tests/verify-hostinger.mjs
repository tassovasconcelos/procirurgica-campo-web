import {readFile} from 'node:fs/promises';
const files=['procuidar-formularios-ui.js','procuidar-formularios-schema.js','prontuario-ui.js','sw.js'];
for(let attempt=0;attempt<12;attempt++){let ok=true;
for(const file of files){try{const response=await fetch('https://procirurgica.gritnews.com.br/'+file+'?verify='+Date.now(),{signal:AbortSignal.timeout(15000),cache:'no-store'});if(!response.ok||(await response.text()).trim()!==(await readFile(file,'utf8')).trim()){ok=false;console.log(file+': versão ainda não confirmada');}}catch{ok=false;console.log(file+': acesso indisponível');}}
if(ok){console.log('HOSTINGER_VERIFIED: quatro módulos publicados correspondem ao commit.');process.exit(0);}await new Promise(r=>setTimeout(r,10000));}
console.error('Não foi possível confirmar a publicação na Hostinger.');process.exit(1);
