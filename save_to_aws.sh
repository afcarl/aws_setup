#!/bin/bash

aws s3 cp ./aws_jupyter_setup.sh s3://kd-aws/aws_jupyter_setup.sh --region us-east-2
aws s3 cp ./aws_private s3://kd-aws/aws_private --region us-east-2