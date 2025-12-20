import { ZodSchema } from "zod";
import { Request, Response, NextFunction } from "express";
export function validateBody(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ message: "Validation error", errors: parsed.error.flatten() });
    req.body = parsed.data;
    next();
  };
}
