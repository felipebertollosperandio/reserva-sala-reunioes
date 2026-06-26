# CLAUDE.md

Guia para trabalhar neste repositório.

## O que é

Site de **reserva de sala de reuniões** para uso interno da empresa. Página única,
**estática** (HTML/CSS/JS puro, sem build, sem framework) com **Supabase** como banco.
**Não tem login** — por design, qualquer pessoa da empresa acessa, cria e cancela
reservas. O controle de cancelamento é por um **código de cancelamento** por reserva.

## Arquivos

- `index.html` — estrutura da página (formulário de reserva, calendário semana/mês, dashboard).
- `styles.css` — estilos.
- `app.js` — toda a lógica: renderização do calendário e chamadas ao Supabase.
- `config.js` — `window.RESERVA_DB` com `supabaseUrl` e `supabaseKey`.
  **A chave é a _publishable_ (pública), pode ficar no repositório** — a segurança vem do
  RLS + funções `security definer` no banco, não do sigilo da chave.
- `supabase-schema.sql` — esquema do banco (tabela, RLS, funções). Aplicar no SQL editor do Supabase.

## Como funciona o backend (Supabase)

`app.js` fala com a API REST do Supabase (`/rest/v1`):

- **Ler:** `GET /meeting_room_reservations?select=...` — a tabela tem RLS; `anon` só tem
  `select` de colunas não sensíveis (o `cancel_code_hash` nunca é exposto).
- **Criar:** `POST /rpc/create_meeting_reservation` (função `security definer`). Grava o código
  de cancelamento como **hash bcrypt** (`crypt(code, gen_salt('bf'))`), nunca em texto puro.
- **Cancelar:** `POST /rpc/cancel_meeting_reservation` — só apaga se o código informado bater
  com o hash.

Detalhes do schema que importam:
- Existe uma **exclusion constraint global** (`no_time_overlap`) sobre `tstzrange(start, "end")`:
  **duas reservas não podem se sobrepor no tempo** (modelo de sala única). Conflito → erro do banco.

## Implantação (produção)

- Publicado em **https://reserva.hsseminovos.com.br** (cadeado Let's Encrypt, renovação automática).
- Roda no **VPS Hostinger** `187.77.192.56` (Ubuntu 24.04), em `/var/www/reserva`, servido por
  **nginx** (`/etc/nginx/sites-available/reserva`, é o `default_server`). Redirect HTTP→HTTPS ativo.
- DNS no **Registro.br**: registro A `reserva` → `187.77.192.56`.
- O servidor é um **clone deste repositório**; a fonte da verdade é o GitHub.

### Publicar edições
1. Commit + push para o GitHub (`github.com/felipebertollosperandio/reserva-sala-reunioes`).
2. `ssh root@187.77.192.56 atualizar-reserva` — atalho em `/usr/local/bin/atualizar-reserva`
   que faz `git pull` + ajusta permissões.

Editar arquivos só localmente **não** atualiza o site no ar; precisa passar pelo GitHub + o comando acima.

## ⚠️ Não quebrar (mesmo VPS)

No `187.77.192.56` também rodam, e **não devem ser tocados**:
- **market-research** — `/root/market-research`, cron semanal (`0 8 * * 1`). Não usa portas web.
- **fotos-bot** — `fotos-bot.service`, em `/opt/fotos-slack-notion`. Não usa portas web.
- O e-mail do domínio é **Microsoft 365**; os registros DNS `MX`/`TXT`/`CNAME` (outlook) na zona
  do Registro.br não devem ser alterados.

## Validar o backend sem abrir o navegador

Replicar as chamadas de `app.js` com `curl` contra o Supabase (a chave publishable está em `config.js`):
`GET` para ler, `POST /rpc/create_meeting_reservation` para criar, `POST /rpc/cancel_meeting_reservation`
para cancelar. Usar um horário no futuro distante e cancelar no fim para não sujar a agenda real.
