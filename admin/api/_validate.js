// Validates and normalises the config JSON before it is published to the app.
const str = (v, max) => typeof v === "string" && v.length <= max;
const optStr = (v, max) => v == null || v === "" || str(v, max);

export function validateConfig(input) {
  const errors = [];
  if (!input || typeof input !== "object") return { ok: false, errors: ["Body must be a JSON object"] };
  const out = {};

  if (input.jumuah != null) {
    if (!Array.isArray(input.jumuah) || input.jumuah.length > 6) errors.push("jumuah must be a list of at most 6 slots");
    else out.jumuah = input.jumuah.map((s, i) => {
      if (!str(s?.label, 40) || !s.label) errors.push(`jumuah[${i}].label is required`);
      if (!str(s?.khutbah, 20) || !s.khutbah) errors.push(`jumuah[${i}].khutbah is required`);
      if (!str(s?.jamaah, 20) || !s.jamaah) errors.push(`jumuah[${i}].jamaah is required`);
      if (!optStr(s?.venue, 120)) errors.push(`jumuah[${i}].venue too long`);
      if (!optStr(s?.note, 160)) errors.push(`jumuah[${i}].note too long`);
      return { label: s.label, khutbah: s.khutbah, jamaah: s.jamaah, venue: s.venue || null, note: s.note || null };
    });
  }
  if (input.venueBanner != null) {
    if (!str(input.venueBanner, 240)) errors.push("venueBanner must be text up to 240 characters");
    else out.venueBanner = input.venueBanner;
  }
  if (input.announcements != null) {
    if (!Array.isArray(input.announcements) || input.announcements.length > 20) errors.push("announcements must be a list of at most 20");
    else out.announcements = input.announcements.map((a, i) => {
      if (!str(a?.title, 120) || !a.title) errors.push(`announcements[${i}].title is required`);
      if (!str(a?.body, 1200) || !a.body) errors.push(`announcements[${i}].body is required`);
      if (!str(a?.date, 40) || !a.date) errors.push(`announcements[${i}].date is required`);
      return { title: a.title, body: a.body, date: a.date };
    });
  }
  if (input.events != null) {
    if (!Array.isArray(input.events) || input.events.length > 30) errors.push("events must be a list of at most 30");
    else out.events = input.events.map((e, i) => {
      if (!str(e?.tag, 40) || !e.tag) errors.push(`events[${i}].tag is required`);
      if (!str(e?.title, 120) || !e.title) errors.push(`events[${i}].title is required`);
      if (!str(e?.detail, 600) || !e.detail) errors.push(`events[${i}].detail is required`);
      if (!optStr(e?.when, 120)) errors.push(`events[${i}].when too long`);
      if (!optStr(e?.note, 240)) errors.push(`events[${i}].note too long`);
      return { tag: e.tag, title: e.title, detail: e.detail, when: e.when || null, note: e.note || null };
    });
  }
  if (input.iqamah != null) {
    const prayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"];
    if (typeof input.iqamah !== "object" || Array.isArray(input.iqamah)) errors.push("iqamah must be an object keyed by prayer");
    else {
      const rules = {};
      for (const p of Object.keys(input.iqamah)) if (!prayers.includes(p)) errors.push(`iqamah.${p} is not a prayer`);
      for (const p of prayers) {
        const r = input.iqamah[p];
        if (r == null) continue;
        const hasMins = r.afterMinutes != null, hasTime = r.time != null && r.time !== "";
        if (hasMins === hasTime) errors.push(`iqamah.${p} needs either minutes after adhan or a fixed time`);
        else if (hasMins) {
          if (!Number.isInteger(r.afterMinutes) || r.afterMinutes < 0 || r.afterMinutes > 180) errors.push(`iqamah.${p} minutes must be a whole number from 0 to 180`);
          else rules[p] = { afterMinutes: r.afterMinutes };
        } else {
          if (typeof r.time !== "string" || !/^([01]\d|2[0-3]):[0-5]\d$/.test(r.time)) errors.push(`iqamah.${p} time must look like 13:30`);
          else rules[p] = { time: r.time };
        }
      }
      out.iqamah = rules;
    }
  }
  if (input.ramadanStart != null && input.ramadanStart !== "") {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(input.ramadanStart) || Number.isNaN(Date.parse(input.ramadanStart))) errors.push("ramadanStart must look like 2027-02-08");
    else out.ramadanStart = input.ramadanStart;
  }
  if (input.ramadanNote != null && input.ramadanNote !== "") {
    if (!str(input.ramadanNote, 400)) errors.push("ramadanNote must be text up to 400 characters");
    else out.ramadanNote = input.ramadanNote;
  }
  return errors.length ? { ok: false, errors } : { ok: true, value: out };
}
