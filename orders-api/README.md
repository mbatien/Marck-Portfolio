# Project 2: Orders API with an AWS CI/CD pipeline

A small REST API for orders (Python, FastAPI, PostgreSQL), shipped by an AWS-native pipeline: every push to `main` that touches `orders-api/` is tested, built into a container image, pushed to ECR and rolled out to the ECS Fargate service from [Project 1](../terraform-platform/).

```
GitHub (push to main)
   │  CodeConnections
   ▼
CodePipeline ── Source ──► Build (CodeBuild) ──────────────────────► Deploy (Amazon ECS)
                            lint → tests on PostgreSQL 16              rolling update of orders-dev,
                            → docker build → push to ECR               circuit breaker rolls back failures
                            → imagedefinitions.json
```

## The API

| Method | Path | What it does |
| --- | --- | --- |
| GET | `/` | Service name, version, environment |
| GET | `/health` | Liveness for the ALB health check (no database call) |
| GET | `/ready` | Readiness: checks the database connection |
| GET | `/orders?limit=50` | Newest orders first |
| POST | `/orders` | Create an order: `{"customer","item","quantity","unit_price"}` |
| GET | `/orders/{id}` | One order |
| PATCH | `/orders/{id}` | Change status: `pending`, `paid`, `shipped`, `cancelled` |
| DELETE | `/orders/{id}` | Delete an order |
| GET | `/docs` | Interactive API docs |

It reads the variables the ECS task definition already injects: `DB_HOST`, `DB_PORT`, `DB_NAME` (plain environment) and `DB_USERNAME`, `DB_PASSWORD` (from Secrets Manager). It connects with TLS (`sslmode=require`), because RDS for PostgreSQL 15+ requires it, and creates its table on start-up.

## Run it locally

```bash
cd orders-api
docker compose up --build        # API on http://localhost:8080, PostgreSQL on 5432
```

Run the tests (needs the compose database running):

```bash
pip install -r requirements-dev.txt
DB_SSLMODE=disable pytest -q
```

## Files

| File | Purpose |
| --- | --- |
| `app/main.py` | API routes and request validation |
| `app/db.py` | Connection pool, connection string, table schema |
| `tests/test_api.py` | Tests against a real PostgreSQL |
| `Dockerfile` | Single-stage build on python:3.12-slim, runs as a non-root user on port 8080 |
| `buildspec.yml` | CodeBuild steps: lint, test, build, push, write `imagedefinitions.json` |
| `iam/codebuild-ecr-policy.json` | Extra permissions the CodeBuild role needs to push to ECR |
| `docker-compose.yml` | Local API + database |

---

## Set up the pipeline (AWS Console)

Region: **us-east-1** everywhere.

### Step 1: Point the infrastructure at the app

The app runs as a non-root user, which can't listen on port 80, so it uses **8080** and serves its health check at **/health**. Three changes in `terraform-platform/` (already made in this repository):

- `envs/dev/terraform.tfvars` (and `envs/prod/`): `container_port = 8080`, `health_check_path = "/health"`
- `modules/ecs-service/main.tf`: `ignore_changes = [desired_count, task_definition]` on the service, so `terraform apply` doesn't roll back the image the pipeline deployed.

Changing the port replaces the target group, and that can't be done in place while the load balancer uses it. Dev is disposable, so recreate it:

```powershell
cd terraform-platform\envs\dev
terraform destroy
terraform plan -out=tfplan
terraform apply tfplan
```

Until the pipeline's first run, the service still runs the placeholder nginx image (which listens on 80, not 8080), so the site returns **503**. That's expected.

### Step 2: Connect AWS to GitHub

1. Open **Developer Tools → Settings → Connections** (search "CodePipeline", then **Settings → Connections** in the left menu).
2. **Create connection** → provider **GitHub** → name `github-mbatien` → **Connect to GitHub**.
3. **Install a new app** → sign in as **mbatien** → choose **Only select repositories → Marck-Portfolio** → **Install**.
4. **Connect**. The status must show **Available**.

### Step 3: Create the pipeline

**CodePipeline → Create pipeline → Build custom pipeline → Next.**

**Pipeline settings**
- Name: `orders-api-pipeline`
- Execution mode: **Queued**
- Service role: **New service role** (it includes the ECS deploy and `iam:PassRole` permissions)

