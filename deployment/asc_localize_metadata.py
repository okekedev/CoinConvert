#!/usr/bin/env python3
"""
Tagwise — upload localized App Store metadata for all languages.

Applies name/subtitle (appInfoLocalizations) + description/keywords/
promotionalText (appStoreVersionLocalizations) for every locale in
deployment/metadata/localizations.py onto the current EDITABLE app version.

Two-pass, per the playbook NEW LESSON 4: POSTing a version localization makes
ASC auto-create a shadow appInfoLocalization for that locale, so we POST all
version-locales first, then re-fetch and PATCH the info-locales.

DRY RUN by default. Pass --apply to write. Optionally pass a version id.

Field limits enforced: name/subtitle <=30, keywords <=100, promotionalText <=170.
"""
import json, sys, time, urllib.request, urllib.error
from pathlib import Path
import jwt
sys.path.insert(0, str(Path(__file__).parent / "metadata"))
from localizations import LOCALIZATIONS  # noqa: E402

KEY_ID = "V8FBWK55MT"
ISSUER_ID = "196f43aa-4520-4178-a7df-68db3cf7ee76"
P8 = Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{KEY_ID}.p8"
API = "https://api.appstoreconnect.apple.com"
APP_ID = "6755891772"
APPLY = "--apply" in sys.argv
VERSION_ID = next((a for a in sys.argv[1:] if not a.startswith("-")), None)

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170, "description": 4000}
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED",
            "WAITING_FOR_REVIEW", "INVALID_BINARY"}
VERSION_FIELDS = ("description", "keywords", "promotionalText", "whatsNew", "marketingUrl", "supportUrl")
INFO_FIELDS = ("name", "subtitle")


def token():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER_ID, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
                      P8.read_text(), algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})


def request(method, path, tok, body=None):
    url = f"{API}{path}" if path.startswith("/") else path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, method=method, data=data,
                                 headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {"raw": e.read().decode(errors="ignore")[:500]}


def get(p, tok): return request("GET", p, tok)


def clip(field, val):
    lim = LIMITS.get(field)
    if lim and val and len(val) > lim:
        print(f"      ! {field} over {lim} ({len(val)}) — truncating")
        return val[:lim]
    return val


def editable_version(tok):
    if VERSION_ID:
        return VERSION_ID
    code, resp = get(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20", tok)
    for v in resp.get("data", []):
        st = v["attributes"].get("appStoreState") or v["attributes"].get("appVersionState")
        if st in EDITABLE:
            print(f"editable version: {v['attributes'].get('versionString')} ({st}) id={v['id']}")
            return v["id"]
    return None


def main():
    tok = token()
    ver = editable_version(tok)
    if not ver:
        print("No editable app version found. Create the next version first "
              "(asc_release.py), or pass a version id. Nothing to do.")
        return
    # Use the EDITABLE appInfo (a new one is created alongside the editable
    # version); the live one is READY_FOR_DISTRIBUTION and rejects writes.
    _, ai = get(f"/v1/apps/{APP_ID}/appInfos", tok)
    infos = ai.get("data", [])
    app_info_id = next((x["id"] for x in infos
                        if (x["attributes"].get("state") or x["attributes"].get("appStoreState")) in EDITABLE),
                       infos[0]["id"])

    locales = [l for l in LOCALIZATIONS if l != "en-US"]
    print(f"{'APPLY' if APPLY else 'DRY RUN'} — {len(locales)} locales onto version {ver}\n")

    # Pass 1 — version localizations (description/keywords/promo)
    _, vl = get(f"/v1/appStoreVersions/{ver}/appStoreVersionLocalizations?limit=200", tok)
    existing_vl = {x["attributes"]["locale"]: x["id"] for x in vl.get("data", [])}
    for loc in locales:
        data = LOCALIZATIONS[loc]
        attrs = {f: clip(f, data[f]) for f in VERSION_FIELDS if data.get(f)}
        if loc in existing_vl:
            print(f"[{loc}] version-loc exists -> PATCH")
            if APPLY:
                c, r = request("PATCH", f"/v1/appStoreVersionLocalizations/{existing_vl[loc]}", tok,
                               {"data": {"type": "appStoreVersionLocalizations", "id": existing_vl[loc], "attributes": attrs}})
                print("    ", "✓" if c in (200, 201) else f"✗ {c} {json.dumps(r)[:200]}")
        else:
            print(f"[{loc}] version-loc -> POST")
            if APPLY:
                body = {"data": {"type": "appStoreVersionLocalizations",
                                 "attributes": {"locale": loc, **attrs},
                                 "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver}}}}}
                c, r = request("POST", "/v1/appStoreVersionLocalizations", tok, body)
                print("    ", "✓" if c in (200, 201) else f"✗ {c} {json.dumps(r)[:200]}")
        time.sleep(0.3)

    if not APPLY:
        print("\n(dry run) Pass 2 (name/subtitle PATCH) runs after version-locales exist. Re-run with --apply.")
        return

    # Pass 2 — re-fetch info-locales (shadows created by pass 1), PATCH name/subtitle
    print("\n-- pass 2: name/subtitle --")
    _, il = get(f"/v1/appInfos/{app_info_id}/appInfoLocalizations?limit=200", tok)
    info_ids = {x["attributes"]["locale"]: x["id"] for x in il.get("data", [])}
    for loc in locales:
        data = LOCALIZATIONS[loc]
        attrs = {f: clip(f, data[f]) for f in INFO_FIELDS if data.get(f)}
        if loc in info_ids:
            c, r = request("PATCH", f"/v1/appInfoLocalizations/{info_ids[loc]}", tok,
                           {"data": {"type": "appInfoLocalizations", "id": info_ids[loc], "attributes": attrs}})
        else:
            body = {"data": {"type": "appInfoLocalizations", "attributes": {"locale": loc, **attrs},
                             "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info_id}}}}}
            c, r = request("POST", "/v1/appInfoLocalizations", tok, body)
        print(f"[{loc}] name/subtitle", "✓" if c in (200, 201) else f"✗ {c} {json.dumps(r)[:200]}")
        time.sleep(0.3)

    print("\nDone.")


if __name__ == "__main__":
    main()
