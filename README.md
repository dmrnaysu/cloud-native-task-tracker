# Cloud-Native Task Tracker (Job/Task Management)
summary
Cloud-Native Task Tracker is a full-stack web app for tracking job applications (or tasks) with secure authentication, a React dashboard, and a Node/Express REST API. Data is persisted in MongoDB Atlas, and the API is documented with Swagger for easy testing and integration.
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
