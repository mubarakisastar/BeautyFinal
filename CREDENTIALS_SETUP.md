# Credentials & Keys Setup Guide

## 🚨 IMPORTANT: What You DON'T Need

### ❌ ngrok Auth Token
- **Was used in:** Colab notebook only
- **Why not needed:** Docker deployment runs on real servers with public IPs
- **Status:** REMOVE from notebook if sharing - this key is exposed!
- **What it did:** Created temporary public tunnels for Colab (dev only)

### ❌ Google Colab Credentials
- **Status:** Not applicable to production
- **Already removed:** Not in Docker setup

---

## ✅ What You DO Need (By Deployment Type)

### 1️⃣ Google Cloud Platform (GCP) - Recommended for GPU

#### Step 1: Create GCP Account & Project
```bash
# Go to https://cloud.google.com
# 1. Create account (or use existing)
# 2. Create new project
# 3. Note your PROJECT_ID (e.g., "beauty-final-project-12345")
```

#### Step 2: Install & Configure gcloud CLI
```bash
# Install (Ubuntu/Debian)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL  # Refresh shell

# OR use existing installation
gcloud --version

# Authenticate
gcloud auth login
# Opens browser - click "Allow"

# Set default project
gcloud config set project YOUR_PROJECT_ID
```

#### Step 3: Enable Required APIs
```bash
# Container Registry (for storing Docker images)
gcloud services enable containerregistry.googleapis.com

# Compute Engine (for GPU VMs)
gcloud services enable compute.googleapis.com

# Cloud Run (for serverless deployment)
gcloud services enable run.googleapis.com
```

#### Step 4: Push Docker Image to Google Container Registry
```bash
# Build image locally
docker build -t beauty-api:latest .

# Tag for GCP
docker tag beauty-api:latest gcr.io/YOUR_PROJECT_ID/beauty-api:latest

# Push to registry (requires ~15GB upload)
docker push gcr.io/YOUR_PROJECT_ID/beauty-api:latest

# Verify
gcloud container images list
```

#### What You Get:
- No additional keys needed (gcloud handles auth)
- Free tier: $300 credit
- Free egress for first 1GB/month
- No ngrok or external tunneling required

---

### 2️⃣ AWS - For ECS/Fargate Deployment

#### Step 1: Create AWS Account
```
Go to https://aws.amazon.com
Create account with billing enabled
```

#### Step 2: Create IAM User with ECR Permissions
```
1. AWS Console → IAM
2. Create User → "beauty-api-deployer"
3. Attach policy: "AmazonEC2ContainerRegistryPowerUser"
4. Generate Access Key (save securely!)
5. Note:
   - Access Key ID: AKIA...
   - Secret Access Key: wJal...
```

#### Step 3: Configure AWS CLI
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure credentials
aws configure
# Enter:
# - Access Key ID: AKIA...
# - Secret Access Key: wJal...
# - Region: us-east-1
# - Output format: json
```

#### Step 4: Create ECR Repository
```bash
# Create repository
aws ecr create-repository --repository-name beauty-api --region us-east-1

# Get repository URL (format: ACCOUNT.dkr.ecr.REGION.amazonaws.com/beauty-api)
aws ecr describe-repositories --repository-names beauty-api --region us-east-1
```

#### Step 5: Push Docker Image
```bash
# Get login token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Tag image
docker tag beauty-api:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/beauty-api:latest

