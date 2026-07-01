# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é

Site de **reserva de sala de reuniões** para uso interno da empresa. Página única, **estática**
(HTML/CSS/JS puro, sem build, sem framework), pensada inclusive para ser **embutida numa página do
Notion** via `/embed` (por isso precisa de URL HTTPS pública). **Não tem login** — por design,
qualquer pessoa com o link cria e cancela reservas. O controle de cancelamento é por um **código
por reserva** (guardado como hash bcrypt no banco; nunca aparece na agenda). Suporta **recorrência**
(repetir por dia/semana/mês/ano): cada ocorrência é uma reserva independente agrupada por um
`series_id`, o que permite cancelar **só aquela** ou **a série inteira**.

## Commands

Não há build, testes automatizados, linter nem gerenciador de pacotes — é HTML/CSS/JS vanilla.

- **Preview local (UI):** `python3 -m http.server 8000` na raiz e abrir http://localhost:8000.
  Atenção: a API é **same-origin (sem CORS)**, então rodando localmente a agenda real **não carrega**
  (o `app.js` cai em dados de exemplo). Serve para mexer no visual, não para dados reais.
- **Publicar edições:** commit + push no GitHub, depois `ssh root@187.77.192.56 atualizar-reserva`
  (faz `git pull` + ajusta permissões em `/var/www/reserva`). Só editar local não atualiza o site.
- **Alterar o banco:** editar `supabase-schema.sql`, aplicar no VPS com
  `sudo -u postgres psql -d reservas -f /var/www/reserva/supabase-schema.sql` e depois
  `systemctl restart postgrest` (para o PostgREST recarregar o cache do schema — colunas/funções novas).
- **Validar o backend sem navegador:** `curl` contra `https://reserva.hsseminovos.com.br/rest/v1`
  com a chave de `config.js` em `apikey` + `Authorization: Bearer` (`GET` para ler,
  `POST /rpc/create_meeting_reservation`, `.../cancel_meeting_reservation`, `.../cancel_meeting_series`).

## Arquitetura

**Frontend** (`index.html`, `styles.css`, `app.js`): renderiza calendário semana/mês + dashboard e
fala com uma API REST em `/rest/v1`. Endpoints: `GET` na tabela e as funções RPC
`create_meeting_reservation`, `cancel_meeting_reservation` e `cancel_meeting_series`.
- A **visão semana** (`renderWeek`) é uma grade de horários estilo agenda: eixo de horas + linhas por
  hora; eventos posicionados por horário (`top`/`height` em px via `HOUR_HEIGHT`), abre rolada em 07:00.
- **Recorrência:** `computeOccurrences` expande a regra em datas e o `app.js` cria **uma reserva por
  ocorrência** (chamadas sequenciais), todas com o mesmo código e um `series_id` compartilhado. Cancelar
  oferece "somente este" (`cancel_meeting_reservation`) ou "toda a série" (`cancel_meeting_series`).

**Configuração** (`config.js`): define `window.RESERVA_DB` com `supabaseUrl` e `supabaseKey`.
- ⚠️ Os nomes `supabase*` são **legado**: o backend hoje é **próprio** (ver abaixo), não o Supabase.
  `supabaseUrl` aponta para o próprio domínio; `supabaseKey` é um JWT de role `anon`.
- ⚠️ **Pegadinha:** o painel "Configurar banco" da tela salva URL/chave no `localStorage`, e o
  `loadConfig()` do `app.js` faz o valor salvo **ter prioridade sobre o `config.js`**. Se um navegador
  tem uma config antiga salva, ele ignora o `config.js` novo. Ao trocar de backend, limpar o
  `localStorage` do navegador afetado resolve.

**Backend auto-hospedado no VPS** (migrado do Supabase em jun/2026 — mesma tecnologia por baixo, por
isso o `app.js` quase não mudou):
- **PostgreSQL** (banco `reservas`) + **PostgREST** (serviço systemd `postgrest`, em `127.0.0.1:3000`).
- **nginx** serve o estático em `/` e faz proxy de `/rest/v1/` → PostgREST (mesmo domínio/HTTPS).
- Segredos (senha do banco, jwt-secret, JWT anon) em `/root/reserva-backend-secrets` no servidor.
- Segurança do cancelamento: RLS + funções `security definer`; `anon` só lê colunas não sensíveis
  (nunca `cancel_code_hash`); o código é gravado como `crypt(code, gen_salt('bf'))` e o cancelamento
  só apaga se `crypt` bater. Há uma **exclusion constraint global** (`no_time_overlap`): duas reservas
  não podem se sobrepor no tempo (modelo de sala única) — conflito vira erro do banco.
- **Séries:** coluna `series_id` agrupa as ocorrências de uma recorrência; `cancel_meeting_series(series_id, code)`
  apaga todas as reservas da série cujo código bate. Depois de aplicar mudança de schema, reiniciar o PostgREST.

## Infra e operação

- Produção: **https://reserva.hsseminovos.com.br** (Let's Encrypt, renovação automática).
- **VPS Hostinger** `187.77.192.56` (Ubuntu 24.04). Site em `/var/www/reserva` (clone deste repo).
- DNS no **Registro.br**: registro A `reserva` → `187.77.192.56`.
- **Backup:** `/usr/local/bin/backup-reservas` roda diariamente às 03:30 (`/etc/cron.d/reservas-backup`),
  gerando `pg_dump -Fc` em `/var/backups/reservas/` (mantém os 14 mais recentes; restaurar com `pg_restore`).
- **Cache:** o nginx envia `Cache-Control: no-cache` nos estáticos (revalidação a cada load) e o
  `index.html` referencia os assets com `?v=N`; ao mudar `app.js`/`styles.css`, incrementar `?v=` garante versão nova.

## ⚠️ Não quebrar (mesmo VPS)

- **market-research** — `/root/market-research`, cron semanal (`0 8 * * 1`). Não usa portas web.
- **fotos-bot** — `fotos-bot.service`, em `/opt/fotos-slack-notion`. Não usa portas web.
- E-mail do domínio é **Microsoft 365**; os registros DNS `MX`/`TXT`/`CNAME` (outlook) não devem ser alterados.
