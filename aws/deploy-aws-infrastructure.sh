#!/bin/bash
set -e

source .env.prod
###############################################################################
# vpc
vpc_id=$(
  aws ec2 create-vpc \
      --region ${REGION} \
      --no-amazon-provided-ipv6-cidr-block \
      --instance-tenancy default \
      --cidr-block ${VPC_CIDR} \
      --query Vpc.VpcId \
      --output text
)
echo $vpc_id

aws ec2 modify-vpc-attribute --vpc-id ${vpc_id} --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id ${vpc_id} --enable-dns-hostnames "{\"Value\":true}"

# private subnet a
sub_a_pri_id=$(
  aws ec2 create-subnet \
      --vpc-id ${vpc_id} \
      --availability-zone ${AZ_A} \
      --cidr-block ${SUB_A_PRI_CIDR} \
      --query Subnet.SubnetId \
      --output text
)
echo $sub_a_pri_id

# private subnet b
sub_b_pri_id=$(
  aws ec2 create-subnet \
      --vpc-id ${vpc_id} \
      --availability-zone ${AZ_B} \
      --cidr-block ${SUB_B_PRI_CIDR} \
      --query Subnet.SubnetId \
      --output text
)
echo $sub_b_pri_id

###############################################################################
# ssm node (bastion host)

# role
ssm_node_role_arn=$(
  aws iam create-role \
    --role-name ${SSM_NODE_ROLE_NAME} \
    --assume-role-policy-document file://aws/ec2_trust_policy.json \
    --max-session-duration 3600 \
    --query Role.Arn \
    --output text
)
aws iam attach-role-policy \
  --role-name ${SSM_NODE_ROLE_NAME} \
  --policy-arn \
  arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# security group
ssm_node_security_group_id=$(
  aws ec2 create-security-group \
    --vpc-id ${vpc_id} \
    --group-name ${SSM_NODE_SECURITY_GROUP_NAME} \
    --description "Allow all local inbound traffic" \
    --query GroupId \
    --output text
)
aws ec2 authorize-security-group-ingress \
  --group-id ${ssm_node_security_group_id} \
  --protocol all \
  --cidr ${VPC_CIDR} \
  --output text

# ec2 spot instance
iam_instance_profile_arn=$(
  aws iam create-instance-profile \
    --instance-profile-name ${SSM_NODE_INSTANCE_PROFILE_NAME} \
    --query InstanceProfile.Arn \
    --output text
)
aws iam add-role-to-instance-profile \
  --instance-profile-name ${SSM_NODE_INSTANCE_PROFILE_NAME} \
  --role-name ${SSM_NODE_ROLE_NAME}

# create a private EC2 spot instance
ssm_node_id=$(
aws ec2 run-instances \
  --image-id ${UBUNTU_AMI_ID} \
  --count ${INSTANCE_COUNT} \
  --instance-type ${INSTANCE_TYPE} \
  --instance-market-options file://aws/spot-instance.json \
  --subnet-id ${sub_a_pri_id} \
  --security-group-ids ${ssm_node_security_group_id} \
  --key-name ${KEY_NAME} \
  --iam-instance-profile Arn=${iam_instance_profile_arn} \
  --query Instances[].InstanceId \
  --output text
)
echo $ssm_node_id

aws ec2 create-tags \
    --resources ${ssm_node_id} \
    --tags Key=Stack,Value=${ENVIRONMENT} Key=Name,Value=${SSM_NODE_NAME}

###############################################################################
# db subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name ${DB_SUB_GROUP_NAME} \
  --db-subnet-group-description "rds subnet group for 2 private subnets" \
  --subnet-ids "[\"${sub_a_pri_id}\", \"${sub_b_pri_id}\"]" \
  --query DBSubnetGroup.DBSubnetGroupName \
  --output text

# db parameter group
aws rds create-db-parameter-group \
  --db-parameter-group-name ${DB_PARAMETER_GROUP_NAME} \
  --db-parameter-group-family postgres16 \
  --description "postgres16 parameter group v01"

