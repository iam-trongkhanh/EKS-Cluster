# EKS Cluster Setup Guide with Terraform and Jenkins

## 📋 Overview

This project automates the creation of an EKS cluster on AWS using Terraform and Jenkins CI/CD pipeline.

## 🏗️ Project Structure

```
EKS-Cluster/
├── eks/                    # Terraform configuration for EKS
│   ├── backend.tf         # Backend configuration (S3, DynamoDB)
│   ├── main.tf            # Main Terraform file
│   ├── variables.tf       # Variable definitions
│   └── dev.tfvars         # Development environment values
├── module/                 # Terraform modules
│   ├── vpc.tf             # VPC, Subnets, IGW, NGW
│   ├── eks.tf             # EKS Cluster and Node Groups
│   ├── iam.tf             # IAM Roles and Policies
│   ├── gather.tf          # Data sources
│   └── variables.tf        # Module variables
├── Jenkinsfile             # Jenkins CI/CD pipeline
├── setup-backend.tf       # Create S3 bucket and DynamoDB table
├── jenkins-server-setup.sh # Script to setup Jenkins server
└── jenkins-plugins.txt     # List of required Jenkins plugins

```

## 🚀 Step 1: Create S3 Bucket and DynamoDB Table

**IMPORTANT**: This step must be completed BEFORE running Terraform in the `eks/` directory. The Jenkins pipeline expects these resources to already exist.

### Method 1: Using setup-backend.tf file (Recommended)

```bash
# 1. From the root EKS-Cluster directory
terraform init
terraform plan
terraform apply

# 2. After creation, you can delete setup-backend.tf (or keep it for management)
```

### Method 2: Manual creation using AWS CLI

```bash
# Create S3 bucket
aws s3api create-bucket \
    --bucket KhanhhocdevopsS3bucket \
    --region ap-southeast-2 \
    --create-bucket-configuration LocationConstraint=ap-southeast-2

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket KhanhhocdevopsS3bucket \
    --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ap-southeast-2
```

## 🖥️ Step 2: Setup Jenkins Server

### 2.1. Create EC2 Instance for Jenkins

1. Go to AWS Console → EC2 → Launch Instance
2. Select Ubuntu 22.04 LTS
3. Instance type: t3.medium or larger
4. Security Group: Open port 8080 (Jenkins), 22 (SSH)
5. **User Data**: Copy content from `jenkins-server-setup.sh` file
6. Launch instance

### 2.2. Configure Jenkins

1. Access Jenkins: `http://<EC2-IP>:8080`
2. Get initial password:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. Install suggested plugins
4. Create admin user

### 2.3. Install Jenkins Plugins

1. Manage Jenkins → Plugins → Available plugins
2. Install plugins listed in `jenkins-plugins.txt`:
   - Pipeline: AWS Steps
   - AWS Credentials
   - Terraform
   - Pipeline Stage View

### 2.4. Configure AWS Credentials in Jenkins

1. Manage Jenkins → Credentials → System → Global credentials
2. Add Credentials:
   - Kind: AWS Credentials
   - ID: `aws-creds` (IMPORTANT: must match this exact name)
   - Access Key ID: [Your AWS Access Key]
   - Secret Access Key: [Your AWS Secret Key]
   - Save

## 📝 Step 3: Create Jenkins Pipeline

1. New Item → Pipeline
2. Name: `eks-terraform-pipeline` (or your preferred name)
3. Pipeline definition: Pipeline script from SCM
4. SCM: Git
5. Repository URL: `https://github.com/iam-trongkhanh/EKS-Cluster.git`
6. Branch: `main`
7. Script Path: `Jenkinsfile`
8. Save

## 🎯 Step 4: Run Pipeline

1. Go to the pipeline you just created
2. Click "Build with Parameters"
3. Select:
   - **Environment**: `dev`
   - **Terraform_Action**:
     - `plan` - Preview changes
     - `apply` - Create infrastructure
     - `destroy` - Destroy infrastructure
4. Click "Build"

## ⚙️ Configuration

### Modify EKS Configuration

Edit the `eks/dev.tfvars` file:

- **VPC CIDR**: `vpc-cidr-block = "10.16.0.0/16"`
- **Cluster version**: `cluster-version = "1.30"`
- **Instance types**: `ondemand_instance_types`, `spot_instance_types`
- **Node capacity**: `desired_capacity_on_demand`, `min_capacity_on_demand`, etc.

### Create New Environment (staging, prod)

1. Copy `eks/dev.tfvars` → `eks/staging.tfvars` or `eks/prod.tfvars`
2. Edit values as appropriate
3. In Jenkins, select the corresponding Environment when building

## 🔍 Post-Deployment Verification

### Connect to EKS Cluster

```bash
# Install AWS CLI and kubectl (if not already installed)
aws eks update-kubeconfig --region ap-southeast-2 --name dev-trongkhanh-eks-cluster

# Check nodes
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces
```

## 📚 Reference Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)

## ⚠️ Important Notes

1. **Cost**: EKS cluster and resources will incur costs. Remember to destroy when not in use
2. **Security**:
   - Do not commit AWS credentials to Git
   - Restrict security group rules (currently open to 0.0.0.0/0)
3. **Backend**: Must create S3 bucket and DynamoDB table before running Terraform
4. **Region**: All resources are created in `ap-southeast-2` (Sydney)

## 🆘 Troubleshooting

### Error: "Error: Backend configuration changed"

```bash
# Remove .terraform folder and reinitialize
rm -rf eks/.terraform
cd eks
terraform init
```

### Error: "Error: Failed to get existing workspaces"

- Verify S3 bucket exists
- Verify AWS credentials are correct
- Verify region is correct

### Jenkins cannot connect to AWS

- Verify AWS credentials ID in Jenkins matches `aws-creds`
- Verify IAM user has sufficient permissions

## 📞 Support

If you encounter issues, check:

1. Jenkins console output
2. Terraform logs
3. AWS CloudWatch logs
