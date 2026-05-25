# Admin claim helper

This folder contains a small helper to set or remove the `admin` custom claim on a Firebase user.

Files:
- `set_admin_claims.js` — Node.js script that calls Firebase Admin SDK to set `{admin: true}` or remove it.

Quick start

1. Install Node.js (if not installed).
2. From the repo root, install the dependency:

```bash
npm init -y
npm install firebase-admin
```

3. Provide credentials:

- Recommended: create a service account key in the Firebase Console (IAM & Admin → Service Accounts)
  and download the JSON. Place it at `scripts/serviceAccountKey.json` (do NOT commit this file).

- Alternatively set the environment variable `GOOGLE_APPLICATION_CREDENTIALS` pointing to the
  service account JSON on your machine/CI.

4. Run the script to assign or remove admin claim:

```bash
# set admin
node scripts/set_admin_claims.js --uid USER_UID --admin true

# remove admin
node scripts/set_admin_claims.js --uid USER_UID --admin false
```

Notes
- The Admin SDK requires the service account to have `iam.serviceAccounts.getAccessToken` permissions.
- Do NOT commit service account JSON to source control. Use secret managers in CI.
- After changing custom claims, a user's ID token must be refreshed to pick up new claims (sign out/in).
