# Chat

AWS ポートフォリオ 2つ目。Java/Spring Boot + SvelteKit のリアルタイムチャット。

## プロジェクト構成

```
chat/
├── api/          # Java 21 + Spring Boot 3.4 (WebSocket, JPA, Redis, SQS, S3)
├── web/          # SvelteKit 2 + Svelte 5 + Tailwind v4
├── infra/        # Terraform（Cognito, RDS, ElastiCache, SQS, S3, ECR, CloudFront）
├── manifests/    # K8s マニフェスト + ArgoCD
├── docs/         # 構成図
└── .github/      # CI/CD
```

## 開発環境

**flox を使う。** `flox activate` で Java, Gradle, pnpm, Terraform 等が全部使える。
PostgreSQL と Redis は docker-compose で自動起動（flox の on-activate フック）。

## パッケージマネージャ

- Java: Gradle (Kotlin DSL)
- Web: pnpm

## コマンド

### API
```bash
cd api && gradle bootRun --args='--spring.profiles.active=local'
cd api && gradle test
cd api && gradle compileJava
cd api && docker build -t chat-api .
```

### Web
```bash
cd web && pnpm install
cd web && pnpm dev
cd web && pnpm build
```

### Infra
```bash
cd infra && terraform init
cd infra && terraform plan
cd infra && terraform apply
cd infra && terraform destroy
```

## DB スキーマドキュメント

`docs/db/` に PostgreSQL スキーマドキュメント。`make db-docs` で Postgres 起動 + Flyway migrate + tbls 再生成。
詳細: [docs/db/schema/](docs/db/schema/) (tbls 自動生成、Postgres スキーマ + ER 図)

## EKS クラスタ

url-shortener と共有。chat/infra/ は data source で既存の VPC/EKS を参照。
url-shortener のインフラが先に立っている必要がある。

## WebSocket

CloudFront は WebSocket 非対応。フロントは ALB に直接 WebSocket 接続する。
