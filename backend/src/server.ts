import { createApp } from "./app";
import { env } from "./config/env";
import { connectDb } from "./lib/db";

async function main() {
  await connectDb();
  const app = createApp();
  app.listen(env.PORT, () => console.log(`API running on http://localhost:${env.PORT}`));
}
main().catch((e) => { console.error(e); process.exit(1); });
