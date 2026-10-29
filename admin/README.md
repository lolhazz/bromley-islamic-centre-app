# BIC app editor

A small Vercel project the committee uses to change Jumu'ah times, the venue banner, announcements, events and Ramadan details without an App Store update.

- `public/index.html` is the editor page, built to work on a phone.
- `api/config.js` serves the config. `GET /api/config` returns the current JSON, which the app reads and which is public. `POST /api/config` publishes changes and needs the `x-admin-passcode` header.
- `api/_validate.js` checks the input. `npm test` runs `test/validate.test.mjs`.
- The config is stored in Vercel Blob as `config.json`.

## Deploy

1. Create a Vercel project from this `admin/` folder.
2. Add a Blob store to the project. This sets `BLOB_READ_WRITE_TOKEN`.
3. Set the `ADMIN_PASSCODE` environment variable to a long passphrase and share it only with the committee.
4. Deploy, then set `ConfigStore.configURL` in the app to `https://<deployment>/api/config` and ship a new build.

The JSON matches `RemoteConfig` in `Sources/Data/ConfigStore.swift`. Every field is optional, and anything missing falls back to the app's built-in content.
