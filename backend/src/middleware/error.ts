import { NextFunction, Request, Response } from "express";
export function notFound(req: Request, res: Response) {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.path}` });
}
export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  console.error(err);
  res.status(err?.statusCode || 500).json({ message: err?.message || "Server error" });
}
