#!/bin/bash

# Setup local AWS Env using doormat alias
$(dme)

# get identity
aws sts get-caller-identity

# add EKS cluster to $HOME/.kube/config
aws eks --region us-west-2 update-kubeconfig --name presto-aws-eks
