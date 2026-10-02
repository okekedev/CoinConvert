"""Push the Tagwise listing to App Store Connect. Nothing is submitted for review.

1. Promotional text on the live version (takes effect immediately).
2. Create version 2.1 (reused if it exists).
3. On 2.1: name, subtitle, categories, description, keywords, What's New, promo text.

Run: python3 deployment/asc_push_metadata.py
"""
from pathlib import Path

from asc import APP_ID, call, en_us, patch, rel

NEW_VERSION = "2.1"
NAME = "Tagwise: Scan Prices Abroad"
SUBTITLE = "Camera Currency Converter"
PRIMARY_CATEGORY = "TRAVEL"
SECONDARY_CATEGORY = "FINANCE"
META = Path(__file__).parent / "metadata"


def read(name):
    return (META / name).read_text().strip()


versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=10")["data"]
live = next(v for v in versions if v["attributes"]["appStoreState"] == "READY_FOR_SALE")

live_loc = en_us(call("GET", f"/v1/appStoreVersions/{live['id']}/appStoreVersionLocalizations")["data"])
patch("appStoreVersionLocalizations", live_loc["id"], {"promotionalText": read("promotional-text.txt")})
print(f"✓ Promotional text updated on live {live['attributes']['versionString']}")

new = next((v for v in versions if v["attributes"]["versionString"] == NEW_VERSION), None)
if new is None:
    new = call("POST", "/v1/appStoreVersions", {"data": {
        "type": "appStoreVersions",
        "attributes": {"platform": "IOS", "versionString": NEW_VERSION},
        "relationships": {"app": rel("apps", APP_ID)},
    }})["data"]
    print(f"✓ Created version {NEW_VERSION}")
else:
    print(f"• Version {NEW_VERSION} exists ({new['attributes']['appStoreState']})")

# Name, subtitle and categories live on the editable AppInfo, not the live one.
infos = call("GET", f"/v1/apps/{APP_ID}/appInfos")["data"]
editable = next(i for i in infos if i["attributes"].get("appStoreState") != "READY_FOR_SALE")
info_loc = en_us(call("GET", f"/v1/appInfos/{editable['id']}/appInfoLocalizations")["data"])
patch("appInfoLocalizations", info_loc["id"], {"name": NAME, "subtitle": SUBTITLE})
print(f"✓ Name: {NAME}\n✓ Subtitle: {SUBTITLE}")

patch("appInfos", editable["id"], relationships={
    "primaryCategory": rel("appCategories", PRIMARY_CATEGORY),
    "secondaryCategory": rel("appCategories", SECONDARY_CATEGORY),
})
print(f"✓ Categories: {PRIMARY_CATEGORY} / {SECONDARY_CATEGORY}")

new_loc = en_us(call("GET", f"/v1/appStoreVersions/{new['id']}/appStoreVersionLocalizations")["data"])
patch("appStoreVersionLocalizations", new_loc["id"], {
    "description": read("description.txt"),
    "keywords": read("keywords.txt"),
    "whatsNew": read("whats-new.txt"),
    "promotionalText": read("promotional-text.txt"),
})
print(f"✓ Description, keywords, What's New set on {NEW_VERSION}")
