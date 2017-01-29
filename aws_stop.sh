#!/bin/bash

# Checks current AWS instance state and stops it if it's running.

# ID of your AWS instance. This assumes you only have one instance running. 
AWS_INSTANCE_ID=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].InstanceId" --output text)

AWS_STATE=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text)
if [ "$AWS_STATE" == "running" ]; then
    aws ec2 stop-instances --instance-ids $AWS_INSTANCE_ID >/dev/null
    echo -n "The AWS instance is now stopping. It usually takes a while, so feel free to CTRL+C if you don't want to wait till the instance has fully stopped."
    echo "Stopping instance"
    # Wait till the instance has actually stopped.
    while AWS_STATE=$(aws ec2 describe-instances --instance-ids $AWS_INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text); test "$AWS_STATE" != "stopped"; do
        sleep 5; echo -n '.'
    done
    echo " AWS instance stopped. "
else
    echo "AWS instance is not running."
fi

