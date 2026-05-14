(function () {
  const SUPABASE_URL = "https://YOUR_PROJECT_ID.supabase.co";
  const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";

  function isConfigured() {
    return (
      SUPABASE_URL.includes(".supabase.co") &&
      !SUPABASE_URL.includes("YOUR_PROJECT_ID") &&
      !SUPABASE_ANON_KEY.includes("YOUR_SUPABASE_ANON_KEY")
    );
  }

  function client() {
    if (!isConfigured() || !window.supabase) return null;
    return window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }

  async function insert(table, payload) {
    const supabaseClient = client();
    if (!supabaseClient) {
      return { ok: false, mode: "local", reason: "Supabase is not configured yet." };
    }

    const { error } = await supabaseClient.from(table).insert(payload);
    if (error) {
      console.warn("Supabase insert failed:", error.message);
      return { ok: false, mode: "supabase", reason: error.message };
    }

    return { ok: true, mode: "supabase" };
  }

  window.HerBidSupabase = {
    isConfigured,
    insert
  };
})();
