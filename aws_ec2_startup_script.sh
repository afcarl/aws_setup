#!/bin/bash

pip install awscli

cd ~

aws s3 cp s3://kd-aws/aws_jupyter_setup.sh ./ --region us-east-2
aws s3 cp s3://kd-aws/aws_private ./ --region us-east-2
chmod a+x aws_jupyter_setup.sh

./aws_jupyter_setup.sh

## TODO add download of anaconda env.
