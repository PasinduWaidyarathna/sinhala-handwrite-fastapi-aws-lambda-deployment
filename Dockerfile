# Dockerfile for AWS Lambda Python 3.9 with FastAPI and TensorFlow
FROM public.ecr.aws/lambda/python:3.9

# Copy model artifacts
COPY models/ /var/task/models/

# Copy application code
COPY app.py /var/task/

# Install dependencies
COPY requirements.txt /var/task/
RUN pip3 install -r requirements.txt --target "/var/task"

# Set AWS Lambda handler
CMD ["app.handler"]