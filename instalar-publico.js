import {paginaInstalar,ativarInstalacao} from './instalar-ui.js';
document.querySelector('#instalar-publico').innerHTML=paginaInstalar();ativarInstalacao();if('serviceWorker' in navigator)navigator.serviceWorker.register('/sw.js').catch(()=>{});
