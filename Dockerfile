FROM public.ecr.aws/lambda/python:3.9 AS builder

# Install AWS CLI and Python deps
RUN pip install --no-cache-dir awscli

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --target ./python

# Fetch model at build time
ARG MODEL_S3_URI
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION

# Configure AWS and pull model
RUN aws configure set aws_access_key_id     "${AWS_ACCESS_KEY_ID}" && \
    aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}" && \
    aws configure set region                "${AWS_REGION}" && \
    mkdir -p python/models && \
    aws s3 cp "${MODEL_S3_URI}" python/models/research_exp01.keras

COPY app.py .

# ───────── Final Stage ─────────
FROM public.ecr.aws/lambda/python:3.9

# Copy in just the packages, model, and code
COPY --from=builder /build/python /var/task
COPY --from=builder /build/app.py /var/task/app.py

# Lambda handler remains the same
CMD ["app.handler"]
# Dockerfile for AWS Lambda Python 3.9 with FastAPI and TensorFlow
#FROM public.ecr.aws/lambda/python:3.9
#
## Copy model artifacts
#COPY models/ /var/task/models/
#
## Copy application code
#COPY app.py /var/task/
#
## Install dependencies
#COPY requirements.txt /var/task/
#RUN pip3 install -r requirements.txt --target "/var/task"
#
## Set AWS Lambda handler
#CMD ["app.handler"]