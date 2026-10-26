# ProCuidar 0.11 — metas, consumo, checklist e pesquisa direta
Somente homologação com dados e respostas fictícios.

## Entregas
- Paciente -> Metas, tarefas e consumo: metas com critério/prazo e tarefas vinculadas; executor profissional, paciente, familiar ou cuidador. Conclusão exige evidência; meta não conclui com tarefa aberta. Cancelamento/reabertura exige justificativa. Todas as revisões são preservadas.
- Consumo: observações datadas por produto/referência/unidade, consumo diário e/ou estoque informado, origem e contexto. Snapshots não são editados. Correções são novas observações identificadas no contexto.
- Autonomia teórica = estoque / consumo diário na mesma observação e unidade; não representa saldo atual, pedido automático ou recomendação de uso. Sem consumo positivo e estoque informado, não calcular.
- Documentos -> paciente -> Checklist: itens definidos pelo jurídico, pendente/em análise/aprovado/complemento/dispensado. Aprovação exige original confirmado, do mesmo paciente e categoria. Complemento/dispensa exigem justificativa. Recebido não equivale a aprovado; aprovado não significa liminar concedida.
- Visita realizada -> Link para paciente/cuidador: token aleatório de 256 bits gerado por CSPRNG, hash persistido no banco, validade de 72 horas. Nova emissão revoga anteriores. Uma resposta por visita; reenvio idêntico pode confirmar resposta já recebida. Coleta direta sem autoria atribuída ao profissional.
- Página pública genérica pesquisa.html recebe token no fragmento e o remove da URL ao abrir; não exibe paciente/documento/diagnóstico. Sem login. Não grava token em armazenamento local nem o envia em query/referer. Link é credencial de acesso: compartilhar somente com o destinatário. Não autentica a identidade de quem responde.
- Sem envio automático de mensagem ou e-mail. Emissão depende da confirmação operacional do usuário. Se resposta assistida for registrada, links pendentes são encerrados.
- Mantém a mesma regra de uma resposta por visita para assistida e direta. O NPS consolidado passa a incluir ambas; não mede resultado clínico.

## Segurança
Ações assistenciais exigem perfil clínico autorizado. Jurídico não vê ações clínicas; profissional de campo não revisa checklist jurídico. Revisões imutáveis e controle de versão evitam substituição silenciosa.
Anon só executa resposta por token: não pode ler pacientes, respostas, links ou metas. Hash não é disponibilizado pela API de listagem. Schema privado separado para a função de resposta pública.
SQL transacional: metas/tarefas, estoque inválido, consumo imutável, isolamento clínico/jurídico, aprovação sem original, complementos, revogação/expiração e resposta repetida. Testes revertidos.
Browser mobile testa os fluxos com APIs simuladas. Não equivale à homologação autenticada integral dos perfis ou de Storage. Liberação para dados reais, antimalware, retenção, restauração e validação dos formulários continuam pendentes.
