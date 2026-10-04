# Byggresursen — luxury redesign

Date: 2026-10-04
Status: approved

## Goal

Make byggresursen.com feel like a premium, personal builder on Lidingö, and match the final print identity in `branding-final/` (logo, A5 flyer, business card). Remove the hero photo; the opening screen is carried by the logo and typography. The text follows the final flyer (`branding-final/reklamblad-vit.png`).

Success: a high-end homeowner on Lidingö trusts the company at first glance, and recognises the brand and wording from the flyer.

## Decisions made in brainstorming

| Question | Choice |
|---|---|
| Colour world | Dark graphite (the print is white; the website deliberately stays dark) |
| Opening | Logo centred on a full-screen graphite opening, no photo, no animation |
| Logo colour | Flat pewter `#868a90`, the same grey as the tagline under it (not metallic) |
| Page body | "Quiet gallery": centred text, photos in true colour side by side, no divider lines between sections |
| Content | The flyer's wording, fitted into the calm layout. No phone number anywhere. No "Därför väljer kunder oss" section |
| Contact | Quote request form (text only) emailed to info@byggresursen.com by a PHP script on one.com |

Final reference mockups (local only): `.superpowers/brainstorm/24244-1791118992/content/page-v8.html` (page) and `contact-form.html` (form look, sent state, error state).

## Constraints

- Static site: `index.html`, `styles.css` and `rfq.js`, with `skicka.php` as the only server code. No build step, no framework.
- Hosting is one.com, deployed by uploading through the File Manager. PHP must be 8.1 or newer.
- No phone number on the site. The form's optional Telefon field is the customer's own number.
- No motion except CSS smooth scrolling for anchor links, which is turned off under `prefers-reduced-motion: reduce`.

## Design tokens

| Token | Value | Use |
|---|---|---|
| `--graphite` | `#1a1b1d` | Page background |
| `--deep` | `#141517` | Contact band |
| `--steel` | `#c9ccd1` | Body text, service words in the opening |
| `--pewter` | `#868a90` | Logo, tagline, nav, secondary text |
| `--shine` | `#eef0f3` | Headings, quotes, service subtitles |
| `--hair` | `rgba(201,204,209,.16)` | Hairlines inside sections (services list, quote separator, form underlines) |
| `--err` | `#d9a0a0` | Form error text and underline |

Type:
- **Marcellus 400:** h2, service names, the service words in the opening, the button.
- **Cormorant Garamond 300 / 300 italic:** body, tagline, quotes, inputs.
- **Jost 300:** nav, labels, captions, small print.

No all-caps text; the logo itself already carries the capitals.

## Page structure

```
┌──────────────────── one full screen (100svh) ────────────────────┐
│                                   Om oss  Tjänster  Referenser  Kontakt │
│                                                                   │
│                 BYGGRESURSEN SVERIGE AB        ← assets/logo.svg  │
│                 ──────── LIDINGÖ ────────        (fill #868a90)   │
│                 VI BYGGER PÅ FÖRTROENDE                           │
│                                                                   │
│            Allt inom bygg, snickeri och måleri   ← italic, pewter │
│                                                                   │
│                    Bygg    Snickeri    Måleri    ← foot of screen │
└───────────────────────────────────────────────────────────────────┘
#om-oss      h2 + flyer intro (centred, ≤36rem)
             two photos side by side, true colour, uncropped, equal height,
             spanning the shared page width (68rem)
#tjanster    h2 + ruled list of three rows: name | italic subtitle + items as one sentence
#referenser  h2 + two italic quotes with attribution, short hairline between
#kontakt     --deep band: "Kontakta oss idag" / "för en offert eller ett första möte",
             form, "Eller mejla oss direkt: info@…", UC seal, © line
```

- **Spacing:** sections are separated by space only (6rem padding, 4rem on phones). There's no border between sections.
- **Shared width:** `.wrap` = `min(100% - 2×gutter, 68rem)`, gutter `clamp(1rem, 4vw, 2.5rem)`. Photos span the full `.wrap`; text blocks are centred inside it.
- **Photos:** they sit in a flex row. Each figure's `flex-grow` equals its own aspect ratio (outdoor2 2000×1443 → 1.386, outdoor 2000×1116 → 1.792), so both get the same height with no cropping. They stack below 600px.

## Content (Swedish, final)

- **Opening tagline:** "Allt inom bygg, snickeri och måleri". **Service words:** Bygg, Snickeri, Måleri.
- **Om oss:** "Vi är ett lokalt byggföretag på Lidingö som tar hand om ditt projekt – från första skiss till sista penseldrag. För privatpersoner, företag och bostadsrättsföreningar."
- **Våra tjänster:**
  - **Bygg:** "Renovering, om- och tillbyggnad – med helhetsansvar." / "Badrum och våtrum, golv och väggar, fönster och dörrar, tak- och fasadarbeten, altaner och uterum, renovering och ombyggnation, totalentreprenad."
  - **Snickeri:** "Måttanpassade lösningar och hantverk i trä." / "Köksmontering, garderober och förvaring, inredning och specialsnickeri."
  - **Måleri:** "Hållbara ytor och rätt kulör – inne och ute." / "Invändig och utvändig målning, tapetsering, spackling och slipning, färg- och materialrådgivning."
- **Referenser:** the two existing quotes, unchanged except the spelling fix "pågende" → "pågående".
- **Kontakt:** heading "Kontakta oss idag", line "för en offert eller ett första möte".
- **Page title and meta:** `<title>` "Byggresursen Sverige AB – Lidingö"; the meta description uses the Om oss text.

## Quote request form

### Look

