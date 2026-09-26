# Supabase Edge Functions

## Functions

- `create_job`: validates quota and inserts a new row in `ocr_jobs`
- `enqueue_job`: marks job as processing and triggers worker webhook
- `get_job_status`: returns current status/output paths of a job
- `get_download_url`: returns a short-lived signed URL for the converted docx
- `process_job`: internal worker endpoint (webhook target for `enqueue_job`)

## Required environment variables

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OCR_INPUT_BUCKET` (default: `ocr-inputs`)
- `OCR_RESULTS_BUCKET` (default: `ocr-results`)
- `OCR_WORKER_WEBHOOK` (recommended, can be `.../functions/v1/process_job` or an external worker such as `http://host:8080/internal/process`)
- `OCR_WORKER_SECRET` (required when `process_job` is exposed without JWT verify)

## Deploy

```bash
supabase functions deploy create_job
supabase functions deploy enqueue_job
supabase functions deploy get_job_status
supabase functions deploy get_download_url
supabase functions deploy process_job --no-verify-jwt
```
