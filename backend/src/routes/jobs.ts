import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { CreateJobSchema, UpdateJobSchema } from "../schemas_job";
import { createJob, deleteJob, listJobs, updateJob } from "../controllers/jobsController";

const router = Router();
router.use(requireAuth);
router.get("/", listJobs);
router.post("/", validateBody(CreateJobSchema), createJob);
router.put("/:id", validateBody(UpdateJobSchema), updateJob);
router.delete("/:id", deleteJob);
export default router;
