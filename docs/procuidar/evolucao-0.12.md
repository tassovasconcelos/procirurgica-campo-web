# ProCuidar 0.12 — prioridades e consumo por produto
Somente dados fictícios de homologação.

- Agenda passa a abrir com os últimos 7 dias e os próximos 30. Abertas vencidas aparecem primeiro. Prioridade pode filtrar visitas de hoje (Brasília), abertas vencidas ou próximas abertas. Filtros continuam respeitando o período consultado e as permissões existentes.
- Metas, tarefas e checklist recebem filtros por tipo, situação, texto e pendências vencidas. Exibe quantos itens do recorte estão visíveis e preserva filtros ao revisar/salvar. Itens concluídos, cancelados, aprovados ou dispensados não são marcados como pendência vencida.
- Resumo de consumo agrupa somente produto + referência + unidade iguais. Usa a última observação pela data informada; desempate por data de registro e identificador. Não soma caixas e unidades nem calcula movimento de estoque a partir de relatos.
- Sinalização administrativa para conferir relatos com pelo menos 7 dias ou autonomia teórica de até 7 dias na data informada. Não estima estoque atual e não sugere alteração de indicação clínica ou pedido automático.
- Mantém as observações e versões originais; filtros não alteram dados.
- Testes novos cobrem vencimento, estados encerrados, unidade, relato mais recente, fuso e filtros em mobile. Regressões existentes continuam no CI. Sem alteração de esquema ou permissões nesta entrega.
