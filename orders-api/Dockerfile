# Orders API image (single-stage build).
# The base image comes from the ECR Public Gallery mirror of Docker Official Images
# to avoid Docker Hub pull rate limits in CodeBuild.
FROM public.ecr.aws/docker/library/python:3.12-slim


ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /srv

# Install dependencies first: this layer stays cached until requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code (changes most often, so it comes last)
COPY app ./app

# Create a non-root user and switch to it
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app
USER app

EXPOSE 8080

# "exec" makes uvicorn PID 1 so it receives SIGTERM and shuts down cleanly.
# --proxy-headers lets the app see the real client IP and https behind the ALB.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --proxy-headers --forwarded-allow-ips='*'"]
