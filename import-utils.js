export const CAMPOS_IMPORTACAO=['codigo','nome','linha','cidade','uf','telefone'];
export const UF_VALIDAS=new Set('AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO'.split(' '));
const texto=v=>String(v??'').trim();
const chave=v=>texto(v).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]/g,'');
export function lerCSV(input){
 const s=String(input).replace(/^\uFEFF/,'');let aspas=false;const cont={';':0,',':0,'\t':0};
 for(const c of s){if(c==='"')aspas=!aspas;if(!aspas&&c==='\n')break;if(!aspas&&c in cont)cont[c]++;}
 const sep=Object.keys(cont).sort((a,b)=>cont[b]-cont[a])[0];let cell='',row=[],rows=[],quoted=false;
 for(let i=0;i<s.length;i++){const c=s[i];if(c==='"'){if(quoted&&s[i+1]==='"'){cell+='"';i++;}else if(quoted||cell==='')quoted=!quoted;else throw Error('Aspas inválidas no CSV. Salve novamente pelo Excel.');}else if(!quoted&&c===sep){row.push(cell);cell='';}else if(!quoted&&(c==='\n'||c==='\r')){if(c==='\r'&&s[i+1]==='\n')i++;row.push(cell);if(row.some(x=>x.trim()))rows.push(row);row=[];cell='';}else cell+=c;}
 if(quoted)throw Error('O CSV contém uma célula com aspas não fechadas.');row.push(cell);if(row.some(x=>x.trim()))rows.push(row);
 return prepararTabela(rows);
}
export function prepararTabela(rows){if(rows.length<2)throw Error('A planilha precisa de cabeçalho e pelo menos uma linha.');if(rows.length>2001)throw Error('Importe no máximo 2.000 pacientes por lote.');if(rows[0].length>100)throw Error('A planilha tem colunas demais (máximo 100).');return {headers:rows[0].map((h,i)=>texto(h)||'Coluna '+(i+1)),rows:rows.slice(1)};}
export function mapearCabecalhos(headers){const aliases={codigo:['codigo','codigopaciente','codigodopaciente','idpaciente','prontuario'],nome:['nome','nomecompleto','paciente','nomedopaciente','nomeficticio'],linha:['linha','linhadecuidado','linhaproduto','produto'],cidade:['cidade','municipio'],uf:['uf','estado'],telefone:['telefone','celular','telefone1','whatsapp']};const mapa={};for(const f of CAMPOS_IMPORTACAO){const i=headers.findIndex(h=>aliases[f].includes(chave(h)));mapa[f]=i;}return mapa;}
export function validarImportacao(tabela,mapa,existentes=[]){
 for(const f of ['codigo','nome','linha'])if(mapa[f]===undefined||mapa[f]<0)throw Error('Mapeie as colunas código, nome e linha de cuidado.');
 const usados=Object.values(mapa).filter(v=>v>=0);if(new Set(usados).size!==usados.length)throw Error('Uma coluna não pode alimentar dois campos.');
 const vistos=new Set(),base=new Set(existentes.map(p=>texto(p.codigo).toLowerCase()));
 return tabela.rows.map((row,i)=>{const p=Object.fromEntries(CAMPOS_IMPORTACAO.map(f=>[f,mapa[f]>=0?texto(row[mapa[f]]):'']));const erros=[];
  if(Object.values(p).some(v=>v==='__FORMULA__'))erros.push('Célula com fórmula: converta para valor.');
  if(!p.codigo||p.codigo.length>80)erros.push('Código obrigatório, até 80 caracteres.');
  if(p.nome.length<2||p.nome.length>150)erros.push('Nome obrigatório, de 2 a 150 caracteres.');
  const linha=chave(p.linha);p.linha=linha==='stomapro'?'stomapro':linha==='confortcath'?'confortcath':p.linha.toLowerCase();if(!['stomapro','confortcath'].includes(p.linha))erros.push('Linha deve ser StomaPro ou ConfortCath.');
  p.uf=p.uf.toUpperCase();if(p.uf&&!UF_VALIDAS.has(p.uf))erros.push('UF inválida.');
  if(p.cidade.length>150)erros.push('Cidade excede 150 caracteres.');
  p.telefone=p.telefone.replace(/\D/g,'');if(p.telefone&&![10,11].includes(p.telefone.length))erros.push('Telefone precisa de 10 ou 11 dígitos, com DDD.');
  const cod=p.codigo.toLowerCase();let status=erros.length?'invalida':'valida';if(!erros.length&&(vistos.has(cod)||base.has(cod)))status='duplicada';if(!erros.length)vistos.add(cod);
  return {numero:tabela.lineNumbers?.[i]??i+2,paciente:p,erros,status};
 });
}
export const MODELO_CSV='\uFEFFcodigo;nome;linha;cidade;uf;telefone\r\nHOMO-001;Paciente Fictício 01;StomaPro;Fortaleza;CE;\r\nHOMO-002;Paciente Fictício 02;ConfortCath;São Paulo;SP;\r\n';
export function csvSeguro(v){const s=String(v??'');return '"'+(/^[=+@-]/.test(s)?"'"+s:s).replaceAll('"','""')+'"';}

