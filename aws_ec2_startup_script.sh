#!/bin/bash

# script to run once instance is started. Unfortunetly this
# can't be passed in to the ami on startup. 

pip install awscli

cd ~

aws s3 cp s3://kd-aws/aws_jupyter_setup.sh ./ --region us-east-2
aws s3 cp s3://kd-aws/aws_private ./ --region us-east-2
chmod a+x aws_jupyter_setup.sh

./aws_jupyter_setup.sh

aws s3 cp s3://kd-carnd/environment-carnd.yml ./ --region us-east-2

conda env create -f environment-carnd.yml

# download github repo

