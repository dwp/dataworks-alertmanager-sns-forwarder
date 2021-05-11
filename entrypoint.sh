#!/bin/sh
set -e
echo "INFO: Checking container configuration..."

# Commented the below because as it currently stands no config files are needed in S3
# if [ -z "${ALERTMANAGER_SNS_FORWARDER_CONFIG_S3_BUCKET}" -o -z "${ALERTMANAGER_SNS_FORWARDER_CONFIG_S3_PREFIX}" ]; then
#   echo "ERROR: ALERTMANAGER_SNS_FORWARDER_CONFIG_S3_BUCKET and ALERTMANAGER_SNS_FORWARDER_CONFIG_S3_PREFIX environment variables must be provided"
#   exit 1
# fi
# S3_URI="s3://${ALERTMANAGER_SNS_FORWARDER_CONFIG_S3_BUCKET}/${ALERTMANAGER_SNS_FORWARDER_CONFIG_S3_PREFIX}"

# If either of the AWS credentials variables were provided, validate them
if [ -n "${AWS_ACCESS_KEY_ID}${AWS_SECRET_ACCESS_KEY}" ]; then
  if [ -z "${AWS_ACCESS_KEY_ID}" -o -z "${AWS_SECRET_ACCESS_KEY}" ]; then
    echo "ERROR: You must provide both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables if you want to use access key based authentication"
    exit 1
  else
    echo "INFO: Using supplied access key for authentication"
  fi

  # If either of the ASSUMEROLE variables were provided, validate them and configure a shared credentials fie
  if [ -n "${AWS_ASSUMEROLE_ACCOUNT}${AWS_ASSUMEROLE_ROLE}" ]; then
    if [ -z "${AWS_ASSUMEROLE_ACCOUNT}" -o -z "${AWS_ASSUMEROLE_ROLE}" ]; then
      echo "ERROR: You must provide both the AWS_ASSUMEROLE_ACCOUNT and AWS_ASSUMEROLE_ROLE variables if you want to assume role"
      exit 1
    else
      ASSUME_ROLE="arn:aws:iam::${AWS_ASSUMEROLE_ACCOUNT}:role/${AWS_ASSUMEROLE_ROLE}"
      echo "INFO: Configuring AWS credentials for assuming role to ${ASSUME_ROLE}..."
      mkdir ~/.aws
      cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[${AWS_ASSUMEROLE_ROLE}]
role_arn=${ASSUME_ROLE}
source_profile=default
EOF
      PROFILE_OPTION="--profile ${AWS_ASSUMEROLE_ROLE}"
    fi
  fi
  if [ -n "${AWS_SESSION_TOKEN}" ]; then
    sed -i -e "/aws_secret_access_key/a aws_session_token=${AWS_SESSION_TOKEN}" ~/.aws/credentials
  fi
else
  echo "INFO: Using attached IAM roles/instance profiles to authenticate with S3 as no AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY have been provided"
fi

# Commented the below because as it currently stands no config files are needed in S3
# echo "INFO: Copying cloudwatch-exporter configuration file(s) from ${S3_URI} to /etc/cloudwatch-exporter..."
# aws ${PROFILE_OPTION} s3 cp ${S3_URI}/agent-config.yml agent-config.yml
# aws ${PROFILE_OPTION} s3 cp ${S3_URI}/agent-application-config.yml agent-application-config.yml

export AWS_REGION=eu-west-2

echo "INFO: Starting the alertmanager SNS forwarder..."
exec /bin/alertmanager-sns-forwarder
