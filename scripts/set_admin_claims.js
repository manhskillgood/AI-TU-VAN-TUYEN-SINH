#!/usr/bin/env node
/**
 * Simple Admin SDK helper to set or remove the `admin` custom claim for a user.
 *
 * Usage:
 *   - Set admin:   node set_admin_claims.js --uid <UID> --admin true
 *   - Remove admin:node set_admin_claims.js --uid <UID> --admin false
 *
 * Requirements:
 *   - Node.js installed
 *   - `npm install firebase-admin` run in this repo (or globally)
 *   - A Firebase service account JSON key or GOOGLE_APPLICATION_CREDENTIALS env var
 *
 * Security: Do NOT commit your service account key to source control. Use
 * environment variables or a CI secrets store for production deployments.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function parseArgs() {
  const out = {};
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) {
        out[key] = true;
      } else {
        out[key] = next;
        i++;
      }
    }
  }
  return out;
}

function initAdmin() {
  // Prefer explicit service account file if present
  const servicePath = path.join(__dirname, 'serviceAccountKey.json');
  if (fs.existsSync(servicePath)) {
    const svc = require(servicePath);
    admin.initializeApp({ credential: admin.credential.cert(svc) });
    return;
  }

  // Otherwise rely on GOOGLE_APPLICATION_CREDENTIALS or environment
  try {
    admin.initializeApp();
  } catch (e) {
    console.error('Failed to initialize Firebase Admin SDK. Provide service account JSON or set GOOGLE_APPLICATION_CREDENTIALS.');
    process.exit(1);
  }
}

async function setAdminClaim(uid, isAdmin) {
  try {
    const claims = isAdmin ? { admin: true } : {};
    await admin.auth().setCustomUserClaims(uid, claims);
    console.log(`Success: set admin=${!!isAdmin} for uid=${uid}`);
  } catch (err) {
    console.error('Error setting custom claims:', err.message || err);
    process.exitCode = 2;
  }
}

async function main() {
  const args = parseArgs();
  const uid = args.uid || args.u;
  const adminFlag = args.admin;

  if (!uid) {
    console.error('Missing --uid <UID>');
    console.error('Usage: node set_admin_claims.js --uid <UID> --admin true|false');
    process.exit(1);
  }

  if (adminFlag === undefined) {
    console.error('Missing --admin flag (true or false)');
    process.exit(1);
  }

  const isAdmin = String(adminFlag).toLowerCase() === 'true';

  initAdmin();
  await setAdminClaim(uid, isAdmin);
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
