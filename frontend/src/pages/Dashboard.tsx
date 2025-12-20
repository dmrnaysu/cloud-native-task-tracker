import React, { useEffect, useState } from "react";
import { api } from "../api/client";
import { useAuth } from "../auth/AuthContext";
import JobForm, { JobCreate, JobStatus } from "../components/JobForm";
import JobList, { Job } from "../components/JobList";

export default function Dashboard() {
  const { user, logout } = useAuth();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [err, setErr] = useState<string | null>(null);

  async function refresh() {
    const res = await api.get("/jobs");
    setJobs(res.data.jobs);
  }

  useEffect(() => {
    (async () => {
      try { await refresh(); }
      catch (e: any) { setErr(e?.response?.data?.message || "Failed to load jobs"); }
    })();
  }, []);

  async function onCreate(job: JobCreate) {
    await api.post("/jobs", job);
    await refresh();
  }

  async function onDelete(id: string) {
    await api.delete(/jobs/);
    await refresh();
  }

  async function onUpdateStatus(id: string, status: JobStatus) {
    await api.put(/jobs/, { status });
    await refresh();
  }

  return (
    <div className="container">
      <div className="row" style={{ justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <h2 style={{ marginBottom: 0 }}>Dashboard</h2>
          <small>Logged in as: {user?.email}</small>
        </div>
        <div className="row">
          <a href="http://localhost:4000/api/docs" target="_blank" rel="noreferrer">Swagger</a>
          <button className="secondary" onClick={logout}>Logout</button>
        </div>
      </div>

      {err ? <p style={{ color: "#ff8a8a" }}>{err}</p> : null}

      <div style={{ height: 16 }} />
      <JobForm onCreate={onCreate} />
      <div style={{ height: 16 }} />
      <JobList jobs={jobs} onDelete={onDelete} onUpdateStatus={onUpdateStatus} />
    </div>
  );
}
