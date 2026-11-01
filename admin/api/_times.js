// Turns the London Unified Prayer Timetable response into the small shape the app reads.
// Keeps only the adhan times and sunrise. The timetable's own jama'ah times are London-wide, not ours.
const FIELDS = [
  ["fajr", "fajr"],
  ["sunrise", "sunrise"],
  ["dhuhr", "dhuhr"],
  ["asr", "asr"], // standard (Shafi'i/Maliki/Hanbali) Asr, matching the centre's website
  ["maghrib", "magrib"], // the timetable spells it "magrib"
  ["isha", "isha"],
];
const HM = /^([01]\d|2[0-3]):[0-5]\d$/;
const minutes = (hm) => Number(hm.slice(0, 2)) * 60 + Number(hm.slice(3));

const isLeap = (y) => (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;

export function normaliseTimes(raw, year) {
  const src = raw && typeof raw === "object" ? raw.times : null;
  if (!src || typeof src !== "object") return { ok: false, errors: ["response has no times"] };

  const errors = [];
  const days = {};
  for (const [date, d] of Object.entries(src)) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !date.startsWith(`${year}-`)) continue;
    const day = {};
    for (const [out, key] of FIELDS) {
      const v = d?.[key];
      if (typeof v !== "string" || !HM.test(v)) errors.push(`${date} ${out} is not a time`);
      else day[out] = v;
    }
    if (Object.keys(day).length === FIELDS.length) {
      // Fajr < sunrise < dhuhr < asr < maghrib < isha, every day.
      const order = FIELDS.map(([out]) => minutes(day[out]));
      if (order.some((m, i) => i > 0 && m <= order[i - 1])) errors.push(`${date} times are out of order`);
    }
    days[date] = day;
  }

  const expected = isLeap(year) ? 366 : 365;
  if (Object.keys(days).length !== expected) errors.push(`expected ${expected} days, got ${Object.keys(days).length}`);
  if (errors.length) return { ok: false, errors: errors.slice(0, 10) };
  return { ok: true, value: { year, source: "London Unified Prayer Timetable", days } };
}

export function timetableUrl(key, year) {
  return `https://www.londonprayertimes.com/api/times/?format=json&key=${encodeURIComponent(key)}&year=${year}&24hours=true`;
}
