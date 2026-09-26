# PDF to Word Pro (Flutter UI Prototype)

Dark themed mobile UI prototype based on provided reference screens.

## Implemented

- Login screen with mock Apple/Google/Email auth actions
- Convert screen with real file picker, signed upload, and job polling flow
- Direct bytes conversion fallback: when the signed storage upload fails
  (storage outage, offline device) or `create_job` fails, the app sends PDF
  bytes to the OCR worker's `POST /internal/convert` endpoint and keeps the
  result locally
- In-app DOCX **preview** (headings, bullets, page breaks rendered from
  `word/document.xml`) that opens automatically after a successful conversion;
  also available from Recent/History cards via the eye icon
- Structured PDF → Word conversion (headings, lists, tables, bold/italic, page breaks) via PyMuPDF + python-docx
- History screen with grouped conversion items
- History screen with row status badges and signed URL download action
- Settings screen with profile, toggles, and language switch
- Routing via `go_router` (`/auth`, `/convert`, `/history`, `/settings`)
- State management via `flutter_riverpod`
- TR/EN localization skeleton (TR default)
- Widget/unit test coverage and golden test scaffold

## Local Flutter Tooling (this workspace)

Flutter SDK is installed in:

`c:\projeler\pdfword\tools\flutter`

Use full path commands if `flutter` is not in your shell PATH:

```bash
c:\projeler\pdfword\tools\flutter\bin\flutter.bat pub get
c:\projeler\pdfword\tools\flutter\bin\flutter.bat test
```

Or use wrapper:

```powershell
.\scripts\flutterw.ps1 pub get
.\scripts\flutterw.ps1 test
```

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```

Real-backend smoke test on a device/emulator (creates a job, uploads through
the signed URL, runs the OCR worker, downloads the DOCX and verifies its text):

```bash
flutter test integration_test/emulator_real_flow_test.dart -d emulator-5554
```

Manual "Open in Word" diagnostic on a device/emulator (reports whether the
device has a DOCX viewer, then runs the real open service and checks the temp
file name it hands to the intent; the system share sheet opens on devices
without a viewer):

```bash
flutter test integration_test/open_in_word_diagnostics_test.dart -d emulator-5554
```

## Real Backend Mode (Supabase + OCR Worker)

The app supports real backend mode behind compile-time flags:

- `USE_REAL_BACKEND=true`
- `SUPABASE_URL=...`
- `SUPABASE_ANON_KEY=...`

Example:

```bash
flutter run -d chrome --dart-define=USE_REAL_BACKEND=true --dart-define=SUPABASE_URL=https://YOUR.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Web runtime alternative:

- Edit `web/index.html` and set `<meta name="pdfword-supabase-anon-key" ...>`.
- `SUPABASE_URL` is prefilled for this project via `<meta name="pdfword-supabase-url" ...>`.

### Supabase assets

- SQL migration: `supabase/migrations/20260216190000_ocr_schema.sql`
- Edge functions:
  - `supabase/functions/create_job/index.ts`
  - `supabase/functions/enqueue_job/index.ts`
  - `supabase/functions/get_job_status/index.ts`
  - `supabase/functions/get_download_url/index.ts`
  - `supabase/functions/process_job/index.ts` (worker webhook target)

### OCR worker

- Code: `backend/ocr_worker/main.py`
- Dockerfile: `backend/ocr_worker/Dockerfile`
- Requirements: `backend/ocr_worker/requirements.txt`
- Supports local embedded-text extraction for text PDFs (`pypdf`), open-source OCR fallback (`OCRmyPDF + Tesseract`, then direct Tesseract) for scanned PDFs, and optional external OCR fallback.
- Render worker image includes a Turkish `tessdata_best` model (`tur.traineddata`) for improved TR OCR attempts.
- Direct conversion endpoint: `POST /internal/convert` (multipart `files`, optional
  `job_id`) converts uploaded bytes without downloading from storage. With
  Supabase credentials it persists the job/artifacts; without them it returns
  `docx_base64` + `markdown` inline so the app can keep the result locally.

### Running the conversion locally (dev/emulator)

```powershell
# Start the worker (Supabase env optional; without it results come back inline)
python -m uvicorn main:app --app-dir backend/ocr_worker --host 0.0.0.0 --port 8080
# or: .\scripts\run_ocr_worker.ps1 -SupabaseUrl ... -SupabaseServiceRoleKey ...
```

The app prefers the worker directly:

1. `POST {OCR_WORKER_URL}/internal/process` after a successful storage upload.
2. If the signed storage upload is blocked (e.g. `403 new row violates
   row-level security policy`) or `create_job` fails, it falls back to
   `POST {OCR_WORKER_URL}/internal/convert` with raw PDF bytes.
3. Only then does it fall back to the hosted `enqueue_job` function.

Defaults: the app targets the hosted production worker
(`https://pdfword-ocr-worker.onrender.com`), so release builds on physical
devices work without extra dart-defines.

The worker bearer secret is **not** committed to the repository. Pass it at
build time:

```bash
flutter build appbundle --release --dart-define=OCR_WORKER_SECRET=<secret>
```

For web builds, add the meta tags to `web/index.html` instead:

```html
<meta name="pdfword-ocr-worker-url" content="https://pdfword-ocr-worker.onrender.com">
<meta name="pdfword-ocr-worker-secret" content="<secret>">
```

When the secret is absent the app simply skips the direct worker calls and uses
the hosted Supabase edge functions, which keep working.

For local development against a worker on your machine, override with
`--dart-define=OCR_WORKER_URL=http://10.0.2.2:8080` (Android emulator host
loopback) and `--dart-define=OCR_WORKER_SECRET=...`. Cleartext HTTP is enabled
in the debug manifest for this purpose.