function xmlTexto(s){return s.replace(/&(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);/g,e=>{const fix={'&amp;':'&','&lt;':'<','&gt;':'>','&quot;':'"','&apos;':"'"};if(fix[e])return fix[e];const h=e.startsWith('&#x');const n=parseInt(e.slice(h?3:2,-1),h?16:10);return n<=0x10ffff?String.fromCodePoint(n):'';});}
function attr(tag,key){return xmlTexto((tag.match(new RegExp('(?:^|\\s)'+key+'=["\\\']([^"\\\']*)["\\\']'))??[])[1]??'');}
function xmlTextos(s){return Array.from(s.matchAll(/<t(?:\s[^>]*)?>([\s\S]*?)<\/t>/g),m=>xmlTexto(m[1])).join('');}
/** Leitor restrito de XLSX: primeira aba, valores, sem execução de fórmulas/macros. */
export async function lerXLSX(buffer){
 if(buffer.byteLength>5*1024*1024)throw Error('Arquivo maior que 5 MB.');const bytes=new Uint8Array(buffer),v=new DataView(buffer);let end=-1;
 for(let i=bytes.length-22;i>=Math.max(0,bytes.length-65557);i--)if(v.getUint32(i,true)===0x06054b50){end=i;break;}
 if(end<0)throw Error('XLSX inválido. Salve como Pasta de Trabalho do Excel (.xlsx).');const n=v.getUint16(end+10,true);if(n>256)throw Error('Arquivo XLSX complexo demais. Copie os pacientes para uma planilha simples.');let pos=v.getUint32(end+16,true),total=0;const files=new Map(),decoder=new TextDecoder();
 for(let i=0;i<n;i++){if(pos+46>bytes.length||v.getUint32(pos,true)!==0x02014b50)throw Error('Estrutura XLSX inválida.');const flags=v.getUint16(pos+8,true),method=v.getUint16(pos+10,true),size=v.getUint32(pos+20,true),uncompressed=v.getUint32(pos+24,true),len=v.getUint16(pos+28,true),extra=v.getUint16(pos+30,true),comment=v.getUint16(pos+32,true),offset=v.getUint32(pos+42,true);const name=decoder.decode(bytes.slice(pos+46,pos+46+len));total+=uncompressed;if(total>10*1024*1024||flags&1||name.includes('..')||name.startsWith('/'))throw Error('Arquivo protegido, excessivo ou com estrutura não permitida.');files.set(name,{method,size,uncompressed,offset});pos+=46+len+extra+comment;}
 async function read(name){const f=files.get(name);if(!f)return '';if(f.offset+30>bytes.length||v.getUint32(f.offset,true)!==0x04034b50)throw Error('Entrada XLSX inválida.');const start=f.offset+30+v.getUint16(f.offset+26,true)+v.getUint16(f.offset+28,true);if(start+f.size>bytes.length)throw Error('XLSX truncado.');let out=bytes.slice(start,start+f.size);if(f.method===8){const reader=new Blob([out]).stream().pipeThrough(new DecompressionStream('deflate-raw')).getReader();let length=0;const parts=[];while(true){const r=await reader.read();if(r.done)break;length+=r.value.length;if(length>f.uncompressed||length>10*1024*1024){await reader.cancel();throw Error('XLSX descompactado excede o limite.');}parts.push(r.value);}out=new Uint8Array(length);let p=0;for(const part of parts){out.set(part,p);p+=part.length;}}else if(f.method!==0)throw Error('Compressão XLSX não suportada.');if(out.length!==f.uncompressed)throw Error('XLSX inconsistente.');return decoder.decode(out);}
 const workbook=await read('xl/workbook.xml'),rels=await read('xl/_rels/workbook.xml.rels');const first=workbook.match(/<sheet\s[^>]*>/)?.[0];if(!first)throw Error('Nenhuma aba encontrada.');const id=attr(first,'r:id');const relation=Array.from(rels.matchAll(/<Relationship\s[^>]*>/g),m=>m[0]).find(t=>attr(t,'Id')===id);const target=relation?attr(relation,'Target'):'';if(!target||target.includes('..')||/https?:/i.test(target))throw Error('Referência de aba não permitida.');const path=target.startsWith('/')?target.slice(1):'xl/'+target;const shared=await read('xl/sharedStrings.xml');const strings=Array.from(shared.matchAll(/<si(?:\s[^>]*)?>([\s\S]*?)<\/si>/g),m=>xmlTextos(m[1]));const sheet=await read(path);if(!sheet)throw Error('Aba sem dados.');const rows=[],lineNumbers=[];
 for(const match of sheet.matchAll(/<row\b([^>]*)>([\s\S]*?)<\/row>/g)){const row=[];for(const cell of match[2].matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)){const tag=cell[1],body=cell[2]??'',ref=attr(tag,'r');const letters=ref.match(/^[A-Z]+/)?.[0];if(!letters)continue;let col=0;for(const l of letters)col=col*26+l.charCodeAt(0)-64;col--;if(col>99)throw Error('A planilha excede 100 colunas.');const raw=xmlTexto(body.match(/<v(?:\s[^>]*)?>([\s\S]*?)<\/v>/)?.[1]??'');const t=attr(tag,'t');row[col]=/<f(?:\s|>)/.test(body)?'__FORMULA__':t==='s'?strings[Number(raw)]??'':t==='inlineStr'?xmlTextos(body):raw;}if(row.some(v=>texto(v))){rows.push(Array.from({length:row.length},(_,i)=>row[i]??''));lineNumbers.push(Number(attr(match[1],'r'))||rows.length);}if(rows.length>2001)throw Error('Importe no máximo 2.000 pacientes por lote.');}
 return {...prepararTabela(rows),lineNumbers:lineNumbers.slice(1),aba:attr(first,'name')};
}
