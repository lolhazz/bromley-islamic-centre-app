import { put, list } from "@vercel/blob";
import { timingSafeEqual } from "node:crypto";
import { validateConfig } from "./_validate.js";

const PATH = "config.json";

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
    if (!safeEqual(req.headers["x-admin-passcode"], passcode)) return res.status(401).json({ error: "Wrong passcode" });
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
