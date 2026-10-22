export function normalizarEmail(valor) { return String(valor ?? '').trim().toLowerCase(); }
export function papelGerencial(papel) { return papel === 'gestor' || papel === 'superadmin'; }
export function mensagemAuth(codigo, status) {
  if (codigo === 'invalid_credentials') return 'E-mail ou senha não reconhecidos. Você também pode entrar com um código enviado ao seu e-mail.';
  if (codigo === 'email_not_confirmed') return 'Confirme seu e-mail antes de entrar.';
  if (codigo === 'otp_expired') return 'Código inválido ou expirado. Solicite um novo código.';
  if (codigo === 'email_address_not_authorized') return 'O provedor de e-mail ainda não autorizou este destinatário. Contate o administrador.';
  if (status === 429 || codigo === 'over_email_send_rate_limit') return 'Aguarde alguns minutos antes de solicitar outro código.';
  if (status >= 500) return 'O serviço de autenticação está temporariamente indisponível. Tente novamente.';
  return 'Não foi possível autenticar. Confira os dados e tente novamente.';
}
