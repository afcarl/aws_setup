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
# ID of your AWS instance.
AWS_INSTANCE_ID="<Your instance ID here>"
# Port that you used in your Jupyter Notebook configuration.
AWS_NOTEBOOK_PORT=8888
# Port that you configured in the security group of your AWS instance.
AWS_SSH_PORT=22
# Browser path to run Jupyter Notebook.
BROWSER_PATH="/Applications/Google Chrome.app"

echo "Starting..."

# Get the instance state.
AWS_STATE=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text)

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

# Launch Chrome with the Jupyter Notebook URL. The URL will fail, since we haven't started it yet.
NOTEBOOK_URL="https://$AWS_IP:$AWS_NOTEBOOK_PORT/"
/usr/bin/open -a "$BROWSER_PATH" $NOTEBOOK_URL

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
ssh -i ~/.aws/my_aws_key.pem ubuntu@$AWS_IP

