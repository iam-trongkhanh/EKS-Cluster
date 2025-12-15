#!/bin/bash
# ============================================
# Install AWS Load Balancer Controller on EKS
# ============================================
# Copy and paste this entire script into your jump server terminal
# Make sure kubectl is configured first: aws eks update-kubeconfig --name <cluster> --region <region>
# ============================================

set -e

# Change to home directory to ensure write permissions
cd ~

# Configuration - UPDATE THESE
CLUSTER_NAME="dev-trongkhanh-eks-cluster"
AWS_REGION="ap-southeast-2"
LB_CONTROLLER_VERSION="v2.5.4"

echo "============================================"
echo "Installing AWS Load Balancer Controller"
echo "Cluster: ${CLUSTER_NAME}"
echo "Region: ${AWS_REGION}"
echo "Working directory: $(pwd)"
echo "============================================"

# Get Account ID
echo "Getting AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Account ID: ${ACCOUNT_ID}"

# Download IAM Policy
echo "Downloading IAM Policy..."
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LB_CONTROLLER_VERSION}/docs/install/iam_policy.json

# Create IAM Policy
echo "Creating IAM Policy..."
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

if aws iam get-policy --policy-arn ${POLICY_ARN} > /dev/null 2>&1; then
  echo "Policy already exists, skipping..."
else
  aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://iam_policy.json
  echo "IAM Policy created"
fi

# Create OIDC Provider
echo "Creating OIDC Provider..."
eksctl utils associate-iam-oidc-provider --region=${AWS_REGION} --cluster=${CLUSTER_NAME} --approve

# Create Service Account
echo "Creating Service Account..."
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
ROLE_NAME="AmazonEKSLoadBalancerControllerRole"

if kubectl get serviceaccount ${SERVICE_ACCOUNT_NAME} -n kube-system > /dev/null 2>&1; then
  echo "Service Account already exists, skipping..."
else
  eksctl create iamserviceaccount \
    --cluster=${CLUSTER_NAME} \
    --namespace=kube-system \
    --name=${SERVICE_ACCOUNT_NAME} \
    --role-name=${ROLE_NAME} \
    --attach-policy-arn=${POLICY_ARN} \
    --approve \
    --region=${AWS_REGION}
  echo "Service Account created"
fi

# Get VPC ID
echo "Getting VPC ID..."
VPC_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --query 'cluster.resourcesVpcConfig.vpcId' --output text)
echo "VPC ID: ${VPC_ID}"

# Install via Helm
echo "Installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

if helm list -n kube-system | grep -q aws-load-balancer-controller; then
  echo "Upgrading existing installation..."
  helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=${CLUSTER_NAME} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=${SERVICE_ACCOUNT_NAME} \
    --set region=${AWS_REGION} \
    --set vpcId=${VPC_ID}
else
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=${CLUSTER_NAME} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=${SERVICE_ACCOUNT_NAME} \
    --set region=${AWS_REGION} \
    --set vpcId=${VPC_ID}
fi

# Verify
echo "Waiting for pods to be ready..."
sleep 30
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Cleanup
rm -f iam_policy.json

echo "============================================"
echo "Installation Complete!"
echo "Check status: kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"
echo "============================================"
