param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef,

  [Parameter(Mandatory = $true)]
  [string]$WorkerWebhook,

  [Parameter(Mandatory = $true)]
  [string]$WorkerSecret,

  [string]$LightOnOcrEndpoint = "",
  [string]$LightOnOcrToken = ""
)

$ErrorActionPreference = "Stop"

$argsList = @(
  "secrets",
  "set",
  "--project-ref", $ProjectRef,
  "OCR_WORKER_WEBHOOK=$WorkerWebhook",
  "OCR_WORKER_SECRET=$WorkerSecret"
)

if ($LightOnOcrEndpoint) {
  $argsList += "LIGHTON_OCR_ENDPOINT=$LightOnOcrEndpoint"
}
if ($LightOnOcrToken) {
  $argsList += "LIGHTON_OCR_TOKEN=$LightOnOcrToken"
}

$output = & supabase @argsList 2>&1
$output | Write-Output

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$joined = ($output | ForEach-Object { $_.ToString() }) -join "`n"
if ($joined -match "Unexpected error setting project secrets" -or
    $joined -match "necessary privileges") {
  throw "Failed to set Supabase secrets. Check project access/role permissions."
}
