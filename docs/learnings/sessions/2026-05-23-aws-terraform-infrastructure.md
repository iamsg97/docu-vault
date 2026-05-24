# AWS Terraform Infrastructure — Session Learning

> **Date:** 2026-05-23
> **Task:** Build the complete Terraform AWS infrastructure from scratch — 14 reusable modules, 3 isolated environment configurations (dev/preprod/prod), two ECS services wired up (webui + bff), and a bootstrap layer for remote state.
> **Files created or modified:**
> - `infra/bootstrap/` — S3 state bucket + DynamoDB lock table
> - `infra/modules/vpc/` — VPC, subnets, IGW, route tables, gateway VPC endpoints
> - `infra/modules/ecr/` — ECR repositories with lifecycle policies
> - `infra/modules/ecs-cluster/` — ECS cluster, EC2 launch template, ASG, capacity provider, IAM roles
> - `infra/modules/ecs-service/` — reusable per-service task definition + ECS service
> - `infra/modules/alb/` — ALB, security groups, target groups, path-based listener rules
> - `infra/modules/rds/` — RDS PostgreSQL 15, subnet group, parameter group, security group
> - `infra/modules/dynamodb/` — ProcessingJobs, NotificationLog, UserSessions tables with TTL
> - `infra/modules/s3/` — documents + thumbnails buckets with CORS, encryption, lifecycle
> - `infra/modules/sqs/` — processing-queue + notification-queue, each with DLQ + CloudWatch alarm
> - `infra/modules/sns/` — processing-events SNS topic
> - `infra/modules/cognito/` — Cognito user pool + app client + domain
> - `infra/modules/cloudfront/` — CloudFront distribution with 3 cache behaviors
> - `infra/modules/lambda/` — ocr-trigger, thumbnail-generator, scheduled-cleanup Lambdas
> - `infra/environments/dev/`, `preprod/`, `prod/` — environment entry points

---

## Chunk 1 — Conceptual

### What is Infrastructure as Code?

Every cloud application needs compute, networking, storage, queues, and permissions. The naive approach is to click through the AWS console to create these resources. That works once, but it breaks immediately when you need to reproduce the setup in a second environment, hand it to a teammate, recover from an accident, or audit what changed last Tuesday. Clicking is undocumented, non-reproducible, and invisible to version control.

Infrastructure as Code (IaC) solves this by expressing infrastructure as text files that a tool can read, compare to what actually exists in AWS, and bring reality into alignment with the description. The tool tracks the gap between "desired state" and "current state", computes the minimum set of API calls to close that gap, and executes them in dependency order.

**Terraform** is the dominant IaC tool for AWS. Its language (HCL — HashiCorp Configuration Language) is declarative: you describe *what you want*, not *the steps to get there*. You write `resource "aws_sqs_queue" "processing"` with the queue's attributes, and Terraform figures out whether to call CreateQueue, SetQueueAttributes, or do nothing.

Terraform keeps its own record of everything it created — the **state file**. This is what allows it to detect drift and plan future changes without re-querying every AWS API endpoint from scratch. Storing the state file remotely (in S3) with a lock (in DynamoDB) ensures that two engineers cannot simultaneously run `terraform apply` and corrupt the state.

### Where IaC fits in the technology landscape

IaC sits at the intersection of software engineering and operations — the discipline now called DevOps or Platform Engineering. Alternatives to Terraform include AWS CloudFormation (AWS-native, more verbose), AWS CDK (imperative code compiled to CloudFormation), and Pulumi (IaC in general-purpose languages). Terraform's advantages are its provider ecosystem (thousands of cloud services), its declarative model, and its portability across cloud providers.

Terraform's **module system** is the mechanism for reuse: a module is a directory of `.tf` files with defined inputs (variables) and outputs. Modules are to Terraform what functions are to programming — they encapsulate a piece of infrastructure with a clean interface so it can be instantiated multiple times with different arguments.

---

## Chunk 2 — Functional

### The Bootstrap Layer

Before any Terraform environment can store remote state, the S3 bucket and DynamoDB lock table must exist. This is the bootstrap problem: you need Terraform to create the state backend, but Terraform needs the state backend to run. The solution is a one-time bootstrap directory (`infra/bootstrap/`) that runs with local state. It creates:

