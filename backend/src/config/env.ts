import dotenv from "dotenv";
import { z } from "zod";
dotenv.config();

const EnvSchema = z.object({
  PORT: z.coerce.number().default(4000),
  MONGO_URL: z.string().min(1),
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default("7d"),
  CORS_ORIGIN: z.string().default("http://localhost:5173")
});

export const env = EnvSchema.parse(process.env);