# security group
rds_security_group_id=$(
  aws ec2 create-security-group \
    --group-name ${RDS_SECURITY_GROUP_NAME} \
    --vpc-id ${vpc_id} \
    --description "Allow port 5432 connect to bastion host security group" \
    --query GroupId \
    --output text
)

# create security group ingress rules
aws ec2 authorize-security-group-ingress \
  --group-id ${rds_security_group_id} \
  --protocol tcp \
  --port 5432 \
  --source-group ${ssm_node_security_group_id}

# db instance
aws rds create-db-instance \
  --availability-zone ${AZ_A} \
  --db-subnet-group-name ${DB_SUB_GROUP_NAME} \
  --db-parameter-group-name ${DB_PARAMETER_GROUP_NAME} \
  --db-instance-identifier ${DB_INSTANCE_ID} \
  --db-instance-class ${DB_INSTANCE_CLASS} \
  --engine postgres \
  --engine-version ${POSTGRES_ENGINE_VERSION} \
  --port ${DB_PORT} \
  --db-name ${POSTGRES_DB} \
  --master-username ${POSTGRES_USER} \
  --master-user-password ${POSTGRES_PASSWORD} \
  --storage-type gp3 \
  --allocated-storage 20 \
  --vpc-security-group-ids ${rds_security_group_id} \
  --no-publicly-accessible \
  --storage-encrypted \
  --enable-iam-database-authentication \
  --no-multi-az \
  --backup-retention-period 0 \
  --copy-tags-to-snapshot \
  --monitoring-interval 0 \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --enable-cloudwatch-logs-exports postgresql

###############################################################################

# role
rds_role_arn=$(
  aws iam create-role \
    --role-name ${RDS_ROLE_NAME} \
    --assume-role-policy-document file://aws/rds_trust_policy.json \
    --max-session-duration 3600 \
    --query Role.Arn \
    --output text
)
# create policy
rds_policy_arn=$(
  aws iam create-policy \
    --policy-name ${RDS_POLICY_NAME} \
    --query Policy.Arn \
    --output text \
    --policy-document \
  '{
      "Version": "2012-10-17",
      "Statement": [
      {
          "Sid": "rdsS3Import",
          "Effect": "Allow",
          "Action": [
                "s3:*",
                "s3-object-lambda:*"
          ],
          "Resource": [
              "arn:aws:s3:::datatestbed/source_crm",
              "arn:aws:s3:::datatestbed/source_crm/*",
              "arn:aws:s3:::datatestbed/source_prd",
              "arn:aws:s3:::datatestbed/source_prd/*"
          ]
      }]
  }'
)
# attach policy to role
aws iam attach-role-policy \
  --policy-arn ${rds_policy_arn} \
  --role-name ${RDS_ROLE_NAME}
# attach role to cluster and import feature
aws rds add-role-to-db-instance \
  --region ${REGION} \
  --db-instance-identifier ${DB_INSTANCE_ID} \
  --role-arn ${rds_role_arn} \
  --feature-name s3Import

###############################################################################
# vpc endpoint ssm
aws ec2 create-vpc-endpoint \
    --vpc-id ${vpc_id} \
    --vpc-endpoint-type Interface \
    --service-name com.amazonaws.${REGION}.ssm \
    --subnet-ids ${sub_a_pri_id} \
    --security-group-id ${ssm_node_security_group_id} \
    --query VpcEndpoint.VpcEndpointId \
    --output text

s3_vpc_endpoint=$(
  aws ec2 create-vpc-endpoint \
      --vpc-id ${vpc_id} \
      --vpc-endpoint-type Gateway \
      --service-name com.amazonaws.${REGION}.s3 \
      --query VpcEndpoint.VpcEndpointId \
      --output text
)

private_rt_id=$(
  aws ec2 describe-route-tables \
    --filters Name=vpc-id,Values=${vpc_id} \
    --query RouteTables[].RouteTableId \
    --output text
)

aws ec2 modify-vpc-endpoint \
  --vpc-endpoint-id ${s3_vpc_endpoint} \
  --add-route-table-ids ${private_rt_id} \
  --reset-policy
