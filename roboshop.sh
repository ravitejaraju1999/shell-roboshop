#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0eceac836e52f5116"

for instance in $@

do

    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0eceac836e52f5116 --tag-specifications 
    "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)


    # Get Private Ip
    if [ $instance != "frontend" ]; then
        




