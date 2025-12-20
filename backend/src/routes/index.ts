import { Router } from "express";
import auth from "./auth";
import jobs from "./jobs";

const router = Router();
router.get("/health", (_req, res) => res.json({ ok: true }));
router.use("/auth", auth);
router.use("/jobs", jobs);
export default router;
