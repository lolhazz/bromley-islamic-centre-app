# BIC app editor

Small Vercel project that lets the committee change Jumu'ah times, the venue banner, announcements, events and Ramadan details without an App Store update.

- `public/index.html`: the editor page (phone friendly).
- `api/config.js`: `GET /api/config` returns the current JSON (public, the app reads it). `POST /api/config` publishes, protected by the `x-admin-passcode` header.
- `api/_validate.js`: input checks. `npm test` runs `test/validate.test.mjs`.
- Storage: Vercel Blob (`config.json`).

## Deploy

1. Create a Vercel project from this `admin/` folder.
2. Add a Blob store to the project (sets `BLOB_READ_WRITE_TOKEN`).
3. Set the `ADMIN_PASSCODE` environment variable to a long passphrase and share it only with the committee.
4. Deploy, then set `ConfigStore.configURL` in the app to `https://<deployment>/api/config` and ship a new build.

The JSON shape matches `RemoteConfig` in `Sources/Data/ConfigStore.swift`. Every field is optional; missing fields fall back to the app's built-in content.
