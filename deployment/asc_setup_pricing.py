#!/usr/bin/env python3
"""Tagwise Pro pricing in App Store Connect (same pattern as Controlla's asc_pricing.py).

  - Group "Currency Conversion Pro" -> display name "Tagwise Pro"; monthly plan -> "Monthly"
    (Apple refuses these edits once the subscription is APPROVED — do them in the web UI)
  - Monthly   pro.monthly         $1.99 -> $2.99, all territories, startDate today + 31 days,
                                  existing subscribers keep their price (preserveCurrentPrice)
  - Weekly    pro.weekly          new, $0.99, same territories as monthly, 3-day free trial
  - Lifetime  pro.lifetime        new NON_CONSUMABLE, $29.99
  - Offer     pro.lifetime.offer  new NON_CONSUMABLE, $14.99 (shown only on the offer screen)
  - Review screenshot (the Pro screen) on each new product

Idempotent: existing objects are reused, 409 "already exists" is treated as done.
Nothing is submitted; new products go to review with the next version.

Usage:
  python3 deployment/asc_setup_pricing.py                    # DRY RUN: reads only, prints the plan
  python3 deployment/asc_setup_pricing.py --apply SHOT.png   # perform the writes
"""
import hashlib
import json
import sys
import urllib.request
from datetime import date, timedelta
from pathlib import Path

from asc import APP_ID, call, en_us, paginate, patch, rel, request

APPLY = "--apply" in sys.argv
SCREENSHOT = next((Path(a) for a in sys.argv[1:] if a.endswith(".png")), None)
START = (date.today() + timedelta(days=31)).isoformat()

GROUP_ID = "21844920"
MONTHLY_ID = "6755893924"
PREFIX = "com.christianokeke.liveexchange.pro"
MONTHLY_TARGET = "2.99"
WEEKLY = dict(product_id=f"{PREFIX}.weekly", price="0.99", name="Weekly",
              description="Camera price scanning, billed weekly.")
LIFETIMES = [
    dict(product_id=f"{PREFIX}.lifetime", ref="Tagwise Pro Lifetime", price="29.99",
         note="One-time purchase that unlocks Tagwise permanently."),
    dict(product_id=f"{PREFIX}.lifetime.offer", ref="Tagwise Pro Lifetime Offer", price="14.99",
         note="Half-price lifetime unlock, shown on the offer screen when someone closes the Pro "
              "screen. Same entitlement as the regular lifetime."),
]


def log(msg):
    print(msg, flush=True)


def write(method, path, body, label):
    """POST/PATCH only with --apply. Returns (status, json) or None in dry run."""
    log(f"    -> {method} {path}  {label}")
    if not APPLY:
        return None
    status, data = request(method, path, body)
    # A 409 on create means it already exists; on PATCH it's a real refusal.
    if status >= 300 and not (status == 409 and method == "POST"):
        log(f"    ✗ HTTP {status}: {json.dumps(data)[:500]}")
    return status, data


def territories_of_monthly():
    avail = call("GET", f"/v1/subscriptions/{MONTHLY_ID}/subscriptionAvailability")["data"]
    return [t["id"] for t in paginate(f"/v1/subscriptionAvailabilities/{avail['id']}/availableTerritories?limit=200")]


def sub_price_points(sub_id, usa_price):
    """USA point for usa_price plus Apple's equalized point in every other territory."""
    usa = [p for p in paginate(f"/v1/subscriptions/{sub_id}/pricePoints?filter[territory]=USA&limit=200")
           if p["attributes"]["customerPrice"] == usa_price]
    if not usa:
        return {}
    points = {"USA": usa[0]["id"]}
    for p in paginate(f"/v1/subscriptionPricePoints/{usa[0]['id']}/equalizations?include=territory&limit=200"):
        points[p["relationships"]["territory"]["data"]["id"]] = p["id"]
    return points


def set_sub_prices(sub_id, points, territories, start_date, preserve, label):
    log(f"    -> POST /v1/subscriptionPrices x{len([t for t in territories if t in points])}  {label}")
    if not APPLY:
        return
    done = skipped = failed = 0
    for terr in territories:
        if terr not in points:
            continue
        status, data = request("POST", "/v1/subscriptionPrices", {"data": {
            "type": "subscriptionPrices",
            "attributes": {"startDate": start_date, "preserveCurrentPrice": preserve},
            "relationships": {
                "subscription": rel("subscriptions", sub_id),
                "subscriptionPricePoint": rel("subscriptionPricePoints", points[terr]),
                "territory": rel("territories", terr),
            },
        }})
        if status < 300:
            done += 1
        elif status == 409:
            skipped += 1
        else:
            failed += 1
            log(f"    ✗ {terr}: HTTP {status} {json.dumps(data)[:200]}")
    log(f"    ✓ {done} set, {skipped} already set, {failed} failed")


