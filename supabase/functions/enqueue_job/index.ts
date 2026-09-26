import { createClient } from "https://esm.sh/@supabase/supabase-js@2.56.0";
import { corsHeaders } from "../_shared/cors.ts";
import { buildDocxFromText } from "../_shared/docx.ts";

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function sanitizeBaseName(name: string) {
  const noExt = name.replace(/\.[^/.]+$/, "");
  const cleaned = noExt.replace(/[^a-zA-Z0-9._-]/g, "_").trim();
  return cleaned.length > 0 ? cleaned : "converted";
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(500, { error: "missing_supabase_env" });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const body = (await req.json().catch(() => ({}))) as { job_id?: string };
    const jobId = body.job_id?.toString().trim();
    if (!jobId) {
      return jsonResponse(400, { error: "job_id_required" });
    }

    const updateRes = await admin
      .from("ocr_jobs")
      .update({
        status: "processing",
        progress_pct: 10,
        started_at: new Date().toISOString(),
      })
      .eq("id", jobId)
      .select("id, input_meta")
      .single();

    if (updateRes.error || !updateRes.data) {
      return jsonResponse(404, { error: "job_not_found" });
    }

    const workerWebhook = Deno.env.get("OCR_WORKER_WEBHOOK") ?? "";
    if (!workerWebhook) {
      const outputBucket = Deno.env.get("OCR_RESULTS_BUCKET") ?? "ocr-results";
      const inputMeta = Array.isArray(updateRes.data.input_meta)
        ? updateRes.data.input_meta
        : [];
      const firstName = inputMeta[0]?.name?.toString() ?? "converted";
      const baseName = sanitizeBaseName(firstName);
      const outputPath = `${jobId}/output/${baseName}.docx`;
      const fallbackText = [
        "PDF to Word Pro fallback output.",
        "",
        "No OCR worker is configured for this environment.",
        "",
        `Input file: ${firstName}`,
      ].join("\n");
      const placeholderDocx = buildDocxFromText(fallbackText);

      const uploadRes = await admin.storage
        .from(outputBucket)
        .upload(outputPath, placeholderDocx, {
          contentType:
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          upsert: true,
        });

      if (uploadRes.error) {
        await admin
          .from("ocr_jobs")
          .update({
            status: "failed",
            progress_pct: 100,
            error_code: "placeholder_upload_failed",
            error_message: uploadRes.error.message,
            finished_at: new Date().toISOString(),
          })
          .eq("id", jobId);

        return jsonResponse(500, {
          error: "placeholder_upload_failed",
          detail: uploadRes.error.message,
        });
      }

      await admin
        .from("ocr_jobs")
        .update({
          status: "succeeded",
          progress_pct: 100,
          output_docx_path: outputPath,
          finished_at: new Date().toISOString(),
        })
        .eq("id", jobId);

      return jsonResponse(200, {
        job_id: jobId,
        status: "succeeded",
        output_docx_path: outputPath,
        mode: "placeholder",
      });
    }

    const workerSecret = Deno.env.get("OCR_WORKER_SECRET") ?? "";
    await fetch(workerWebhook, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(workerSecret ? { Authorization: `Bearer ${workerSecret}` } : {}),
      },
      body: JSON.stringify({ job_id: jobId }),
    });

    return jsonResponse(200, {
      job_id: jobId,
      status: "processing",
    });
  } catch (error) {
    return jsonResponse(500, {
      error: "unexpected_error",
      detail: error instanceof Error ? error.message : "unknown",
    });
  }
});
