# ProCuidar — formulários v1
Programa de Cuidado Continuado do Grupo Prohospital.

## Entrega
Prévia navegável em web/procuidar/formularios.html e definição estruturada em formularios-schema.js. Quatro fichas: ConfortCath, atendimento de ostomia, avaliação do equipamento coletor e conclusão de teste/homologação. A última é complemento proposto, não transcrição documental.

## Fidelidade e limitações
As cinco imagens recebidas em 26/10/2026 retornaram texto parcialmente extraído, permitindo identificar alguns campos. Não foi possível inspecionar os pixels nem confirmar todas as alternativas. O PDF anterior não foi lido integralmente. Portanto esta versão é rascunho, não transcrição integral.
Cada campo distingue fonte de imagem e complemento operacional. Os campos/tabelas ilegíveis estão em pending e não recebem alternativas presumidas. Diagnósticos, modelos/calibres, escala de drenagem e desenhos de abdômen precisam de revisão.

## Operação
Sem persistência, API ou envio de mensagens. Apenas preenchimento temporário e impressão. Troca de ficha avisa antes de descartar respostas. Usar dados fictícios. Não integrado ao prontuário nem publicado no domínio operacional nesta etapa.
Ao integrar: autenticação/RLS, profissional habilitado, paciente autorizado, versão da ficha, data de atendimento/registro e autor do servidor, rascunho com retomada e conclusão imutável com adendos. Não disponibilizar campos clínicos ao comercial. Arquivos pessoais somente no cofre. Resultado individual e homologação institucional são eventos distintos.
Testes locais/browser não executados: ambiente de execução indisponível. Revisão estática do esquema realizada; pendente validação de interface e conteúdo pela equipe.