- An S3 bucket (`docuvault-terraform-state-<account-id>`) with versioning, AES-256 encryption, and all public access blocked.
- A DynamoDB table (`docuvault-terraform-locks`) with a `LockID` string hash key — the exact schema Terraform's S3 backend expects for pessimistic locking.

The bootstrap uses a `lifecycle { prevent_destroy = true }` block on the S3 bucket so that even a `terraform destroy` on bootstrap cannot delete the state bucket and corrupt all downstream environments.

After bootstrap, each environment's `backend.tf` points to this bucket with a unique key per environment (`environments/dev/terraform.tfstate`, `environments/preprod/terraform.tfstate`, `environments/prod/terraform.tfstate`). One bucket, three isolated state files.

### Module Composition Pattern

The fourteen modules are each a self-contained directory with `main.tf`, `variables.tf`, and `outputs.tf`. The environment's `main.tf` instantiates them in sequence, threading outputs from one module into inputs of the next:

```
bootstrap/       ← one-time; creates state bucket
modules/vpc/     ← outputs: vpc_id, public_subnet_ids, private_subnet_ids
modules/ecr/     ← outputs: repository_urls (map)
modules/sns/     ← outputs: processing_events_topic_arn
modules/sqs/     ← inputs: sns_processing_topic_arn → outputs: queue ARNs/URLs
modules/alb/     ← inputs: vpc_id, subnet_ids → outputs: alb_dns_name, target_group_arns, ecs_tasks_sg_id
modules/ecs-cluster/ ← inputs: subnet_ids, sg_ids → outputs: cluster_id, capacity_provider_name, task_execution_role_arn
modules/cognito/ ← outputs: user_pool_id, client_id, domain
modules/dynamodb/ ← outputs: table names and ARNs
modules/s3/      ← outputs: bucket names, ARNs, domain
modules/rds/     ← inputs: vpc_id, subnet_ids, ecs_tasks_sg_id
modules/lambda/  ← inputs: queue URLs/ARNs, bucket names/ARNs, table names/ARNs
modules/cloudfront/ ← inputs: alb_dns_name → outputs: distribution domain
modules/ecs-service/ ← instantiated twice (bff, webui); inputs: cluster outputs + alb outputs + image URIs
```

Data flows strictly downward: no module imports from the environment layer; outputs bubble up to the environment and are passed sideways to sibling modules.

### Resolving the SNS–SQS Circular Dependency

A circular dependency would occur if the SQS module tried to create the SNS subscription (which needs the SNS ARN) *and* the SNS module tried to reference the SQS ARN (which needs the SQS queue). The resolution splits ownership:

1. `modules/sns` creates only the SNS topic and exports its ARN.
2. `modules/sqs` receives the SNS ARN as a variable input and uses it solely to write the SQS queue policy (allowing SNS to publish to the notification queue). It does **not** create the subscription.
3. The environment's `main.tf` creates the actual `aws_sns_topic_subscription` resource after both modules have been instantiated — it has both ARNs in scope and no dependency cycle exists.

### VPC Topology

The VPC module creates a `/16` CIDR (e.g., `10.0.0.0/16` for dev), then carves out subnets using `cidrsubnet()`. Public subnets get offsets 1, 2 (giving `10.0.1.0/24`, `10.0.2.0/24`); private subnets get offsets 10, 11 (`10.0.10.0/24`, `10.0.11.0/24`). This leaves room for future tiers without renumbering.

The public subnets host the ALB and, in dev, the ECS EC2 instances. The private subnets host only RDS. ECS tasks on public subnets can reach RDS on private subnets via in-VPC routing with no NAT Gateway needed. Gateway VPC endpoints for S3 and DynamoDB are attached to both route tables, which means all API calls to S3 or DynamoDB leave over AWS's private backbone — no internet egress charges and no NAT required.

### ALB and Path-Based Routing

