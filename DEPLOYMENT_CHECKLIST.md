# BeautyFinal Deployment Checklist

## ✅ Pre-Deployment Requirements

### 1. **Local Environment**
- [ ] Docker installed and running
- [ ] 30GB+ free disk space (20GB for models + 10GB for image build)
- [ ] Git installed
- [ ] Internet connection (stable, for downloading ~5GB of models during build)

### 2. **Cloud Account** (Choose one)

#### Option A: Google Cloud Platform (Recommended for GPU)
- [ ] Google Cloud account created
- [ ] Project created
- [ ] Billing enabled
- [ ] `gcloud` CLI installed locally: `gcloud init`
- [ ] Container Registry API enabled
- [ ] Compute Engine API enabled (for GPU support)

#### Option B: AWS
- [ ] AWS account with billing enabled
- [ ] AWS CLI installed: `aws configure`
- [ ] ECR repository created
- [ ] IAM user with ECR push permissions

#### Option C: Docker Hub
- [ ] Docker Hub account created
- [ ] Logged in locally: `docker login`

#### Option D: Self-hosted VPS
- [ ] VPS/server with GPU support (optional but recommended)
- [ ] Docker installed on server
- [ ] SSH access configured

### 3. **Security & API Keys Needed** ⚠️ IMPORTANT

#### NOT NEEDED (already removed):
- ❌ **ngrok auth token** - Only used in Colab notebook, NOT for Docker deployment
- ❌ **Google Colab credentials** - Not applicable to production

#### DO YOU NEED:
**For Cloud Deployment:**
- [ ] Google Cloud service account JSON key (if using GCP)
- [ ] AWS access key ID & secret (if using AWS)
- [ ] Docker Hub credentials (if using Docker Hub)

