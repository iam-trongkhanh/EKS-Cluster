# Jenkins Pipeline Troubleshooting

## Error: "No flow definition, cannot run"

This error occurs when Jenkins cannot find or read the Jenkinsfile. Follow these steps to fix:

### ✅ Step 1: Verify Jenkinsfile exists in GitHub

1. Go to: `https://github.com/iam-trongkhanh/EKS-Cluster`
2. Check if `Jenkinsfile` exists in the root directory
3. Click on it to verify the content is correct

### ✅ Step 2: Configure Pipeline Correctly in Jenkins

1. Go to your Jenkins pipeline job
2. Click **Configure**
3. Under **Pipeline** section, verify:

   **Pipeline definition:**
   - ✅ Select: **"Pipeline script from SCM"** (NOT "Pipeline script")
   
   **SCM:**
   - ✅ Select: **Git**
   
   **Repository URL:**
   - ✅ Enter: `https://github.com/iam-trongkhanh/EKS-Cluster.git`
   - Or if using SSH: `git@github.com:iam-trongkhanh/EKS-Cluster.git`
   
   **Credentials:**
   - If repo is private, add GitHub credentials
   - If repo is public, leave empty
   
   **Branch Specifier:**
   - ✅ Enter: `*/main` or `main`
   - Make sure branch name matches your GitHub branch
   
   **Script Path:**
   - ✅ Enter: `Jenkinsfile` (exactly this name, case-sensitive)
   - This is the path relative to repo root

4. Click **Save**

### ✅ Step 3: Verify Branch Name

Check your GitHub branch name:
```bash
git branch
```

If your branch is `main`, use `*/main` or `main` in Jenkins
If your branch is `master`, use `*/master` or `master` in Jenkins

### ✅ Step 4: Test Pipeline

1. Click **Build Now** (or **Build with Parameters**)
2. Check the console output

### 🔍 Common Issues

#### Issue 1: Wrong Script Path
- ❌ Wrong: `Jenkinsfile.txt`, `jenkinsfile`, `./Jenkinsfile`
- ✅ Correct: `Jenkinsfile`

#### Issue 2: Wrong Branch
- ❌ Wrong: `master` when branch is `main`
- ✅ Correct: Match your actual branch name

#### Issue 3: Pipeline Definition Type
- ❌ Wrong: "Pipeline script" (inline script)
- ✅ Correct: "Pipeline script from SCM"

#### Issue 4: Jenkinsfile not in root
- ❌ Wrong: Jenkinsfile in subdirectory
- ✅ Correct: Jenkinsfile must be in repo root

#### Issue 5: Jenkinsfile not committed
- Make sure Jenkinsfile is committed and pushed:
  ```bash
  git add Jenkinsfile
  git commit -m "Add Jenkinsfile"
  git push origin main
  ```

### 📋 Quick Checklist

- [ ] Jenkinsfile exists in GitHub repo root
- [ ] Pipeline definition = "Pipeline script from SCM"
- [ ] SCM = Git
- [ ] Repository URL is correct
- [ ] Branch specifier matches your branch (`*/main` or `main`)
- [ ] Script Path = `Jenkinsfile` (exact name)
- [ ] Jenkinsfile is committed and pushed to GitHub
- [ ] If private repo, credentials are configured

### 🧪 Test Jenkinsfile Syntax

You can test Jenkinsfile syntax locally (if you have Jenkins CLI):

```bash
# Install Jenkins CLI or use Jenkins web interface
# Go to: http://your-jenkins-url/pipeline-syntax/
# Or use: http://your-jenkins-url/pipeline-syntax/validator
```

### 📞 Still Not Working?

1. Check Jenkins console output for detailed error
2. Verify Jenkins has access to GitHub (network/firewall)
3. Check Jenkins logs: `/var/log/jenkins/jenkins.log`
4. Verify Git plugin is installed in Jenkins

---

**After fixing, try building the pipeline again!**

