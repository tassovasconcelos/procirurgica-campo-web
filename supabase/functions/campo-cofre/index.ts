const origins=new Set(['https://procirurgica.gritnews.com.br']);
Deno.serve(async(req:Request)=>{
 const origin=req.headers.get('origin');const headers:Record<string,string>={'Cache-Control':'no-store','Vary':'Origin','Access-Control-Allow-Headers':'authorization,apikey,content-type','Access-Control-Allow-Methods':'POST,OPTIONS'};
 if(origin&&origins.has(origin))headers['Access-Control-Allow-Origin']=origin;
 if(origin&&!origins.has(origin))return new Response('Origin denied',{status:403,headers});
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 const json=(v:unknown,status=200)=>new Response(JSON.stringify(v),{status,headers:{...headers,'Content-Type':'application/json'}});
 if(req.method!=='POST')return json({error:'Method not allowed'},405);
 try{
 const url=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!,service=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
 const auth=req.headers.get('Authorization')??'';if(!/^Bearer .+/.test(auth))return json({error:'Unauthorized'},401);
 const userResponse=await fetch(url+'/auth/v1/user',{headers:{apikey:anon,Authorization:auth}});if(!userResponse.ok)return json({error:'Unauthorized'},401);const user=await userResponse.json();
 const {id,operacao}=await req.json();if(!/^[a-f0-9-]{36}$/i.test(id??'')||!['confirmar','baixar'].includes(operacao))return json({error:'Invalid request'},400);
 const permission=await fetch(url+'/rest/v1/rpc/campo_documento_autorizar',{method:'POST',headers:{apikey:anon,Authorization:auth,'Content-Type':'application/json'},body:JSON.stringify({p_id:id,p_operacao:operacao})});
 if(!permission.ok)return json({error:'Access denied'},403);const doc=await permission.json();
 const objectResponse=await fetch(url+'/storage/v1/object/authenticated/campo-documentos-pessoais/'+doc.caminho.split('/').map(encodeURIComponent).join('/'),{headers:{apikey:service,Authorization:'Bearer '+service}});
 if(!objectResponse.ok)return json({error:'Object unavailable'},409);
 const bytes=new Uint8Array(await objectResponse.arrayBuffer());if(bytes.length!==doc.tamanho||bytes.length>20971520)return json({error:'Size mismatch'},409);
 const valid=doc.mime==='application/pdf'?new TextDecoder().decode(bytes.slice(0,5))==='%PDF-':doc.mime==='image/jpeg'?bytes[0]===255&&bytes[1]===216&&bytes[2]===255:doc.mime==='image/png'?[137,80,78,71,13,10,26,10].every((v,i)=>bytes[i]===v):false;
 if(!valid)return json({error:'Content type mismatch'},415);
 const hash=[...new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))].map(b=>b.toString(16).padStart(2,'0')).join('');
 if(operacao==='confirmar'){
 const result=await fetch(url+'/rest/v1/rpc/campo_documento_confirmar_servico',{method:'POST',headers:{apikey:service,Authorization:'Bearer '+service,'Content-Type':'application/json'},body:JSON.stringify({p_id:id,p_autor:user.id,p_sha:hash})});
 if(!result.ok)return json({error:'Confirmation denied'},409);return json({id,status:'confirmado',sha256:hash});
 }
 if(!doc.sha256||hash!==doc.sha256)return json({error:'Integrity mismatch'},409);
 return new Response(bytes,{headers:{...headers,'Content-Type':'application/octet-stream','Content-Disposition':'attachment; filename="'+String(doc.nome).replace(/[^a-zA-Z0-9._-]/g,'_')+'"','X-Content-Type-Options':'nosniff'}});
 }catch{return json({error:'Request could not be completed'},400);}
});
