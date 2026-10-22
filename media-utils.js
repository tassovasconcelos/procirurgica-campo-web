export const TIPOS_MIDIA={'image/jpeg':{ext:'jpg',max:10*1024*1024},'image/png':{ext:'png',max:10*1024*1024},'image/webp':{ext:'webp',max:10*1024*1024},'video/mp4':{ext:'mp4',max:50*1024*1024},'video/webm':{ext:'webm',max:50*1024*1024}};
export async function validarMidia(arquivo){
 const tipo=TIPOS_MIDIA[arquivo.type];if(!tipo)throw Error('Use JPG, PNG, WebP, MP4 ou WebM. Converta HEIC/MOV antes de enviar.');
 if(!arquivo.size||arquivo.size>tipo.max)throw Error('Limite: fotos até 10 MB e vídeos até 50 MB.');
 if(!arquivo.name?.trim()||arquivo.name.length>150||/[\\/]/.test(arquivo.name))throw Error('Use um nome de arquivo de até 150 caracteres, sem barras.');
 const b=new Uint8Array(await arquivo.slice(0,32).arrayBuffer()),s=(a,z)=>String.fromCharCode(...b.slice(a,z));
 const valido=arquivo.type==='image/jpeg'?b[0]===255&&b[1]===216&&b[2]===255:arquivo.type==='image/png'?[137,80,78,71,13,10,26,10].every((v,i)=>b[i]===v):arquivo.type==='image/webp'?s(0,4)==='RIFF'&&s(8,12)==='WEBP':arquivo.type==='video/mp4'?s(4,8)==='ftyp':b[0]===26&&b[1]===69&&b[2]===223&&b[3]===163;
 if(!valido)throw Error('O conteúdo do arquivo não corresponde ao formato informado.');
 return tipo;
}

