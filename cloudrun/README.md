# Cloud Run container for recommendations

## Setup

### File structure

The Dockerfile is located at `docker/Dockerfile` and the apps are in the relevant folders so that the Docker context contains both.

### Building

#### Run this from cloud_run/

```sh
docker build -f docker/Dockerfile -t recommendations-cloudrun-image .
```

### Deploying

When deploying to Cloud Run, you can either:

- Mount the service account JSON as a secret
  - Create a service account in Google Cloud Console with:
    - Firestore Reader role
    - Service Account Token Creator role (for authentication)
  - Download the JSON key file
- Or rely on the default service account (recommended for simplicity)

```sh
gcloud run deploy firestore-to-csv \
  --image gcr.io/YOUR_PROJECT_ID/firestore-to-csv \
  --platform managed \
  --region us-central1 \
  --memory 512Mi \
  --command="/app/export_firestore" \
  --args="--collection=YOUR_COLLECTION,--output=/tmp/output.csv,--project=YOUR_PROJECT_ID" \
  --service-account=YOUR_SERVICE_ACCOUNT_EMAIL \
  --set-env-vars="GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json" \
  --no-allow-unauthenticated
```
