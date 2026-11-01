import assert from "node:assert/strict";
import { validateConfig } from "../api/_validate.js";

const good = validateConfig({
  jumuah: [{ label: "1st Jumu’ah", khutbah: "1:15 pm", jamaah: "1:30 pm" }, { label: "2nd Jumu’ah", khutbah: "2:00 pm", jamaah: "2:15 pm", venue: "Hall" }],
  venueBanner: "Temporary venue",
  ramadanStart: "2027-02-08",
});
assert.equal(good.ok, true);
assert.equal(good.value.jumuah[0].venue, null);
assert.equal(good.value.jumuah[1].venue, "Hall");

assert.equal(validateConfig({ jumuah: [{ label: "x", khutbah: "", jamaah: "1" }] }).ok, false);
assert.equal(validateConfig({ ramadanStart: "tomorrow" }).ok, false);
assert.equal(validateConfig({ jumuah: new Array(7).fill({}) }).ok, false);
assert.equal(validateConfig(null).ok, false);
assert.equal(validateConfig({ venueBanner: 5 }).ok, false);
assert.deepEqual(validateConfig({}).value, {});

// iqamah rules
const iq = validateConfig({ iqamah: { fajr: { afterMinutes: 30 }, dhuhr: { time: "13:30" } } });
assert.equal(iq.ok, true);
assert.deepEqual(iq.value.iqamah, { fajr: { afterMinutes: 30 }, dhuhr: { time: "13:30" } });
assert.equal(validateConfig({ iqamah: { fajr: { afterMinutes: -1 } } }).ok, false);
assert.equal(validateConfig({ iqamah: { fajr: { afterMinutes: 2.5 } } }).ok, false);
assert.equal(validateConfig({ iqamah: { fajr: { afterMinutes: 181 } } }).ok, false);
assert.equal(validateConfig({ iqamah: { fajr: { time: "25:00" } } }).ok, false);
assert.equal(validateConfig({ iqamah: { fajr: { time: "1:30 pm" } } }).ok, false);
assert.equal(validateConfig({ iqamah: { fajr: {} } }).ok, false);
assert.equal(validateConfig({ iqamah: { fajr: { afterMinutes: 10, time: "06:30" } } }).ok, false);
assert.equal(validateConfig({ iqamah: { sunrise: { afterMinutes: 10 } } }).ok, false);
assert.equal(validateConfig({ iqamah: [] }).ok, false);
console.log("validate tests passed");
