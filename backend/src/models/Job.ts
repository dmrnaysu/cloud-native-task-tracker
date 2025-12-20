import mongoose from "mongoose";
const JobSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    company: { type: String, required: true },
    role: { type: String, required: true },
    status: { type: String, enum: ["SAVED","APPLIED","INTERVIEWING","OFFER","REJECTED"], default: "SAVED" },
    notes: { type: String }
  },
  { timestamps: true }
);
export const Job = mongoose.model("Job", JobSchema);
