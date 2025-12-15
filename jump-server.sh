#!/bin/bash
# ============================================
# Jump Server Setup Script for EKS Cluster
# ============================================
# This script installs all necessary tools to manage EKS cluster
# Usage: Copy this script to EC2 User Data when creating jump server
# ============================================

set -e  # Exit on error

echo "============================================"
echo "Starting Jump Server Setup..."
echo "============================================"

# Update system packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install basic dependencies
sudo apt-get install -y curl wget unzip gpg apt-transport-https ca-certificates gnupg lsb-release

# ============================================
# 1. Install AWS CLI v2
# ============================================
echo ""
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
aws --version
echo "✅ AWS CLI installed"

# ============================================
# 2. Install kubectl (Kubernetes CLI)
# ============================================
echo ""
echo "Installing kubectl..."
EKS_VERSION="1.30"  # ⚠️ CHANGE THIS: Match your EKS cluster version
KUBECTL_VERSION="v1.30.0"  # ⚠️ CHANGE THIS: Match your EKS version

curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client --short
echo "✅ kubectl installed"

# ============================================
# 3. Install Helm (Kubernetes Package Manager)
# ============================================
echo ""
echo "Installing Helm..."
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm
helm version --short
echo "✅ Helm installed"

# ============================================
# 4. Install eksctl (EKS CLI)
# ============================================
echo ""
echo "Installing eksctl..."
ARCH=amd64  # ⚠️ CHANGE THIS: Use arm64 for ARM-based instances
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"
tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp && rm eksctl_${PLATFORM}.tar.gz
sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl
eksctl version
echo "✅ eksctl installed"

# ============================================
# 5. Install additional tools
# ============================================
echo ""
echo "Installing additional tools..."
sudo apt-get install -y jq git
echo "✅ Additional tools installed"

# ============================================
# 6. AWS Authentication Setup
# ============================================
echo ""
echo "============================================"
echo "AWS Authentication Setup"
echo "============================================"

# Check if IAM Role is attached
if curl -s --max-time 1 http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /dev/null 2>&1; then
  IAM_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)
  echo "✅ IAM Role detected: ${IAM_ROLE}"
  echo "✅ Using IAM Role credentials"
else
  echo "ℹ️  No IAM Role detected"
  echo "ℹ️  Setting up AWS credentials..."
  echo ""
  echo "Please run 'aws configure' after SSH into this server"
  echo "Or the script will prompt you to configure now..."
  echo ""
  read -p "Do you want to configure AWS credentials now? (y/n): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    aws configure
  else
    echo "⚠️  AWS credentials not configured"
    echo "   Run 'aws configure' manually after SSH"
  fi
fi

# ============================================
# 7. Configure kubeconfig for EKS cluster
# ============================================
echo ""
echo "============================================"
echo "Configuring kubeconfig for EKS cluster"
echo "============================================"
CLUSTER_NAME="dev-trongkhanh-eks-cluster"  # ⚠️ CHANGE THIS: Your EKS cluster name
AWS_REGION="ap-southeast-2"  # ⚠️ CHANGE THIS: Your AWS region

# Test AWS authentication first
if aws sts get-caller-identity > /dev/null 2>&1; then
  echo "✅ AWS authentication verified"
  
  # Update kubeconfig
  if aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION} > /dev/null 2>&1; then
    echo "✅ kubeconfig configured successfully"
    
    # Verify connection
    if kubectl cluster-info > /dev/null 2>&1; then
      echo "✅ Successfully connected to EKS cluster"
      echo ""
      echo "Cluster information:"
      kubectl cluster-info
      echo ""
      echo "Cluster nodes:"
      kubectl get nodes
    else
      echo "⚠️  kubeconfig configured but cannot connect to cluster"
      echo "   This might be normal if cluster is still initializing"
    fi
  else
    echo "❌ Failed to configure kubeconfig"
    echo "   Please check cluster name and region"
    echo "   Run manually: aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}"
  fi
else
  echo "⚠️  AWS authentication required"
  echo "   Please run 'aws configure' first"
  echo "   Then run: aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}"
fi

# ============================================
# Setup Complete
# ============================================
echo ""
echo "============================================"
echo "Jump Server Setup Complete!"
echo "============================================"
echo ""
echo "Installed tools:"
echo "  - AWS CLI: $(aws --version | cut -d' ' -f1)"
echo "  - kubectl: $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || echo 'installed')"
echo "  - Helm: $(helm version --short 2>/dev/null || echo 'installed')"
echo "  - eksctl: $(eksctl version 2>/dev/null | head -n1 || echo 'installed')"
echo ""
echo "EKS Cluster: ${CLUSTER_NAME}"
echo "Region: ${AWS_REGION}"
echo ""
echo "Next steps:"
echo "  1. If AWS credentials not configured, run: aws configure"
echo "  2. If kubeconfig not configured, run:"
echo "     aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}"
echo "  3. Test connection: kubectl get nodes"
echo ""
echo "You can now use kubectl, helm, and eksctl to manage your cluster!"
echo "============================================"
