import React from "react";
import { JobStatus } from "./JobForm";

export type Job = {
  id: string;
  company: string;
  role: string;
  status: JobStatus;
  notes?: string | null;
  updatedAt: string;
};

export default function JobList({
  jobs,
  onDelete,
  onUpdateStatus
}: {
  jobs: Job[];
  onDelete: (id: string) => Promise<void>;
  onUpdateStatus: (id: string, status: JobStatus) => Promise<void>;
}) {
  return (
    <div className="card">
      <h3>Your Jobs</h3>
      <small>{jobs.length} total</small>
      <hr />
      {jobs.length === 0 ? (
        <p>No jobs yet. Add your first one above.</p>
      ) : (
        <div style={{ display: "grid", gap: 10 }}>
          {jobs.map((j) => (
            <div key={j.id} className="card" style={{ padding: 12 }}>
              <div className="row" style={{ justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ minWidth: 240 }}>
                  <b>{j.company}</b> — {j.role}
                  <div><small>Updated: {new Date(j.updatedAt).toLocaleString()}</small></div>
                </div>
                <div style={{ width: 220 }}>
                  <select value={j.status} onChange={(e) => onUpdateStatus(j.id, e.target.value as JobStatus)}>
                    <option value="SAVED">SAVED</option>
                    <option value="APPLIED">APPLIED</option>
                    <option value="INTERVIEWING">INTERVIEWING</option>
                    <option value="OFFER">OFFER</option>
                    <option value="REJECTED">REJECTED</option>
                  </select>
                </div>
                <button className="secondary" onClick={() => onDelete(j.id)}>Delete</button>
              </div>
              {j.notes ? <p style={{ marginBottom: 0, opacity: 0.9 }}>{j.notes}</p> : null}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
