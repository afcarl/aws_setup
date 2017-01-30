#!/bin/bash

# Starts your AWS instance, connects via SSH and launches Chrome with the remote Jupyter Notebook page open.
# Usage is as follows:
# 1. Run this script, so that Chrome has launched and SSH connection is established.
# 2. Execute 'jupyter notebook' on the AWS instance.
# 3. Reload the page in Chrome and log in to Jupyter Notebook.
#
# Note: we use Chrome, as there's a known issue with Safari that won't let Jupyter Notebook connect to a remote kernel.
#
# Script configuration:
#
# ID of your AWS instance. This assumes you only have one instance running. 
AWS_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text)

if [ -z AWS_INSTANCE_ID ]; then
	echo "Unable to find active instance."
	exit
fi

# Get the instance state.
AWS_STATE=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text)
# Port that you used in your Jupyter Notebook configuration.
AWS_NOTEBOOK_PORT=8888
# Port that you configured in the security group of your AWS instance.
AWS_SSH_PORT=22
# Browser path to run Jupyter Notebook.
BROWSER_PATH="/Applications/Google Chrome.app"
# Path to .pem file
AWS_PEM_PATH="~/.aws/admin-key-pair-us-east-1b.pem"
# ec2 user. Based on ami.
USER="carnd"

echo "Starting..."

if [ "$AWS_STATE" != "stopped" ] && [ "$AWS_STATE" != "running" ]; then
    echo "...Instance is not available, try again later."
    exit
fi

if [ "$AWS_STATE" == "running" ]; then
    echo -n "...AWS instance is already running. Initialising..."
elif [ "$AWS_STATE" == "stopped" ]; then
    # If the state is 'stopped', start it.
    aws ec2 start-instances --instance-ids $AWS_INSTANCE_ID >/dev/null
    echo -n "...AWS instance started. Initialising..."
fi

# Wait till the instance has started.
while AWS_STATE=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text); test "$AWS_STATE" != "running"; do
    sleep 1; echo -n '.'
done
echo " Ready."

# Get the instance public IP address.
AWS_IP=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
echo "AWS instance IP: $AWS_IP."
AWS_DNS_NAME=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].PublicDnsName" --output text)
echo "AWS instance IP: $AWS_DNS_NAME."

# Launch Chrome with the Jupyter Notebook URL. The URL will fail, since we haven't started it yet.
NOTEBOOK_URL="http://$AWS_IP:$AWS_NOTEBOOK_PORT/"
SCRIPT_LOGS="https://$AWS_DNS_NAME/var/log/cloud-init-output.log"
/usr/bin/open -a "$BROWSER_PATH" $NOTEBOOK_URL
/usr/bin/open -a "$BROWSER_PATH" $SCRIPT_LOGS

# When the AWS instance starts there is still a bit of a delay till its network interface is initialised, we will wait till it is available.
echo -n "Waiting for AWS instance network interface..."
nc -z -w 5 $AWS_IP $AWS_SSH_PORT 1>/dev/null 2>&1
while [ $? != 0 ]; do 
    sleep 1; echo -n '.'
    nc -z -w 5 $AWS_IP $AWS_SSH_PORT 1>/dev/null 2>&1
done
echo " Ready."

# Add instance IP to known hosts to avoid a security warning dialog.
ssh-keyscan -H $AWS_IP >> ~/.ssh/known_hosts

# Connect to the AWS instance.
ssh -i $AWS_PEM_PATH $USER@$AWS_IP

