#!/usr/bin/env python3
"""Localize Tagwise Pro product names/descriptions in App Store Connect.

Adds a localization per language to the subscription group, Weekly, Monthly,
Lifetime and Lifetime Offer. Existing localizations are left alone (Apple won't
let the API edit approved ones). Subscription descriptions are capped at 55 chars.

Usage:
  python3 deployment/asc_localize_products.py           # DRY RUN
  python3 deployment/asc_localize_products.py --apply
"""
import json
import sys

from asc import APP_ID, call, paginate, rel, request

APPLY = "--apply" in sys.argv
GROUP_ID = "21844920"
PREFIX = "com.christianokeke.liveexchange.pro"

# locale: (weekly, monthly, lifetime, sub description, lifetime description)
L = {
    "es-ES": ("Semanal", "Mensual", "Vitalicio", "Escanea precios con la cámara y conviértelos.", "Desbloquea Tagwise para siempre."),
    "es-MX": ("Semanal", "Mensual", "Vitalicio", "Escanea precios con la cámara y conviértelos.", "Desbloquea Tagwise para siempre."),
    "fr-FR": ("Hebdomadaire", "Mensuel", "À vie", "Scannez les prix avec l'appareil photo.", "Débloquez Tagwise à vie."),
    "de-DE": ("Wöchentlich", "Monatlich", "Lebenslang", "Preise mit der Kamera scannen und umrechnen.", "Tagwise für immer freischalten."),
    "it": ("Settimanale", "Mensile", "A vita", "Scansiona i prezzi con la fotocamera.", "Sblocca Tagwise per sempre."),
    "pt-BR": ("Semanal", "Mensal", "Vitalício", "Escaneie preços com a câmera e converta.", "Desbloqueie o Tagwise para sempre."),
    "ja": ("週間", "月間", "買い切り", "カメラで値札をスキャンして換算。", "Tagwiseをずっと使えます。"),
    "ko": ("주간", "월간", "평생", "카메라로 가격을 스캔하고 환산하세요.", "Tagwise를 평생 사용하세요."),
    "zh-Hans": ("每周", "每月", "终身", "用相机扫描价格并换算。", "永久解锁 Tagwise。"),
    "zh-Hant": ("每週", "每月", "終身", "用相機掃描價格並換算。", "永久解鎖 Tagwise。"),
    "nl-NL": ("Wekelijks", "Maandelijks", "Levenslang", "Scan prijzen met je camera en reken om.", "Ontgrendel Tagwise voor altijd."),
    "ru": ("Неделя", "Месяц", "Навсегда", "Сканируйте цены камерой и конвертируйте.", "Tagwise навсегда."),
    "tr": ("Haftalık", "Aylık", "Ömür Boyu", "Fiyatları kamerayla tarayıp çevirin.", "Tagwise'ın kilidini kalıcı açın."),
    "ar-SA": ("أسبوعي", "شهري", "مدى الحياة", "امسح الأسعار بالكاميرا وحوّلها.", "افتح Tagwise مدى الحياة."),
    "th": ("รายสัปดาห์", "รายเดือน", "ตลอดชีพ", "สแกนราคาด้วยกล้องแล้วแปลงสกุลเงิน", "ปลดล็อก Tagwise ตลอดไป"),
    "id": ("Mingguan", "Bulanan", "Seumur Hidup", "Pindai harga dengan kamera dan konversi.", "Buka Tagwise selamanya."),
    "pt-PT": ("Semanal", "Mensal", "Vitalício", "Digitaliza preços com a câmara e converte.", "Desbloqueia o Tagwise para sempre."),
}


def log(msg):
    print(msg, flush=True)


def post(path, body, label):
    log(f"    -> POST {path}  {label}")
    if not APPLY:
        return
    status, data = request("POST", path, body)
    if status >= 300:
        log(f"    ✗ HTTP {status}: {json.dumps(data)[:300]}")


def main():
    log("APPLY" if APPLY else "DRY RUN")
    subs = {s["attributes"]["productId"]: s["id"] for s in paginate(f"/v1/subscriptionGroups/{GROUP_ID}/subscriptions?limit=50")}
    iaps = {i["attributes"]["productId"]: i["id"] for i in paginate(f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200")}

    log("\n[GROUP] Tagwise Pro")
    have = {l["attributes"]["locale"] for l in call("GET", f"/v1/subscriptionGroups/{GROUP_ID}/subscriptionGroupLocalizations")["data"]}
    for locale in L:
        if locale not in have:
            post("/v1/subscriptionGroupLocalizations", {"data": {
                "type": "subscriptionGroupLocalizations", "attributes": {"locale": locale, "name": "Tagwise Pro"},
                "relationships": {"subscriptionGroup": rel("subscriptionGroups", GROUP_ID)}}}, locale)

    for index, product in [(0, f"{PREFIX}.weekly"), (1, f"{PREFIX}.monthly")]:
        sid = subs[product]
        log(f"\n[SUB] {product}")
        have = {l["attributes"]["locale"] for l in call("GET", f"/v1/subscriptions/{sid}/subscriptionLocalizations")["data"]}
        for locale, names in L.items():
            if locale not in have:
                assert len(names[3]) <= 55, (locale, names[3])
                post("/v1/subscriptionLocalizations", {"data": {
                    "type": "subscriptionLocalizations",
                    "attributes": {"locale": locale, "name": names[index], "description": names[3]},
                    "relationships": {"subscription": rel("subscriptions", sid)}}}, f"{locale}: {names[index]}")

    for product in [f"{PREFIX}.lifetime", f"{PREFIX}.lifetime.offer"]:
        iid = iaps[product]
        log(f"\n[IAP] {product}")
        have = {l["attributes"]["locale"] for l in call("GET", f"/v2/inAppPurchases/{iid}/inAppPurchaseLocalizations")["data"]}
        for locale, names in L.items():
            if locale not in have:
                post("/v1/inAppPurchaseLocalizations", {"data": {
                    "type": "inAppPurchaseLocalizations",
                    "attributes": {"locale": locale, "name": names[2], "description": names[4]},
                    "relationships": {"inAppPurchaseV2": rel("inAppPurchases", iid)}}}, f"{locale}: {names[2]}")

    if not APPLY:
        log("\nDry run only. Re-run with --apply.")


if __name__ == "__main__":
    main()
