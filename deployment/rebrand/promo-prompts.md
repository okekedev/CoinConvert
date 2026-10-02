# Rebrand — promo content prompts

Replace `[NAME]` with the chosen name. Replace `[ACCENT]` with the palette accent:
- **Gold/Navy (current):** warm metallic gold #D4AF37 with deep navy #19375F
- **Modern Teal:** vivid teal #14B8A6 with near-black #0B1220 and soft white
- **Coral Travel:** coral #FF6B5A with sand #F5E9DA and ink #1F2937

## Ground rules (every image prompt)
- **Never let the image model draw the phone screen.** It garbles UI and text ("CURROCY $500").
  Generate the scene with a **blank or green screen**, then composite a real simulator screenshot onto it.
  Apple guideline 2.3.3: screenshots must show the app actually in use.
- **No text in generated images.** Add headlines afterward in Figma/Canva/Keynote.
- Leave the **top ~30% clear** for the headline.
- Negative prompt (if the tool supports one):
  `text, letters, words, watermark, logo, signature, UI, app interface, numbers on screen, distorted hands, extra fingers, blurry, low quality, oversaturated`

---

## 1. App icon

**A — Lens + currency (evolves current icon)**
> Minimal iOS app icon, a single camera lens viewed head-on, the lens glass reflecting a subtle currency-exchange arrow loop, [ACCENT] color scheme, smooth gradient background, soft inner glow, flat-meets-glass style, centered, generous padding, no text, no letters, 1024x1024, Apple Human Interface Guidelines style

**B — Price tag scan**
> Minimal iOS app icon, a rounded price tag shape with corner scan brackets around it like a viewfinder, [ACCENT] colors, clean vector style, subtle depth shadow, solid gradient background, no text, no numbers, 1024x1024

**C — Abstract mark**
> Minimal iOS app icon, two overlapping circles forming an abstract coin-and-lens mark, the overlap glowing [ACCENT], bold geometric, very simple, recognizable at small sizes, gradient background, no text, 1024x1024

> Icon tip: generate at 1024, then check it at 60x60. If it reads as mush, simplify.

---

## 2. App Store screenshots (6.7" = 1290x2796; iPad 13" = 2064x2752)

Each one is a **scene prompt** plus the real screenshot to composite and a headline to overlay.

**S1 — Hero: scan a price**
> Over-the-shoulder photo of a hand holding a modern iPhone with a plain bright green screen, pointed at a handwritten price chalkboard at a European street market, warm late-afternoon light, shallow depth of field, background bokeh of produce stalls, vertical composition, phone in lower two thirds, empty soft sky in upper third, photorealistic, no text
- Composite: Scanner tab, live conversion showing in the header
- Headline: **Point. Scan. Done.** / sub: *Prices converted the moment you see them*

**S2 — Restaurant menu**
> Top-down photo of a café table with a printed paper menu (blurred, unreadable), espresso cup, iPhone lying face up with a plain green screen, natural window light, [ACCENT] accent in a napkin or cup, clean minimal styling, vertical, empty space at top, photorealistic, no readable text
- Composite: Scanner with several prices highlighted and one selected
- Headline: **Tap any price** / sub: *Menus, tags, receipts*

**S3 — Calculator**
> Clean studio product shot, iPhone floating at a slight 3D angle with a plain green screen, soft [ACCENT] gradient background, gentle reflection below, subtle floating currency symbol shapes blurred in the background, vertical, empty top third, no text
- Composite: Calculator tab mid-calculation
- Headline: **Split bills. Add tips.** / sub: *Converts live as you type*

**S4 — 150+ currencies**
> Flat-lay of banknotes and coins from many countries arranged in a loose arc around an iPhone with a plain green screen, soft even lighting, [ACCENT] backdrop, vertical, empty top third, photorealistic, banknotes slightly out of focus, no readable text
- Composite: Currency picker with the search bar and flags
- Headline: **150+ currencies**

**S5 — Offline + privacy**
> Airplane window seat, iPhone on the tray table with a plain green screen, clouds and a wing at golden hour outside the window, airplane-mode calm mood, vertical, empty top area, photorealistic, no text
- Composite: Settings showing "Rates updated" and offline status
- Headline: **Works offline** / sub: *On-device. No tracking. No account.*

---

## 3. Subscription / paywall art
> Elegant abstract background for a premium paywall, soft [ACCENT] gradient with a glowing camera-lens ring motif and faint floating currency symbols ($ € £ ¥) as blurred shapes, lots of empty space in the center for text, minimal, luxurious, vertical 1290x2796, no text, no watermark

---

## 4. Social / launch posts (1080x1350)

**Before/after split**
> Split-screen photo, left half a confusing foreign price tag in a Tokyo shop (blurred unreadable characters), right half the same scene seen through an iPhone held up with a plain green screen, [ACCENT] divider line, vibrant, no readable text
- Overlay: "Before" / "After [NAME]"

**Traveler lifestyle**
> Candid photo of a young traveler with a backpack at a colorful outdoor market in Mexico City, smiling at the iPhone in their hand (screen not visible), warm natural light, documentary style, empty sky area for text, no text

---

## 5. Short video storyboard (15s, Reels/TikTok/App Preview)
App Preview **must be real screen recordings**. Lifestyle B-roll is fine for social only.

| Time | Shot | On-screen text |
|---|---|---|
| 0–2s | Hand raises phone toward a price tag abroad | "¥4,800… is that a lot?" |
| 2–6s | Screen recording: scanner snaps to the price, conversion appears | (none, let it play) |
| 6–9s | Tap a second price on a menu | "Tap any price" |
| 9–12s | Calculator: split the bill | "Split it. Tip it." |
| 12–15s | Icon + name end card | "[NAME] — free on the App Store" |

Video B-roll prompt (Sora/Veo/Runway):
> Handheld cinematic shot, a traveler raises an iPhone toward a handwritten price tag at a night market in Bangkok, warm string lights, shallow depth of field, phone screen faces away from camera, 4 seconds, natural motion, no text

---

## 6. Copy prompts (for an LLM)

**Name brainstorm**
> I have an iOS app that converts prices into your home currency instantly by pointing the camera at them (menus, price tags, receipts). It works offline and on-device, and includes a calculator. Audience: travelers and people shopping abroad. Give me 25 app names, max 12 characters, easy to say, no existing big brand. For each, give a 30-char App Store subtitle that includes the keywords "currency" or "converter" or "camera." Group them as: descriptive, brandable, playful.

**Store listing rewrite**
> Rewrite this App Store description for an app now called [NAME]. Keep every feature, make the first 3 lines hook skimmers (only ~170 characters show before "more"), use short scannable sections, no hype words like "revolutionary", mention the free calculator and the Pro camera scanner with 3-day trial. Original: <paste deployment/metadata/description.txt>

**Promo text (170 chars, editable without review)**
> Write 5 App Store promotional-text options for [NAME], max 170 characters each. Seasonal angles: summer travel, holiday shopping abroad, study abroad, a general one, and one about offline use.
