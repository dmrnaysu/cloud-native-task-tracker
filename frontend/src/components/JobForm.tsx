import React, { useState } from "react";

export type JobStatus = "SAVED" | "APPLIED" | "INTERVIEWING" | "OFFER" | "REJECTED";
export type JobCreate = { company: string; role: string; status?: JobStatus; notes?: string };

export default function JobForm({ onCreate }: { onCreate: (job: JobCreate) => Promise<void> }) {
  const [company, setCompany] = useState("");
  const [role, setRole] = useState("");
  const [status, setStatus] = useState<JobStatus>("SAVED");
  const [notes, setNotes] = useState("");

  return (
    <div className="card">
      <h3>Add Job</h3>
      <div className="row">
        <div style={{ flex: 1, minWidth: 220 }}>
          <small>Company</small>
          <input value={company} onChange={(e) => setCompany(e.target.value)} placeholder="Google" />
        </div>
        <div style={{ flex: 1, minWidth: 220 }}>
          <small>Role</small>
          <input value={role} onChange={(e) => setRole(e.target.value)} placeholder="Cloud Engineer" />
        </div>
        <div style={{ width: 220 }}>
          <small>Status</small>
          <select value={status} onChange={(e) => setStatus(e.target.value as JobStatus)}>
            <option value="SAVED">SAVED</option>
            <option value="APPLIED">APPLIED</option>
            <option value="INTERVIEWING">INTERVIEWING</option>
            <option value="OFFER">OFFER</option>
            <option value="REJECTED">REJECTED</option>
          </select>
        </div>
      </div>
      <div style={{ marginTop: 10 }}>
        <small>Notes</small>
        <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={3} placeholder="Links, follow-ups..." />
      </div>
      <div style={{ marginTop: 12 }}>
        <button
          onClick={async () => {
            if (!company.trim() || !role.trim()) return;
            await onCreate({ company, role, status, notes: notes.trim() || undefined });
            setCompany(""); setRole(""); setStatus("SAVED"); setNotes("");
          }}
        >
          Create
        </button>
      </div>
    </div>
  );
}