- Centred block, max 36rem, two-column grid that collapses to one column below 600px.
- Fields are an underline only (`--hair`, turning `--steel` on focus). Labels are in Jost 300, 0.75rem, `--pewter`, with `*` on required fields. Input text is in Cormorant Garamond 300, `--shine`.
- One outlined button, "Skicka förfrågan" (Marcellus). On hover it fills with `--shine` and the text turns `--deep`.
- A privacy line beside the button: "Vi använder dina uppgifter enbart för att besvara din förfrågan." On phones, the privacy line and the button are centred, stacked (note above button).
- Below: "Eller mejla oss direkt: info@byggresursen.com" (mailto).

### Fields

| Name | Label | Type | Required | Server rule |
|---|---|---|---|---|
| `namn` | Namn | text, `autocomplete=name` | yes | ≤100 chars, not blank |
| `epost` | E-post | email | yes | `FILTER_VALIDATE_EMAIL` |
| `telefon` | Telefon | tel | no | ≤30 chars |
| `typ` | Typ av projekt | select: Välj… / Bygg / Snickeri / Måleri / Annat | no | not in list → "Annat" |
| `plats` | Var ligger projektet? | text | no | ≤150 chars |
| `beskrivning` | Beskriv projektet | textarea | yes | ≤5000 chars, not blank |
| `webbplats` | hidden honeypot | text, off-screen | must be empty | filled → silent drop |
| `t` | hidden | ms from page load to submit, measured by JS on the visitor's device | — | present and < 3000 → silent drop; empty = not checked |

### Behaviour

- **Without JS:** a normal POST to `skicka.php`, which answers with a 303 redirect to `./?skickat=1#kontakt` or `./?fel=1#kontakt`.
- **With JS** (`rfq.js`):
  - Swedish messages appear under the fields.
  - The form is sent with `fetch` (`Accept: application/json`); the button reads "Skickar…" and is disabled while sending.
  - On success, the form is replaced by "Tack, {förnamn}." / "Vi har tagit emot din förfrågan och hör av oss så snart vi kan.", and the heading receives focus.
  - On a server or network error, a line above the button reads: "Förfrågan kunde inte skickas. Försök igen eller mejla info@byggresursen.com."
  - It also shows the matching message when the page loads with `?skickat=1` or `?fel=1`.
- **`skicka.php`:**
  - **Requests:** POST only (405 otherwise).
  - **Validation:** trims every field, rejects non-string or invalid-UTF-8 values, strips CR/LF from header values, and returns 422 with field errors.
  - **Email:** sent with `mail()`. To and From are `info@byggresursen.com`; Reply-To is the customer; the subject is "Offertförfrågan: {typ} – {namn}", RFC 2047 encoded; the body is plain UTF-8 text.
  - **Dev mode:** `RFQ_DEV=1` writes to `rfq-dev.log`; `RFQ_DEV=fail` simulates a failed send.

### Deployment (one.com)

1. **Check PHP:** upload `test.php` (`<?php echo 'PHP fungerar ' . phpversion();`), open it, and confirm version ≥ 8.1. Then delete it.
2. **Upload the site:** `index.html`, `styles.css`, `rfq.js`, `skicka.php`, and `assets/` (`logo.svg`, `outdoor.jpg`, `outdoor2.jpg`). Remove the old `assets/logo.png`, `outdoor.png` and `outdoor2.png` from the server.
3. **Never upload:** `docs/`, `tests/`, `.superpowers/`, `branding/`, `branding-final/`, `rfq-dev.log`, or `info@byggresursen.com`.
4. **Live test:** send one real request and confirm that it arrives (check spam), that åäö look right, and that Reply goes to the customer.

## Files

- **`index.html`:** rewritten.
- **`styles.css`:** rewritten.
- **`rfq.js`:** new.
- **`skicka.php`:** new.
- **`assets/logo.svg`:** `branding-final/byggresursen-logo-primar-currentcolor.svg` with `fill="currentColor"` replaced by `fill="#868a90"`, so it can be used as a plain `<img>` (robust, no CSS mask needed).
- **Photos:** `assets/outdoor.jpg` and `assets/outdoor2.jpg` are 2000px JPEG versions of the existing PNGs (combined under 1 MB).
- **Removed:** `assets/logo.png`, `assets/outdoor.png`, `assets/outdoor2.png`.
- **`.gitignore`:** `.DS_Store`, `.superpowers/`, `rfq-dev.log`, `info@byggresursen.com`, `branding/`, `branding-final/`.
- **Tests:** `tests/page_check.sh` and `tests/rfq_test.sh`.

## Out of scope

- File attachments.
- A confirmation email to the customer.
- CAPTCHA.
- The flyer's "Därför väljer kunder oss" and "Vi arbetar med" blocks (the audience is folded into the Om oss text).
- New photography: finished interiors would raise quality the most, and are recommended later.
- Sticky nav.
- Multiple pages.

## Verification

- **`tests/page_check.sh`:** static assertions on markup, CSS and assets.
- **`tests/rfq_test.sh`:** HTTP tests of `skicka.php` under `RFQ_DEV=1 php -S`, covering:
  - the happy path
  - validation, including whitespace-only fields, array input and invalid UTF-8
  - honeypot and timing
  - header injection
  - the non-JS redirects
  - 405 for non-POST requests
  - send failure
- **Browser checks:**
  - At 1440 and 375px: no horizontal scroll; the opening fills exactly one screen; photos are equal height and uncropped; the services list stacks; the form is one column with the button centred.
  - The form flows: empty submit, invalid email, success, a double-click sending exactly one email, and the `?skickat=1` / `?fel=1` messages.
  - Keyboard focus is visible everywhere.
