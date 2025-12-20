import path from "path";
import fs from "fs";
import YAML from "yaml";
export function loadOpenApiSpec() {
  const file = path.join(__dirname, "openapi.yaml");
  const raw = fs.readFileSync(file, "utf8");
  return YAML.parse(raw);
}
