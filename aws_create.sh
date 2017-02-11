#!/bin/bash

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -i|--instance-type)
    INSTANCE_TYPE="$2"
    shift # past argument
    ;;
    -v|--volume-size)
    SIZE="$2"
    shift # past argument
    ;;
    -d|--dry-run)
    DO_DRY_RUN=true
    ;;
    *)
esac
shift # past argument or value
done

T2="t2.micro"
P2="p2.xlarge"

if [ -z $INSTANCE_TYPE ]; then
	INSTANCE_TYPE=$T2
fi

if [ -z $SIZE ]; then 
	SIZE=16
fi

if [ -z $DO_DRY_RUN ]; then
	DO_DRY_RUN=false
	DRY_RUN=""
else
	DRY_RUN="--dry-run"
fi

if [ "$INSTANCE_TYPE" != "$T2" ] && [ "$INSTANCE_TYPE" != "$P2" ]; then
	echo $INSTANCE_TYPE
	echo "Not a valid instance type $INSTANCE_TYPE. Please enter either $T2 or $P2."
	exit
fi

source aws_private

TERMINATION="--enable-api-termination"
ROLE="Name=data_ec2"
BLOCK_MAPPINGS="DeviceName=/dev/sda1,Ebs={SnapshotId=$SNAPSHOT,VolumeSize=$SIZE}"
USER_DATA="" ## :( ami won't take this file. "file://aws_ec2_startup_script.sh" --user-data $USER_DATA

INSTANCE_ID=$( aws ec2 describe-instances --filters "Name=image-id,Values=$AMI" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text )

if [ -z $INSTANCE_ID ]; then 
	echo "Starting your ec2 instance."
	start_cmd="aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP --iam-instance-profile $ROLE --block-device-mappings $BLOCK_MAPPINGS $TERMINATION $DRY_RUN"
	echo "Running: $start_cmd"
	$start_cmd

	if $DO_DRY_RUN; then
		exit
	fi
	
	echo "Instance started. Waiting for instance id..."

	while [ -z "$INSTANCE_ID" ]; do
		INSTANCE_ID=$( aws ec2 describe-instances --filters "Name=image-id,Values=$AMI" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text )
    	sleep 1; echo -n '.'
	done

	echo "Instance id: $INSTANCE_ID"

	AWS_STATE="not-running"
	while [ "$AWS_STATE" != "running" ]; do
		AWS_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text)
    	sleep 1; echo -n '.'
	done
	echo "Instance Ready!"
	
else
	STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[*].Instances[*].State.Name" --output text)
	echo "Instance already create with $INSTANCE_ID. Instance state is $STATE. Run aws_start.sh to start instance."
fi
