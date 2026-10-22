# Procirúrgica Campo — portal de homologação

Publicado em 22/10/2026 na Hostinger:

- Portal: https://procirurgica.gritnews.com.br/
- Gerencial: https://procirurgica.gritnews.com.br/gerencial/
- Campo: https://procirurgica.gritnews.com.br/campo/

## Escopo desta publicação

Cadastro de pacientes fictícios, fichas textuais StomaPro e ConfortCath dirigidas pelos JSON, rascunhos, acompanhamento e retornos, protocolos de testes de padronização com critérios, amostras, evolução e resultado.

O modo de demonstração usa dados fictícios na memória da aba e não envia registros ao backend. O modo autenticado utiliza exclusivamente o namespace de tabelas `campo_*` do projeto Supabase Procirúrgica existente. Não modifica tabelas comerciais nem compartilha registros da demonstração com a base autenticada.

O perfil superadmin foi vinculado à conta Auth previamente existente `gritsolucoes@gmail.com`. Não foi criada senha, não existe senha padrão e o cadastro público está fechado. Além da senha, a versão 0.2.1 oferece código por e-mail para contas existentes (`create_user: false`). O modelo de e-mail preserva o link anterior e acrescenta o código de uso único. O envio depende das regras e limites do serviço de e-mail do Supabase. A entrada final depende da senha ou do código recebido pelo titular; não foi realizada com credenciais do usuário.

## Segurança implementada e verificada

- Login Supabase, tokens apenas em memória, sem localStorage, bloqueio por inatividade de cinco minutos e logout da sessão atual.
- RLS e negação de SELECT anônimo nas seis tabelas novas.
- Isolamento por empresa e responsável; gestor com acesso à própria empresa.
- Imutabilidade de atendimento concluído, trilha de eventos sem copiar dados clínicos nos eventos.
- Teste transacional com identidade autenticada: criação, conclusão, bloqueio de alteração, auditoria e isolamento de usuário sem perfil. Todo o teste foi revertido com ROLLBACK.
- Apenas chave pública no código cliente. Nenhuma service role, senha ou informação real de paciente no repositório.
- HTTPS, política de conteúdo, prevenção de enquadramento e ausência de indexação.
- Service worker armazena apenas arquivos públicos do app; nunca intercepta consultas do Supabase.

## Verificações de interface

- Site e rotas gerencial/campo acessíveis pelo HTTPS final.
- Demonstração: cadastrar paciente, listar histórico, salvar rascunho incompleto, abrir retornos e evoluir protocolo.
- Aprovação/reprovação exige resultado.
- Layout conferido em largura de 390 px, sem rolagem lateral da página.
- 27 testes locais do núcleo e armazenamento da sessão passaram. Eles não substituem teste de login real nem homologação clínica.

## Limites explícitos

Use somente dados fictícios. O termo `homologacao-v1` não é um termo jurídico para pacientes reais. As tabelas exigem a marcação de homologação; isso não substitui a orientação operacional de não inserir dados reais.

A ficha web é textual, sem fotografias clínicas, OCR, assinatura, PDF assinado, sincronização offline de registros ou integração PROH. Não confundir o app shell instalável com a versão nativa Expo/SQLCipher. Esses itens continuam no projeto nativo, além da gerencial Next.js prevista no prompt mestre. Esta camada web estática é a primeira publicação de homologação solicitada; não substitui os aceites E0–E6.

Próximas liberações: validação clínica das fichas e idade pediátrica, inclusão versionada de volume residual, consentimento e retenção aprovados, usuários de campo por empresa, mídias e assinatura, testes do app nativo, contrato de integração PROH.

## Publicação

O repositório contém somente os arquivos públicos do portal. Hostinger importa `main` em `public_html`. Não adicionar segredos, arquivos de pacientes ou exports. Publicar uma atualização por vez e aguardar sua conclusão para evitar concorrência no clone superficial da hospedagem.
