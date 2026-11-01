import { normaliseTimes, timetableUrl } from "./_times.js";

// GET /api/times?year=2026 returns that year's adhan times from the London Unified Prayer Timetable.
// The API key stays here, in the LUPT_API_KEY environment variable. The app never sees it.
export default async function handler(req, res) {
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    return res.status(405).json({ error: "Method not allowed" });
  }
  const key = process.env.LUPT_API_KEY;
  if (!key) return res.status(500).json({ error: "Prayer times are not set up on the server" });

  // Only the years the app can need, so strangers cannot spend the key's quota on other years.
  const thisYear = new Date().getUTCFullYear();
  const year = Number(req.query?.year ?? thisYear);
  if (!Number.isInteger(year) || year < thisYear - 1 || year > thisYear + 1) {
    return res.status(400).json({ error: `year must be ${thisYear - 1} to ${thisYear + 1}` });
  }

  try {
    const upstream = await fetch(timetableUrl(key, year), { signal: AbortSignal.timeout(10000) });
    if (!upstream.ok) throw new Error(`upstream ${upstream.status}`);
    const result = normaliseTimes(await upstream.json(), year);
    if (!result.ok) throw new Error(result.errors.join("; "));
    // The timetable is fixed for the year, so let the CDN keep it for a day and serve stale if the source is down.
    res.setHeader("Cache-Control", "public, s-maxage=86400, stale-while-revalidate=604800");
    return res.status(200).json(result.value);
  } catch (err) {
    console.error("timetable fetch failed:", err.message); // never log the URL: it contains the key
    return res.status(502).json({ error: "Could not get the prayer times just now" });
  }
}
