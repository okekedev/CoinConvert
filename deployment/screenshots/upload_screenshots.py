#!/usr/bin/env python3
"""Upload localized screenshots to the editable App Store version, replacing existing sets.

  python3 deployment/screenshots/upload_screenshots.py            # DRY RUN
  python3 deployment/screenshots/upload_screenshots.py --apply [locale ...]

Reads deployment/screenshots/{iphone,ipad}/<locale>/*.png (from make_screenshots.py).
Every existing screenshot set in an uploaded locale is deleted first, so old screenshots
never linger. Locales without a folder fall back to en-US in the store.
"""
import hashlib
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from asc import APP_ID, call, paginate, patch, rel, request  # noqa: E402

HERE = Path(__file__).resolve().parent
APPLY = "--apply" in sys.argv
ONLY = [a for a in sys.argv[1:] if not a.startswith("-")]
DISPLAY = {"iphone": "APP_IPHONE_67", "ipad": "APP_IPAD_PRO_3GEN_129"}
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"}


def log(msg):
    print(msg, flush=True)


def upload(set_id, path):
    blob = path.read_bytes()
    status, data = request("POST", "/v1/appScreenshots", {"data": {
        "type": "appScreenshots",
        "attributes": {"fileName": path.name, "fileSize": len(blob)},
        "relationships": {"appScreenshotSet": rel("appScreenshotSets", set_id)},
    }})
    if status >= 300:
        raise SystemExit(f"reserve {path}: HTTP {status} {str(data)[:300]}")
    shot = data["data"]
    for op in shot["attributes"]["uploadOperations"]:
        chunk = blob[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"],
                                     headers={h["name"]: h["value"] for h in op["requestHeaders"]})
        urllib.request.urlopen(req, timeout=120).read()
    patch("appScreenshots", shot["id"], {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()})


def main():
    version = next(v for v in call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=10")["data"]
                   if v["attributes"]["appStoreState"] in EDITABLE)
    log(f"{'APPLY' if APPLY else 'DRY RUN'} — version {version['attributes']['versionString']}")
    localizations = {l["attributes"]["locale"]: l["id"] for l in
                     paginate(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")}

    locales = sorted({p.name for d in DISPLAY for p in (HERE / d).glob("*") if p.is_dir()})
    for locale in [l for l in locales if not ONLY or l in ONLY]:
        loc_id = localizations.get(locale)
        if not loc_id:
            log(f"  {locale}: no listing localization, skipped")
            continue
        existing = paginate(f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=50")
        plan = {d: sorted((HERE / d / locale).glob("*.png")) for d in DISPLAY if (HERE / d / locale).is_dir()}
        log(f"  {locale}: delete {len(existing)} old set(s); upload " +
            ", ".join(f"{len(files)} {d}" for d, files in plan.items()))
        if not APPLY:
            continue
        for old in existing:
            request("DELETE", f"/v1/appScreenshotSets/{old['id']}")
        for device, files in plan.items():
            created = call("POST", "/v1/appScreenshotSets", {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": DISPLAY[device]},
                "relationships": {"appStoreVersionLocalization": rel("appStoreVersionLocalizations", loc_id)},
            }})["data"]
            for path in files:
                upload(created["id"], path)
    if not APPLY:
        log("Dry run only. Re-run with --apply.")


if __name__ == "__main__":
    main()
