import {readFile} from 'node:fs/promises';
const files=['app.js','visitas-ui.js','visitas-utils.js','cofre-ui.js','prontuario-ui.js','paciente-cadastro-ui.js','paciente-utils.js','admin-import-ui.js','style.css','sw.js','config.js','manifest.webmanifest'];
for(let attempt=0;attempt<12;attempt++){let ok=true;
for(const file of files){try{const response=await fetch('https://procirurgica.gritnews.com.br/'+file+'?verify='+Date.now(),{signal:AbortSignal.timeout(15000),cache:'no-store'});if(!response.ok||(await response.text()).trim()!==(await readFile(file,'utf8')).trim()){ok=false;console.log(file+': versão ainda não confirmada');}}catch{ok=false;console.log(file+': acesso indisponível');}}
if(ok){console.log('HOSTINGER_VERIFIED: arquivos da versão publicados correspondem ao commit.');process.exit(0);}await new Promise(r=>setTimeout(r,10000));}
console.error('Não foi possível confirmar a publicação na Hostinger.');process.exit(1);
