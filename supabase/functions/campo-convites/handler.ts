export function criarHandler(env:Record<string,string>,fetcher:typeof fetch=fetch){
 return async(req:Request)=>{
 const origin=req.headers.get('origin'),headers:Record<string,string>={'Cache-Control':'no-store','Vary':'Origin','Access-Control-Allow-Methods':'POST,OPTIONS','Access-Control-Allow-Headers':'authorization,apikey,content-type'};
 if(origin==='https://procirurgica.gritnews.com.br')headers['Access-Control-Allow-Origin']=origin;
 const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...headers,'Content-Type':'application/json'}});
 if(origin&&origin!=='https://procirurgica.gritnews.com.br')return json({error:'Origem não permitida.'},403);
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return json({error:'Método inválido.'},405);
 try{
 const url=env.SUPABASE_URL,key=env.SUPABASE_ANON_KEY,service=env.SUPABASE_SERVICE_ROLE_KEY,auth=req.headers.get('Authorization')??'';
 if(!auth.startsWith('Bearer '))return json({error:'Autenticação necessária.'},401);
 const me=await fetcher(url+'/auth/v1/user',{headers:{apikey:key,Authorization:auth}});
 if(!me.ok)return json({error:'Autenticação necessária.'},401);
 const user=await me.json(),body=await req.json();
 if(body.confirmar_envio!==true||!/^[-a-f0-9]{36}$/i.test(body.id??''))return json({error:'Confirme o envio do convite.'},400);
 const dados={email:String(body.email??'').trim().toLowerCase(),nome:String(body.nome??'').trim(),papel:body.papel,profissao:body.profissao??'',gestor:body.gestor??''};
 const prepare=await fetcher(url+'/rest/v1/rpc/campo_preparar_convite',{method:'POST',headers:{apikey:key,Authorization:auth,'Content-Type':'application/json'},body:JSON.stringify({p_id:body.id,p_dados:dados})});
 if(!prepare.ok){const error=await prepare.json().catch(()=>({}));return json({error:error.message??'Convite não autorizado.'},prepare.status===403?403:400);}
 const p=await prepare.json();if(!p.novo)return json({id:p.id,status:p.status,repeticao:true});
 const finish=async(state:string,authid:string|null)=>fetcher(url+'/rest/v1/rpc/campo_concluir_convite_servico',{method:'POST',headers:{apikey:service,Authorization:'Bearer '+service,'Content-Type':'application/json'},body:JSON.stringify({p_id:body.id,p_autor:user.id,p_auth:authid,p_estado:state})});
 let invited:Response;
 try{invited=await fetcher(url+'/auth/v1/invite?redirect_to='+encodeURIComponent('https://procirurgica.gritnews.com.br/ativar.html'),{method:'POST',headers:{apikey:service,Authorization:'Bearer '+service,'Content-Type':'application/json'},body:JSON.stringify({email:dados.email})});}
 catch{return json({id:body.id,status:'preparado',error:'Envio sem confirmação. Consulte o protocolo antes de qualquer nova tentativa.'},409);}
 if(!invited.ok){await finish('erro',null);return json({id:body.id,status:'erro',error:'O serviço de autenticação não aceitou o convite. Verifique conta existente, SMTP, limites e configuração de redirecionamento.'},409);}
 const response=await invited.json(),created=response.user??response;
 if(!created.id){await finish('vinculo_pendente',null);return json({id:body.id,status:'vinculo_pendente'});}
 const linked=await finish('enviado',created.id);
 if(!linked.ok){await finish('vinculo_pendente',created.id);return json({id:body.id,status:'vinculo_pendente'});}
 return json({id:body.id,status:'enviado',observacao:'Convite aceito pelo provedor; entrega e ativação precisam ser confirmadas pelo destinatário.'});
 }catch{return json({error:'Não foi possível concluir. Consulte o protocolo; não repita envios sem verificar o estado.'},400);}
 };
}
