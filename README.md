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
