#!/bin/python

import boto3

# How to terminate an ec2 instance in python
ec2 = boto3.resource('ec2', region_name='us-east-1')
instances = ec2.instances.filter(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])
ids = [i.id for i in instances]
ec2.instances.filter(InstanceIds=ids).terminate() # .stop()