The ALB module converts the `services` list variable into a map and uses `for_each` to create one target group per service. Listener rules are created for every service except the `default_service` (which is the ALB's default action, not a rule). The BFF rule matches `/api/*` at priority 10 (evaluated first); the webui acts as the catch-all. In dev, the HTTP listener forwards directly. When an ACM certificate ARN is provided (preprod/prod), the HTTP listener redirects to HTTPS and a new HTTPS listener handles forwarding — this is controlled by a single `var.acm_certificate_arn` nullable variable and a `dynamic "redirect"` block.

ECS tasks on EC2 use bridge networking with `hostPort = 0` (dynamic port assignment). The target group is of type `instance`, so it registers the EC2 instance IP and the dynamically assigned host port.

### ECS Cluster and Capacity Provider

The cluster module provisions:
- The ECS cluster resource.
- A Launch Template referencing the latest ECS-optimized Amazon Linux 2023 AMI (fetched via a `data "aws_ami"` filter at plan time).
- An Auto Scaling Group spanning the public subnets.
- A Capacity Provider that links the ASG to the cluster and enables managed scaling targeting 80% CPU/memory.
- A shared task execution IAM role (allows ECR pulls and CloudWatch log writes) — used by every service.

The ASG's `desired_capacity` is managed by ECS's capacity provider after initial creation, so the Terraform config uses `lifecycle { ignore_changes = [desired_capacity, tag] }` to prevent Terraform from fighting ECS on every subsequent plan.

### ECS Service Module

The `ecs-service` module is the key reusable unit — it is instantiated once per deployed service. It creates:
- A CloudWatch log group (`/ecs/<cluster>/<service-name>`).
- An ECS task definition (bridge network mode, EC2 compatibility, jsonencoded container definitions).
- An ECS service wired to the ALB target group via a `dynamic "load_balancer"` block.
- Rolling deployment configured with 50% minimum healthy / 200% maximum — meaning ECS brings up new tasks before draining old ones.
- A deployment circuit breaker with automatic rollback: if health checks fail during a deploy, ECS reverts to the previous task definition.

CI/CD owns `task_definition` and `desired_count` after the first deploy, so `lifecycle { ignore_changes = [...] }` prevents Terraform from reverting CI/CD updates.

### Lambda Functions

Three Lambdas share a single IAM role with least-privilege permissions:

- **ocr-trigger** (128 MB, 30 s timeout): triggered by `s3:ObjectCreated:*` events on the documents bucket. Sends a message to the processing SQS queue. The S3 notification and `aws_lambda_permission` granting S3 invoke access are both in this module.
- **thumbnail-generator** (512 MB, 60 s timeout): higher memory because PDF rendering is CPU-intensive. Triggered on demand or by SQS.
- **scheduled-cleanup** (128 MB, 300 s timeout): EventBridge cron at `cron(0 1 * * ? *)` (01:00 UTC daily) scans DynamoDB for expired entries beyond the TTL window.

All three deploy with a `placeholder.zip` file that Terraform knows about via `source_code_hash`. CI/CD replaces the zip with the real bundle at deploy time without Terraform needing to re-plan.

### CloudFront Cache Behaviors

Three ordered behaviors on the CloudFront distribution correspond to the three traffic types:

| Path | Behavior | TTL | Rationale |
|------|----------|-----|-----------|
| `/_next/static/*` | Cached at edge | 1 year (31,536,000 s) | Content-hashed filenames; safe to cache forever |
| `/api/*` | Bypass cache | 0 s | API responses are user-specific and dynamic |
| `/*` (default) | Short cache | 0–60 s | SSR pages may be personalized; forward Auth header |

The `acm_certificate_arn_us_east_1` variable is nullable — when null, CloudFront uses its default `*.cloudfront.net` certificate. When provided, a `dynamic "viewer_certificate"` block switches to the custom cert. Two mutually exclusive `dynamic` blocks handle the two cases (Terraform does not have an `if/else` on resource blocks, so two `dynamic` blocks each gated on opposite conditions is the idiomatic pattern).

---

## Chunk 3 — Product

### What the User Experiences

From a user's perspective, this infrastructure is invisible — which is exactly the point. When a user uploads a document, clicks search, or views a notification, they are interacting with an application that runs reliably across many moving parts. The infrastructure layer is what makes that reliability possible.

More concretely, the infrastructure created in this session enables:

**Fast, globally distributed page loads.** CloudFront caches Next.js static assets (JavaScript bundles, CSS, fonts) at edge locations worldwide. A user in Mumbai and a user in Paris both get the same `/_next/static/` chunk from a nearby edge node rather than waiting for a round-trip to the origin server in `ap-south-1`. The one-year TTL means the asset is served from cache on every subsequent visit until the content hash changes (which only happens on a new deploy).

**A single URL for everything.** The user never sees `/api/` vs. the frontend — both live under the same CloudFront domain. The ALB silently routes `/api/*` to the BFF and everything else to the Next.js webui. This is invisible to the user but essential: it avoids CORS issues, simplifies auth cookie handling, and lets the frontend use relative URLs.

**Resilient document processing.** When a document is uploaded, the user sees a "Processing..." status. Behind the scenes, S3 fires an event to the ocr-trigger Lambda, which enqueues a message to SQS. If the processing-service is temporarily unavailable, the message waits in SQS (up to 24 hours). If processing fails three times, the message moves to the DLQ and a CloudWatch alarm fires. The user's document is never silently lost.

**Authentication that just works.** Cognito manages password policy, MFA options, email verification, and OAuth flows. The infrastructure provisions the user pool, app client, and a `docuvault-dev` auth domain — the auth service just calls Cognito APIs rather than implementing any of that plumbing itself.

**Consistent environments.** The `dev`, `preprod`, and `prod` environments are structurally identical — they use the same modules, the same module composition order, and the same naming conventions. A bug found in dev can be traced to the same resource type in prod without relearning the layout. This consistency reduces deployment surprises.

### How It Fits the DocuVault Product Vision

DocuVault's core promise is: upload a document, get searchable, intelligently classified results back, quickly. Every layer of infrastructure created here serves that promise:

- VPC + ALB: traffic enters cleanly and reaches the right service.
- ECS + ECR: containerized services deploy reliably and roll back automatically.
- S3: documents are stored durably without touching the backend server.
- SQS + Lambda: OCR processing is decoupled and reliable.
- RDS + DynamoDB: structured metadata and ephemeral job state coexist.
- Cognito: users are authenticated without the team building an auth system.
- CloudFront: the frontend is fast regardless of where the user is located.

---

## Chunk 4 — System Design

### Pattern: Modular IaC with Explicit Output Wiring

The infrastructure is organized as a library of single-responsibility modules, each exposing a minimal public surface (outputs). The environment entry point (`environments/dev/main.tf`) acts as the composition root — it instantiates every module and threads their outputs together explicitly. There is no implicit magic: every connection between modules is a named variable assignment you can read linearly in `main.tf`.

This is analogous to the Dependency Injection pattern in application code: modules declare their dependencies as inputs (constructor arguments) rather than reaching into global state. The environment is the DI container.

**Trade-off:** Explicit wiring is verbose. Adding a new module means updating the environment `main.tf` in all three environments. The alternative — a root module that absorbs all resources — becomes a monolith that is hard to reason about and slow to plan (every resource is in one dependency graph). The explicit wiring was judged the better trade-off for a project at DocuVault's scale.

### Pattern: Directory-per-Environment over Workspaces

Terraform Workspaces allow multiple state files from a single directory, selected via `terraform workspace select`. They are tempting for multi-environment setups. They were deliberately avoided here because:

1. The wrong workspace selection cannot be detected before `apply` runs — a `terraform apply` on the prod workspace while dev was intended is catastrophic and silent.
2. Workspaces share the same variable values file; environment-specific sizing (e.g., `db.t3.micro` in dev vs. `db.r6g.large` in prod) requires conditionals rather than clean separate files.
3. Separate directories make it structurally impossible to accidentally operate on the wrong environment: `cd infra/environments/prod` is an explicit and visible choice.

### Pattern: No NAT Gateway (Free-Tier Network Topology)

A typical three-tier VPC places all application servers in private subnets behind a NAT Gateway so they can reach the internet (ECR, SQS, SNS, S3 APIs) without being directly addressable. NAT Gateways cost ~$32/month — a non-starter for a $0/month budget.

The solution has two parts:
- **ECS tasks go in public subnets.** They get public IPs but are unreachable from the internet because their security group only accepts inbound traffic from the ALB security group. The internet can reach the ALB; the ALB can reach the ECS tasks; the internet cannot reach ECS tasks directly.
- **S3 and DynamoDB get Gateway VPC endpoints.** These are free and route API calls to these services over AWS's private network — no internet hop, no NAT needed.

SQS, SNS, ECR, and CloudWatch are still reached over the public internet (via the tasks' public IP), but that traffic is outbound and has no additional cost. The only concern is that ECS pull from ECR is also outbound, but ECR free tier is 500 MB/month and lifecycle policies keep usage below that.

### Pattern: Single ALB with Path-Based Routing

A dedicated ALB per service (one for webui, one for bff) would be cleaner in isolation but costs ~$16/month each in ALB-hour charges. A single ALB serving both services via path-based routing costs the same as one ALB and scales to additional services by adding listener rules. The ALB module makes this easy: the `services` list variable drives both target group creation and listener rule creation via `for_each`.

### Interaction with the Rest of the System

The infrastructure created here is the platform that every microservice runs on. When the document-service team adds a new endpoint, they deploy a new container image to ECR and update the ECS task definition — the ALB, VPC, and security groups do not change. When the processing-service team needs a new DynamoDB table, they add it to the `dynamodb` module and re-apply the environment.

The contract between IaC and application code is narrow: environment variable names. The ECS service module injects environment variables from the `environment_variables` map in the environment's `main.tf`. Application services read those variables at startup (validated by Zod). Changing an environment variable name requires coordinating a Terraform change and an application code change — this is intentional coupling, and it is the only coupling.

### What Changes at Scale

At 100x the current load:

- **ECS:** The ASG's `asg_max` increases; ECS's capacity provider manages scaling automatically. No module changes needed.
- **RDS:** Upgrade `instance_class` from `db.t3.micro` to a larger class and enable `multi_az = true` for failover. The module variable already exists — it's a one-line change per environment.
- **ALB:** A single ALB scales horizontally by AWS's internal mechanism — no operator action needed up to very high request rates.
- **NAT Gateway:** At scale, ECS tasks would move to private subnets and NAT Gateways would be added. The VPC module already creates private subnets; the ECS cluster module's `subnet_ids` variable would switch from `public_subnet_ids` to `private_subnet_ids`. Interface endpoints for SQS, SNS, and ECR would replace outbound public routing.
- **Multi-Region:** The module structure supports this — each region would get its own environment directory with `provider` configured for that region.
- **Multi-Tenant:** Tenants could be isolated at the VPC level (separate VPC per tenant, VPC peering) or at the IAM policy level (per-tenant S3 prefixes, per-tenant DynamoDB table). The module interface does not preclude either approach.

---

## Chunk 5 — Fundamentals

### Terraform Modules

**What they are:** A directory containing `.tf` files. Called with `module "name" { source = "..." ... }`. Accept variables as call arguments; expose outputs that callers can reference as `module.name.output_name`.

**Why not one big file:** A flat file of 1,000+ resource blocks has no grouping, no reuse, and no encapsulation. Modules impose a boundary: the caller cannot reference internal resources — only what the module explicitly exports via `output` blocks. This is the same encapsulation principle as a public API in application code.

### `for_each` vs `count`

Both create multiple instances of a resource. `count` indexes instances numerically (`resource[0]`, `resource[1]`). `for_each` indexes by a map key or set element (`resource["bff"]`, `resource["web"]`). **The critical difference:** if you add an item in the middle of a `count` list, Terraform renumbers all following instances and re-creates them. With `for_each` on a set, adding an element only creates the new instance — existing instances are untouched.

This is why the ECR module uses `for_each = toset(var.repositories)` and the ALB module uses `for_each = local.services_map`. Removing `"auth-service"` from the repositories list destroys only that ECR repo, not everything after it in a numbered list.

### `locals`

`locals` are computed values that are referenced multiple times in the same module. They eliminate repetition and give meaningful names to derived values. The dev `main.tf` uses a large `locals` block to centralize sizing constants (`task_cpu`, `rds_instance_class`, `asg_min`) and computed values (`ecr_base`, `webui_image`). Changing `local.task_cpu` updates every module call that references it — one edit, not six.

### `data` Sources

`data` blocks query existing infrastructure rather than creating it. Two examples in this codebase:

- `data "aws_ami" "ecs_optimized"` — fetches the latest ECS-optimized Amazon Linux 2023 AMI ID from AWS at plan time. The AMI ID changes as AWS releases updates; using a data source means the infrastructure always uses the current recommended AMI without manual updates.
- `data "aws_caller_identity" "current"` — retrieves the AWS account ID of the currently authenticated identity. This is used to construct ECR image URIs without hardcoding the account number.

### `dynamic` Blocks

`dynamic` blocks conditionally generate nested blocks inside a resource. The ALB module uses one to generate the `redirect` action inside the HTTP listener only when an ACM certificate ARN is provided:

```hcl
dynamic "redirect" {
  for_each = var.acm_certificate_arn != null ? [1] : []
  content { ... }
}
```

The `for_each = [1]` (one iteration) pattern is idiomatic for "include this block once if condition is true". The CloudFront module uses two mutually exclusive `dynamic "viewer_certificate"` blocks — one for custom cert, one for the CloudFront default cert — because HCL has no `if/else` at the block level.

### `lifecycle` Blocks

`lifecycle` meta-arguments control how Terraform handles resource state changes:

- `prevent_destroy = true` (S3 state bucket): Terraform will error before destroying this resource, even on `terraform destroy`. Protects the state bucket from accidental deletion.
- `create_before_destroy = true` (ALB target groups, launch template): Terraform creates the replacement before destroying the old one, avoiding downtime. Without this, Terraform would destroy first, causing a gap.
- `ignore_changes = [desired_capacity, tag]` (ASG): ECS's capacity provider and AWS Auto Scaling modify `desired_capacity` at runtime. Without `ignore_changes`, every `terraform plan` would show this as drift and try to reset it to the declared value, fighting ECS.
- `ignore_changes = [task_definition, desired_count]` (ECS service): CI/CD updates the task definition ARN and desired count; Terraform should not revert those changes on the next infrastructure plan.

### `cidrsubnet()`

Built-in Terraform function: `cidrsubnet(prefix, newbits, netnum)`. Given a CIDR prefix, adds `newbits` bits to the prefix length and selects the `netnum`-th subnet. Example: `cidrsubnet("10.0.0.0/16", 8, 1)` → `10.0.1.0/24`. This is used in the VPC module to generate subnet CIDRs deterministically from the VPC CIDR, ensuring consistency and predictability without managing a list of hard-coded CIDRs.

### `jsonencode()`

Terraform's built-in function to serialize HCL values to JSON strings. Used for IAM policies, ECS container definitions, and SQS redrive policies — all of which the AWS API expects as JSON strings, not HCL objects. Using `jsonencode()` keeps policy definitions as native HCL objects (with proper syntax highlighting, easy variable interpolation, and no JSON string escaping), then serializes them at apply time.

### `base64encode()`

Used in the ECS launch template's `user_data`. EC2 user data must be base64-encoded. The `base64encode()` function takes a multiline string (the shell script that writes ECS cluster config to `/etc/ecs/ecs.config`) and encodes it. The heredoc syntax (`<<-EOT ... EOT`) allows a clean multiline string without string concatenation.

### `toset()`

Converts a list to a set, which is required for `for_each`. Sets have no defined order and no duplicate elements. The ECR module receives `var.repositories` as a `list(string)` and converts it with `toset()` before passing it to `for_each` — this allows the caller to declare repositories as a natural list while the module internally uses stable set semantics.

### Ternary Expressions

HCL uses the same ternary form as most languages: `condition ? value_if_true : value_if_false`. Used throughout — for example, in the ALB module to select whether to forward or redirect on the HTTP listener (`var.acm_certificate_arn != null ? "redirect" : "forward"`), and to choose the active listener ARN for routing rules based on whether HTTPS is enabled.

### S3 Backend Configuration

The `backend "s3"` block in each environment's `backend.tf` configures Terraform remote state. Notable: backend configuration cannot reference Terraform variables or locals — all values must be literals. This is why the account ID placeholder in `backend.tf` requires manual substitution (`<YOUR_ACCOUNT_ID>`). The `encrypt = true` flag enables server-side encryption for the state file (the S3 bucket itself also has SSE configured, providing defense in depth). The `dynamodb_table` enables state locking: before any `plan` or `apply`, Terraform writes a lock record to DynamoDB; if it finds an existing record, it waits or errors rather than proceeding concurrently.
