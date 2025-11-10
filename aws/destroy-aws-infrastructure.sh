#!/bin/bash
set -e

source .env.prod

ssm_node_id=$(
  aws ec2 describe-instances \
      --filters Name=tag-value,Values=${SSM_NODE_NAME} \
      --query Reservations[].Instances[].InstanceId \
      --output text
)
ssm_node_sg_id=$(
  aws ec2 describe-security-groups \
    --filters Name=group-name,Values=${SSM_NODE_SECURITY_GROUP_NAME} \
    --query  SecurityGroups[].GroupId \
    --output text
)
rds_sg_id=$(
  aws ec2 describe-security-groups \
    --filters Name=group-name,Values=${RDS_SECURITY_GROUP_NAME} \
    --query  SecurityGroups[].GroupId \
    --output text
)
vpc_endpoint_ids=$(
  aws ec2 describe-vpc-endpoints \
    --filters Name=service-name,Values=com.amazonaws.${REGION}.ssm,com.amazonaws.${REGION}.ssmmessages,com.amazonaws.${REGION}.s3 \
    --query VpcEndpoints[].VpcEndpointId \
    --output text
)

vpc_id=$(
  aws ec2 describe-vpcs \
      --filters Name=tag:Name,Values=${VPC_NAME} \
      --query Vpcs[].VpcId \
      --output text
)

subnets=$(
  aws ec2 describe-subnets \
      --filters Name=vpc-id,Values=${vpc_id} \
      --query Subnets[].SubnetId \
      --output text
)

private_rt_id=$(
  aws ec2 describe-route-tables \
    --filters Name=vpc-id,Values=${vpc_id} \
    --query RouteTables[].RouteTableId \
    --output text
)

ssm_node_role_policies_arn=$(
  aws iam list-attached-role-policies \
    --role-name ${SSM_NODE_ROLE_NAME} \
    --query AttachedPolicies[].PolicyArn\
    --output text
)

rds_role_policies_arn=$(
  aws iam list-attached-role-policies \
    --role-name ${RDS_ROLE_NAME} \
    --query AttachedPolicies[].PolicyArn\
    --output text
)

# show config blog
echo -e "
               ssm_node_id: ${ssm_node_id}\n\
            ssm_node_sg_id: ${ssm_node_sg_id}\n\
                 rds_sg_id: ${rds_sg_id}\n\
          vpc_endpoint_ids: ${vpc_endpoint_ids}\n\
                    vpc_id: ${vpc_id}\n\
                   subnets: ${subnets}\n\
             private_rt_id: ${private_rt_id}\n\
ssm_node_role_policies_arn: ${ssm_node_role_policies_arn}\n\
     rds_role_policies_arn: ${rds_role_policies_arn}\n"

###############################################################################
# destroy infrastructure

aws rds delete-db-instance \
  --db-instance-identifier ${DB_INSTANCE_ID} \
  --skip-final-snapshot \
  --output yaml

sleep 120

aws rds delete-db-subnet-group \
  --db-subnet-group-name ${DB_SUB_GROUP_NAME} \
  --output yaml

aws rds delete-db-parameter-group \
  --db-parameter-group-name ${DB_PARAMETER_GROUP_NAME} \
  --output yaml

aws ec2 terminate-instances \
  --instance-ids ${ssm_node_id} \
  --output yaml

aws iam remove-role-from-instance-profile \
  --instance-profile-name ${SSM_NODE_INSTANCE_PROFILE_NAME} \
  --role-name ${SSM_NODE_ROLE_NAME} \
  --output yaml

aws iam delete-instance-profile \
  --instance-profile-name ${SSM_NODE_INSTANCE_PROFILE_NAME} \
  --output yaml

sleep 120

aws ec2 delete-security-group \
  --group-id ${ssm_node_sg_id} \
  --output yaml

aws ec2 delete-security-group \
  --group-id ${rds_sg_id} \
  --output yaml

aws ec2 delete-vpc-endpoints \
  --vpc-endpoint-ids ${vpc_endpoint_ids} \
  --output yaml

aws iam detach-role-policy \
  --role-name ${SSM_NODE_ROLE_NAME} \
  --policy-arn ${ssm_node_role_policies_arn} \
  --output yaml

aws iam delete-role \
  --role-name ${SSM_NODE_ROLE_NAME} \
  --output yaml

aws iam detach-role-policy \
    --role-name ${RDS_ROLE_NAME} \
    --policy-arn ${rds_role_policies_arn}

aws iam delete-role \
  --role-name ${RDS_ROLE_NAME} \
  --output yaml

for subnet in ${subnets[@]}
do
aws ec2 delete-subnet \
    --subnet-id $subnet
done

aws ec2 delete-vpc \
    --vpc-id ${vpc_id}
