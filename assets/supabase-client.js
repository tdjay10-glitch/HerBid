(function () {
  const SUPABASE_URL = "https://lziyyqnwgbyteztvqojo.supabase.co";
  const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6aXl5cW53Z2J5dGV6dHZxb2pvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3ODAzNzAsImV4cCI6MjA5NDM1NjM3MH0.WDk283T8mI_IpaPsMoU7C9QPS3qD4N2YuAc6GSF3xAE";

  function isConfigured() {
    return (
      SUPABASE_URL.includes(".supabase.co") &&
      !SUPABASE_URL.includes("YOUR_PROJECT_ID") &&
      !SUPABASE_ANON_KEY.includes("YOUR_SUPABASE_ANON_KEY")
    );
  }

  async function insert(table, payload) {
    if (!isConfigured()) {
      return { ok: false, mode: "local", reason: "Supabase is not configured yet." };
    }

    try {
      const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
        method: "POST",
        headers: {
          apikey: SUPABASE_ANON_KEY,
          "Content-Type": "application/json",
          Prefer: "return=minimal"
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const message = await response.text();
        console.warn("Supabase insert failed:", message);
        return { ok: false, mode: "supabase", reason: message };
      }

      return { ok: true, mode: "supabase" };
    } catch (error) {
      console.warn("Supabase insert failed:", error.message);
      return { ok: false, mode: "supabase", reason: error.message };
    }
  }

  window.HerBidSupabase = {
    isConfigured,
    insert
  };
})();
