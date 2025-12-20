import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { api, setAuthToken } from "../api/client";

type User = { id: string; email: string };
type AuthCtx = {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string) => Promise<void>;
  logout: () => void;
};

const Ctx = createContext<AuthCtx | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem("token"));
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    setAuthToken(token);
    if (token) localStorage.setItem("token", token);
    else localStorage.removeItem("token");
  }, [token]);

  useEffect(() => {
    (async () => {
      if (!token) return;
      try {
        const res = await api.get("/auth/me");
        setUser(res.data.user);
      } catch {
        setToken(null);
        setUser(null);
      }
    })();
  }, [token]);

  async function login(email: string, password: string) {
    const res = await api.post("/auth/login", { email, password });
    setToken(res.data.token);
    setUser(res.data.user);
  }

  async function signup(email: string, password: string) {
    const res = await api.post("/auth/signup", { email, password });
    setToken(res.data.token);
    setUser(res.data.user);
  }

  function logout() {
    setToken(null);
    setUser(null);
  }

  const value = useMemo(() => ({ user, token, login, signup, logout }), [user, token]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
