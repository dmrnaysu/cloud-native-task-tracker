$ErrorActionPreference = "Stop"

Write-Host "== Cloud Native Task Tracker Bootstrap =="

# Ensure we are in project root
$root = Get-Location
Write-Host "Project root: $root"

# 1) Frontend scaffold (React + Vite + TS)
if (-not (Test-Path ".\frontend\package.json")) {
  Write-Host "`n[1/6] Creating frontend with Vite (React + TS)..."
  npm create vite@latest frontend -- --template react-ts | Out-Host
  Push-Location .\frontend
  npm install | Out-Host
  npm install axios react-router-dom | Out-Host
  Pop-Location
} else {
  Write-Host "`n[1/6] Frontend already exists. Skipping scaffold."
}

# 2) Backend scaffold (Node + Express + TS + Prisma)
if (-not (Test-Path ".\backend\package.json")) {
  Write-Host "`n[2/6] Creating backend (Express + TS + Prisma)..."
  New-Item -ItemType Directory -Force -Path ".\backend" | Out-Null
  Push-Location .\backend
  npm init -y | Out-Host

  npm install express cors helmet morgan dotenv jsonwebtoken bcryptjs zod swagger-ui-express yaml @prisma/client | Out-Host
  npm install -D typescript ts-node-dev prisma @types/node @types/express @types/cors @types/morgan @types/jsonwebtoken | Out-Host

  npx tsc --init | Out-Host
  npx prisma init | Out-Host
  Pop-Location
} else {
  Write-Host "`n[2/6] Backend already exists. Skipping scaffold."
}

# 3) Root files
Write-Host "`n[3/6] Writing root files (.gitignore, README)..."

@"
node_modules
.env
dist
build
.vite
.DS_Store

# Prisma local sqlite DB
backend/prisma/dev.db
backend/prisma/dev.db-journal
"@ | Set-Content -Encoding utf8 ".gitignore"

@"
# Cloud-Native Task Tracker (Job/Task Management)

**Full-stack flagship project**:
- Frontend: React + Vite + TypeScript
- Backend: Node.js + Express + TypeScript
- Database (Local): SQLite (Prisma)
- Auth: JWT
- Docs: Swagger UI
- CI/CD: GitHub Actions (add later)
- Docker/Postgres: optional upgrade (add later)

## Run locally
### Backend
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
npm run dev

Swagger: http://localhost:4000/api/docs

### Frontend
cd ../frontend
cp .env.example .env
npm install
npm run dev

Frontend: http://localhost:5173
"@ | Set-Content -Encoding utf8 "README.md"

# 4) Backend code files
Write-Host "`n[4/6] Writing backend code..."

New-Item -ItemType Directory -Force -Path `
  ".\backend\src\config",
  ".\backend\src\lib",
  ".\backend\src\middleware",
  ".\backend\src\routes",
  ".\backend\src\schemas",
  ".\backend\src\controllers",
  ".\backend\prisma" | Out-Null

@"
PORT=4000
DATABASE_URL=file:./dev.db

JWT_SECRET=super_secret_change_me_please_12345
JWT_EXPIRES_IN=7d

CORS_ORIGIN=http://localhost:5173
"@ | Set-Content -Encoding utf8 ".\backend\.env.example"

@"
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

enum JobStatus {
  SAVED
  APPLIED
  INTERVIEWING
  OFFER
  REJECTED
}

model User {
  id           String   @id @default(uuid())
  email        String   @unique
  passwordHash String
  createdAt    DateTime @default(now())
  jobs         Job[]
}

model Job {
  id         String    @id @default(uuid())
  userId     String
  user       User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  company    String
  role       String
  status     JobStatus @default(SAVED)
  appliedAt  DateTime?
  notes      String?
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt

  @@index([userId])
}
"@ | Set-Content -Encoding utf8 ".\backend\prisma\schema.prisma"

@"
import { prisma } from "../src/lib/prisma";
import { hashPassword } from "../src/lib/password";

async function main() {
  const email = "demo@demo.com";
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return;

  const user = await prisma.user.create({
    data: {
      email,
      passwordHash: await hashPassword("Password123!"),
      jobs: {
        create: [
          { company: "IBM", role: "Cloud Developer", status: "APPLIED", notes: "Follow up in 7 days" },
          { company: "AWS", role: "Full Stack Intern", status: "INTERVIEWING", appliedAt: new Date() }
        ]
      }
    }
  });

  console.log("Seeded demo user:", user.email);
}

main()
  .then(async () => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
"@ | Set-Content -Encoding utf8 ".\backend\prisma\seed.ts"

@"
import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const EnvSchema = z.object({
  PORT: z.coerce.number().default(4000),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default("7d"),
  CORS_ORIGIN: z.string().default("http://localhost:5173")
});

export const env = EnvSchema.parse(process.env);
"@ | Set-Content -Encoding utf8 ".\backend\src\config\env.ts"

@"
import { PrismaClient } from "@prisma/client";
export const prisma = new PrismaClient();
"@ | Set-Content -Encoding utf8 ".\backend\src\lib\prisma.ts"

@"
import bcrypt from "bcryptjs";

export async function hashPassword(password: string) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

export async function verifyPassword(password: string, hash: string) {
  return bcrypt.compare(password, hash);
}
"@ | Set-Content -Encoding utf8 ".\backend\src\lib\password.ts"

@"
import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type JwtPayload = { userId: string; email: string };

export function signToken(payload: JwtPayload) {
  return jwt.sign(payload, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN });
}

export function verifyToken(token: string) {
  return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
}
"@ | Set-Content -Encoding utf8 ".\backend\src\lib\jwt.ts"

@"
import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../lib/jwt";

export type AuthedRequest = Request & { user?: { userId: string; email: string } };

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization || "";
  const [type, token] = header.split(" ");

  if (type !== "Bearer" || !token) {
    return res.status(401).json({ message: "Missing or invalid Authorization header" });
  }

  try {
    req.user = verifyToken(token);
    return next();
  } catch {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}
"@ | Set-Content -Encoding utf8 ".\backend\src\middleware\auth.ts"

@"
import { Request, Response, NextFunction } from "express";
import { ZodSchema } from "zod";

export function validateBody(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        message: "Validation error",
        errors: parsed.error.flatten()
      });
    }
    req.body = parsed.data;
    next();
  };
}
"@ | Set-Content -Encoding utf8 ".\backend\src\middleware\validate.ts"

@"
import { NextFunction, Request, Response } from "express";

export function notFound(req: Request, res: Response) {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.path}` });
}

