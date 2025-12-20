import { z } from "zod";
export const JobStatusSchema = z.enum(["SAVED","APPLIED","INTERVIEWING","OFFER","REJECTED"]);
export const CreateJobSchema = z.object({
  company: z.string().min(1),
  role: z.string().min(1),
  status: JobStatusSchema.optional(),
  notes: z.string().max(2000).optional()
});
export const UpdateJobSchema = CreateJobSchema.partial();
