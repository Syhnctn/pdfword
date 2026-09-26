param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$flutter = "c:\projeler\pdfword\tools\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    Write-Error "Flutter SDK not found at $flutter"
    exit 1
}

& $flutter @Args
exit $LASTEXITCODE
