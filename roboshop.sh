#!/bin/bash

AMI_ID="ami-07ff62358b87c7116"
SG_ID="sg-0eceac836e52f5116"
ZONE_ID="Z09554163BEIVGQB3DW1S"
DOMAIN_NAME="raviteja.store"

for instance in $@

do

    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)


    # Get Private Ip
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.raviteja.store
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME" #raviteja.store

    fi

    echo "$instance: $IP"


    aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
    {
        "Comment": "Updating record set",
        "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "'$RECORD_NAME'",
            "Type": "A",
            "TTL": 1,
            "ResourceRecords": [{
            "Value": "'$IP'"
            }]
        }
        }]
    }'


done







