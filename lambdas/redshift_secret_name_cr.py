import boto3
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(event)
    return boto3.client('secretsmanager').describe_secret(SecretId=event['ResourceProperties']['SecretArn'])['Name']