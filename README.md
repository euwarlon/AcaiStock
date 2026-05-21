# Açaí Stock (Flutter)

## Run (Supabase + backup enabled)

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=SUPABASE_BACKUP_BUCKET=backups
```

Windows PowerShell:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY --dart-define=SUPABASE_BACKUP_BUCKET=backups
```

Pre-check (Windows plugins): enable Developer Mode.

```powershell
start ms-settings:developers
```

## Arquitetura (Camadas)

- `lib/screens`: apresentação (auth, abas, scanner, entrada manual).
- `lib/providers`: estado e regras (`AppStore`).
- `lib/models`: entidades (`Product`).
- `lib/data`: acesso a dados e integrações (`sqflite`, export, notificações, biometria, backup).
- `lib/widgets`: componentes reutilizáveis.
- `lib/theme`: tema e paleta.

## Dependências principais

- Estado/UI: `provider`
- Persistência local: `sqflite`, `path`, `shared_preferences`
- Arquivos e exportação: `path_provider`, `csv`, `pdf`
- Segurança e alertas: `local_auth`, `flutter_local_notifications`
- Backup em nuvem: `supabase`

## Configuração de banco e ambiente

1. Instale dependências:

```bash
dart pub get
```

2. Banco SQLite:
   - arquivo: `acai_stock.db`
   - criação e migração executadas automaticamente por `LocalDatabase`.

3. Variáveis de ambiente (`--dart-define`):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_BACKUP_BUCKET` (opcional, default `backups`)

4. Recuperacao de senha pelo Supabase:
   - em Authentication > URL Configuration, adicione `acai-stock://auth-callback` em Redirect URLs.
   - o link de recuperacao abrira o app e mostrara a tela para definir a nova senha.

5. Crie bucket no Supabase Storage:
   - nome: `backups` (ou o definido em `SUPABASE_BACKUP_BUCKET`)
   - permissão de upload para a chave utilizada.

## Scripts de migração (auditoria)

Implementados em `lib/data/local_database.dart`.

Schema inicial (`onCreate`, `version: 2`):

```sql
CREATE TABLE products(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nome TEXT NOT NULL,
  categoria TEXT NOT NULL,
  quantidade INTEGER NOT NULL,
  ponto_pedido INTEGER NOT NULL,
  lote TEXT NOT NULL,
  data_validade TEXT NOT NULL,
  trend INTEGER NOT NULL,
  galpao_zerado INTEGER NOT NULL,
  last_updated TEXT NOT NULL
);

CREATE TABLE loss_logs(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,
  nome TEXT NOT NULL,
  lote TEXT NOT NULL,
  quantidade INTEGER NOT NULL,
  motivo TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```

Migração para versão 2 (`onUpgrade`):

```sql
ALTER TABLE products ADD COLUMN last_updated TEXT;
UPDATE products SET last_updated = CURRENT_TIMESTAMP WHERE last_updated IS NULL;
```
