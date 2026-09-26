param(
  [Parameter(Mandatory = $true)]
  [string]$SupabaseUrl,

  [Parameter(Mandatory = $true)]
  [string]$SupabaseServiceRoleKey,

  [string]$OcrWorkerSecret = "",
  [string]$OcrInputBucket = "ocr-inputs",
  [string]$OcrResultsBucket = "ocr-results",
  [string]$LightOnOcrEndpoint = "",
  [string]$LightOnOcrToken = "",
  [string]$Host = "0.0.0.0",
  [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

$env:SUPABASE_URL = $SupabaseUrl
$env:SUPABASE_SERVICE_ROLE_KEY = $SupabaseServiceRoleKey
$env:OCR_INPUT_BUCKET = $OcrInputBucket
$env:OCR_RESULTS_BUCKET = $OcrResultsBucket

if ($OcrWorkerSecret) {
  $env:OCR_WORKER_SECRET = $OcrWorkerSecret
}
if ($LightOnOcrEndpoint) {
  $env:LIGHTON_OCR_ENDPOINT = $LightOnOcrEndpoint
}
if ($LightOnOcrToken) {
  $env:LIGHTON_OCR_TOKEN = $LightOnOcrToken
}

python -m uvicorn main:app --app-dir backend/ocr_worker --host $Host --port $Port
