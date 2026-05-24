# Açaí Stock (Flutter)

## Quick Start

```bash
flutter pub get
flutter run
```

**Nota**: Configure Firebase conforme [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

Pre-check (Windows plugins): enable Developer Mode.

```powershell
start ms-settings:developers
```

## Arquitetura (Camadas)

- `lib/screens`: apresentação (auth, abas, scanner, entrada manual).
- `lib/providers`: estado e regras (`AppStore`).
- `lib/models`: entidades (`Product`).
- `lib/data`: acesso a dados e integrações (`sqflite`, export, notificações, biometria, auth).
- `lib/widgets`: componentes reutilizáveis.
- `lib/theme`: tema e paleta.

## Dependências principais

- Estado/UI: `provider`
- Persistência local: `sqflite`, `path`, `shared_preferences`
- Arquivos e exportação: `path_provider`, `csv`, `pdf`
- Segurança e alertas: `local_auth`, `flutter_local_notifications`
- Autenticação: `firebase_auth`, `firebase_core`

## Configuração de banco e ambiente

1. Instale dependências:

```bash
dart pub get
```

2. Configure Firebase (veja [FIREBASE_SETUP.md](FIREBASE_SETUP.md)):
   - Crie projeto no Firebase Console
   - Baixe credenciais para suas plataformas
   - Atualize `lib/firebase_options.dart`

3. Banco SQLite:
   - arquivo: `acai_stock.db`
   - criação e migração executadas automaticamente por `LocalDatabase`.

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
