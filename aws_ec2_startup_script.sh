#!/bin/bash

pip install awscli

SCRIPT_DIR="aws_script_setup"

if [ ! -d "~/$SCRIPT_DIR" ]; then
	cd ~
    mkdir $SCRIPT_DIR
fi

cd ~/$SCRIPT_DIR

aws s3 cp s3://kd-aws/aws_jupyter_setup.sh ./ --region us-east-2
aws s3 cp s3://kd-aws/aws_private ./ --region us-east-2
chmod a+x aws_jupyter_setup.sh

cd ~

./$SCRIPT_DIR/aws_jupyter_setup.sh

## TODO add download of anaconda env.
