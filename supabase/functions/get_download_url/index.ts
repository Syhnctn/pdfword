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
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();
    let userId: string | null = null;
    if (jwt) {
      const authResult = await admin.auth.getUser(jwt);
      userId = authResult.data.user?.id ?? null;
    }

    const body = (await req.json().catch(() => ({}))) as { job_id?: string };
    const jobId = body.job_id?.toString().trim();
    if (!jobId) {
      return jsonResponse(400, { error: "job_id_required" });
    }

    const jobRes = await admin
      .from("ocr_jobs")
      .select("id, user_id, device_id_hash, status, output_docx_path")
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
    if (userId != null) {
      if (jobRes.data.user_id !== userId) {
        return jsonResponse(403, { error: "forbidden_job_access" });
      }
    } else if (jobRes.data.user_id != null) {
      return jsonResponse(401, { error: "auth_required_for_user_job" });
    }
    if (jobRes.data.status !== "succeeded") {
      return jsonResponse(409, { error: "job_not_ready" });
    }

    const outputPath = jobRes.data.output_docx_path?.toString().trim() ?? "";
    if (!outputPath) {
      return jsonResponse(404, { error: "output_not_found" });
    }

    const outputBucket = Deno.env.get("OCR_RESULTS_BUCKET") ?? "ocr-results";
    const signedRes = await admin.storage
      .from(outputBucket)
      .createSignedUrl(outputPath, 60 * 15);

    if (signedRes.error || !signedRes.data?.signedUrl) {
      return jsonResponse(500, {
        error: "signed_url_failed",
        detail: signedRes.error?.message,
      });
    }

    return jsonResponse(200, {
      job_id: jobId,
      signed_url: signedRes.data.signedUrl,
      expires_in: 900,
    });
  } catch (error) {
    return jsonResponse(500, {
      error: "unexpected_error",
      detail: error instanceof Error ? error.message : "unknown",
    });
  }
});
