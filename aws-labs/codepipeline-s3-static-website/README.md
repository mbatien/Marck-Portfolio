# CI/CD for a static website with AWS CodePipeline

**Services:** S3, CodePipeline, CodeBuild, IAM, EventBridge  ·  **Tools:** AWS Console  ·  **Completed:** 2026-10-22

## Goal

Automate deployment of a static website. Whenever `index.html` changes in a source S3 bucket, a pipeline picks up the change, runs a CodeBuild job, and publishes the file to a second S3 bucket that serves the site publicly.

## Architecture

```
  Source S3 bucket            CodePipeline                     Deployment S3 bucket
  (versioned)        ──►  Source ──► Build (CodeBuild)  ──►   (static website, public read)
  index.html change         │          aws s3 cp index.html          │
       │                    │                                        ▼
       └── EventBridge rule starts the pipeline           http://<bucket>.s3-website-us-east-1.amazonaws.com
```

There is no separate Deploy stage: the build step itself copies the file to the website bucket.

| Resource | Name |
| --- | --- |
| Source bucket | `<source-bucket>` (existing, holds the site source) |
| Deployment bucket | `<deployment-bucket>` |
| Pipeline | `webapp-pipeline` |
| CodeBuild project | `webapp-build-project` |

## Solution (Console)

### 1. Prepare the source bucket
1. **S3 → `<source-bucket>`** and note the exact name of the source object (used as the pipeline's object key).
2. **Properties → Bucket Versioning → Edit → Enable.** CodePipeline only accepts a versioned bucket as an S3 source.

### 2. Create the website bucket
1. **S3 → Create bucket**: name `<deployment-bucket>`, region `us-east-1`.
2. Uncheck **Block all public access** and acknowledge the warning.
3. **Properties → Static website hosting → Edit**: enable, host a static website, index document `index.html`.
4. **Permissions → Bucket policy**: paste [`bucket-policy.json`](bucket-policy.json) (public `s3:GetObject` on the bucket's objects).

### 3. Create the pipeline
**CodePipeline → Create pipeline → Build custom pipeline**
1. **Pipeline settings:** name `webapp-pipeline`, new service role.
2. **Source stage:** provider Amazon S3, bucket `<source-bucket>`, object key from step 1. Change detection: **Amazon EventBridge** (starts the pipeline automatically when the object changes).
3. **Build stage:** provider AWS CodeBuild → **Create project**:
   - Name `webapp-build-project`
   - Environment: managed image, Amazon Linux, image `aws/codebuild/amazonlinux2-x86_64-standard:4.0`, **Always use the latest image for this runtime version**
   - Compute: 2 vCPUs, 4 GiB memory
   - New service role
   - Buildspec: **Insert build commands**, using [`buildspec.yml`](buildspec.yml)
4. **Deploy stage:** skipped (the build step publishes the file).
5. **Create pipeline**, which triggers the first run.

### 4. Give CodeBuild access to the website bucket
The role the console creates for CodeBuild only covers the pipeline's artifact bucket, so the copy needs permission on the website bucket too. **IAM → Roles → `codebuild-webapp-build-project-service-role` → Add permissions**, using [`codebuild-s3-policy.json`](codebuild-s3-policy.json).

## Verification

- Both pipeline stages show **Succeeded**.
- `index.html` is in the deployment bucket:
  ```bash
  aws s3 ls s3://<deployment-bucket>/
  ```
- The site loads from the website endpoint:
  ```bash
  curl http://<deployment-bucket>.s3-website-us-east-1.amazonaws.com
  ```
- Upload a changed `index.html` to the source bucket: the pipeline starts on its own and the website shows the new version.

## Troubleshooting

Common failure points in this setup and their fixes:

| Symptom | Cause | Fix |
| --- | --- | --- |
| Source stage fails, or the bucket is rejected when creating the pipeline | Source bucket not versioned | Enable Bucket Versioning on the source bucket |
| Bucket policy won't save (`Access denied`) | Block Public Access still on | Turn off Block Public Access on the deployment bucket first |
| Build fails with `AccessDenied` on `PutObject` | CodeBuild role can't write to the website bucket | Attach `codebuild-s3-policy.json` to the CodeBuild role, then **Retry** the stage |
| Site returns 403 Forbidden | No public-read bucket policy | Add `bucket-policy.json` |
| Browser downloads the page instead of showing it | Wrong `Content-Type` | `aws s3 cp` sets `text/html` automatically; if uploading another way, set it explicitly |

<!-- Add anything that went wrong during your own run here. -->

## What I learned

- A CodePipeline S3 source needs a **versioned** bucket, and EventBridge change detection is what makes the pipeline run on every upload.
- CodeBuild can act as the deploy step by running AWS CLI commands, but its IAM role must be granted access to every bucket it writes to. Least privilege means granting only `s3:PutObject` on that one bucket.
- Making an S3 site public takes two separate settings: Block Public Access off, and a bucket policy that grants `s3:GetObject`.

## Screenshots

Save these in [`screenshots/`](screenshots/) and blur account IDs and usernames:

1. `01-pipeline-succeeded.png`: the pipeline with both stages green
2. `02-codebuild-logs.png`: build logs showing the `aws s3 cp` upload
3. `03-website-hosting.png`: the bucket's Static website hosting settings
4. `04-website-live.png`: the site open in the browser
5. `05-auto-trigger.png`: (optional) a second run started automatically after changing `index.html`
