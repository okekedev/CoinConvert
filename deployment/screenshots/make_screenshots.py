#!/usr/bin/env python3
"""Localized App Store screenshots for Tagwise.

For each App Store locale and device, launches the app in the simulator in screenshot
demo mode (see ScreenshotDemo in AppTheme.swift) with that country's language and
currencies, captures 3 screens, and composes them on the brand background with a
translated headline.

  python3 deployment/screenshots/make_screenshots.py [iphone|ipad] [locale ...]

Output: deployment/screenshots/<device>/<locale>/1-scan.png, 2-calculator.png, 3-currencies.png
Needs: the debug simulator build at $APP and the simulators below booted.
"""
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
APP = Path("/private/tmp/claude-501/-Users-christian-dev/268905fc-2bd3-4fcd-bd8d-92501b21dda7/scratchpad/dd/Build/Products/Debug-iphonesimulator/CoinConvert.app")
RAW = Path("/private/tmp/claude-501/-Users-christian-dev/268905fc-2bd3-4fcd-bd8d-92501b21dda7/scratchpad/raw")
BUNDLE = "com.christianokeke.liveexchange"

DEVICES = {
    # 6.9" iPhone (1320x2868) and 13" iPad (2064x2752): the sizes App Store Connect requires.
    "iphone": dict(udid="A77DF717-7124-4261-BFF1-4EDCA73D656E", shot_width=0.80, top=560, title=112, sub=54),
    "ipad": dict(udid="A833035C-6B0B-40AB-8284-D8A83F7E368D", shot_width=0.70, top=600, title=124, sub=60),
}

# ASC locale: (app language, region, home currency, tag currency, scan amount, calculator amount)
# The scan uses a real photo of a "$44.99" tag (source/scan-usd.png); en-US uses a copy
# with "€" so the US shot converts into dollars (source/scan-eur.png).
SCAN_AMOUNT = 44.99
LOCALES = {
    "en-US": ("en", "en_US", "USD", "EUR"), "en-GB": ("en-GB", "en_GB", "GBP", "USD"),
    "en-AU": ("en-AU", "en_AU", "AUD", "USD"), "en-CA": ("en-CA", "en_CA", "CAD", "USD"),
    "es-ES": ("es", "es_ES", "EUR", "USD"), "es-MX": ("es-MX", "es_MX", "MXN", "USD"),
    "fr-FR": ("fr", "fr_FR", "EUR", "USD"), "fr-CA": ("fr-CA", "fr_CA", "CAD", "USD"),
    "de-DE": ("de", "de_DE", "EUR", "USD"), "it": ("it", "it_IT", "EUR", "USD"),
    "pt-BR": ("pt-BR", "pt_BR", "BRL", "USD"), "pt-PT": ("pt-PT", "pt_PT", "EUR", "USD"),
    "nl-NL": ("nl", "nl_NL", "EUR", "USD"), "ru": ("ru", "ru_RU", "RUB", "USD"),
    "tr": ("tr", "tr_TR", "TRY", "USD"), "th": ("th", "th_TH", "THB", "USD"),
    "id": ("id", "id_ID", "IDR", "USD"),
    "ja": ("ja", "ja_JP", "JPY", "USD"), "ko": ("ko", "ko_KR", "KRW", "USD"),
    "zh-Hans": ("zh-Hans", "zh_CN", "CNY", "USD"), "zh-Hant": ("zh-Hant", "zh_TW", "TWD", "USD"),
}
SCAN_IMAGES = {"USD": OUT / "source" / "scan-usd.png", "EUR": OUT / "source" / "scan-eur.png"}

EN = [("Point. Scan. Done.", "Prices convert as you look"),
      ("Split it. Tip it.", "A calculator for every currency"),
      ("150+ currencies", "Works offline, no account")]
