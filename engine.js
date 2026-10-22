/** Motor declarativo: não executa código dos JSON e não inventa regras clínicas. */
                                                
                        
                                                                    
                                                                            
                  
  
                     
                                                                  
                                                                    
                                                                       
                                               
  
                     
                                                                               
                                                     
                                                                          
  
                          
                                             
                                                            
                   
  
                        
                                                             
                                    
  
export function idadeEm(nascimento         , hoje        )                     {
  if (typeof nascimento !== 'string' || !dataValida(nascimento) || !dataValida(hoje)) return;
  const [ano, mes, dia] = nascimento.split('-').map(Number)                            ;
  const [a, m, d] = hoje.split('-').map(Number)                            ;
  const idade = a - ano - (m < mes || (m === mes && d < dia) ? 1 : 0);
  return idade >= 0 ? idade : undefined;
}
export function dataValida(valor        )          {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(valor)) return false;
  const data = new Date(`${valor}T12:00:00Z`);
  return !Number.isNaN(data.getTime()) && data.toISOString().slice(0, 10) === valor;
}
export function condicaoAtendida(c                      , r           , ctx          )          {
  if (!c) return true;
  if (c.ou) return c.ou.some(x => condicaoAtendida(x, r, ctx));
  if (c.idadeMenorQue !== undefined) {
    const idade = idadeEm(r.data_nascimento, ctx.hoje);
    return idade !== undefined && idade < c.idadeMenorQue;
  }
  if (c.sugestaoAlterada !== undefined) return Boolean(ctx.sugestaoAlterada) === c.sugestaoAlterada;
  if (!c.campo) return false;
  const valor = r[c.campo];
  if ('igual' in c) return valor === c.igual;
  if ('contem' in c) return Array.isArray(valor) && valor.includes(c.contem);
  if (c.em) return c.em.includes(valor);
  if (c.maiorOuIgual !== undefined) return typeof valor === 'number' && valor >= c.maiorOuIgual;
  return false;
}
export function opcoesCampo(campo       , ctx          )           {
  if (campo.opcoes) return campo.opcoes;
  if (!campo.opcoesPorPublico || !ctx.publico) return [];
  return campo.opcoesPorPublico[ctx.publico] ?? [];
}
export function cpfValido(valor         )          {
  if (typeof valor !== 'string') return false;
  const cpf = valor.replace(/\D/g, '');
  if (!/^\d{11}$/.test(cpf) || /^(\d)\1{10}$/.test(cpf)) return false;
  for (const tamanho of [9, 10]) {
    let soma = 0;
    for (let i = 0; i < tamanho; i++) soma += Number(cpf[i]) * (tamanho + 1 - i);
    const digito = (soma * 10 % 11) % 10;
    if (digito !== Number(cpf[tamanho])) return false;
  }
  return true;
}
const vazio = (v         ) => v === undefined || v === null || (typeof v === 'string' && !v.trim()) || (Array.isArray(v) && v.length === 0);
export function validarCampos(campos         , r           , ctx          , raiz = r)                         {
  const erros                         = {};
  for (const c of campos) {
    if (!condicaoAtendida(c.mostrarSe, raiz, ctx)) continue;
    const v = r[c.id];
    const exigido = c.obrigatorio || (c.obrigatorioSe !== undefined && condicaoAtendida(c.obrigatorioSe, raiz, ctx));
    if (vazio(v)) { if (exigido) erros[c.id] = 'Preencha este campo.'; continue; }
    if (c.tipo === 'grupo') {
      if (typeof v !== 'object' || v === null || Array.isArray(v)) erros[c.id] = 'Preencha os dados do responsável.';
      else for (const [k, e] of Object.entries(validarCampos(c.campos ?? [], v             , ctx, raiz))) erros[`${c.id}.${k}`] = e;
    } else if (c.tipo === 'aceite' && (typeof v !== 'boolean' || (exigido && v !== true))) erros[c.id] = 'É necessário aceitar para continuar.';
    else if (c.tipo === 'cpf' && !cpfValido(v)) erros[c.id] = 'CPF inválido.';
    else if (c.tipo === 'data' && (typeof v !== 'string' || !dataValida(v) || v > ctx.hoje)) erros[c.id] = 'Data inválida.';
    else if (c.tipo === 'contador' && (typeof v !== 'number' || !Number.isSafeInteger(v) || v < (c.min ?? 0) || v > (c.max ?? Number.MAX_SAFE_INTEGER))) erros[c.id] = 'Quantidade fora do intervalo.';
    else if (c.tipo === 'simnao' && !['sim', 'nao'].includes(String(v))) erros[c.id] = 'Selecione sim ou não.';
    else if (['escolha', 'escolha_ilustrada'].includes(c.tipo) && !opcoesCampo(c, ctx).includes(String(v))) erros[c.id] = 'Selecione uma opção válida.';
    else if (c.tipo === 'multipla' && (!Array.isArray(v) || !v.every(x => typeof x === 'string' && opcoesCampo(c, ctx).includes(x)))) erros[c.id] = 'Selecione opções válidas.';
    else if (['texto','texto_longo','mesano','email','cep','telefone','uf'].includes(c.tipo) && typeof v !== 'string') erros[c.id] = 'Informe um texto válido.';
    else if (c.tipo === 'cep' && !/^\d{8}$/.test(String(v).replace(/\D/g, ''))) erros[c.id] = 'CEP inválido.';
    else if (c.tipo === 'telefone' && !/^\d{10,11}$/.test(String(v).replace(/\D/g, ''))) erros[c.id] = 'Telefone inválido.';
    else if (c.tipo === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(v))) erros[c.id] = 'E-mail inválido.';
  }
  if (campos.some(c => c.id === 'tem_responsavel' && c.obrigatorioSe && condicaoAtendida(c.obrigatorioSe, raiz, ctx)) && r.tem_responsavel !== 'sim') erros.tem_responsavel = 'Registre o responsável para continuar.';
  return erros;
}
/** Lista fechada de operações. Fórmulas novas exigem implementação e testes. */
function calcular(expressao        , r           )                              {
  if (expressao === 'bolsas' || expressao === 'cateteres') return expressao;
  if (expressao === 'ceil(trocas_semana * 30 / 7)') {
    const n = r.trocas_semana;
    return typeof n === 'number' && Number.isInteger(n) && n >= 1 && n <= 21 ? Math.ceil(n * 30 / 7) : undefined;
  }
  if (expressao === 'cat_dia * 30') {
    const n = r.cat_dia === 'outro' ? r.cat_dia_outro : Number(r.cat_dia);
    return typeof n === 'number' && Number.isInteger(n) && n >= 1 && n <= 12 ? n * 30 : undefined;
  }
  throw new Error('Operação de formulário não suportada.');
}
export function executarRegras(form            , r           , ctx          ) {
  const sugestao            = {}, calculos            = {}, exigencias            = {};
  const alertas           = [], pendencias           = [];
  for (const regra of form.regras ?? []) {
    if (regra.validar && !ctx.regrasClinicasValidadas) { pendencias.push(regra.id); continue; }
    if (regra.id === 'publico_do_paciente') {
      const idade = idadeEm(r.data_nascimento, ctx.hoje);
      if (regra.idadeCortePediatrica == null || idade === undefined) { pendencias.push(regra.id); continue; }
      const publico = idade < regra.idadeCortePediatrica ? 'ped' : r.sexo === 'masculino' ? 'masc' : r.sexo === 'feminino' ? 'fem' : undefined;
      if (publico) calculos.publico_do_paciente = publico; else pendencias.push(regra.id);
    }
    for (const caso of regra.casos ?? []) if (condicaoAtendida(caso.se, r, ctx)) Object.assign(sugestao, caso.sugerir);
    // Ignora respostas residuais de campos que deixaram de estar visíveis.
    const condicao = regra.id === 'alerta_itu' && r.itu !== 'sim' ? false : condicaoAtendida(regra.se, r, ctx);
    if (condicao && regra.alerta) alertas.push(regra.alerta);
    if (condicao && regra.exigir) Object.assign(exigencias, regra.exigir);
    for (const [chave, expressao] of Object.entries(regra.calcular ?? {})) {
      const valor = calcular(expressao, r);
      if (valor !== undefined) calculos[chave] = valor;
    }
  }
  return { sugestao, calculos, exigencias, alertas, pendencias };
}
