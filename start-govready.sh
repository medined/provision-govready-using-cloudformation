#!/bin/bash

if [ -z $REGION_NAME ]; then
  echo "Set REGION_NAME"
  exit
fi

source source-me.sh

echo "GovReady CloudFormation stack started."
aws cloudformation deploy \
  --stack-name "govready" \
  --region $REGION_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-file govready.yaml

#############################
echo "Getting IP address of server."
#############################

IP_SERVER=$(aws cloudformation list-exports \
  --query "Exports[?Name==\`govready:PublicIp\`].Value" \
  --output text)

if [ -z ${IP_SERVER} ]; then
  echo "ERROR: Missing CloudFormat export: govready:PublicIp";
  exit
fi

#############################
echo "Collecting server ECDSA key fingerprints."
#############################

if [ "`ssh-keygen -F $IP_SERVER | wc -l`" -eq "0" ]; then
  ssh-keyscan -H $IP_SERVER >> ~/.ssh/known_hosts
fi

#############################
echo "Waiting for Server to respond to SSH."
#############################

echo "  ssh -i $Z97_PEM_FILE ec2-user@$IP_SERVER"
echo "  /var/lib/cloud/instance/scripts/part-001"
echo "  /var/log/cloud-init-output.log"

STATUS=$(ssh -o ConnectTimeout=2 -o BatchMode=yes -i $Z97_PEM_FILE ec2-user@$IP_SERVER pwd)
while [ "${STATUS}x" != "/home/ec2-userx" ]; do
  echo -n "."
  sleep 10
  STATUS=$(ssh -o ConnectTimeout=2 -o BatchMode=yes -i $Z97_PEM_FILE ec2-user@$IP_SERVER pwd)
done
echo ""

ssh -i $Z97_PEM_FILE ec2-user@$IP_SERVER sudo cat /var/log/cloud-init-output.log

echo "URL"
echo "---"
echo " http://$IP_SERVER:8000/"
