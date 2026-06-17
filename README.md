# Reserva de Sala de Reunioes - Supabase + Notion

Esta versao usa:

- Frontend estatico em HTML, CSS e JavaScript.
- Banco Postgres e API REST do Supabase.
- Publicacao em Hostinger, GitHub Pages, Netlify, Vercel ou outro host estatico.
- Embed no Notion por URL HTTPS.

## Arquivos importantes

- `index.html`: pagina principal.
- `styles.css`: visual responsivo no padrao verde, amarelo e branco.
- `app.js`: logica da agenda e conexao Supabase.
- `config.js`: onde voce pode deixar a URL e a chave publica do Supabase.
- `supabase-schema.sql`: script para criar tabela, politicas e bloqueio de conflito.

## 1. Criar projeto no Supabase

1. Acesse https://supabase.com/.
2. Entre na sua conta ou crie uma.
3. Clique em **New project**.
4. Escolha a organizacao.
5. Preencha:
   - Project name: `reserva-sala-reunioes`
   - Database password: crie uma senha forte.
   - Region: escolha a mais proxima.
6. Clique em **Create new project**.
7. Aguarde o projeto ficar pronto.

## 2. Criar tabela e permissoes

1. Dentro do projeto Supabase, abra **SQL Editor**.
2. Clique em **New query**.
3. Copie todo o conteudo de `supabase-schema.sql`.
4. Cole no SQL Editor.
5. Clique em **Run**.

O script cria:

- Tabela `meeting_room_reservations`.
- Row Level Security.
- Politicas para leitura, criacao e cancelamento sem login.
- Bloqueio de reservas sobrepostas pelo proprio banco.

## 3. Copiar URL e chave publica

1. No Supabase, abra **Project Settings**.
2. Entre em **API Keys** ou use o dialogo **Connect** do projeto.
3. Copie:
   - Project URL.
   - Publishable key `sb_publishable_...`.

Se seu projeto ainda mostrar chaves legadas, use a `anon public key`.

Nunca use `secret key`, `service_role` ou qualquer chave secreta no `config.js`.

## 4. Configurar o arquivo config.js

Abra `config.js` e preencha:

```js
window.RESERVA_DB = {
  supabaseUrl: "https://SEU-PROJETO.supabase.co",
  supabaseKey: "SUA_CHAVE_PUBLICA_AQUI",
};
```

Salve o arquivo.

Tambem e possivel configurar pela propria tela da aplicacao, clicando em **Configurar Supabase**, mas para uso da equipe e melhor deixar o `config.js` preenchido antes de publicar.

## 5. Publicar a aplicacao

Voce precisa de uma URL HTTPS para o Notion conseguir incorporar.

### Opcao A: Hostinger

1. Abra o hPanel da Hostinger.
2. Va para **Gerenciador de Arquivos**.
3. Entre em `public_html`.
4. Crie uma pasta, por exemplo `reserva-sala`.
5. Envie estes arquivos:
   - `index.html`
   - `styles.css`
   - `app.js`
   - `config.js`
   - `supabase-schema.sql` opcional, pode nao publicar se preferir
6. Acesse:

```text
https://seudominio.com.br/reserva-sala/
```

### Opcao B: GitHub Pages

1. Crie um repositorio no GitHub.
2. Envie os arquivos da aplicacao.
3. No repositorio, va em **Settings** > **Pages**.
4. Em **Build and deployment**, escolha a branch principal.
5. Salve.
6. Use a URL gerada pelo GitHub Pages.

## 6. Testar antes de colocar no Notion

Abra a URL publicada e teste:

1. A tela mostra **Supabase conectado**.
2. Crie uma reserva.
3. Atualize a pagina e confirme que a reserva continua aparecendo.
4. Tente criar uma reserva no mesmo horario.
5. Confirme que aparece conflito.
6. Abra a mesma URL em outro navegador ou celular e confirme que a reserva aparece.

## 7. Incorporar no Notion

1. Copie a URL HTTPS da aplicacao publicada.
2. Abra a pagina do Notion.
3. Digite:

```text
/embed
```

4. Escolha **Embed**.
5. Cole a URL.
6. Confirme.
7. Ajuste a altura/largura do bloco na pagina.

## Observacoes de seguranca

- Esta versao foi feita sem login, como solicitado.
- Qualquer pessoa com o link pode ver, criar e cancelar reservas.
- A chave publica do Supabase pode ficar no frontend, desde que as politicas RLS estejam corretas.
- Para uso mais restrito no futuro, adicione login, regra por dominio de e-mail ou permissao para cancelar apenas reservas proprias.
