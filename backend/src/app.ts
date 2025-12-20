import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import swaggerUi from "swagger-ui-express";
import { env } from "./config/env";
import routes from "./routes";
import { notFound, errorHandler } from "./middleware/error";
import { loadOpenApiSpec } from "./swagger";

export function createApp() {
  const app = express();
  app.get("/", (_req, res) => res.send("Cloud Task Tracker API is running. Go to /api/health or /api/docs"));

  app.use(helmet());
  app.use(morgan("dev"));
  app.use(express.json());
  app.use(cors({ origin: env.CORS_ORIGIN }));

  app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(loadOpenApiSpec()));
  app.use("/api", routes);

  app.use(notFound);
  app.use(errorHandler);
  return app;
}
