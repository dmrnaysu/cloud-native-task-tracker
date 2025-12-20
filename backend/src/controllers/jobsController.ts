import { Response } from "express";
import { Job } from "../models/Job";
import { AuthedRequest } from "../middleware/auth";

export async function listJobs(req: AuthedRequest, res: Response) {
  const jobs = await Job.find({ userId: req.user!.userId }).sort({ updatedAt: -1 });
  res.json({ jobs });
}

export async function createJob(req: AuthedRequest, res: Response) {
  const job = await Job.create({ userId: req.user!.userId, ...(req.body as any) });
  res.status(201).json({ job });
}

export async function updateJob(req: AuthedRequest, res: Response) {
  const job = await Job.findOneAndUpdate(
    { _id: req.params.id, userId: req.user!.userId },
    { $set: req.body },
    { new: true }
  );
  if (!job) return res.status(404).json({ message: "Job not found" });
  res.json({ job });
}

export async function deleteJob(req: AuthedRequest, res: Response) {
  const ok = await Job.findOneAndDelete({ _id: req.params.id, userId: req.user!.userId });
  if (!ok) return res.status(404).json({ message: "Job not found" });
  res.status(204).send();
}