export function errorHandler(err: any, req: Request, res: Response, _next: NextFunction) {
  console.error(err);
  res.status(err?.statusCode || 500).json({ message: err?.message || "Server error" });
}
"@ | Set-Content -Encoding utf8 ".\backend\src\middleware\error.ts"

@"
import { z } from "zod";

export const SignupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(72)
});

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});
"@ | Set-Content -Encoding utf8 ".\backend\src\schemas\authSchemas.ts"

@"
import { z } from "zod";

export const JobStatusSchema = z.enum(["SAVED", "APPLIED", "INTERVIEWING", "OFFER", "REJECTED"]);

export const CreateJobSchema = z.object({
  company: z.string().min(1),
  role: z.string().min(1),
  status: JobStatusSchema.optional(),
  appliedAt: z.string().datetime().optional(),
  notes: z.string().max(2000).optional()
});

export const UpdateJobSchema = CreateJobSchema.partial();
"@ | Set-Content -Encoding utf8 ".\backend\src\schemas\jobSchemas.ts"

@"
import { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { hashPassword, verifyPassword } from "../lib/password";
import { signToken } from "../lib/jwt";
import { AuthedRequest } from "../middleware/auth";

export async function signup(req: Request, res: Response) {
  const { email, password } = req.body as { email: string; password: string };

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return res.status(409).json({ message: "Email already in use" });

  const user = await prisma.user.create({
    data: { email, passwordHash: await hashPassword(password) },
    select: { id: true, email: true, createdAt: true }
  });

  const token = signToken({ userId: user.id, email: user.email });
  return res.status(201).json({ user, token });
}

export async function login(req: Request, res: Response) {
  const { email, password } = req.body as { email: string; password: string };

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) return res.status(401).json({ message: "Invalid credentials" });

  const ok = await verifyPassword(password, user.passwordHash);
  if (!ok) return res.status(401).json({ message: "Invalid credentials" });

  const token = signToken({ userId: user.id, email });
  return res.json({ user: { id: user.id, email: user.email }, token });
}

export async function me(req: AuthedRequest, res: Response) {
  const userId = req.user!.userId;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, email: true, createdAt: true }
  });
  return res.json({ user });
}
"@ | Set-Content -Encoding utf8 ".\backend\src\controllers\authController.ts"

@"
import { Response } from "express";
import { prisma } from "../lib/prisma";
import { AuthedRequest } from "../middleware/auth";

export async function listJobs(req: AuthedRequest, res: Response) {
  const userId = req.user!.userId;
  const jobs = await prisma.job.findMany({
    where: { userId },
    orderBy: { updatedAt: "desc" }
  });
  res.json({ jobs });
}

