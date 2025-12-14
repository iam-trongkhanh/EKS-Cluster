properties([
    parameters([
        string(
            defaultValue: 'dev',
            name: 'Environment'
        ),
        choice(
            choices: ['plan', 'apply', 'destroy'], 
            name: 'Terraform_Action'
        )])
])
pipeline {
    agent any
    stages {
        stage('Preparing') {
            steps {
                sh 'echo Preparing'
            }
        }
        stage('Git Pulling') {
            steps {
                git branch: 'main', url: 'https://github.com/iam-trongkhanh/EKS-Cluster.git'
            }
        }
        stage('Init') {
            steps {
                withAWS(credentials: 'creds-aws', region: 'ap-southeast-2') {
                    script {
                        // Check if Terraform is installed
                        sh 'terraform version || (echo "ERROR: Terraform not found. Please install Terraform on Jenkins server." && exit 1)'
                        
                        // Verify S3 bucket exists
                        sh '''
                            echo "Checking if S3 bucket exists..."
                            if ! aws s3api head-bucket --bucket KhanhhocdevopsS3bucket 2>/dev/null; then
                                echo "ERROR: S3 bucket 'KhanhhocdevopsS3bucket' does not exist!"
                                echo "Please create it first using setup-backend.tf or AWS CLI"
                                exit 1
                            fi
                            echo "✓ S3 bucket exists"
                        '''
                        
                        // Verify DynamoDB table exists
                        sh '''
                            echo "Checking if DynamoDB table exists..."
                            if ! aws dynamodb describe-table --table-name terraform-state-lock --region ap-southeast-2 2>/dev/null; then
                                echo "ERROR: DynamoDB table 'terraform-state-lock' does not exist!"
                                echo "Please create it first using setup-backend.tf or AWS CLI"
                                exit 1
                            fi
                            echo "✓ DynamoDB table exists"
                        '''
                        
                        // Initialize Terraform
                        sh 'terraform -chdir=eks/ init'
                    }
                }
            }
        }
        stage('Validate') {
            steps {
                withAWS(credentials: 'creds-aws', region: 'ap-southeast-2') {
                sh 'terraform -chdir=eks/ validate'
                }
            }
        }
        stage('Action') {
            steps {
                withAWS(credentials: 'creds-aws', region: 'ap-southeast-2') {
                    script {    
                        if (params.Terraform_Action == 'plan') {
                            sh "terraform -chdir=eks/ plan -var-file=${params.Environment}.tfvars"
                        }   else if (params.Terraform_Action == 'apply') {
                            sh "terraform -chdir=eks/ apply -var-file=${params.Environment}.tfvars -auto-approve"
                        }   else if (params.Terraform_Action == 'destroy') {
                            sh "terraform -chdir=eks/ destroy -var-file=${params.Environment}.tfvars -auto-approve"
                        } else {
                            error "Invalid value for Terraform_Action: ${params.Terraform_Action}"
                        }
                    }
                }
            }
        }
    }
}

