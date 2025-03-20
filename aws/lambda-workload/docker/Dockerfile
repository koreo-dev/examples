# Use AWS Lambda's Python 3.9 base image
FROM public.ecr.aws/lambda/python:3.9

# Set the working directory
WORKDIR /var/task

# Copy the function code directly to the expected path
COPY lambda_function.py .

# Install dependencies
RUN pip install boto3

# Set the CMD to use Lambda's entrypoint
CMD ["lambda_function.lambda_handler"]
