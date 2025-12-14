# Terraform Init Troubleshooting

## Common Errors in "Init" Stage

### Error 1: S3 Bucket Not Found

**Error message:**
```
Error: error loading state: bucket "KhanhhocdevopsS3bucket" does not exist
```

**Solution:**
1. Create S3 bucket first using `setup-backend.tf`:
   ```bash
   terraform init
   terraform apply
   ```

2. Or create manually:
   ```bash
   aws s3api create-bucket \
       --bucket KhanhhocdevopsS3bucket \
       --region ap-southeast-2 \
       --create-bucket-configuration LocationConstraint=ap-southeast-2
   ```

### Error 2: DynamoDB Table Not Found

**Error message:**
```
Error: error loading state: table "terraform-state-lock" does not exist
```

**Solution:**
1. Create DynamoDB table using `setup-backend.tf`:
   ```bash
   terraform apply
   ```

2. Or create manually:
   ```bash
   aws dynamodb create-table \
       --table-name terraform-state-lock \
       --attribute-definitions AttributeName=LockID,AttributeType=S \
       --key-schema AttributeName=LockID,KeyType=HASH \
       --billing-mode PAY_PER_REQUEST \
       --region ap-southeast-2
   ```

### Error 3: Access Denied to S3/DynamoDB

**Error message:**
```
Error: AccessDenied: Access Denied
```

**Solution:**
1. Check AWS credentials in Jenkins:
   - Go to: Manage Jenkins → Credentials → System → Global credentials
   - Verify credentials ID: `creds-aws`
   - Verify Access Key and Secret Key are correct

2. Check IAM permissions:
   - IAM user/role needs:
     - `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` on S3 bucket
     - `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem` on DynamoDB table

3. Example IAM policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:ListBucket",
           "s3:GetObject",
           "s3:PutObject"
         ],
         "Resource": [
           "arn:aws:s3:::KhanhhocdevopsS3bucket",
           "arn:aws:s3:::KhanhhocdevopsS3bucket/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:GetItem",
           "dynamodb:PutItem",
           "dynamodb:DeleteItem"
         ],
         "Resource": "arn:aws:dynamodb:ap-southeast-2:*:table/terraform-state-lock"
       }
     ]
   }
   ```

### Error 4: Terraform Not Found

**Error message:**
```
terraform: command not found
```

**Solution:**
1. Install Terraform on Jenkins server:
   ```bash
   # On Jenkins server (Ubuntu/Debian)
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update
   sudo apt install terraform
   ```

2. Or use the `jenkins-server-setup.sh` script which includes Terraform installation

### Error 5: Region Mismatch

**Error message:**
```
Error: error loading state: RequestError: send request failed
```

**Solution:**
1. Verify region in `eks/backend.tf` matches your AWS region
2. Verify region in Jenkinsfile matches: `region: 'ap-southeast-2'`
3. Verify S3 bucket and DynamoDB table are in the same region

### Error 6: Backend Configuration Changed

**Error message:**
```
Error: Backend configuration changed
```

**Solution:**
1. If you changed backend configuration, you need to migrate:
   ```bash
   terraform init -migrate-state
   ```

2. Or remove old state and reinitialize:
   ```bash
   rm -rf eks/.terraform
   terraform -chdir=eks/ init
   ```

## Quick Checklist

Before running pipeline, verify:

- [ ] S3 bucket `KhanhhocdevopsS3bucket` exists in `ap-southeast-2`
- [ ] DynamoDB table `terraform-state-lock` exists in `ap-southeast-2`
- [ ] AWS credentials `creds-aws` configured in Jenkins
- [ ] IAM user has permissions for S3 and DynamoDB
- [ ] Terraform installed on Jenkins server
- [ ] Region matches in all files (`ap-southeast-2`)

## Test Commands

Test on Jenkins server (SSH into it):

```bash
# Check Terraform
terraform version

# Check AWS CLI
aws --version

# Test S3 access
aws s3 ls s3://KhanhhocdevopsS3bucket

# Test DynamoDB access
aws dynamodb describe-table --table-name terraform-state-lock --region ap-southeast-2

# Test credentials
aws sts get-caller-identity
```

## Debug Steps

1. **Check Jenkins console output** for exact error message
2. **SSH into Jenkins server** and test commands manually
3. **Verify AWS credentials** work outside Jenkins
4. **Check IAM permissions** for the AWS user/role
5. **Verify resources exist** in AWS Console

---

**After fixing, try running the pipeline again!**