export async function createJob(req: AuthedRequest, res: Response) {
  const userId = req.user!.userId;
  const { company, role, status, appliedAt, notes } = req.body as any;

  const job = await prisma.job.create({
    data: {
      userId,
      company,
      role,
      status,
      appliedAt: appliedAt ? new Date(appliedAt) : undefined,
      notes
    }
  });

  res.status(201).json({ job });
}

export async function updateJob(req: AuthedRequest, res: Response) {
  const userId = req.user!.userId;
  const id = req.params.id;

  const existing = await prisma.job.findFirst({ where: { id, userId } });
  if (!existing) return res.status(404).json({ message: "Job not found" });

  const { company, role, status, appliedAt, notes } = req.body as any;

  const job = await prisma.job.update({
    where: { id },
    data: {
      company,
      role,
      status,
      appliedAt: appliedAt ? new Date(appliedAt) : undefined,
      notes
    }
  });

  res.json({ job });
}

export async function deleteJob(req: AuthedRequest, res: Response) {
  const userId = req.user!.userId;
  const id = req.params.id;

  const existing = await prisma.job.findFirst({ where: { id, userId } });
  if (!existing) return res.status(404).json({ message: "Job not found" });

  await prisma.job.delete({ where: { id } });
  res.status(204).send();
}
"@ | Set-Content -Encoding utf8 ".\backend\src\controllers\jobsController.ts"

@"
import { Router } from "express";
import { validateBody } from "../middleware/validate";
import { LoginSchema, SignupSchema } from "../schemas/authSchemas";
import { login, me, signup } from "../controllers/authController";
import { requireAuth } from "../middleware/auth";

const router = Router();

router.post("/signup", validateBody(SignupSchema), signup);
router.post("/login", validateBody(LoginSchema), login);
router.get("/me", requireAuth, me);

export default router;
"@ | Set-Content -Encoding utf8 ".\backend\src\routes\auth.ts"

@"
import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { CreateJobSchema, UpdateJobSchema } from "../schemas/jobSchemas";
import { createJob, deleteJob, listJobs, updateJob } from "../controllers/jobsController";

const router = Router();
router.use(requireAuth);

router.get("/", listJobs);
router.post("/", validateBody(CreateJobSchema), createJob);
router.put("/:id", validateBody(UpdateJobSchema), updateJob);
router.delete("/:id", deleteJob);

export default router;
"@ | Set-Content -Encoding utf8 ".\backend\src\routes\jobs.ts"

@"
import { Router } from "express";
import auth from "./auth";
import jobs from "./jobs";

const router = Router();

router.get("/health", (_req, res) => res.json({ ok: true }));
router.use("/auth", auth);
router.use("/jobs", jobs);

export default router;
"@ | Set-Content -Encoding utf8 ".\backend\src\routes\index.ts"

@"
openapi: 3.0.3
info:
  title: Cloud-Native Task Tracker API
  version: 1.0.0
servers:
  - url: /api
paths:
  /health:
    get:
      summary: Health check
      responses:
        "200":
          description: OK
  /auth/signup:
    post:
      summary: Create a user
      responses:
        "201": { description: Created }
  /auth/login:
    post:
      summary: Login
      responses:
        "200": { description: OK }
  /jobs:
    get:
      summary: List jobs
      responses:
        "200": { description: OK }
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
"@ | Set-Content -Encoding utf8 ".\backend\src\openapi.yaml"

@"
import path from "path";
import fs from "fs";
import YAML from "yaml";

export function loadOpenApiSpec() {
  const file = path.join(__dirname, "openapi.yaml");
  const raw = fs.readFileSync(file, "utf8");
  return YAML.parse(raw);
}
"@ | Set-Content -Encoding utf8 ".\backend\src\swagger.ts"

@"
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import swaggerUi from "swagger-ui-express";

import { env } from "./config/env";
import routes from "./routes";
import { notFound, errorHandler } from "./middleware/error";
import { loadOpenApiSpec } from "./swagger";

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(morgan("dev"));
  app.use(express.json());

  app.use(cors({ origin: env.CORS_ORIGIN }));

  const spec = loadOpenApiSpec();
  app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(spec));

  app.use("/api", routes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}
"@ | Set-Content -Encoding utf8 ".\backend\src\app.ts"

@"
import { createApp } from "./app";
import { env } from "./config/env";

const app = createApp();

app.listen(env.PORT, () => {
  console.log(`API running on http://localhost:${env.PORT}`);
  console.log(`Swagger on http://localhost:${env.PORT}/api/docs`);
});
"@ | Set-Content -Encoding utf8 ".\backend\src\server.ts"