HEADLINES = {
    "en": EN,
    "es": [("Apunta. Escanea. Listo.", "Los precios se convierten al instante"),
           ("Divide. Añade propina.", "Calculadora en cualquier moneda"),
           ("Más de 150 monedas", "Sin conexión y sin cuenta")],
    "fr": [("Visez. Scannez. Voilà.", "Les prix convertis d'un coup d'œil"),
           ("Partagez. Ajoutez le pourboire.", "Une calculatrice pour chaque devise"),
           ("Plus de 150 devises", "Hors ligne, sans compte")],
    "de": [("Zielen. Scannen. Fertig.", "Preise sofort umgerechnet"),
           ("Teilen. Trinkgeld. Fertig.", "Ein Rechner für jede Währung"),
           ("Über 150 Währungen", "Offline, ohne Konto")],
    "it": [("Inquadra. Scansiona. Fatto.", "Prezzi convertiti all'istante"),
           ("Dividi. Aggiungi la mancia.", "Calcolatrice in ogni valuta"),
           ("Oltre 150 valute", "Offline e senza account")],
    "pt": [("Aponte. Escaneie. Pronto.", "Preços convertidos na hora"),
           ("Divida. Some a gorjeta.", "Calculadora em qualquer moeda"),
           ("Mais de 150 moedas", "Offline e sem conta")],
    "ja": [("かざすだけで換算", "値札をあなたの通貨で"),
           ("割り勘もチップも", "どの通貨でも使える電卓"),
           ("150以上の通貨", "オフライン・アカウント不要")],
    "ko": [("비추면 바로 환산", "가격표를 내 통화로"),
           ("더치페이도 팁도", "모든 통화를 위한 계산기"),
           ("150개 이상의 통화", "오프라인, 계정 없이")],
    "nl": [("Richten. Scannen. Klaar.", "Prijzen direct omgerekend"),
           ("Delen. Fooi erbij.", "Rekenmachine in elke valuta"),
           ("150+ valuta's", "Offline, zonder account")],
    "ru": [("Навёл. Отсканировал.", "Цены сразу в вашей валюте"),
           ("Делите счёт и чаевые", "Калькулятор в любой валюте"),
           ("Более 150 валют", "Офлайн и без аккаунта")],
    "tr": [("Tut. Tara. Tamam.", "Fiyatlar anında çevrilir"),
           ("Böl. Bahşiş ekle.", "Her para birimi için hesap makinesi"),
           ("150+ para birimi", "Çevrimdışı, hesapsız")],
    "th": [("ส่อง สแกน เสร็จ", "แปลงราคาทันทีที่มอง"),
           ("หารบิล ใส่ทิป", "เครื่องคิดเลขทุกสกุลเงิน"),
           ("กว่า 150 สกุลเงิน", "ใช้ออฟไลน์ ไม่ต้องมีบัญชี")],
    "id": [("Arahkan. Pindai. Beres.", "Harga langsung terkonversi"),
           ("Bagi tagihan, tambah tip", "Kalkulator untuk semua mata uang"),
           ("150+ mata uang", "Offline, tanpa akun")],
    "zh-Hant": [("一掃即換算", "價格標籤秒變你的貨幣"),
                ("分帳小費都輕鬆", "支援所有貨幣的計算機"),
                ("150 多種貨幣", "離線可用，無需帳號")],
    "zh": [("一扫即换算", "价签秒变你的货币"),
           ("平摊小费都轻松", "支持所有货币的计算器"),
           ("150 多种货币", "离线可用，无需账号")],
}

FONTS = ROOT / "CoinConvert" / "Fonts"
CJK = {
    "zh-Hant": ("/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc", 0, "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc", 0),
    "ru": ("/System/Library/Fonts/HelveticaNeue.ttc", 1, "/System/Library/Fonts/HelveticaNeue.ttc", 10),
    "ja": ("/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc", 0, "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc", 0),
    "ko": ("/System/Library/Fonts/AppleSDGothicNeo.ttc", 6, "/System/Library/Fonts/AppleSDGothicNeo.ttc", 2),
    "zh": ("/System/Library/Fonts/Hiragino Sans GB.ttc", 2, "/System/Library/Fonts/Hiragino Sans GB.ttc", 0),
}
NAVY, GLOW, GOLD = (13, 35, 66), (39, 70, 111), (212, 175, 55)


