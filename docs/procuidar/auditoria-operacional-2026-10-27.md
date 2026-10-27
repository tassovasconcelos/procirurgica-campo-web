# Auditoria operacional ProCuidar — 27/10/2026
Escopo: app ProCuidar, gerencial e campo, namespace campo_* no banco compartilhado.

## Situação encontrada
- 1 perfil: superadmin ativo, sem profissão assistencial.
- 0 gestores e profissionais assistenciais; 0 pacientes, visitas, prontuários e documentos na base operacional consultada.
- Cadastro de usuários só vinculava conta Auth já confirmada; não oferecia convite de nova conta.
- Fichas derivadas de imagens permaneciam com leitura parcial. Não é possível afirmar transcrição integral nem aprovação clínica dos modelos.
- Não havia fluxo de instalação orientada nem registro centralizado das evidências de homologação.
- Protocolo institucional permitia edição após conclusão pela aplicação; faltava histórico detalhado próprio.
- A configuração compartilhada de Auth reporta proteção contra senhas vazadas desativada. Exige configuração e validação do responsável pela infraestrutura; não foi alterada globalmente. Referência: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Correções desta entrega 0.13
1. Convite de nova conta: somente superadm, confirmação explícita antes de enviar, protocolo de solicitação e proteção contra repetição. Perfis campo, gestor e jurídico; conta existente usa vinculação, sem gerar acesso de recuperação para terceiros. Não cria senha padrão nem devolve tokens/chave de serviço.
2. Ativação: página dedicada, senha pessoal mínima de 12 caracteres, tokens em memória e remoção da URL. Cadastro e confirmação de e-mail são diferentes de verificação de habilitação profissional.
3. Cadastro manual de paciente exige responsável assistencial ativo com e-mail confirmado. Importação continua em estágio administrativo: reatribuir responsável e revisar cadastro antes de atendimento.
4. Central com 14 etapas e evidência, autoria, versões e escopo empresa/equipe. Estados não iniciado, em teste, aprovado ou reprovado. Nenhuma etapa aprovada automaticamente e nenhuma liberação de dados reais.
5. Catálogo com 7 fichas: ConfortCath; acompanhamento de ostomia; equipamento coletor; conclusão de teste; planejamento; uso/treinamento; reavaliação/ocorrências. Filtros por linha evitam abrir ficha StomaPro em paciente ConfortCath e vice-versa. Complementos são propostas para revisão técnica.
6. Três modelos preliminares de protocolo institucional, editáveis, com versão nos critérios; objetivo e resultado justificado. Histórico detalhado, encerramento preservado e consulta de protocolos concluídos.
7. Área Instalar app, orientações Android/computador/iPhone/iPad e suporte ao prompt quando disponível. PWA usa a mesma plataforma. Não foi produzido APK/IPA nem publicação em lojas.

## Como iniciar homologação
1. Superadm acessa Usuários -> Convidar nova conta. Começar por gestor de teste, confirmar entrega e ativação.
2. Convidar profissionais de teste com gestor e profissão; verificar conselho/atribuição com liderança. Usar Vincular conta confirmada para identidades já existentes.
3. Cadastrar paciente fictício atribuído ao assistencial confirmado; completar cuidador, plano/liminar e produtos.
4. Executar anamnese, modelos de avaliação, retorno, visita, documentos/cofre, metas/consumo e pesquisa.
5. Validar em Android e iOS reais, registrar evidências e responsável na central.

## Pendências para uso real
- Confirmar SMTP, entrega e redirecionamento do convite para /ativar.html com destinatário de teste. Status enviado significa aceite do provedor, não entrega. Nenhum convite foi enviado por esta auditoria.
- Homologação autenticada ponta a ponta com profissionais e gestores reais de teste, incluindo Storage.
- Revisão técnica das alternativas ilegíveis das fichas, critérios por produto, instruções do fabricante e habilitação dos profissionais.
- Revisão jurídica/privacidade, retenção, assinatura aplicável, antimalware e restauração de backup.
- Proteção contra senhas vazadas no Auth compartilhado.
- Offline clínico protegido e aplicativo nativo/lojas continuam pendentes.

## Evidências técnicas
- Testes SQL transacionais com dados fictícios e rollback: autorização e repetição de convite, conta existente bloqueada, finalização restrita a service_role, confirmação pendente, escopo do gestor, evidência de aprovação, responsável assistencial e protocolo encerrado imutável.
- Handler de convite testado com chamadas simuladas, sem envio de e-mail.
- Testes de navegador e regressão são gate do CI: central, modelos, convite em demonstração bloqueado, instalação e ativação com APIs simuladas.
- Advisor de segurança não apontou novos avisos campo_* na consulta desta auditoria; isso não certifica conformidade ou ausência de risco.
