# Jenkins AWS Credentials Setup Guide

## Error: "Cannot find a Username with password credential with the ID creds-aws"

This error occurs when AWS credentials are not configured correctly in Jenkins.

## ✅ Step-by-Step Setup

### 1. Access Jenkins Credentials

1. Go to Jenkins Dashboard
2. Click **Manage Jenkins** (left sidebar)
3. Click **Credentials** (under Security)
4. Click **System** (under Stores scoped to Jenkins)
5. Click **Global credentials (unrestricted)** (or your domain)
6. Click **Add Credentials** (left sidebar)

### 2. Configure AWS Credentials

**Important**: You must select the correct credential type!

**Credential Type:**
- ✅ Select: **"AWS Credentials"** (NOT "Username with password")
- ❌ Wrong: "Username with password"
- ❌ Wrong: "Secret text"
- ❌ Wrong: "SSH Username with private key"

**Fill in the form:**

| Field | Value | Required |
|-------|-------|----------|
| **Kind** | `AWS Credentials` | ✅ |
| **ID** | `creds-aws` | ✅ **MUST match exactly** |
| **Description** | `AWS Credentials for EKS Terraform` | ⚠️ Optional |
| **Access Key ID** | `AKIA...` (your AWS Access Key) | ✅ |
| **Secret Access Key** | `...` (your AWS Secret Key) | ✅ |
| **IAM Role** | (leave empty if using Access Key) | ⚠️ Optional |
| **Scope** | `Global` | ✅ |

### 3. Verify Credentials

After saving, you should see:
- Credential ID: `creds-aws`
- Type: `AWS Credentials`
- Description: (if you added one)

### 4. Test in Pipeline

The pipeline should now be able to use:
```groovy
withAWS(credentials: 'creds-aws', region: 'ap-southeast-2') {
    // Your commands here
}
```

## 🔍 Troubleshooting

### Issue 1: Credential ID Mismatch

**Error**: `Cannot find a credential with the ID creds-aws`

**Solution**:
- Verify the ID is exactly `creds-aws` (case-sensitive)
- Check for typos: `creds-aws` not `creds_aws` or `creds-aws-1`

### Issue 2: Wrong Credential Type

**Error**: `Cannot find a Username with password credential`

**Solution**:
- Delete the wrong credential
- Create new one with type **"AWS Credentials"** (not "Username with password")

### Issue 3: AWS Access Key Invalid

**Error**: `Invalid credentials` or `Access Denied`

**Solution**:
1. Verify Access Key ID and Secret Key are correct
2. Check IAM user has necessary permissions:
   - S3 access (for Terraform state)
   - DynamoDB access (for state locking)
   - EKS, EC2, VPC, IAM permissions (for creating infrastructure)

### Issue 4: Credentials Not Visible

**Solution**:
- Make sure scope is set to **Global**
- Check you're in the right domain (System → Global credentials)

## 📋 Quick Checklist

- [ ] Credential type = **"AWS Credentials"** (not "Username with password")
- [ ] Credential ID = `creds-aws` (exact match, case-sensitive)
- [ ] Access Key ID is valid
- [ ] Secret Access Key is valid
- [ ] Scope = Global
- [ ] Credential is saved successfully

## 🔐 Getting AWS Access Keys

If you need to create AWS Access Keys:

1. Go to AWS Console → IAM → Users
2. Select your user (or create new one)
3. Go to **Security credentials** tab
4. Click **Create access key**
5. Choose use case: **Command Line Interface (CLI)**
6. Download or copy:
   - Access Key ID
   - Secret Access Key

**⚠️ Security Note**: Never commit AWS credentials to Git!

## 🧪 Test Credentials

You can test credentials work by SSH into Jenkins server:

```bash
# Set credentials (temporarily)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-2"

# Test
aws sts get-caller-identity
aws s3 ls
```

---

**After setting up credentials correctly, run the pipeline again!**

