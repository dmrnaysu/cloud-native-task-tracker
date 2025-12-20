import { Router } from "express";
import { validateBody } from "../middleware/validate";
import { SignupSchema, LoginSchema } from "../schemas_auth";
import { signup, login } from "../controllers/authController";

const router = Router();
router.post("/signup", validateBody(SignupSchema), signup);
router.post("/login", validateBody(LoginSchema), login);
export default router;
