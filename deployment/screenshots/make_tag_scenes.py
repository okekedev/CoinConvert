#!/usr/bin/env python3
"""Photo-style scan scenes for screenshots: a retail price tag hanging on a soccer jersey.

Writes scenes/<currency>.jpg (3600x4000). The big price is centered in the image and is
exactly PRICE_BOX_FRACTION of the image width wide, so the app's screenshot mode
(-demoScanImage) can scale it into the scan brackets on any device.

  python3 deployment/screenshots/make_tag_scenes.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent / "scenes"
W, H = 3600, 4000
PRICE_BOX_FRACTION = 0.20      # price text width / image width (mirrored in ScannerView)
HELV = "/System/Library/Fonts/HelveticaNeue.ttc"
JP_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"
JP_REG = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
INK = (24, 24, 26)

SCENES = {
    "EUR": dict(jersey=(176, 20, 38), trim=(18, 88, 52), store="CASA LUSA", country="PORTUGAL",
                item="Camisola de futebol", compare="COMPARAR  40,00 €", price="24,50 €", note="IVA INCL.",
                dept="DEP 042   ART 18375", size="M", barcode="560123418375", jp=False),
    "USD": dict(jersey=(22, 34, 72), trim=(190, 30, 45), store="FIELD & CO.", country="",
                item="Men's soccer jersey", compare="COMPARE AT  $40.00", price="$24.50", note="",
                dept="DEPT 042   STYLE 18375", size="M", barcode="012345183750", jp=False),
    "JPY": dict(jersey=(18, 52, 140), trim=(235, 235, 240), store="サッカーショップ北", country="",
                item="サッカーユニフォーム", compare="通常価格  ¥6,800", price="¥4,800", note="税込",
                dept="部門 042   品番 18375", size="M", barcode="491234518375", jp=True),
}

# EAN-13 encoding tables
L_CODES = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"]
G_CODES = ["0100111", "0110011", "0011011", "0100001", "0011101", "0111001", "0000101", "0010001", "0001001", "0010111"]
R_CODES = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"]
PARITY = ["LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG", "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"]


def ean13(first12):
    digits = [int(c) for c in first12]
    check = (10 - sum(d * (3 if i % 2 else 1) for i, d in enumerate(digits)) % 10) % 10
    digits.append(check)
    bits = "101"
    for i, d in enumerate(digits[1:7]):
        bits += (L_CODES if PARITY[digits[0]][i] == "L" else G_CODES)[d]
    bits += "01010"
    for d in digits[7:]:
        bits += R_CODES[d]
    bits += "101"
    return "".join(map(str, digits)), bits


def font(size, bold=True, jp=False, condensed=False):
    if jp:
        return ImageFont.truetype(JP_BOLD if bold else JP_REG, size)
    return ImageFont.truetype(HELV, size, index=(4 if condensed else 1) if bold else 0)


def jersey(base, trim, seed):
    rng = np.random.default_rng(seed)
    img = np.ones((H, W, 3), np.float32) * np.array(base, np.float32)
    # Knit mesh: rows of tiny holes in a staggered grid.
    yy, xx = np.mgrid[0:H, 0:W]
    pitch = 26
    stagger = ((yy // pitch) % 2) * (pitch // 2)
    holes = (((xx + stagger) % pitch - pitch / 2) ** 2 + ((yy % pitch) - pitch / 2) ** 2) < 30
    img[holes] *= 0.55
    # Yarn texture and large soft folds.
    img *= (1 + rng.normal(0, 0.05, (H, W, 1))).astype(np.float32)
    folds = np.sin(xx / 520.0 + yy / 900.0) * 0.12 + np.sin((xx - yy) / 1300.0) * 0.08
    img *= (1 + folds[..., None]).astype(np.float32)
    # Trim panel with a stitched seam on the left.
    panel = xx < 420
    img[panel] = np.array(trim, np.float32) * (1 + folds[panel][..., None] * 0.6)
    seam = (np.abs(xx - 430) < 6) & ((yy // 40) % 2 == 0)
    img[seam] = img[seam] * 0.6 + 60
    # Vignette, like a phone camera close-up.
    vignette = 1 - 0.38 * (((xx - W / 2) / (W / 1.4)) ** 2 + ((yy - H / 2) / (H / 1.4)) ** 2)
    img *= vignette[..., None].astype(np.float32)
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    return out.filter(ImageFilter.GaussianBlur(5))       # background slightly out of focus


def tag_image(s):
    """The tag on a transparent canvas, price centered at (tw/2, price_y)."""
    tw, th = 1060, 2050
    tag = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    d = ImageDraw.Draw(tag)
    paper = (250, 249, 245, 255)
    d.rectangle([0, 0, tw, th], fill=paper)
    # paper grain
    grain = (np.random.default_rng(7).normal(0, 4, (th, tw))).astype(np.int16)
    arr = np.array(tag).astype(np.int16)
    arr[..., :3] += grain[..., None]
    tag = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(tag)
    jp = s["jp"]

    # Hang hole and reinforcement ring.
    d.ellipse([tw / 2 - 46, 70, tw / 2 + 46, 162], fill=(0, 0, 0, 0), outline=(200, 198, 190), width=10)
    y = 230
    d.text((tw / 2, y), s["store"], font=font(96, jp=jp), fill=INK, anchor="mm")
    y += 92
    if s["country"]:
        d.text((tw / 2, y), s["country"], font=font(46, bold=False), fill=(90, 90, 92), anchor="mm")
        y += 70
    d.line([60, y, tw - 60, y], fill=INK, width=5)
    y += 70
    d.text((70, y), s["dept"], font=font(44, bold=False, jp=jp), fill=INK, anchor="lm")
    d.rectangle([tw - 190, y - 46, tw - 70, y + 46], outline=INK, width=6)
    d.text((tw - 130, y), s["size"], font=font(64), fill=INK, anchor="mm")
    y += 90
    d.text((70, y), s["item"], font=font(50, bold=False, jp=jp), fill=INK, anchor="lm")
    y += 110
    compare_font = font(60, bold=False, jp=jp)
    d.text((tw / 2, y), s["compare"], font=compare_font, fill=(80, 80, 82), anchor="mm")
    cw = d.textlength(s["compare"], font=compare_font)
    d.line([tw / 2 - cw / 2, y + 4, tw / 2 + cw / 2, y + 4], fill=(80, 80, 82), width=5)
    y += 190

    # The big price: exactly PRICE_BOX_FRACTION * W wide.
    target = PRICE_BOX_FRACTION * W
    size = 300
    while True:
        f = font(size, jp=jp and not s["price"].isascii(), condensed=False)
        if d.textlength(s["price"], font=f) >= target:
            break
        size += 4
    price_y = y
    d.text((tw / 2, price_y), s["price"], font=f, fill=INK, anchor="mm")
    y += 250
    if s["note"]:
        d.text((tw / 2, y), s["note"], font=font(52, bold=False, jp=jp), fill=(60, 60, 62), anchor="mm")
    y += 130

    # Barcode
    digits, bits = ean13(s["barcode"])
    module = 9
    bw = len(bits) * module
    x0 = (tw - bw) / 2
    for i, bit in enumerate(bits):
        if bit == "1":
            guard = i < 3 or 45 <= i < 50 or i >= len(bits) - 3
            d.rectangle([x0 + i * module, y, x0 + (i + 1) * module - 1, y + (300 if guard else 270)], fill=INK)
    d.text((tw / 2, y + 330), f"{digits[0]}  {digits[1:7]}  {digits[7:]}", font=font(54, bold=False), fill=INK, anchor="mm")
    return tag, price_y


def compose(currency, s):
    scene = jersey(s["jersey"], s["trim"], seed=len(currency))
    tag, price_y = tag_image(s)
    angle = -3
    rotated = tag.rotate(angle, resample=Image.BICUBIC, expand=True)
    # Where the price center lands after rotation (rotate about the tag center).
    tw, th = tag.size
    rad = np.deg2rad(-angle)
    cx, cy = tw / 2, th / 2
    px, py = tw / 2 - cx, price_y - cy
    rx = px * np.cos(rad) - py * np.sin(rad) + rotated.width / 2
    ry = px * np.sin(rad) + py * np.cos(rad) + rotated.height / 2
    ox, oy = int(W / 2 - rx), int(H / 2 - ry)

    shadow = Image.new("L", scene.size, 0)
    shadow.paste(rotated.split()[3].point(lambda a: 140 if a else 0), (ox + 40, oy + 60))
    scene.paste((10, 8, 8), (0, 0), shadow.filter(ImageFilter.GaussianBlur(45)))
    # Plastic fastener running up out of frame from the hang hole.
    d = ImageDraw.Draw(scene)
    hole_x, hole_y = ox + rotated.width / 2 + 5, oy + 130
    d.line([hole_x, 0, hole_x + 30, hole_y], fill=(235, 235, 235), width=14)
    scene.paste(rotated, (ox, oy), rotated)
    # Light from the top-left across the tag.
    light = Image.new("L", scene.size, 0)
    ImageDraw.Draw(light).ellipse([-W * 0.4, -H * 0.4, W * 0.9, H * 0.7], fill=40)
    scene.paste((255, 250, 240), (0, 0), light.filter(ImageFilter.GaussianBlur(400)))
    OUT.mkdir(exist_ok=True)
    scene.convert("RGB").save(OUT / f"{currency}.jpg", quality=88)
    print(f"{currency}: {OUT / (currency + '.jpg')}")


if __name__ == "__main__":
    for currency, spec in SCENES.items():
        compose(currency, spec)