**For Production Security (Add Later):**
- [ ] API Key for authentication (implement in `main.py` if restricting access)
- [ ] SSL/TLS certificate (from Let's Encrypt or your provider)
- [ ] CORS settings finalized (currently allows all origins)

---

## 🐳 Docker Build Checklist

```bash
# 1. Navigate to project
cd /workspaces/BeautyFinal

# 2. Build the image
docker build -t beauty-api:latest .

# Expected output:
# ✓ Pose estimation model downloaded
# ✓ PIFuHD model downloaded
# Build time: 20-30 minutes
# Image size: ~15-18GB
```

- [ ] Image builds successfully
- [ ] All models download without errors
- [ ] No "Out of memory" errors during build

---

## 🧪 Local Testing Before Deployment

```bash
# 1. Run container locally
docker run --gpus all -p 8000:8000 --name beauty-api-test beauty-api:latest

# 2. In another terminal, test health check
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","gpu_available":true,"models_loaded":true}

# 3. Test with sample images
curl -X POST "http://localhost:8000/process" \
  -F "front_image=@path/to/front.jpg" \
  -F "side_image=@path/to/side.jpg"

# 4. Stop test container
docker stop beauty-api-test
docker rm beauty-api-test
```

- [ ] Container starts without errors
- [ ] Health endpoint responds correctly
- [ ] GPU is detected (`gpu_available: true`)
- [ ] Can process sample images successfully
- [ ] Response includes all 7 measurements

---

## 🌐 Deployment Steps

### If Deploying to Google Cloud Run (Serverless):

```bash
# 1. Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 2. Enable services
gcloud services enable containerregistry.googleapis.com

# 3. Tag and push image
docker tag beauty-api:latest gcr.io/YOUR_PROJECT_ID/beauty-api:latest
docker push gcr.io/YOUR_PROJECT_ID/beauty-api:latest

# 4. Deploy
gcloud run deploy beauty-api \
  --image gcr.io/YOUR_PROJECT_ID/beauty-api:latest \
  --platform managed \
  --region us-central1 \
  --memory 4Gi \
  --timeout 3600 \
  --allow-unauthenticated
```

- [ ] GCP project created with ID noted
- [ ] `gcloud` authenticated
- [ ] Image pushed successfully (check: `gcloud container images list`)
- [ ] Service deployed (get URL from output)
- [ ] Service is accessible (test URL in browser)

### If Deploying to Google Compute Engine (VM + GPU):

```bash
# 1. Create GPU-enabled VM
gcloud compute instances create beauty-api \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --machine-type=n1-standard-4 \
  --zone=us-central1-a \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --scopes=https://www.googleapis.com/auth/cloud-platform

# 2. SSH into VM
gcloud compute ssh beauty-api --zone=us-central1-a

# 3. Inside VM, pull and run:
docker pull gcr.io/YOUR_PROJECT_ID/beauty-api:latest
docker run --gpus all -d -p 8000:8000 \
  --restart always \
  gcr.io/YOUR_PROJECT_ID/beauty-api:latest

# 4. Get external IP
gcloud compute instances describe beauty-api --zone=us-central1-a | grep natIP
```

- [ ] VM instance created with GPU
- [ ] SSH access confirmed
- [ ] Container running on VM
- [ ] External IP noted
- [ ] Port 8000 accessible from outside

### If Deploying to AWS ECS/Fargate:

```bash
# 1. Push to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

docker tag beauty-api:latest \
  YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/beauty-api:latest

docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/beauty-api:latest

# 2. Deploy via AWS Console (ECS > Create Service)
```

- [ ] ECR repository created
- [ ] Image pushed to ECR
- [ ] ECS task definition created
- [ ] Service running

---

## 🔒 Production Security Checklist

- [ ] Remove `allow-unauthenticated` flag (add API key validation)
- [ ] Add rate limiting to prevent abuse
- [ ] Enable HTTPS/SSL certificate
- [ ] Configure CORS to specific origins (not `["*"]`)
- [ ] Add request/response logging
- [ ] Set up monitoring (CloudWatch, Datadog, etc.)
- [ ] Configure alerts for high error rates
- [ ] Add backup storage for results (Cloud Storage, S3, etc.)
- [ ] Document API key distribution process

### Example: Add API Key to `main.py`
```python
from fastapi import Header, HTTPException

VALID_API_KEYS = {"your-secure-key-here"}

@app.post("/process")
async def process_images(
    front_image: UploadFile = File(...),
    side_image: UploadFile = File(...),
    x_api_key: str = Header(None)
):
    if x_api_key not in VALID_API_KEYS:
        raise HTTPException(status_code=401, detail="Invalid API key")
    # ... rest of function
```

---

## 📊 Performance & Optimization

### Recommended VM/Instance Specs:
- **CPU:** 4-8 cores
- **RAM:** 16-32GB
- **GPU:** NVIDIA Tesla T4 or better (for faster inference)
- **Storage:** 30GB (models + OS)

### Expected Performance:
- **Health check:** <100ms
- **Image processing:** 30-120 seconds (depends on GPU & image resolution)
- **Concurrent requests:** 1-3 (depending on memory)

### Optional Improvements:
- [ ] Add request queuing with Redis
- [ ] Implement result caching (Redis/Memcached)
- [ ] Add horizontal scaling (Kubernetes, auto-scaling groups)
- [ ] Monitor GPU memory usage
- [ ] Set up automated backups

---

## 🚨 Troubleshooting

| Problem | Solution |
|---------|----------|
| Image build fails | Check internet (models ~5GB), ensure 30GB free space |
| GPU not detected | Verify `nvidia-docker` installed, check `nvidia-smi` |
| Out of memory | Reduce image resolution in processing, increase RAM |
| Model download fails | Check URL, internet connection, disk space |
| 503 Service Unavailable | Increase timeout, check GPU memory, monitor logs |

---

## 📝 Post-Deployment Verification

```bash
# 1. Check service health
curl https://YOUR_DEPLOYED_URL/health

# 2. Get API docs
https://YOUR_DEPLOYED_URL/docs

# 3. Test with real images
curl -X POST "https://YOUR_DEPLOYED_URL/process" \
  -F "front_image=@front.jpg" \
  -F "side_image=@side.jpg" \
  -H "Authorization: Bearer YOUR_API_KEY"

# 4. Monitor logs
# GCP: gcloud logging read
# AWS: aws logs get-log-events
# Self-hosted: docker logs <container_id>
```

- [ ] API is responsive
- [ ] Documentation accessible
- [ ] Image processing works
- [ ] Results accurate
- [ ] Logs show no errors
- [ ] GPU utilization normal (50-95%)

---

## 📞 Support Resources

- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **Docker Docs:** https://docs.docker.com/
- **GCP Docs:** https://cloud.google.com/docs
- **AWS Docs:** https://docs.aws.amazon.com/
- **PyTorch Docs:** https://pytorch.org/docs/