def run(*args):
    subprocess.run(args, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def capture(udid, locale, screen, path):
    lang, region, home, travel = LOCALES[locale]
    run("xcrun", "simctl", "terminate", udid, BUNDLE)
    args = ["xcrun", "simctl", "launch", udid, BUNDLE, "-hasOnboarded", "YES", "-demoPro", "YES", "-locationAskedAfterUpdate", "YES",
            "-AppleLanguages", f"({lang})", "-AppleLocale", region,
            "-com.coinconvert.sourcecurrency", travel, "-com.coinconvert.destinationcurrency", home,
            "-com.coinconvert.homecurrency", home]
    args += {"scan": ["-demoMode", "scan", "-demoScanAmount", str(SCAN_AMOUNT),
                      "-demoScanImage", str(SCAN_IMAGES[travel])],
             "calculator": ["-demoCalculator", str(SCAN_AMOUNT)],
             "currencies": ["-demoPicker", "YES"]}[screen]
    run(*args)
    time.sleep(4.5)
    run("xcrun", "simctl", "io", udid, "screenshot", str(path))


def fonts(lang_key, size_title, size_sub):
    if lang_key in CJK:
        bold, bi, reg, ri = CJK[lang_key]
        return ImageFont.truetype(bold, size_title, index=bi), ImageFont.truetype(reg, size_sub, index=ri)
    return (ImageFont.truetype(str(FONTS / "ChakraPetch-Bold.ttf"), size_title),
            ImageFont.truetype(str(FONTS / "ChakraPetch-Medium.ttf"), size_sub))


def fit(draw, text, font, max_width):
    """Shrink the font until the line fits."""
    while draw.textlength(text, font=font) > max_width and font.size > 40:
        font = font.font_variant(size=font.size - 4)
    return font


def compose(raw_path, out_path, title, subtitle, lang_key, cfg):
    shot = Image.open(raw_path).convert("RGB")
    W, H = shot.size
    canvas = Image.new("RGB", (W, H), NAVY)
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse([-W * 0.3, H * 0.15, W * 1.3, H * 1.2], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(W * 0.18))
    canvas.paste(Image.new("RGB", (W, H), GLOW), (0, 0), glow.point(lambda v: int(v * 0.55)))

    draw = ImageDraw.Draw(canvas)
    title_font, sub_font = fonts(lang_key, cfg["title"], cfg["sub"])
    title_font = fit(draw, title, title_font, W * 0.9)
    sub_font = fit(draw, subtitle, sub_font, W * 0.88)
    draw.text((W / 2, cfg["top"] * 0.36), title, font=title_font, fill="white", anchor="mm")
    draw.text((W / 2, cfg["top"] * 0.36 + cfg["title"] * 1.05), subtitle, font=sub_font,
              fill=(196, 206, 222), anchor="mm")

    width = int(W * cfg["shot_width"])
    height = int(H * width / W)
    phone = shot.resize((width, height), Image.LANCZOS)
    x, y = (W - width) // 2, cfg["top"]
    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rectangle([x + 10, y + 24, x + width + 10, y + height + 24], fill=150)
    canvas.paste((5, 12, 24), (0, 0), shadow.filter(ImageFilter.GaussianBlur(28)))
    border = 8
    draw.rectangle([x - border, y - border, x + width + border - 1, y + height + border - 1], fill=GOLD)
    canvas.paste(phone, (x, y))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, optimize=True)


def main():
    devices = [a for a in sys.argv[1:] if a in DEVICES] or list(DEVICES)
    locales = [a for a in sys.argv[1:] if a in LOCALES] or list(LOCALES)
    RAW.mkdir(parents=True, exist_ok=True)
    for device in devices:
        cfg = DEVICES[device]
        run("xcrun", "simctl", "install", cfg["udid"], str(APP))
        for locale in locales:
            lang = LOCALES[locale][0]
            key = lang if lang in HEADLINES else lang.split("-")[0]
            lines = HEADLINES.get(key, EN)
            for index, screen in enumerate(["scan", "calculator", "currencies"]):
                raw = RAW / f"{device}-{locale}-{screen}.png"
                capture(cfg["udid"], locale, screen, raw)
                title, subtitle = lines[index]
                compose(raw, OUT / device / locale / f"{index + 1}-{screen}.png", title, subtitle, key, cfg)
                raw.unlink()
            print(f"{device} {locale} ✓", flush=True)


if __name__ == "__main__":
    main()
