# PostgreSQL Schema Documentation

このディレクトリは chat の PostgreSQL スキーマドキュメント。8 テーブル (chat_rooms /
chat_messages / room_members / users / friendships / file_attachments / push_subscriptions /
reactions) を Flyway migration V1〜V7 で管理。

| File | Owner | When updated |
|---|---|---|
| [`schema/`](schema/) | tbls (auto) | `make db-docs` で再生成 |

## ドキュメント生成

```bash
make db-docs        # Postgres 起動 + Flyway migrate + tbls 実行 + docs/db/schema/ 再生成
make db-docs-diff   # 現状の docs と live スキーマの差分表示
```

**`tbls doc` を素手で打たないこと。** ローカル psql に同名 DB があれば誤接続する可能性が
ある。必ず `make db-docs` (Postgres コンテナ + Flyway migrate を済ませた状態) を経由する。

## 更新ポリシー

`schema/` を再生成すべきタイミング:
- `api/src/main/resources/db/migration/V*.sql` の追加 / 変更 (新 migration)
- `.tbls.yml` の comment / exclude 変更

`COMMENT ON TABLE` / `COMMENT ON COLUMN` を Flyway DDL に直書きする場合も再生成必要
(現状は `.tbls.yml` の comments で代替している)。

## CI による drift 検出の限界

`.github/workflows/db-docs.yaml` は `tbls diff` でスキーマ drift を検出する。
PostgreSQL は DDL が一次情報なので、DynamoDB と違って手書き補足が不要 → CI ガードの
守備範囲が広い (DDL の変更が即 schema に反映される)。

CI が捕捉できる範囲:
- カラム追加 / 削除 / 型変更
- FK / Index / UNIQUE / CHECK 制約の追加 / 削除
- テーブル追加 / 削除 / 名前変更
- `.tbls.yml` の comment 更新が `schema/` に反映されてない

## tbls の Postgres 出力

Postgres driver は INFORMATION_SCHEMA から以下を完全抽出する:

- カラム型 / NOT NULL / DEFAULT
- PRIMARY KEY (単一 / 複合)
- FOREIGN KEY (ON DELETE CASCADE 含む)
- INDEX (単一 / 複合 / UNIQUE)
- CHECK 制約

DynamoDB (兄弟プロジェクト receipto / burnnote / url-shortener) と違い、手書きの
`entities.md` / `access-patterns.md` は不要。代わりに `.tbls.yml` の `comments:` で
テーブル単位の概要を記述する (将来は Flyway DDL に `COMMENT ON TABLE` を直書きする候補)。

## 対象外: Elasticsearch

`api/src/main/java/com/example/chat/model/entity/ChatMessageDocument.java` の Elasticsearch
インデックス (`chat-messages`、kuromoji_analyzer) は **本ドキュメントの対象外**。tbls には
ES driver もあるが、本 PR では Postgres のみをスコープとする。

## Flyway

- ローカル / CI: Flyway CLI バイナリ (v12.5.0) を curl tar で DL して `flyway migrate` 実行
- Spring Boot 起動経由ではない (本体改変を避けるため Gradle plugin 追加せず)
- migration ファイル: `api/src/main/resources/db/migration/V{1..7}__*.sql`
- Flyway 自身の `flyway_schema_history` テーブルは `.tbls.yml` の `exclude` で対象外