# Push
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/beauty-api:latest
```

#### What You Need to Save:
```
AWS_ACCOUNT_ID: 123456789012
AWS_ACCESS_KEY_ID: AKIA...
AWS_SECRET_ACCESS_KEY: wJal... (KEEP SECRET!)
AWS_REGION: us-east-1
ECR_REPOSITORY_URL: 123456789012.dkr.ecr.us-east-1.amazonaws.com/beauty-api
```

---

### 3️⃣ Docker Hub - Simplest Option (No GPU)

#### Step 1: Create Docker Hub Account
```
Go to https://hub.docker.com
Sign up (free)
Create username (e.g., "your-username")
```

#### Step 2: Create Access Token
```
1. Account Settings → Security
2. New Access Token
3. Name: "beauty-api-deploy"
4. Save token (won't show again!)
```

#### Step 3: Push Image
```bash
# Login
docker login
# Username: your-username
# Password: (paste access token)

# Tag
docker tag beauty-api:latest your-username/beauty-api:latest

# Push
docker push your-username/beauty-api:latest

# Anyone can now run:
docker run your-username/beauty-api:latest
```

#### What You Need to Save:
```
DOCKER_USERNAME: your-username
DOCKER_ACCESS_TOKEN: dckr_... (KEEP SECRET!)
IMAGE_URL: your-username/beauty-api
```

---

### 4️⃣ Self-Hosted VPS (Linode, DigitalOcean, Vultr)

#### Step 1: Rent a VPS
- **Recommended:** NVIDIA GPU support
- **Specs:** 4+ CPU, 16GB+ RAM, 30GB+ SSD, T4/RTX GPU
- **Cost:** $200-500/month (GPU-enabled)
- **Providers:**
  - [Linode](https://www.linode.com) (GPU available)
  - [DigitalOcean App Platform](https://www.digitalocean.com)
  - [Vultr](https://www.vultr.com) (GPU available)

#### Step 2: SSH into VPS
```bash
# Given by provider (e.g., ssh root@123.45.67.89)
ssh root@YOUR_VPS_IP

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Verify
docker --version
```

#### Step 3: Deploy Your Image
```bash
# Option A: Pull from Docker Hub
docker pull your-username/beauty-api:latest
docker run --gpus all -d -p 8000:8000 \
  --restart always \
  your-username/beauty-api:latest

# Option B: Build on VPS (slow but private)
git clone https://github.com/YOUR_REPO/BeautyFinal.git
cd BeautyFinal
docker build -t beauty-api .
docker run --gpus all -d -p 8000:8000 beauty-api
```

#### Step 4: Access Your API
```
http://YOUR_VPS_IP:8000
http://YOUR_VPS_IP:8000/docs  # Swagger UI
```

#### What You Need to Save:
```
VPS_IP: 123.45.67.89
SSH_KEY: (store securely)
SSH_USERNAME: root (or custom)
```

---

## 🔐 Security Best Practices

### 1. Store Credentials Safely
```bash
# ❌ WRONG - Don't hardcode or commit!
API_KEY = "your-secret-key-here"  # in code
docker build -t api --build-arg KEY="secret"

# ✅ RIGHT - Use environment variables
export GCP_PROJECT_ID="beauty-final-project"
export AWS_ACCESS_KEY_ID="AKIA..."
# Add to ~/.bashrc or ~/.zshrc to persist

# Or use .env file (add to .gitignore!)
echo "GCP_PROJECT_ID=beauty-final-project" >> .env
source .env
```

### 2. Rotate Keys Regularly
- [ ] Change AWS/GCP credentials every 90 days
- [ ] Revoke old Docker Hub tokens
- [ ] Monitor API usage for suspicious activity

### 3. Limit Permissions
- **AWS IAM:** Only "AmazonEC2ContainerRegistryPowerUser" (not full admin)
- **GCP:** Use service accounts with minimal roles
- **Docker Hub:** Personal access token only, not password

### 4. Add API Authentication (After Deployment)
```python
# In main.py
from fastapi import Header, HTTPException

@app.post("/process")
async def process_images(
    front_image: UploadFile,
    side_image: UploadFile,
    x_api_key: str = Header(None)
):
    if x_api_key != os.getenv("API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API key")
    # ... process images
```

---

## 📋 Credentials Checklist

### For GCP Deployment:
- [ ] GCP account created
- [ ] Project created (note PROJECT_ID)
- [ ] gcloud CLI installed & authenticated
- [ ] Container Registry API enabled
- [ ] Compute Engine API enabled
- [ ] Docker image pushed to GCR

### For AWS Deployment:
- [ ] AWS account with billing
- [ ] IAM user created
- [ ] Access Key saved (KEEP SECRET!)
- [ ] AWS CLI configured
- [ ] ECR repository created
- [ ] Docker image pushed to ECR

### For Docker Hub Deployment:
- [ ] Docker Hub account created
- [ ] Username saved
- [ ] Access token generated (KEEP SECRET!)
- [ ] Logged in locally (`docker login`)
- [ ] Docker image pushed

### For Self-Hosted VPS:
- [ ] VPS rented & SSH access confirmed
- [ ] Docker installed on VPS
- [ ] Image pushed or built on VPS
- [ ] API accessible at VPS IP

---

## ❌ Common Mistakes to Avoid

1. **Committing credentials to git**
   - Use `.gitignore` for `.env` files
   - Use `git filter-branch` to remove if already committed

2. **Using same key for multiple services**
   - Create separate keys for each deployment

3. **Not rotating credentials**
   - Set calendar reminder every 90 days

4. **Sharing keys in Slack/Email**
   - Use encrypted password managers (1Password, LastPass)

5. **Hardcoding ngrok token** (your case!)
   - Already removed from Docker setup ✅

---

## 🆘 Need Help?

- **GCP Issues:** `gcloud logging read` or Cloud Console
- **AWS Issues:** Check CloudTrail and IAM policies
- **Docker Issues:** `docker logs <container_id>`
- **Network Issues:** `curl http://localhost:8000/health`

