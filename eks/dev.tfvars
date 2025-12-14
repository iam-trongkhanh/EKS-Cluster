env                   = "dev"
aws-region            = "ap-southeast-2"
vpc-cidr-block        = "10.16.0.0/16"
vpc-name              = "vpc"
igw-name              = "igw"
pub-subnet-count      = 3
pub-cidr-block        = ["10.16.0.0/20", "10.16.16.0/20", "10.16.32.0/20"]
pub-availability-zone = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
pub-sub-name          = "subnet-public"
pri-subnet-count      = 3
pri-cidr-block        = ["10.16.128.0/20", "10.16.144.0/20", "10.16.160.0/20"]
pri-availability-zone = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
pri-sub-name          = "subnet-private"
public-rt-name        = "public-route-table"
private-rt-name       = "private-route-table"
eip-name              = "elasticip-ngw"
ngw-name              = "ngw"
eks-sg                = "eks-sg"

# EKS
is-eks-cluster-enabled     = true
cluster-version            = "1.30"
cluster-name               = "eks-cluster"
endpoint-private-access    = true
endpoint-public-access     = false
# ============================================
# EC2 INSTANCE TYPES - CAN BE MODIFIED
# ============================================
# You can change these instance types based on your needs:
# - Free Tier: t2.micro, t3.micro, t4g.micro
# - Small: t3.small, t3a.small (2 vCPU, 2 GB RAM)
# - Medium: t3.medium, t3a.medium (2 vCPU, 4 GB RAM)
# - Large: m7i-flex.large, t3.large, etc.
# ============================================
ondemand_instance_types    = ["m7i-flex.large"]
spot_instance_types        = ["m7i-flex.large", "m7i-flex.xlarge", "m7i-flex.2xlarge"]
desired_capacity_on_demand = "1"
min_capacity_on_demand     = "1"
max_capacity_on_demand     = "5"
desired_capacity_spot      = "1"
min_capacity_spot          = "1"
max_capacity_spot          = "10"
addons = [
  {
    name    = "vpc-cni"
    version = "v1.20.0-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.2-eksbuild.4"
  },
  {
    name    = "kube-proxy"
    version = "v1.30.0-eksbuild.1"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.30.0-eksbuild.1"
  }
  # Add more addons as needed
]

