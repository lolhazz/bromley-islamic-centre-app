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
console.log("validate tests passed");
