import { Request, Response } from "express";
import { User } from "../models/User";
import { hashPassword, verifyPassword } from "../lib/password";
import { signToken } from "../lib/jwt";

export async function signup(req: Request, res: Response) {
  const { email, password } = req.body as any;
  const existing = await User.findOne({ email });
  if (existing) return res.status(409).json({ message: "Email already in use" });

  const user = await User.create({ email, passwordHash: await hashPassword(password) });
  const token = signToken({ userId: String(user._id), email: user.email });
  res.status(201).json({ user: { id: String(user._id), email: user.email }, token });
}

export async function login(req: Request, res: Response) {
  const { email, password } = req.body as any;
  const user = await User.findOne({ email });
  if (!user) return res.status(401).json({ message: "Invalid credentials" });

  const ok = await verifyPassword(password, user.passwordHash);
  if (!ok) return res.status(401).json({ message: "Invalid credentials" });

  const token = signToken({ userId: String(user._id), email: user.email });
  res.json({ user: { id: String(user._id), email: user.email }, token });
}
