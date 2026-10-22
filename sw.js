// Somente arquivos públicos. Nunca intercepta autenticação ou dados de pacientes.
const CACHE='campo-shell-v3';
const FILES=['/','/index.html','/style.css','/app.js','/auth-utils.js','/import-utils.js','/admin-import-ui.js','/engine.js','/forms.json','/config.js','/icon.svg'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES))));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(e.request.method!=='GET'||u.origin!==self.location.origin||!FILES.includes(u.pathname))return;e.respondWith(fetch(e.request).catch(()=>caches.match(u.pathname)));});
