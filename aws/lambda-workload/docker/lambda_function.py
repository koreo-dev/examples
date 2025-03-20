import json
import boto3
import os
import uuid

# Initialize the S3 client
s3_client = boto3.client("s3")

# Environment variable for the bucket name
BUCKET_NAME = os.environ.get("BUCKET_NAME", "your-default-bucket-name")


def lambda_handler(event, context):
    """
    AWS Lambda function that writes the event data to an S3 bucket.

    - The event data is saved as a JSON file.
    - The filename is a UUID to ensure uniqueness.
    """

    # Convert event to JSON string
    event_data = json.dumps(event, indent=2)

    # Generate a unique filename
    file_name = f"lambda-event-{uuid.uuid4()}.json"

    try:
        # Upload the file to S3
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=file_name,
            Body=event_data,
            ContentType="application/json",
        )

        return {
            "statusCode": 200,
            "body": json.dumps(
                {"message": "File uploaded successfully", "file_name": file_name}
            ),
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
