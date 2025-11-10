# import
source .env.prod

ssm_node_id=$(
  aws ec2 describe-instances \
    --filters Name=tag-value,Values=${SSM_NODE_NAME} \
    --query Reservations[].Instances[].InstanceId \
    --output text
)
rds_endpoint_address=$(
  aws rds describe-db-instances \
    --db-instance-identifier  ${DB_INSTANCE_ID} \
    --query DBInstances[].Endpoint[].Address \
    --output text
)

aws ssm start-session \
  --region ${REGION} \
  --target ${ssm_node_id} \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters host="${rds_endpoint_address}",portNumber="${DW_PORT}",localPortNumber="${DW_PORT}"