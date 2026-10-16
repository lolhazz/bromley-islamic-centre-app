import { put, list } from "@vercel/blob";
import { timingSafeEqual } from "node:crypto";
import { validateConfig } from "./_validate.js";

const PATH = "config.json";
const AUTH_PATH = "auth-state.json";
const MAX_FAILS = 10;
const LOCK_MS = 15 * 60 * 1000;

async function readJson(path) {
  const { blobs } = await list({ prefix: path, limit: 1 });
  if (!blobs.length) return null;
  const res = await fetch(blobs[0].url, { cache: "no-store" });
  return res.ok ? res.json() : null;
}

const writeJson = (path, value) =>
  put(path, JSON.stringify(value), { access: "public", contentType: "application/json", addRandomSuffix: false, allowOverwrite: true });

const safeEqual = (a = "", b = "") => {
  const x = Buffer.from(a), y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
};

async function current() {
  const { blobs } = await list({ prefix: PATH, limit: 1 });
  if (!blobs.length) return {};
  const res = await fetch(blobs[0].url, { cache: "no-store" });
  return res.ok ? res.json() : {};
}

export default async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store");
  if (req.method === "GET") {
    return res.status(200).json(await current());
  }
  if (req.method === "POST") {
    const passcode = process.env.ADMIN_PASSCODE;
    if (!passcode) return res.status(500).json({ error: "ADMIN_PASSCODE is not set on the server" });
    // Lock out guessing: after MAX_FAILS wrong passcodes, refuse everything for LOCK_MS.
    const now = Date.now();
    let auth = (await readJson(AUTH_PATH)) || { count: 0, since: now };
    if (now - auth.since > LOCK_MS) auth = { count: 0, since: now };
    if (auth.count >= MAX_FAILS) {
      const mins = Math.ceil((auth.since + LOCK_MS - now) / 60000);
      return res.status(429).json({ error: `Too many wrong passcodes. Try again in ${mins} minute${mins === 1 ? "" : "s"}.` });
    }
    if (!safeEqual(req.headers["x-admin-passcode"], passcode)) {
      await writeJson(AUTH_PATH, { count: auth.count + 1, since: auth.since });
      return res.status(401).json({ error: "Wrong passcode" });
    }
    if (auth.count > 0) await writeJson(AUTH_PATH, { count: 0, since: now });
    const result = validateConfig(req.body);
    if (!result.ok) return res.status(400).json({ error: "Invalid content", details: result.errors });
    await put(PATH, JSON.stringify(result.value, null, 2), {
      access: "public", contentType: "application/json", addRandomSuffix: false, allowOverwrite: true,
    });
    return res.status(200).json({ ok: true });
  }
  res.setHeader("Allow", "GET, POST");
  return res.status(405).json({ error: "Method not allowed" });
}
