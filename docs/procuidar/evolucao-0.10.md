# ProCuidar 0.10 — visitas, acompanhamento e campo
Data: 26/10/2026. Somente dados fictícios de homologação.

## Entregas
- Visitas e qualidade: agenda por período de até 93 dias, profissional, status e paciente/cidade. Novas visitas usam o responsável assistencial ativo do cadastro. Reatribuição da equipe continua no cadastro do paciente.
- Estados agendada, confirmada, reagendada, realizada, cancelada e não realizada. Motivos obrigatórios para reagendar/cancelar/não realizar. Visita realizada exige anamnese/evolução do profissional responsável. Histórico preservado; sem edição de encerradas.
- Bloqueio de sobreposição de horários, controle de versão concorrente e reenvio com mesmo protocolo.
- NPS 0–10 com respondente paciente/familiar/cuidador, coleta assistida, uma resposta imutável por visita realizada. Não há disparo automático, link público nem integração Formbricks nesta versão.
- Indicadores por recorte: realizadas, visitas vencidas, canceladas, status atual de reagendamento, cumprimento da agenda, NPS e cobertura de respostas. Status atual de reagendamento não é taxa histórica de reagendamentos. NPS não mede resultado clínico.
- Anamnese ampliada: mobilidade, limitações, avaliação inicial, necessidades, metas e critérios de reavaliação.
- Evolução ampliada: situação avaliada pelo profissional, justificativa obrigatória para melhora/estabilidade/piora, treinamento do paciente/cuidador e próximo passo.
- Cadastro: endereço para visitas e situação de liminar não informada/não/em preparação/sim. Familiar/cuidador, vínculo, telefone e plano preservados e melhor apresentados. Liminar concedida exige identificação; preparação não significa concessão.
- Cofre documental: envio de PDF/JPEG/PNG originais até 20 MB, recibo de protocolo/hash; consulta restrita. Categorias mostram recebimento, não aprovação jurídica. Lista de conferência é referência, não exigência universal. Sem compressão destrutiva. Fluxo depende do backend campo-cofre já publicado.
- PWA de campo com atalhos fixos e controles de toque; início em Visitas quando não há rota. Nome ProCuidar no manifesto. Sem armazenamento clínico offline ou app nativo entregue.

## Dados e métricas
Consumo permanece por produto, unidade e período informado, com equivalência de 30 dias. Não somar bolsas, caixas e cateteres como se fossem uma unidade. Não inferir troca clínica a partir de estoque ou vendas.
Cumprimento: realizadas / visitas com início até agora no recorte. NPS: 100 × (notas 9–10 − notas 0–6) / respostas válidas. Mostrar amostra e cobertura. Para retrospectivas históricas de agenda, usar os eventos preservados; o painel atual é um retrato do status.

## Validação e limites
SQL transacional, com dados sintéticos e rollback: idempotência, conflito de horário, realização sem prontuário bloqueada, versão/histórico, encerramento preservado, nota inválida, duplicação de pesquisa, grants e isolamento de outra equipe/comercial. Melhora sem justificativa é rejeitada.
CI: sintaxe, indicadores e browser mobile com APIs simuladas. Isso não substitui homologação autenticada ponta a ponta de todos os perfis nem teste real de arquivos no Storage. Antimalware, retenção, restauração e assinatura permanecem requisitos antes do uso real.

## Próximas melhorias recomendadas
1. Checklist jurídico configurado pelo jurídico, com revisão de arquivos e solicitação de complemento; recebido não significa aprovado.
2. Avaliação técnica das alternativas ilegíveis das fichas e critérios por produto; concluir teste individual não homologa produto institucionalmente.
3. Histórico de consumo e estoque informado com data, unidade e origem para previsão explicável de reposição, sem modificar indicação clínica.
4. Pesquisa independente do profissional para reduzir viés de coleta assistida, com preferência de contato, link opaco e webhook autenticado.
5. Offline protegido com política de dispositivos, expiração, criptografia e resolução de conflitos, antes de permitir prontuário no aparelho.
6. Plano de cuidados estruturado com tarefas/metas e reavaliação; os novos campos de metas são narrativos nesta etapa.
7. Integrações de alertas e análises de IA somente com fontes aprovadas, permissão e revisão humana. Não há modelo clínico preditivo ativado.

Reforço de acesso: atendimentos legados passaram a exigir escopo clínico na leitura e escrita. Teste transacional confirmou bloqueio após mudança do profissional para função Comercial.
