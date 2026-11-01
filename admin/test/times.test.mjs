import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { normaliseTimes, timetableUrl } from "../api/_times.js";

const day = { fajr: "05:14", sunrise: "06:51", dhuhr: "11:49", asr: "14:06", magrib: "16:37", isha: "18:05", fajr_jamat: "05:34" };
function year(y, mutate) {
  const times = {};
  const n = (y % 4 === 0 ? 366 : 365);
  for (let i = 0; i < n; i++) {
    const d = new Date(Date.UTC(y, 0, 1 + i)).toISOString().slice(0, 10);
    times[d] = { ...day, date: d };
  }
  mutate?.(times);
  return { city: "london", times };
}

const ok = normaliseTimes(year(2026), 2026);
assert.equal(ok.ok, true);
assert.equal(Object.keys(ok.value.days).length, 365);
assert.deepEqual(ok.value.days["2026-11-01"], { fajr: "05:14", sunrise: "06:51", dhuhr: "11:49", asr: "14:06", maghrib: "16:37", isha: "18:05" });
assert.equal("fajr_jamat" in ok.value.days["2026-11-01"], false, "jama'ah times are dropped");

assert.equal(normaliseTimes(year(2028), 2028).ok, true, "leap year has 366 days");
assert.equal(normaliseTimes(year(2026, (t) => { delete t["2026-05-05"]; }), 2026).ok, false, "missing day");
assert.equal(normaliseTimes(year(2026, (t) => { t["2026-05-05"].isha = "7pm"; }), 2026).ok, false, "bad time");
assert.equal(normaliseTimes(year(2026, (t) => { t["2026-05-05"].asr = "11:00"; }), 2026).ok, false, "out of order");
assert.equal(normaliseTimes({}, 2026).ok, false);
assert.equal(normaliseTimes(null, 2026).ok, false);
assert.match(timetableUrl("a b&c", 2026), /key=a%20b%26c&year=2026&24hours=true$/);

// A real response, saved locally by the person running the tests (never committed).
const sample = process.env.LUPT_SAMPLE;
if (sample && existsSync(sample)) {
  const r = normaliseTimes(JSON.parse(readFileSync(sample, "utf8")), 2026);
  assert.equal(r.ok, true, JSON.stringify(r.errors));
  assert.deepEqual(r.value.days["2026-10-23"], { fajr: "06:00", sunrise: "07:35", dhuhr: "12:50", asr: "15:20", maghrib: "17:54", isha: "19:19" });
  console.log("real timetable sample passed");
}
console.log("times tests passed");