**Source**
- Provider: **GitHub (via GitHub App)**
- Connection: `github-mbatien`, repository `mbatien/Marck-Portfolio`, default branch `main`
- Output artifact format: **CodePipeline default**
- Trigger: **Specify filter** → event type **Push** → branch `main` → **File paths: include `orders-api/**`**, so changes to Terraform alone don't redeploy the app.

**Build**
- Provider: **Other build providers → AWS CodeBuild** → **Create project** (opens a new window):
  - Project name: `orders-api-build`
  - Environment: **Managed image**, compute **EC2**, OS **Ubuntu**, runtime **Standard**, image `aws/codebuild/standard:7.0`
  - **Privileged: ON** (required to run Docker)
  - Service role: **New service role** (note its name, for example `codebuild-orders-api-build-service-role`)
  - **Additional configuration → Environment variables:**
    `REPOSITORY_URI` = `945360924569.dkr.ecr.us-east-1.amazonaws.com/orders-api-dev`
    (or run `terraform output ecr_repository_url` in `envs/dev`)
  - Buildspec: **Use a buildspec file**, name `orders-api/buildspec.yml`
  - Logs: **CloudWatch logs** on
  - **Continue to CodePipeline**
- Back in the wizard, keep the build type **Single build**.

**Test** (if shown): skip.

**Deploy**
- Provider: **Amazon ECS**
- Cluster: `orders-dev`, service: `orders-dev`
- Image definitions file: `imagedefinitions.json`

**Create pipeline.** It starts right away, and the first run **fails at Build**, because the CodeBuild role can't push to ECR yet. Step 4 fixes that.

### Step 4: Let CodeBuild push to ECR

1. **IAM → Roles →** `codebuild-orders-api-build-service-role`
2. **Add permissions → Create inline policy → JSON**, paste `iam/codebuild-ecr-policy.json`, name it `push-orders-api`, **Create policy**.
3. Back in CodePipeline: **Release change**.

### Step 5: Check it worked

- All three stages turn green. The deploy stage waits until ECS reports the new tasks healthy.
- `terraform output app_url` in `envs/dev`, then open `<app_url>/` and `<app_url>/docs`.
- Create an order:

```powershell
$url = terraform output -raw app_url
Invoke-RestMethod -Method Post -Uri "$url/orders" -ContentType "application/json" -Body '{"customer":"Ada","item":"keyboard","quantity":2,"unit_price":"49.99"}'
Invoke-RestMethod "$url/orders"
```

From now on, a push to `main` that changes `orders-api/` deploys automatically.

### Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| Build fails at `docker login` / `push` with AccessDenied | Step 4 policy missing, or `REPOSITORY_URI` wrong |
| Build fails with "Cannot connect to the Docker daemon" | Privileged mode is off on the CodeBuild project |
| Build fails at `docker push` with "tag invalid / already exists" | The ECR repo has immutable tags; each build uses a unique `<commit>-<build number>` tag, so check for a manual retry with an edited buildspec |
| Deploy stage runs a long time, then fails | New tasks fail the health check: check **ECS → orders-dev → Events** and the logs in `/ecs/orders-dev` |
| Tasks log `connection ... SSL` errors | `DB_SSLMODE` was set to `disable` somewhere other than local runs |
| Pipeline doesn't start on push | The commit didn't touch `orders-api/**`, or the connection isn't **Available** |

## Design choices (interview notes)

- **Tests run against a real PostgreSQL** in CodeBuild (a throwaway container), so the SQL is tested, not mocked.
- **Image tags = commit + build number.** ECR tags are immutable, so `latest` would fail on the second push, and every image traces back to a commit.
- **Base images from `public.ecr.aws`** avoid Docker Hub's anonymous pull rate limits, which shared CodeBuild IPs hit often.
- **Non-root container on 8080**, a slim single-stage build with cached dependency installs and no pip cache in the image.
- **`/health` doesn't touch the database.** If it did, one database blip would make the ALB mark every task unhealthy at once. `/ready` checks the database separately.
- **Terraform owns the infrastructure, the pipeline owns the image.** `ignore_changes = [task_definition]` stops `terraform apply` from reverting deployments. The trade-off: task-definition changes made in Terraform (new environment variables, for example) only take effect on the next pipeline deploy, because the deploy action copies the service's current task definition and swaps the image.
- **Rolling deploy + circuit breaker:** ECS keeps 100% of tasks running while new ones start, and rolls back automatically if the new ones keep failing.
- **CodeConnections, not CodeCommit:** CodeCommit is closed to new AWS customers. The GitHub App connection uses no personal access tokens.