Note: guest conversions send a stable per-install `device_id_hash` (random
128-bit id stored via `shared_preferences`) so the daily free quota is
enforced per device instead of collapsing all guests into one shared bucket.

### Deployed worker must match this source tree

The Flutter client calls `POST /internal/convert` on the fallback path, so the
Render image has to be built from the same revision as `backend/ocr_worker`.
When it drifts behind, the endpoint starts returning `404` and every conversion
that needs the fallback fails while `/healthz` still reports `200`.

Check before shipping:

```bash
python scripts/check_worker_deployment.py
```

It compares the local `main.py` version against the deployed `/openapi.json` and
lists missing endpoints. Fix a failure with a Render redeploy (Blueprint
`autoDeploy`, or Dashboard > Manual Deploy).

### Worker resilience on the free Render tier

The free plan parks the container between requests, so the first call after an
idle period can return `503` while the container spins back up. The app
therefore:

- pings `GET /healthz` before posting a job, so the spin-up cost lands on a
  cheap probe instead of the conversion request;
- retries transient failures (`408`, `429`, `502`, `503`, `504`) up to 3 times
  with backoff;
- allows 60s to establish the connection and holds the job request open for up
  to 15 minutes, because OCR is slow (a single scanned page takes ~65s) and the
  worker processes the job synchronously.

`render.yaml` also pins `TESSERACT_PSM_CANDIDATES=6` and
`TESSERACT_MAX_VARIANTS=1`; the previous `6,4` x `3` combination allowed up to
six Tesseract passes per page, which is what pushed a one-page scan past the
client timeout.

### Signed upload (verified against hosted storage v1.77.5)

Presigned uploads go to
`PUT /storage/v1/object/upload/sign/{bucket}/{path}?token=...` and the storage
route runs as superuser, so the signed-upload conversion flow works **without**
any `storage.objects` RLS policy. The Dart SDK (`uploadBinaryToSignedUrl` ->
`putBinaryFile`) already uses `PUT`.

Pitfall: sending the same token with `POST` (or `uploadBinary` to
`POST /object/{bucket}/{path}`) hits the create-object route, which inserts as
`anon` and fails with `403 new row violates row-level security policy`.
`supabase/migrations/20260924120000_storage_policies.sql` keeps the matching
insert/select policies as optional hardening for that POST path.

Conversion pipeline (structured output):

1. **Extraction** — `extract_pdf_text_sections` prefers PyMuPDF (`fitz`): headings (font size vs. page average), bold/italic/mono span flags (16/2/8), bullet lists, and `page.find_tables()` grids become Markdown per page; plain text falls back to `pypdf`.
2. **DOCX render** — `markdown_to_docx_bytes` (python-docx) maps that Markdown to Heading 1–3 styles, List Bullet, bold/italic/mono runs, real Word tables, blockquote notes (`> ` lines), and hard page breaks between pages (the `<!-- pagebreak -->` marker, plus legacy `### Page N` headings).
3. **Artifacts** — worker uploads `ocr-results/{job_id}/result.md` and `result.docx`; the source filename becomes the document H1.
4. **Regression test** — `python backend/ocr_worker/test_conversion.py` runs 19 checks over extraction and DOCX structure (sample PDF built with PyMuPDF, plus a `fitz = None` fallback path).

Worker env vars:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OCR_INPUT_BUCKET` (default: `ocr-inputs`)
- `OCR_RESULTS_BUCKET` (default: `ocr-results`)
- `OPEN_SOURCE_OCR_ENABLED` (default: `true`)
- `OCRMYPDF_ENABLED` (default: `true`)
- `OCRMYPDF_LANG` (default: uses `TESSERACT_LANG`)
- `OCRMYPDF_JOBS` (default: `1`)
- `OCRMYPDF_TIMEOUT_SEC` (default: `240`)
- `OCRMYPDF_TESSERACT_TIMEOUT_SEC` (default: derived from `TESSERACT_CALL_TIMEOUT_SEC`)
- `OCRMYPDF_FORCE_OCR` (default: `true`)
- `OCRMYPDF_ROTATE_PAGES` (default: `false`)
- `OCRMYPDF_DESKEW` (default: `false`)
- `OCRMYPDF_CLEAN_FINAL` (default: `false`)
- `OCRMYPDF_OUTPUT_TYPE` (default: `pdf`)
- `TESSERACT_LANG` (default: `tur`)
- `TESSERACT_DPI` (default: `300`)
- `TESSERACT_PSM` (default: `6`)
- `TESSERACT_OEM` (default: `1`)
- `TESSERACT_PSM_CANDIDATES` (default: `6,4`)
- `TESSERACT_MAX_VARIANTS` (default: `3`)
- `TESSERACT_CALL_TIMEOUT_SEC` (default: `10`)
- `TESSERACT_MAX_ATTEMPTS` (default: `3`)
- Optional LightOn endpoint integration:
  - `LIGHTON_OCR_ENDPOINT`
  - `LIGHTON_OCR_TOKEN`

## Production notes

- Public functions are deployed with JWT verification enabled:
  - `create_job`, `enqueue_job`, `get_job_status`, `get_download_url`
- Internal worker endpoint:
  - `process_job` is deployed with `--no-verify-jwt` and protected by `OCR_WORKER_SECRET`
- Required Supabase secrets:
  - `OCR_WORKER_WEBHOOK=https://<project-ref>.supabase.co/functions/v1/process_job` (Supabase internal worker)
  - or `OCR_WORKER_WEBHOOK=https://<your-worker-host>/internal/process` (Python worker, recommended for local text extraction)
  - `OCR_WORKER_SECRET=<random-strong-secret>`
