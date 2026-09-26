import { createClient } from "https://esm.sh/@supabase/supabase-js@2.56.0";
import { corsHeaders } from "../_shared/cors.ts";

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
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

    const jobRes = await admin
      .from("ocr_jobs")
      .select(
        "id, status, progress_pct, error_code, error_message, output_docx_path, output_md_path, created_at, finished_at",
      )
      .eq("id", jobId)
      .maybeSingle();

    if (jobRes.error) {
      return jsonResponse(500, {
        error: "job_query_failed",
        detail: jobRes.error.message,
      });
    }
    if (!jobRes.data) {
      return jsonResponse(404, { error: "job_not_found" });
    }

    return jsonResponse(200, {
      job: jobRes.data,
    });
  } catch (error) {
    return jsonResponse(500, {
      error: "unexpected_error",
      detail: error instanceof Error ? error.message : "unknown",
    });
  }
});
