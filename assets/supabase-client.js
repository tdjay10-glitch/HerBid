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

  function authStorageKey() {
    return "herbidSupabaseSession";
  }

  function getSession() {
    try {
      return JSON.parse(localStorage.getItem(authStorageKey()) || "null");
    } catch (error) {
      return null;
    }
  }

  function setSession(session) {
    if (session && session.access_token) {
      localStorage.setItem(authStorageKey(), JSON.stringify(session));
    } else {
      localStorage.removeItem(authStorageKey());
    }
  }

  function setSessionFromUrlHash() {
    const params = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const accessToken = params.get("access_token");
    const refreshToken = params.get("refresh_token");
    const type = params.get("type");
    if (!accessToken) return null;

    const session = {
      access_token: accessToken,
      refresh_token: refreshToken,
      token_type: params.get("token_type") || "bearer",
      expires_at: params.get("expires_at"),
      expires_in: params.get("expires_in"),
      type
    };
    setSession(session);
    return session;
  }

  async function request(path, options = {}) {
    if (!isConfigured()) {
      return { ok: false, reason: "Supabase is not configured yet." };
    }

    try {
      const response = await fetch(`${SUPABASE_URL}${path}`, {
        ...options,
        headers: {
          apikey: SUPABASE_ANON_KEY,
          "Content-Type": "application/json",
          ...(options.headers || {})
        }
      });
      const text = await response.text();
      const data = text ? JSON.parse(text) : null;

      if (!response.ok) {
        return { ok: false, status: response.status, reason: data?.msg || data?.message || text };
      }

      return { ok: true, data };
    } catch (error) {
      return { ok: false, reason: error.message };
    }
  }

  function authHeaders() {
    const session = getSession();
    return session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {};
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

  async function signUp({ email, password, profile }) {
    const result = await request("/auth/v1/signup", {
      method: "POST",
      body: JSON.stringify({ email, password })
    });

    if (!result.ok) return result;
    if (result.data?.access_token) {
      setSession(result.data);
      await upsertProfile(profile);
    }

    return result;
  }

  async function signIn({ email, password }) {
    const result = await request("/auth/v1/token?grant_type=password", {
      method: "POST",
      body: JSON.stringify({ email, password })
    });

    if (result.ok) setSession(result.data);
    return result;
  }

  async function requestPasswordReset(email) {
    return request("/auth/v1/recover", {
      method: "POST",
      body: JSON.stringify({
        email,
        redirect_to: `${window.location.origin}/dashboard.html`
      })
    });
  }

  async function updatePassword(password) {
    return request("/auth/v1/user", {
      method: "PUT",
      headers: authHeaders(),
      body: JSON.stringify({ password })
    });
  }

  async function signOut() {
    const session = getSession();
    if (session?.access_token) {
      await request("/auth/v1/logout", {
        method: "POST",
        headers: authHeaders()
      });
    }
    setSession(null);
  }

  async function upsertProfile(profile) {
    const session = getSession();
    if (!session?.user?.id) {
      return { ok: false, reason: "No signed-in user." };
    }

    return request("/rest/v1/user_profiles", {
      method: "POST",
      headers: {
        ...authHeaders(),
        Prefer: "resolution=merge-duplicates,return=representation"
      },
      body: JSON.stringify({
        id: session.user.id,
        email: session.user.email,
        ...profile
      })
    });
  }

  async function getProfile() {
    const session = getSession();
    if (!session?.user?.id) {
      return { ok: false, reason: "No signed-in user." };
    }

    return request(`/rest/v1/user_profiles?id=eq.${session.user.id}&select=*`, {
      method: "GET",
      headers: authHeaders()
    });
  }

  async function listSavedOpportunities() {
    return request("/rest/v1/saved_opportunities?select=*&order=created_at.desc", {
      method: "GET",
      headers: authHeaders()
    });
  }

  async function listOpportunities() {
    return request("/rest/v1/opportunities?select=*&is_active=eq.true&order=deadline_date.asc", {
      method: "GET",
      headers: authHeaders()
    });
  }

  async function upsertOpportunity(opportunity) {
    return request("/rest/v1/opportunities?on_conflict=id", {
      method: "POST",
      headers: {
        ...authHeaders(),
        Prefer: "resolution=merge-duplicates,return=minimal"
      },
      body: JSON.stringify(opportunity)
    });
  }

  async function deactivateOpportunity(opportunityId) {
    return request(`/rest/v1/opportunities?id=eq.${opportunityId}`, {
      method: "PATCH",
      headers: {
        ...authHeaders(),
        Prefer: "return=minimal"
      },
      body: JSON.stringify({ is_active: false })
    });
  }

  async function saveOpportunity(opportunity) {
    const session = getSession();
    if (!session?.user?.id) {
      return { ok: false, reason: "No signed-in user." };
    }

    return request("/rest/v1/saved_opportunities?on_conflict=user_id,opportunity_id", {
      method: "POST",
      headers: {
        ...authHeaders(),
        Prefer: "resolution=merge-duplicates,return=minimal"
      },
      body: JSON.stringify({
        user_id: session.user.id,
        opportunity_id: opportunity.id,
        title: opportunity.title,
        agency: opportunity.agency,
        deadline: opportunity.deadline,
        naics: opportunity.naics,
        set_aside: opportunity.setAside,
        source_url: opportunity.link
      })
    });
  }

  async function removeSavedOpportunity(opportunityId) {
    return request(`/rest/v1/saved_opportunities?opportunity_id=eq.${opportunityId}`, {
      method: "DELETE",
      headers: {
        ...authHeaders(),
        Prefer: "return=minimal"
      }
    });
  }

  window.HerBidSupabase = {
    isConfigured,
    getSession,
    setSessionFromUrlHash,
    insert,
    signUp,
    signIn,
    requestPasswordReset,
    updatePassword,
    signOut,
    upsertProfile,
    getProfile,
    listOpportunities,
    upsertOpportunity,
    deactivateOpportunity,
    listSavedOpportunities,
    saveOpportunity,
    removeSavedOpportunity
  };
})();
