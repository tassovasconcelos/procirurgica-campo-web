export function validarNovaSenha(senha,confirmacao){
 if(typeof senha!=='string'||senha.length<12)throw Error('Use uma senha individual com pelo menos 12 caracteres.');
 if(senha.length>128)throw Error('Use até 128 caracteres.');
 if(new Set(senha.toLowerCase()).size<4||['123456789012','password1234','procirurgica123','gritsolucoes123'].includes(senha.toLowerCase()))throw Error('Evite sequências, repetições e senhas padrão.');
 if(senha!==confirmacao)throw Error('As senhas não coincidem.');
 return senha;
}

