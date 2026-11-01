# BIC app editor

Small Vercel project that lets the committee change Jumu'ah times, the venue banner, announcements, events and Ramadan details without an App Store update.

- `public/index.html`: the editor page (phone friendly).
- `api/config.js`: `GET /api/config` returns the current JSON (public, the app reads it). `POST /api/config` publishes, protected by the `x-admin-passcode` header.
- `api/_validate.js`: input checks. `npm test` runs `test/validate.test.mjs`.
- `api/times.js`: `GET /api/times?year=2026` returns that year's adhan times from the London Unified Prayer Timetable (cached a day at the CDN). `api/_times.js` checks and trims the response.
- Storage: Vercel Blob (`config.json`).

## Deploy (done; steps kept for redeploys)

1. Create a Vercel project from this `admin/` folder.
2. Add a Blob store to the project (sets `BLOB_READ_WRITE_TOKEN`).
3. Set the `LUPT_API_KEY` environment variable to the London Prayer Times API key (mark it sensitive). Without it `/api/times` returns 500 and the app uses its calculated times.
4. Set the `ADMIN_PASSCODE` environment variable to a long passphrase and share it only with the committee.
5. Deploy, then set `ConfigStore.configURL` in the app to `https://<deployment>/api/config` and ship a new build.

The JSON shape matches `RemoteConfig` in `Sources/Data/ConfigStore.swift`. Every field is optional; missing fields fall back to the app's built-in content. `iqamah` holds one rule per prayer (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`): `{"afterMinutes": 40}` or `{"time": "13:30"}`.

Tests: `npm test`. Set `LUPT_SAMPLE` to a saved copy of a real LUPT year response to also check it against the real data.
