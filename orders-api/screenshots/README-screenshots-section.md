## Screenshots

### Pipeline
The pipeline runs Source (GitHub) → Build (CodeBuild) → Deploy (Amazon ECS). Production deployments go through a manual approval stage (not pictured).

![Pipeline overview: Source, Build and Deploy all succeeded](screenshots/01-pipeline-overview.png)

### Problem I hit and fixed: buildspec path
The first builds failed at `DOWNLOAD_SOURCE` because CodeBuild couldn't find `buildspec.yml` at the repo root. The app lives in `orders-api/`, so I pointed the project at `orders-api/buildspec.yml`, and the next build succeeded.

![CodeBuild YAML_FILE_ERROR: buildspec.yml not found](screenshots/02-buildspec-error.png)
![CodeBuild build succeeded using orders-api/buildspec.yml](screenshots/03-codebuild-success.png)

### Separate dev and prod environments
![ECS clusters: orders-prod running 3 tasks, orders-dev running 1](screenshots/04-ecs-clusters-dev-prod.png)

### Rollback test
To prove automatic rollback works, I pushed a commit that deliberately made the `/health` check fail ("test: temporarily fail /health in ECS to test rollback"). ECS detected the unhealthy deployment and rolled back to the last good task definition, so the service stayed up.

![Pipeline Deploy stage marked Rollback after the failing commit](screenshots/05-pipeline-rollback.png)
![CodePipeline: the new deployment has failed and rolled back](screenshots/06-deployment-failed-rolled-back.png)
![ECS tasks: orders-dev:5 stopped while orders-dev:4 keeps running](screenshots/07-tasks-v5-stopped-v4-running.png)
![ECS service: rollback successful, back on orders-dev:4](screenshots/08-service-rollback-successful.png)
