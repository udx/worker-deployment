#!/usr/bin/env node
const fs = require("fs");
const YAML = require("yaml");

const [,, cmd, rawPath, filePath] = process.argv;
if (!cmd) {
  console.error("Usage: yaml.js <get|length|keys|selftest> <path> <file>");
  process.exit(1);
}
if (cmd === "selftest") {
  process.exit(0);
}
if (!rawPath || !filePath) {
  console.error("Usage: yaml.js <get|length|keys|selftest> <path> <file>");
  process.exit(1);
}

let doc;
try {
  const content = fs.readFileSync(filePath, "utf8");
  doc = YAML.parse(content);
} catch (err) {
  console.error(`Failed to parse YAML: ${err.message}`);
  process.exit(1);
}

const path = rawPath.startsWith(".") ? rawPath.slice(1) : rawPath;

function tokenize(p) {
  const tokens = [];
  const parts = p.split(".").filter(Boolean);
  for (const part of parts) {
    const re = /([^\[\]]+)|\[(\d+)\]/g;
    let m;
    while ((m = re.exec(part)) !== null) {
      if (m[1]) tokens.push({ type: "key", value: m[1] });
      if (m[2]) tokens.push({ type: "index", value: parseInt(m[2], 10) });
    }
  }
  return tokens;
}

function resolve(obj, p) {
  if (!p) return obj;
  const tokens = tokenize(p);
  let cur = obj;
  for (const t of tokens) {
    if (cur === null || cur === undefined) return undefined;
    if (t.type === "key") {
      cur = cur[t.value];
    } else if (t.type === "index") {
      if (!Array.isArray(cur)) return undefined;
      cur = cur[t.value];
    }
  }
  return cur;
}

const value = resolve(doc, path);

if (cmd === "get") {
  if (value === undefined || value === null) {
    process.stdout.write("null");
  } else if (typeof value === "object") {
    process.stdout.write("null");
  } else {
    process.stdout.write(String(value));
  }
  process.exit(0);
}

if (cmd === "length") {
  if (Array.isArray(value)) {
    process.stdout.write(String(value.length));
  } else if (value && typeof value === "object") {
    process.stdout.write(String(Object.keys(value).length));
  } else {
    process.stdout.write("0");
  }
  process.exit(0);
}

if (cmd === "keys") {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    Object.keys(value).forEach((k) => process.stdout.write(`${k}\\n`));
  }
  process.exit(0);
}

console.error("Unknown command:", cmd);
process.exit(1);