# Update backend package.json scripts
Write-Host "Updating backend package.json scripts..."
$pkgPath = ".\backend\package.json"
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
$pkg.scripts = @{
  dev = "ts-node-dev --respawn --transpile-only src/server.ts"
  build = "tsc"
  start = "node dist/server.js"
  "prisma:generate" = "prisma generate"
  "prisma:migrate" = "prisma migrate dev --name init"
  "prisma:seed" = "ts-node prisma/seed.ts"
}
$pkg | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $pkgPath

# 5) Frontend code files
Write-Host "`n[5/6] Writing frontend code..."

@"
VITE_API_URL=http://localhost:4000/api
"@ | Set-Content -Encoding utf8 ".\frontend\.env.example"

@"
:root { font-family: system-ui, Arial, sans-serif; }
body { margin: 0; background: #0b0f14; color: #e8eef6; }
a { color: #9bd1ff; text-decoration: none; }
.container { max-width: 1000px; margin: 0 auto; padding: 24px; }
.card { background: #121a24; border: 1px solid #1f2b3a; border-radius: 12px; padding: 16px; }
.row { display: flex; gap: 12px; flex-wrap: wrap; }
input, select, textarea {
  background: #0b0f14; color: #e8eef6; border: 1px solid #1f2b3a;
  border-radius: 10px; padding: 10px; width: 100%;
}
button {
  background: #2b77ff; border: 0; color: white; padding: 10px 14px;
  border-radius: 10px; cursor: pointer;
}
button.secondary { background: #2a3546; }
small { opacity: 0.8; }
hr { border: 0; border-top: 1px solid #1f2b3a; margin: 16px 0; }
"@ | Set-Content -Encoding utf8 ".\frontend\src\styles.css"

New-Item -ItemType Directory -Force -Path `
  ".\frontend\src\api",
  ".\frontend\src\auth",
  ".\frontend\src\components",
  ".\frontend\src\pages" | Out-Null

@"
import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
});

export function setAuthToken(token: string | null) {
  if (token) api.defaults.headers.common["Authorization"] = `Bearer ${token}`;
  else delete api.defaults.headers.common["Authorization"];
}
"@ | Set-Content -Encoding utf8 ".\frontend\src\api\client.ts"

@"
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
"@ | Set-Content -Encoding utf8 ".\frontend\src\auth\AuthContext.tsx"

@"
import React from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { token } = useAuth();
  if (!token) return <Navigate to="/login" replace />;
  return <>{children}</>;
}
"@ | Set-Content -Encoding utf8 ".\frontend\src\components\ProtectedRoute.tsx"

@"
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
"@ | Set-Content -Encoding utf8 ".\frontend\src\components\JobForm.tsx"

@"
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
"@ | Set-Content -Encoding utf8 ".\frontend\src\components\JobList.tsx"

@"
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
          <small>Don’t have an account? <Link to="/signup">Sign up</Link></small>
        </div>
      </div>
    </div>
  );
}
"@ | Set-Content -Encoding utf8 ".\frontend\src\pages\Login.tsx"

@"
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
"@ | Set-Content -Encoding utf8 ".\frontend\src\pages\Signup.tsx"

@"
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
    await api.delete(`/jobs/${id}`);
    await refresh();
  }

  async function onUpdateStatus(id: string, status: JobStatus) {
    await api.put(`/jobs/${id}`, { status });
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
"@ | Set-Content -Encoding utf8 ".\frontend\src\pages\Dashboard.tsx"

@"
import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import ProtectedRoute from "./components/ProtectedRoute";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import Dashboard from "./pages/Dashboard";
import "./styles.css";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
"@ | Set-Content -Encoding utf8 ".\frontend\src\App.tsx"

# main.tsx in Vite is already there, we just ensure it imports App.
@"
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
"@ | Set-Content -Encoding utf8 ".\frontend\src\main.tsx"

# 6) Install backend deps and run prisma setup
Write-Host "`n[6/6] Final backend setup (Prisma generate/migrate/seed)..."

Push-Location .\backend

# create .env from example if missing
if (-not (Test-Path ".\.env")) {
  Copy-Item ".\.env.example" ".\.env"
}

npm install | Out-Host
npx prisma generate | Out-Host
npx prisma migrate dev --name init | Out-Host
npx ts-node prisma/seed.ts | Out-Host

Pop-Location

# create frontend .env if missing
if (-not (Test-Path ".\frontend\.env")) {
  Copy-Item ".\frontend\.env.example" ".\frontend\.env"
}

Write-Host "`n✅ DONE."
Write-Host "Next: Run backend + frontend in two terminals:"
Write-Host "  Terminal 1: cd backend; npm run dev"
Write-Host "  Terminal 2: cd frontend; npm run dev"
Write-Host "Login demo: demo@demo.com / Password123!"
