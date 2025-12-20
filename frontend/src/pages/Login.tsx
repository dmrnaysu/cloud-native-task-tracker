import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export default function Login() {
  const { login } = useAuth();
  const nav = useNavigate();
  const [email, setEmail] = useState("demo@demo.com");
  const [password, setPassword] = useState("Password123!");
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="container">
      <div className="card" style={{ maxWidth: 520, margin: "60px auto" }}>
        <h2>Login</h2>
        <small>Use demo credentials or create your own account.</small>
        <hr />
        {error ? <p style={{ color: "#ff8a8a" }}>{error}</p> : null}
        <small>Email</small>
        <input value={email} onChange={(e) => setEmail(e.target.value)} />
        <div style={{ height: 10 }} />
        <small>Password</small>
        <input value={password} type="password" onChange={(e) => setPassword(e.target.value)} />
        <div style={{ height: 14 }} />
        <button
          onClick={async () => {
            setError(null);
            try { await login(email, password); nav("/"); }
            catch (e: any) { setError(e?.response?.data?.message || "Login failed"); }
          }}
        >
          Login
        </button>
        <div style={{ marginTop: 12 }}>
          <small>Donâ€™t have an account? <Link to="/signup">Sign up</Link></small>
        </div>
      </div>
    </div>
  );
}
