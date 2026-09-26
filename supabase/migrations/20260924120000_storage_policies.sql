-- Optional storage hardening for the conversion buckets.
--
-- The signed-upload path (`PUT /storage/v1/object/upload/sign/{bucket}/{path}`)
-- runs as the storage superuser on hosted Supabase (verified on storage
-- v1.77.5), so the app's `uploadBinaryToSignedUrl` flow works without these
-- policies. Add them only if the app switches to a plain `uploadBinary`
-- (POST /object/{bucket}/{path}) upload, which inserts as `anon` and otherwise
-- fails with:
--   403 new row violates row-level security policy
-- Apply via `supabase db push` or paste into the dashboard SQL editor.

drop policy if exists "ocr_inputs_insert_signed" on storage.objects;
create policy "ocr_inputs_insert_signed" on storage.objects
for insert to anon, authenticated
with check (bucket_id = 'ocr-inputs');

drop policy if exists "ocr_results_select" on storage.objects;
create policy "ocr_results_select" on storage.objects
for select to anon, authenticated
using (bucket_id = 'ocr-results');
