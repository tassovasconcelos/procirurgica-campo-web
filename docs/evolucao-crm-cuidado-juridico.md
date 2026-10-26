# Evolução CRM, assistência e jurídico
Data: 2026-10-26. Ambiente: homologação, somente dados fictícios.

## Requisitos e rastreabilidade
Os seis anexos foram localizados, porém a ferramenta de leitura não retornou texto ou páginas. Requisitos abaixo vêm das mensagens do solicitante; não representam extração dos anexos. A leitura dos documentos e a validação da equipe são critérios pendentes antes de fechar escopo e regras jurídicas.

| Frente | Entregável | Aceitação |
|---|---|---|
| CRM | Carteira, oportunidades, compras/recompras, itens, valores, agendamento e histórico | Total calculado no servidor; alteração auditada; comercial vê apenas carteira autorizada |
| Consumo | Quantidade, unidade, periodicidade, última compra e estoque informado | Recompra proposta com origem do dado; falta de informação impede previsão categórica |
| Jurídico | Processo por paciente/plano, decisão, validade, prazos e responsáveis | Calendário com timezone, origem do prazo e confirmação humana; checklist aprovado pelo jurídico |
| Assistência | Anamnese, evolução, visita, autoria, data e adendo | Histórico preservado; comercial e jurídico sem acesso clínico genérico |
| Documentos pessoais | Cofre separado, upload profissional e consulta restrita | Superadmin, jurídico e gestor da equipe; profissional sem leitura; storage privado; auditoria |
| Produtos | Ostomias, sondas e cateteres hidrofílicos; adaptação, padronização e contínuo | Catálogo/IFU versionados e revisados por responsável clínico |
| Homologação | Teste, hipótese, produto, início/fim, resultado, intercorrência e avaliador | Indicadores com denominador explícito e motivos de interrupção |
| Pesquisas | Satisfação pós-visita e avaliação de teste | Convite único, consentimento/preferências, webhook autenticado e deduplicado |
| Alertas | Retorno, recompra, prazo judicial e pendência documental | Responsável, prioridade, lido/resolvido, repetição controlada; mensagem externa sem dados de saúde |
| Gestão | Conversão, recompra, ticket médio, consumo, atendimento, testes e prazos | Filtros por período/equipe; métricas reproduzíveis; tabela acessível |
| Mobile | PWA de campo e interface gerencial profissional | Layout responsivo, acessibilidade, rede lenta, sessão expirada e upload interrompido |

## Implementado nesta etapa
Backend do cofre separado e papel jurídico; download mediado por função autenticada, checagem de assinatura PDF/JPEG/PNG, limite 20 MiB e SHA-256. Nenhuma URL pública de documento. Arquivos jurídicos preservam bytes originais, sem compressão destrutiva.
Testes SQL transacionais passaram para enfermeiro (envio sem leitura), gestor da equipe, outro gestor, jurídico, superadmin, comercial, inativo e anônimo; confirmação reservada a service_role. Transações de teste revertidas.
A tela, upload/download ponta a ponta, antimalware, retenção, restauração e revisão jurídica/LGPD permanecem pendentes. Validação de cabeçalho não substitui inspeção antimalware. Auditoria registra autorização do download, não comprova entrega de todos os bytes.

## Sequência de entrega
1. Integrar cofre ao app e testar sessão, envio, retomada e download com usuários fictícios de cada perfil; nunca reutilizar anexos clínicos como identificação.
2. Implementar pedidos/itens, carteira comercial, agenda e recompras; validações/valores no servidor, autorização e auditoria; sem compras automáticas.
3. Processos, calendário e checklist definido pelo jurídico após leitura dos anexos. Campo de origem do prazo, documento e responsável.
4. Pesquisas e central de alertas; habilitar conectores externos somente com configuração real, preferência de contato e teste de assinatura/idempotência.
5. Agentes com fontes aprovadas, avaliação e revisão humana; primeiro modo proposta.
6. Migrar interface para React/shadcn e gráficos ECharts empacotados localmente; testar regressões do fluxo atual, acessibilidade e desempenho.

## Benchmark e dependências reais
- EspoCRM: pedidos e atividades: https://docs.espocrm.com/user-guide/sales-orders/ e https://docs.espocrm.com/user-guide/activities-and-calendar/
- OpenEMR: separação de acessos: https://www.open-emr.org/wiki/index.php/Access_Controls_Listing
- Presidio: https://microsoft.github.io/presidio/ — camada de detecção/redação; pode deixar passar dados pessoais. Exige regras brasileiras, OCR, avaliação e controles complementares.
- Formbricks: https://formbricks.com/docs/platform/introduction — serviço, domínio, segredos e webhook necessários.
- Novu: https://docs.novu.co/platform/workflow/overview — serviço, canais, preferências e credenciais necessários.
- Haystack: https://docs.haystack.deepset.ai/docs — pipeline documental isolado, OCR, armazenamento privado e autorização antes da recuperação.
- shadcn/ui: https://ui.shadcn.com/docs/installation/vite — exige migração do frontend atual em JavaScript sem build.
- Apache ECharts: https://echarts.apache.org/handbook/en/best-practices/security/ — opções declarativas, sem HTML não confiável; biblioteca local versionada, alternativa em tabela.

Estas referências orientam o desenho. Presidio, Formbricks, Novu, Haystack, shadcn e ECharts NÃO estão instalados ou integrados nesta etapa.

## Critérios de liberação
Não liberar coleta real antes da política de acesso validada, testes ponta a ponta, definição de base legal/finalidade/retenção, contrato dos operadores, resposta a incidentes e procedimento de direitos dos titulares. Não afirmar conformidade LGPD apenas pela adoção de uma ferramenta.
