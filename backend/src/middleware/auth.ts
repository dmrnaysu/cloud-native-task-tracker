import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../lib/jwt";

export type AuthedRequest = Request & { user?: { userId: string; email: string } };

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = req.headers.authorization || "";
  const [type, token] = header.split(" ");
  if (type !== "Bearer" || !token) return res.status(401).json({ message: "Missing or invalid Authorization header" });

  try {
    req.user = verifyToken(token);
    next();
  } catch {
    res.status(401).json({ message: "Invalid or expired token" });
  }
}