def upload_review_screenshot(endpoint, rel_key, rel_type, parent_id):
    if SCREENSHOT is None:
        log("    ! no screenshot passed; product stays MISSING_METADATA until one is uploaded")
        return
    blob = SCREENSHOT.read_bytes()
    result = write("POST", f"/v1/{endpoint}", {"data": {
        "type": endpoint,
        "attributes": {"fileName": SCREENSHOT.name, "fileSize": len(blob)},
        "relationships": {rel_key: rel(rel_type, parent_id)},
    }}, f"review screenshot {SCREENSHOT.name}")
    if not result or result[0] >= 300:
        return
    shot = result[1]["data"]
    for op in shot["attributes"]["uploadOperations"]:
        chunk = blob[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=chunk, method=op["method"],
                                     headers={h["name"]: h["value"] for h in op["requestHeaders"]})
        urllib.request.urlopen(req, timeout=120).read()
    patch(endpoint, shot["id"], {"uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()})
    log("    ✓ screenshot uploaded")


def main():
    log(f"{'APPLY' if APPLY else 'DRY RUN'}  —  price change start date {START}")
    territories = territories_of_monthly()
    log(f"Monthly is sold in {len(territories)} territories")

    # Names
    log("\n[NAMES]")
    group_loc = en_us(call("GET", f"/v1/subscriptionGroups/{GROUP_ID}/subscriptionGroupLocalizations")["data"])
    monthly_loc = en_us(call("GET", f"/v1/subscriptions/{MONTHLY_ID}/subscriptionLocalizations")["data"])
    log(f"    group '{group_loc['attributes']['name']}' -> 'Tagwise Pro'; "
        f"monthly '{monthly_loc['attributes']['name']}' -> 'Monthly'")
    write("PATCH", f"/v1/subscriptionGroupLocalizations/{group_loc['id']}", {"data": {
        "type": "subscriptionGroupLocalizations", "id": group_loc["id"], "attributes": {"name": "Tagwise Pro"}}},
        "group display name")
    write("PATCH", f"/v1/subscriptionLocalizations/{monthly_loc['id']}", {"data": {
        "type": "subscriptionLocalizations", "id": monthly_loc["id"],
        "attributes": {"name": "Monthly", "description": "Camera price scanning, billed monthly."}}},
        "monthly display name")

    # Monthly price
    log(f"\n[MONTHLY] -> ${MONTHLY_TARGET} from {START}, existing subscribers keep their price")
    points = sub_price_points(MONTHLY_ID, MONTHLY_TARGET)
    log(f"    price points: {len(points)} territories")
    set_sub_prices(MONTHLY_ID, points, territories, START, True, f"${MONTHLY_TARGET} scheduled")

    # Weekly
    log(f"\n[WEEKLY] {WEEKLY['product_id']} @ ${WEEKLY['price']} + 3-day trial")
    subs = {s["attributes"]["productId"]: s for s in paginate(f"/v1/subscriptionGroups/{GROUP_ID}/subscriptions?limit=50")}
    weekly = subs.get(WEEKLY["product_id"])
    if weekly:
        weekly_id = weekly["id"]
        log(f"    exists: {weekly_id} ({weekly['attributes']['state']})")
    else:
        result = write("POST", "/v1/subscriptions", {"data": {
            "type": "subscriptions",
            "attributes": {"name": "Tagwise Pro Weekly", "productId": WEEKLY["product_id"],
                           "familySharable": False, "groupLevel": 1, "subscriptionPeriod": "ONE_WEEK",
                           "reviewNote": "Same Pro features as Monthly, billed weekly. 3-day free trial."},
            "relationships": {"group": rel("subscriptionGroups", GROUP_ID)},
        }}, "create subscription")
        weekly_id = result[1]["data"]["id"] if result and result[0] < 300 else None
    if weekly_id or not APPLY:
        sid = weekly_id or "<new>"
        if not weekly_id or not call("GET", f"/v1/subscriptions/{weekly_id}/subscriptionLocalizations")["data"]:
            write("POST", "/v1/subscriptionLocalizations", {"data": {
                "type": "subscriptionLocalizations",
                "attributes": {"locale": "en-US", "name": WEEKLY["name"], "description": WEEKLY["description"]},
                "relationships": {"subscription": rel("subscriptions", sid)},
            }}, "en-US name")
        write("POST", "/v1/subscriptionAvailabilities", {"data": {
            "type": "subscriptionAvailabilities", "attributes": {"availableInNewTerritories": True},
            "relationships": {"subscription": rel("subscriptions", sid),
                              "availableTerritories": {"data": [{"type": "territories", "id": t} for t in territories]}},
        }}, f"availability in {len(territories)} territories")
        if weekly_id:
            set_sub_prices(weekly_id, sub_price_points(weekly_id, WEEKLY["price"]), territories, None, False,
                           f"${WEEKLY['price']} initial price")
            have = {o["relationships"]["territory"]["data"]["id"] for o in
                    paginate(f"/v1/subscriptions/{weekly_id}/introductoryOffers?include=territory&limit=200")}
            missing = [t for t in territories if t not in have]
            log(f"    -> POST /v1/subscriptionIntroductoryOffers x{len(missing)}  3-day free trial")
            if APPLY:
                for terr in missing:
                    status, data = request("POST", "/v1/subscriptionIntroductoryOffers", {"data": {
                        "type": "subscriptionIntroductoryOffers",
                        "attributes": {"duration": "THREE_DAYS", "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
                        "relationships": {"subscription": rel("subscriptions", weekly_id),
                                          "territory": rel("territories", terr)},
                    }})
                    if status >= 300 and status != 409:
                        log(f"    ✗ trial {terr}: HTTP {status} {json.dumps(data)[:200]}")
            shot = call("GET", f"/v1/subscriptions/{weekly_id}?include=appStoreReviewScreenshot")["data"]
            if not shot["relationships"]["appStoreReviewScreenshot"].get("data"):
                upload_review_screenshot("subscriptionAppStoreReviewScreenshots", "subscription", "subscriptions", weekly_id)
        else:
            log("    (price, trial and screenshot follow once the subscription exists)")

    # Lifetimes
    iaps = {i["attributes"]["productId"]: i for i in paginate(f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200")}
    for item in LIFETIMES:
        log(f"\n[LIFETIME] {item['product_id']} @ ${item['price']}")
        iap = iaps.get(item["product_id"])
        if iap:
            iap_id = iap["id"]
            log(f"    exists: {iap_id} ({iap['attributes']['state']})")
        else:
            result = write("POST", "/v2/inAppPurchases", {"data": {
                "type": "inAppPurchases",
                "attributes": {"name": item["ref"], "productId": item["product_id"],
                               "inAppPurchaseType": "NON_CONSUMABLE", "reviewNote": item["note"],
                               "familySharable": False},
                "relationships": {"app": rel("apps", APP_ID)},
            }}, "create NON_CONSUMABLE")
            iap_id = result[1]["data"]["id"] if result and result[0] < 300 else None
        sid = iap_id or "<new>"
        if not iap_id or not call("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")["data"]:
            write("POST", "/v1/inAppPurchaseLocalizations", {"data": {
                "type": "inAppPurchaseLocalizations",
                "attributes": {"locale": "en-US", "name": "Lifetime", "description": "Unlock Tagwise forever."},
                "relationships": {"inAppPurchaseV2": rel("inAppPurchases", sid)},
            }}, "en-US name")
        write("POST", "/v1/inAppPurchaseAvailabilities", {"data": {
            "type": "inAppPurchaseAvailabilities", "attributes": {"availableInNewTerritories": True},
            "relationships": {"inAppPurchase": rel("inAppPurchases", sid),
                              "availableTerritories": {"data": [{"type": "territories", "id": t} for t in territories]}},
        }}, f"availability in {len(territories)} territories")
        if not iap_id:
            log("    (price and screenshot follow once the product exists)")
            continue
        point = next((p["id"] for p in paginate(f"/v2/inAppPurchases/{iap_id}/pricePoints?filter[territory]=USA&limit=200")
                      if p["attributes"]["customerPrice"] == item["price"]), None)
        if not point:
            log(f"    ! no USA price point for ${item['price']}")
            continue
        write("POST", "/v1/inAppPurchasePriceSchedules", {
            "data": {"type": "inAppPurchasePriceSchedules", "relationships": {
                "inAppPurchase": rel("inAppPurchases", iap_id),
                "baseTerritory": rel("territories", "USA"),
                "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${new-price}"}]}}},
            "included": [{"type": "inAppPurchasePrices", "id": "${new-price}", "attributes": {"startDate": None},
                          "relationships": {"inAppPurchasePricePoint": rel("inAppPurchasePricePoints", point)}}],
        }, f"${item['price']} (other territories equalized from USA)")
        if not call("GET", f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot")["data"]:
            upload_review_screenshot("inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseV2", "inAppPurchases", iap_id)

    if APPLY:
        log("\nStates:")
        for s in paginate(f"/v1/subscriptionGroups/{GROUP_ID}/subscriptions?limit=50"):
            log(f"    {s['attributes']['productId']}: {s['attributes']['state']}")
        for i in paginate(f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200"):
            log(f"    {i['attributes']['productId']}: {i['attributes']['state']}")
    else:
        log("\nDry run only. Re-run with --apply <paywall.png> to make these changes.")


if __name__ == "__main__":
    main()
