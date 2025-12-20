import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export default function Signup() {
  const { signup } = useAuth();
  const nav = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="container">
      <div className="card" style={{ maxWidth: 520, margin: "60px auto" }}>
        <h2>Create account</h2>
        <hr />
        {error ? <p style={{ color: "#ff8a8a" }}>{error}</p> : null}
        <small>Email</small>
        <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@email.com" />
        <div style={{ height: 10 }} />
        <small>Password</small>
        <input value={password} type="password" onChange={(e) => setPassword(e.target.value)} placeholder="min 8 chars" />
        <div style={{ height: 14 }} />
        <button
          onClick={async () => {
            setError(null);
            try { await signup(email, password); nav("/"); }
            catch (e: any) { setError(e?.response?.data?.message || "Signup failed"); }
          }}
        >
          Sign up
        </button>
        <div style={{ marginTop: 12 }}>
          <small>Already have an account? <Link to="/login">Login</Link></small>
        </div>
      </div>
    </div>
  );
}
