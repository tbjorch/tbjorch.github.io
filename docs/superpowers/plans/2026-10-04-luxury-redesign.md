# Byggresursen luxury redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild byggresursen.com in the approved dark graphite "quiet gallery" design, with the final flyer's content, the final logo in pewter grey, and a quote request form that emails info@byggresursen.com via PHP on one.com.

**Architecture:**
- **Pages:** a static `index.html` + `styles.css` (no build step).
- **Form handler:** a single `skicka.php` validates the form and sends it with PHP `mail()`. Under `RFQ_DEV=1` it writes to `rfq-dev.log` instead, so it can be tested locally.
- **Form behaviour:** `rfq.js` adds the in-page sending and messages on top of a form that also works without JS.
- **Tests:** shell scripts. `tests/page_check.sh` does static assertions; `tests/rfq_test.sh` runs real HTTP requests against `php -S`.

**Tech Stack:** HTML, CSS, vanilla JS (ES2019+), PHP ≥ 8.1 (local: 8.3), bash + curl, macOS `sips`. Google Fonts: Marcellus, Cormorant Garamond, Jost.

**Spec:** `docs/superpowers/specs/2026-10-04-luxury-redesign-design.md`. Final visual reference (local only): `.superpowers/brainstorm/24244-1791118992/content/page-v8.html` and `contact-form.html`.

## Global Constraints

- Static site: `index.html` + `styles.css` + `rfq.js`; `skicka.php` is the only server code. No framework, no build step, no npm.
- Content exactly as listed under *Content (Swedish, final)* in the spec. **No phone number anywhere.**
- Colour tokens exactly: `--graphite #1a1b1d`, `--deep #141517`, `--steel #c9ccd1`, `--pewter #868a90`, `--shine #eef0f3`, `--hair rgba(201,204,209,.16)`, `--err #d9a0a0`.
- Logo: flat pewter `#868a90`, a plain `<img>`, no animation. Photos: true colour, never cropped.
- No lines between sections; hairlines only inside sections.
- No animation. CSS smooth scrolling only, which is off under `prefers-reduced-motion: reduce`.
- `From` is always `info@byggresursen.com`; the customer's address only goes in `Reply-To`.
- Never commit: `.superpowers/`, `rfq-dev.log`, `.DS_Store`, `info@byggresursen.com` (contains a credential), `branding/`, `branding-final/`.
- Work on branch `redesign`, not `main`. Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- **Whitespace-only required fields** pass the browser's `required` check, so the server must reject them with 422. Pinned in Task 3, case "whitespace-only name".
- **Non-string POST values** (`namn[]=x`) must give a clean 422, not a TypeError or 500. Pinned in Task 3, case "array input".
- **Invalid UTF-8 bytes** must give 422, never a garbled email. Pinned in Task 3, case "invalid UTF-8".
- **Swedish characters (åäö)** must arrive intact in the subject (RFC 2047) and the body. Pinned in Task 3, cases "subject encoded" and "body keeps åäö".
- **Double-clicking "Skicka förfrågan"** must send exactly one email. Pinned in Task 4, Step 6.4 (double-click against the dev log count).

---

## File structure

| File | Responsibility | Task |
|---|---|---|
| `.gitignore` | Keep local/secret files out of git | 1 |
| `assets/logo.svg` | Final logo, pewter fill | 1 |
| `assets/outdoor.jpg`, `assets/outdoor2.jpg` | Web-sized photos | 1 |
| `tests/page_check.sh` | Static checks of markup/CSS/assets | 2 (extended in 4) |
| `index.html` | Page structure and content | 2 (form added in 4) |
| `styles.css` | All styling | 2 (form styles appended in 4) |
| `tests/rfq_test.sh` | HTTP tests of `skicka.php` | 3 |
| `skicka.php` | Validate, block spam, send email | 3 |
| `rfq.js` | Client-side form behaviour | 4 |

---

### Task 1: Branch, hygiene and assets

**Files:**
- Create: `.gitignore`, `assets/logo.svg`, `assets/outdoor.jpg`, `assets/outdoor2.jpg`
- Delete (git): `assets/logo.png`, `assets/outdoor.png`, `assets/outdoor2.png`, `assets/.DS_Store`
- Add: `docs/superpowers/specs/2026-10-04-luxury-redesign-design.md`, `docs/superpowers/plans/2026-10-04-luxury-redesign.md`

**Interfaces:**
- Produces: `assets/logo.svg` (viewBox `0 0 1193.7 272.2`, fill `#868a90`), `assets/outdoor.jpg` (2000×1116), `assets/outdoor2.jpg` (2000×1443).

- [ ] **Step 1: Create the branch**

```bash
cd /Users/tobiasbjorch/personal/websites/byggresursen
git checkout -b redesign
```

- [ ] **Step 2: Write `.gitignore`**

```gitignore
.DS_Store
.superpowers/
rfq-dev.log
info@byggresursen.com
branding/
branding-final/
```

- [ ] **Step 3: Create the logo and convert the photos**

```bash
sed 's/fill="currentColor"/fill="#868a90"/' branding-final/byggresursen-logo-primar-currentcolor.svg > assets/logo.svg
grep -c 'fill="#868a90"' assets/logo.svg      # expect 1
sips -s format jpeg -s formatOptions 70 -Z 2000 assets/outdoor.png  --out assets/outdoor.jpg
sips -s format jpeg -s formatOptions 70 -Z 2000 assets/outdoor2.png --out assets/outdoor2.jpg
sips -g pixelWidth -g pixelHeight assets/outdoor.jpg assets/outdoor2.jpg
cat assets/outdoor.jpg assets/outdoor2.jpg | wc -c
```

Expected: 2000×1116 and 2000×1443, and the byte total under 1048576. If it's over, rerun both `sips` commands with `formatOptions 60`.

- [ ] **Step 4: Remove the old assets from git**

```bash
git rm -q assets/logo.png assets/outdoor.png assets/outdoor2.png
git rm -q --cached assets/.DS_Store
```

Note: `index.html` still references the old files until Task 2. That's expected.

- [ ] **Step 5: Verify the ignore rules**

Run: `git status --short`
Expected:
- **Listed:** `.gitignore`, `assets/logo.svg`, `assets/outdoor*.jpg`, `docs/`, and the deletions.
- **Not listed:** `.superpowers/`, `branding/`, `branding-final/`, `info@byggresursen.com`, `.DS_Store`.

- [ ] **Step 6: Commit**

```bash
git add .gitignore assets/logo.svg assets/outdoor.jpg assets/outdoor2.jpg docs/superpowers
git commit -m "Add redesign spec and plan, final logo, web-sized photos and .gitignore

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Page structure and styles (no form yet)

**Files:**
- Create: `tests/page_check.sh`
- Rewrite: `index.html`, `styles.css`

**Interfaces:**
- Consumes: the assets from Task 1.
- Produces:
  - **Section ids:** `om-oss`, `tjanster`, `referenser`, `kontakt` (`<footer>`).
  - **Tokens:** `--graphite --deep --steel --pewter --shine --hair --err --serif-display --serif-text --sans --page --gutter`.
  - **Marker for Task 4:** the comment `<!-- RFQ form (Task 4) -->` inside `#kontakt`, which Task 4 replaces with the form.

- [ ] **Step 1: Write the failing page check**

`tests/page_check.sh`:

```bash
#!/usr/bin/env bash
# Static checks that index.html / styles.css / assets follow the redesign spec.
set -u
cd "$(dirname "$0")/.."
FAILS=0

pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; FAILS=$((FAILS + 1)); }
has()   { if grep -q -- "$2" "$1"; then pass "$3"; else fail "$3"; fi; }
lacks() { if grep -q -- "$2" "$1"; then fail "$3"; else pass "$3"; fi; }

has   index.html '<html lang="sv">'                      'page language is Swedish'
lacks index.html 'unsplash'                              'no hero stock photo'
lacks index.html 'class="hero"'                          'no hero section'
has   index.html 'src="assets/logo.svg"'                 'final logo used'
lacks index.html '\.png'                                 'no PNG images referenced'
has   index.html 'Allt inom bygg, snickeri och måleri'   'flyer tagline present'
has   index.html 'från första skiss till'                'flyer intro present'
has   index.html 'Kontakta oss idag'                     'flyer contact heading present'
lacks index.html '076'                                   'no phone number on the site'
has   index.html 'family=Marcellus'                      'new fonts loaded'
lacks index.html 'Montserrat'                            'old fonts removed'
lacks index.html 'smoothScroll'                          'old scroll JS removed'
for id in om-oss tjanster referenser kontakt; do
  has index.html "id=\"$id\""    "section #$id exists"
  has index.html "href=\"#$id\"" "nav links to #$id"
done
has   styles.css '--graphite: #1a1b1d'                   'graphite token defined'
has   styles.css 'min-height: 100svh'                    'opening fills the screen'
has   styles.css 'prefers-reduced-motion'                'reduced motion respected'
lacks styles.css 'grayscale'                             'photos keep true colour'
lacks styles.css 'animation'                             'no animation'
lacks styles.css 'text-transform: uppercase'             'no all-caps text'
if grep -A3 '^\.section {' styles.css | grep -q 'border'; then fail 'no lines between sections'; else pass 'no lines between sections'; fi
has   assets/logo.svg 'fill="#868a90"'                   'logo is pewter grey'

for f in assets/logo.svg assets/outdoor.jpg assets/outdoor2.jpg; do
  if [ -f "$f" ]; then pass "$f exists"; else fail "$f missing"; fi
done
size=$(cat assets/*.jpg | wc -c | tr -d ' ')
if [ "$size" -lt 1048576 ]; then pass "photos under 1 MB ($size bytes)"; else fail "photos are $size bytes"; fi

if [ "$FAILS" -eq 0 ]; then echo "All page checks passed"; else echo "$FAILS check(s) failed"; exit 1; fi
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/page_check.sh`
Expected: exit 1, with FAIL on language, hero, logo, tagline, sections and tokens.

- [ ] **Step 3: Rewrite `index.html`**

```html
<!DOCTYPE html>
<html lang="sv">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Byggresursen Sverige AB – Lidingö</title>
    <meta name="description"
        content="Vi är ett lokalt byggföretag på Lidingö som tar hand om ditt projekt – från första skiss till sista penseldrag. Allt inom bygg, snickeri och måleri.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
        href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;1,300&family=Jost:wght@300;400&family=Marcellus&display=swap"
        rel="stylesheet">
    <link rel="stylesheet" href="styles.css">
</head>

<body>
    <header class="opening">
        <nav class="nav" aria-label="Huvudmeny">
            <a href="#om-oss">Om oss</a>
            <a href="#tjanster">Tjänster</a>
            <a href="#referenser">Referenser</a>
            <a href="#kontakt">Kontakt</a>
        </nav>
        <div class="opening-center">
            <h1 class="logo">
                <img src="assets/logo.svg" width="1194" height="272"
                    alt="Byggresursen Sverige AB – Lidingö – Vi bygger på förtroende">
            </h1>
            <p class="tagline">Allt inom bygg, snickeri och måleri</p>
        </div>
        <ul class="service-words">
            <li>Bygg</li>
            <li>Snickeri</li>
            <li>Måleri</li>
        </ul>
    </header>

    <main>
        <section id="om-oss" class="section">
            <div class="wrap">
                <div class="column">
                    <h2>Om oss</h2>
                    <p>Vi är ett lokalt byggföretag på Lidingö som tar hand om ditt projekt – från första skiss till
                        sista penseldrag. För privatpersoner, företag och bostadsrättsföreningar.</p>
                </div>
                <div class="photos">
                    <figure class="photo photo--frame">
                        <img src="assets/outdoor2.jpg" width="2000" height="1443" loading="lazy"
                            alt="Stomme i lösvirke under uppförande, med utsikt över vattnet">
                    </figure>
                    <figure class="photo photo--site">
                        <img src="assets/outdoor.jpg" width="2000" height="1116" loading="lazy"
                            alt="Gjuten grundplatta vid vattnet">
                    </figure>
                </div>
            </div>
        </section>

        <section id="tjanster" class="section">
            <div class="wrap">
                <h2>Våra tjänster</h2>
                <div class="services">
                    <div class="service">
                        <h3>Bygg</h3>
                        <div>
                            <p class="service-lede">Renovering, om- och tillbyggnad – med helhetsansvar.</p>
                            <p class="service-items">Badrum och våtrum, golv och väggar, fönster och dörrar, tak- och
                                fasadarbeten, altaner och uterum, renovering och ombyggnation, totalentreprenad.</p>
                        </div>
                    </div>
                    <div class="service">
                        <h3>Snickeri</h3>
                        <div>
                            <p class="service-lede">Måttanpassade lösningar och hantverk i trä.</p>
                            <p class="service-items">Köksmontering, garderober och förvaring, inredning och
                                specialsnickeri.</p>
                        </div>
                    </div>
                    <div class="service">
                        <h3>Måleri</h3>
                        <div>
                            <p class="service-lede">Hållbara ytor och rätt kulör – inne och ute.</p>
                            <p class="service-items">Invändig och utvändig målning, tapetsering, spackling och
                                slipning, färg- och materialrådgivning.</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <section id="referenser" class="section">
            <div class="wrap">
                <h2>Referenser</h2>
                <figure class="reference">
                    <blockquote>
                        <p>”...utförde arbetet med precision, inom tid och hade alltid idéer och lösningar på de
                            problem som dök upp. Vi var så nöjda att han sedan fick bygga ett garage som utfördes på
                            samma professionella sätt.”</p>
                    </blockquote>
                    <figcaption>Måns, 50 kvm altan samt lösvirke garage</figcaption>
                </figure>
                <hr class="rule">
                <figure class="reference">
                    <blockquote>
                        <p>”...uppfattades som mycket professionell och kunnig inom yrket som snickare...Arbetsplatsen
                            var prydlig trots pågående arbete. Byggresursen fick ytterligare uppdrag att bygga ett
                            uterum vilket utfördes till stor belåtenhet.”</p>
                    </blockquote>
                    <figcaption>Johan, 80 kvm altan med tillhörande uterum</figcaption>
                </figure>
            </div>
        </section>
    </main>

    <footer id="kontakt" class="contact">
        <div class="wrap">
            <h2>Kontakta oss idag</h2>
            <p class="contact-lede">för en offert eller ett första möte</p>
            <!-- RFQ form (Task 4) -->
            <p class="contact-alt">Eller mejla oss direkt: <a
                    href="mailto:info@byggresursen.com">info@byggresursen.com</a></p>
            <a class="uc-seal" href="https://www.uc.se/risksigill2?showorg=5594366584&amp;language=swe"
                target="_blank" rel="noopener"
                title="Sigillet är utfärdat av UC AB. Klicka på bilden för information om UC:s Riskklasser.">
                <img src="https://www.uc.se/ucsigill2/sigill?org=5594366584&amp;language=swe&amp;product=psa&amp;fontcolor=w&amp;type=svg"
                    alt="UC Riskklass-sigill för Byggresursen Sverige AB">
            </a>
            <p class="copyright">© 2026 Byggresursen Sverige AB</p>
        </div>
    </footer>
</body>

</html>
```

- [ ] **Step 4: Rewrite `styles.css`**

```css
:root {
    --graphite: #1a1b1d;
    --deep: #141517;
    --steel: #c9ccd1;
    --pewter: #868a90;
    --shine: #eef0f3;
    --hair: rgba(201, 204, 209, 0.16);
    --err: #d9a0a0;
    --serif-display: "Marcellus", Georgia, serif;
    --serif-text: "Cormorant Garamond", Georgia, serif;
    --sans: "Jost", system-ui, sans-serif;
    --page: 68rem;
    --gutter: clamp(1rem, 4vw, 2.5rem);
}

*,
*::before,
*::after {
    box-sizing: border-box;
}

html {
    scroll-behavior: smooth;
    -webkit-text-size-adjust: 100%;
}

body {
    margin: 0;
    background-color: var(--graphite);
    color: var(--steel);
    font: 300 1.2rem/1.7 var(--serif-text);
    -webkit-font-smoothing: antialiased;
}

img {
    display: block;
    max-width: 100%;
}

[hidden] {
    display: none !important;
}

:focus-visible {
    outline: 1px solid var(--steel);
    outline-offset: 4px;
}

h2 {
    margin: 0 0 1.25rem;
    font: 400 2.1rem/1.2 var(--serif-display);
    letter-spacing: 0.02em;
    color: var(--shine);
    text-align: center;
}

/* Shared page width: text blocks and photos line up on the same edges */
.wrap {
    width: min(100% - 2 * var(--gutter), var(--page));
    margin-inline: auto;
}

/* Opening: exactly one screen. Nav on top, logo centred, service words at the foot. */
.opening {
    min-height: 100vh;
    min-height: 100svh;
    display: grid;
    grid-template-rows: auto 1fr auto;
    padding: 0 var(--gutter);
}

.nav {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 0.5rem 1.75rem;
    padding: 1.4rem 0;
    font: 300 0.75rem/1 var(--sans);
    letter-spacing: 0.12em;
}

.nav a {
    padding: 0.4rem 0;
    color: var(--pewter);
    text-decoration: none;
}

.nav a:hover {
    color: var(--shine);
}

.opening-center {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
}

.logo {
    width: min(80%, 40rem);
    margin: 0;
}

.logo img {
    width: 100%;
    height: auto;
}

.tagline {
    margin: 1.75rem 0 0;
    font-style: italic;
    font-size: 1.45rem;
    color: var(--pewter);
}

.service-words {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 0.5rem 2.25rem;
    margin: 0;
    padding: 0 0 2.5rem;
    list-style: none;
    font: 400 0.95rem/1.4 var(--serif-display);
}

/* Sections are separated by space only, never by lines */
.section {
    padding: 6rem 0;
}

.column {
    max-width: 36rem;
    margin: 0 auto;
    text-align: center;
}

.column p {
    margin: 0;
}

/* Photos: true colour, never cropped. Each figure grows by its own aspect ratio,
   so both end up the same height and together fill the page width. */
.photos {
    display: flex;
    gap: clamp(0.5rem, 1.2vw, 1rem);
    margin-top: 4.5rem;
}

.photo {
    margin: 0;
    min-width: 0;
}

.photo img {
    width: 100%;
    height: auto;
}

.photo--frame {
    flex: 1.386;
}

.photo--site {
    flex: 1.792;
}

/* Services */
.services {
    max-width: 41rem;
    margin: 2.25rem auto 0;
}

.service {
    display: grid;
    grid-template-columns: 12rem 1fr;
    gap: 1.5rem;
    padding: 1.5rem 0;
    border-top: 1px solid var(--hair);
}

.service:last-child {
    border-bottom: 1px solid var(--hair);
}

.service h3 {
    margin: 0;
    font: 400 1.25rem/1.4 var(--serif-display);
    color: var(--shine);
}

.service-lede {
    margin: 0 0 0.35rem;
    font-style: italic;
    font-size: 1.12rem;
    line-height: 1.5;
    color: var(--shine);
}

.service-items {
    margin: 0;
    font-size: 1.06rem;
    line-height: 1.65;
    color: var(--pewter);
}

/* References */
.reference {
    max-width: 39rem;
    margin: 0 auto;
    text-align: center;
}

.reference blockquote {
    margin: 0;
}

.reference blockquote p {
    margin: 0;
    font-style: italic;
    font-size: 1.75rem;
    line-height: 1.45;
    color: var(--shine);
}

.reference figcaption {
    margin-top: 1rem;
    font: 300 0.8rem/1.5 var(--sans);
    color: var(--pewter);
}

.rule {
    width: 2.5rem;
    margin: 3rem auto;
    border: 0;
    border-top: 1px solid var(--hair);
}

/* Contact */
.contact {
    padding: 6rem 0 2.25rem;
    background-color: var(--deep);
    text-align: center;
}

.contact-lede {
    margin: -0.4rem 0 2.75rem;
    font-style: italic;
    font-size: 1.35rem;
    color: var(--pewter);
}

.contact-alt {
    margin: 3rem 0 0;
    font: 300 0.85rem/1.6 var(--sans);
    color: var(--pewter);
}

.contact-alt a {
    border-bottom: 1px solid var(--hair);
    color: var(--steel);
    text-decoration: none;
}

.uc-seal {
    display: inline-block;
    margin-top: 2.25rem;
}

.uc-seal img {
    width: 15rem;
}

.copyright {
    margin: 3rem 0 0;
    font: 300 0.75rem var(--sans);
    color: var(--pewter);
}

@media (max-width: 600px) {
    html {
        font-size: 15px;
    }

    body {
        font-size: 1.1rem;
    }

    h2 {
        font-size: 1.75rem;
    }

    .nav {
        justify-content: center;
        gap: 0.4rem 1.25rem;
    }

    .section {
        padding: 4rem 0;
    }

    .photos {
        flex-direction: column;
    }

    .photo--frame,
    .photo--site {
        flex: none;
    }

    .service {
        grid-template-columns: 1fr;
        gap: 0.4rem;
    }

    .reference blockquote p {
        font-size: 1.35rem;
    }
}

@media (prefers-reduced-motion: reduce) {
    html {
        scroll-behavior: auto;
    }
}
```

- [ ] **Step 5: Run the page check to verify it passes**

Run: `bash tests/page_check.sh`
Expected: `All page checks passed`, exit 0.

- [ ] **Step 6: Look at it in the browser**

Start `php -S 127.0.0.1:8000` in the background and open `http://127.0.0.1:8000/`. Compare with `page-v8.html`:
- The opening fills exactly one screen, with the service words at the bottom edge.
- The logo is pewter grey; nothing animates.
- There are no lines between sections.
- The photos are in colour, equal height, uncropped, and span the page width.
- At 375px there's no horizontal scroll, the photos stack, and the services stack.
- Tabbing through the nav shows a visible outline.

Stop the server afterwards.

- [ ] **Step 7: Commit**

```bash
git add index.html styles.css tests/page_check.sh
git commit -m "Redesign page: graphite opening, flyer content, quiet gallery layout

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `skicka.php` form handler

**Files:**
- Create: `tests/rfq_test.sh`, `skicka.php`

**Interfaces:**
- Produces, as an HTTP contract for Task 4:
  - **Endpoint:** `POST skicka.php`, fields `namn, epost, telefon, typ, plats, beskrivning, webbplats, t`.
  - **Allowed `typ` values:** `Bygg`, `Snickeri`, `Måleri`, `Annat` (anything else becomes `Annat`).
  - **With `Accept: application/json`:**
    - 200 `{"ok":true,"fornamn":"Anna"}`
    - 422 `{"ok":false,"errors":{field: message}}`
    - 500 `{"ok":false,"error":"send"}`
  - **Without it:** 303 to `./?skickat=1#kontakt` or `./?fel=1#kontakt`.
  - **Other methods:** 405.
  - **`RFQ_DEV`:** `1` writes to `rfq-dev.log` (each message ends with a `=====` line); `fail` simulates a send failure.

- [ ] **Step 1: Write the failing test script**

`tests/rfq_test.sh`:

```bash
#!/usr/bin/env bash
# Exercises skicka.php through PHP's built-in server in dev mode (no real email is sent).
set -u
cd "$(dirname "$0")/.."
PORT=8765
URL="http://127.0.0.1:$PORT/skicka.php"
LOG=rfq-dev.log
TMP=$(mktemp -d)
FAILS=0
SERVER_PID=""

start_server() { # $1: value for RFQ_DEV
  RFQ_DEV="$1" php -S 127.0.0.1:$PORT >"$TMP/server.log" 2>&1 &
  SERVER_PID=$!
  for _ in $(seq 1 50); do
    curl -s -o /dev/null "http://127.0.0.1:$PORT/" && return
    sleep 0.1
  done
  echo "PHP server did not start"; exit 1
}
stop_server() { [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null && wait "$SERVER_PID" 2>/dev/null; SERVER_PID=""; }
trap 'stop_server; rm -rf "$TMP"' EXIT

pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; FAILS=$((FAILS + 1)); }
expect() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$3', got '$2')"; fi; }
body_has() { if grep -q -- "$2" "$TMP/body"; then pass "$1"; else fail "$1 (body: $(cat "$TMP/body"))"; fi; }
log_has() { if grep -q -- "$2" "$LOG"; then pass "$1"; else fail "$1"; fi; }
messages() { if [ -f "$LOG" ]; then grep -c '^=====' "$LOG"; else echo 0; fi; }

# post_json <curl args...>  → prints HTTP status, body in $TMP/body
post_json() { curl -s -o "$TMP/body" -w '%{http_code}' -H 'Accept: application/json' "$@" "$URL"; }
# post_form <curl args...>  → prints HTTP status, headers in $TMP/headers
post_form() { curl -s -o /dev/null -D "$TMP/headers" -w '%{http_code}' "$@" "$URL"; }

VALID=(--data-urlencode 'namn=Anna Lindqvist' --data-urlencode 'epost=anna@exempel.se'
       --data-urlencode 'telefon=070-123 45 67' --data-urlencode 'typ=Bygg'
       --data-urlencode 'plats=Lidingö, Käppala' --data-urlencode 'beskrivning=Renovera badrummet, ca 6 kvm.'
       --data-urlencode 't=8000')

rm -f "$LOG"
start_server 1

# --- happy path ---
before=$(messages)
expect "valid request returns 200" "$(post_json "${VALID[@]}")" 200
body_has "valid request returns ok and first name" '"ok":true,"fornamn":"Anna"'
expect "valid request writes one message" "$(messages)" $((before + 1))
log_has "To is info@" 'To: info@byggresursen.com'
log_has "From is on own domain" '^From: .*<info@byggresursen.com>'
log_has "Reply-To is the customer" '^Reply-To: .*<anna@exempel.se>'
subject_b64=$(printf '%s' 'Offertförfrågan: Bygg – Anna Lindqvist' | base64)
log_has "subject encoded" "Subject: =?UTF-8?B?${subject_b64}?="
log_has "body keeps åäö" 'Plats:     Lidingö, Käppala'
log_has "body has type" 'Typ:       Bygg'
log_has "body has description" 'Renovera badrummet, ca 6 kvm.'

# --- validation ---
before=$(messages)
expect "missing name returns 422" "$(post_json --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
body_has "missing name message" '"namn":"Fyll i ditt namn."'
expect "whitespace-only name returns 422" "$(post_json --data-urlencode 'namn=   ' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
expect "invalid email returns 422" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
body_has "invalid email message" '"epost":"Ange en giltig e-postadress."'
expect "missing description returns 422" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 't=8000')" 422
body_has "missing description message" '"beskrivning":"Beskriv kort vad du vill ha hjälp med."'
long=$(printf 'a%.0s' $(seq 1 5001))
expect "5001-char description returns 422" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode "beskrivning=$long" --data-urlencode 't=8000')" 422
expect "array input returns 422" "$(post_json --data-urlencode 'namn[]=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
expect "invalid UTF-8 returns 422" "$(post_json --data 'namn=%FF%FE' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
expect "no message written for invalid requests" "$(messages)" "$before"
if grep -q 'Fatal\|Warning\|TypeError' "$TMP/server.log"; then fail "no PHP warnings or errors"; else pass "no PHP warnings or errors"; fi

# --- spam handling ---
before=$(messages)
expect "honeypot returns 200" "$(post_json "${VALID[@]}" --data-urlencode 'webbplats=http://spam.example')" 200
body_has "honeypot looks successful" '"ok":true'
expect "fast submit returns 200" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=1200')" 200
expect "spam writes nothing" "$(messages)" "$before"
expect "missing t (no JS) is sent" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej')" 200
expect "missing t writes a message" "$(messages)" $((before + 1))

# --- header injection and type fallback ---
expect "injection attempt is accepted" "$(post_json --data-urlencode $'namn=Eve\r\nBcc: x@evil.example' --data-urlencode 'epost=eve@exempel.se' --data-urlencode 'typ=Hack' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 200
if grep -q '^Bcc:' "$LOG"; then fail "no injected Bcc header"; else pass "no injected Bcc header"; fi
log_has "unknown type becomes Annat" 'Typ:       Annat'

# --- non-JS responses and method ---
expect "form post redirects 303" "$(post_form "${VALID[@]}")" 303
if grep -qi '^Location: ./?skickat=1#kontakt' "$TMP/headers"; then pass "redirects to skickat"; else fail "redirects to skickat"; fi
expect "invalid form post redirects 303" "$(post_form --data-urlencode 'namn=Anna')" 303
if grep -qi '^Location: ./?fel=1#kontakt' "$TMP/headers"; then pass "redirects to fel"; else fail "redirects to fel"; fi
expect "GET returns 405" "$(curl -s -o /dev/null -w '%{http_code}' "$URL")" 405

# --- send failure ---
stop_server
start_server fail
expect "mail failure returns 500" "$(post_json "${VALID[@]}")" 500
body_has "mail failure error code" '"error":"send"'
stop_server

rm -f "$LOG"
if [ "$FAILS" -eq 0 ]; then echo "All RFQ tests passed"; else echo "$FAILS test(s) failed"; exit 1; fi
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash tests/rfq_test.sh`
Expected: exit 1, with most cases FAIL (404, because `skicka.php` doesn't exist yet).

- [ ] **Step 3: Write `skicka.php`**

```php
<?php
// Receives the quote request form and emails it to Byggresursen.
// RFQ_DEV=1 writes the email to rfq-dev.log instead of sending; RFQ_DEV=fail simulates a send failure.
declare(strict_types=1);

const RFQ_TO = 'info@byggresursen.com';
const RFQ_FROM = 'info@byggresursen.com';
const RFQ_FROM_NAME = 'Byggresursen webbformulär';
const RFQ_MIN_MS = 3000;
const RFQ_TYPES = ['Bygg', 'Snickeri', 'Måleri', 'Annat'];

date_default_timezone_set('Europe/Stockholm');

$wantsJson = str_contains($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json');

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit;
}

function respond(bool $wantsJson, int $status, array $payload): never
{
    if ($wantsJson) {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    } else {
        header('Location: ./?' . ($payload['ok'] ? 'skickat=1' : 'fel=1') . '#kontakt', true, 303);
    }
    exit;
}

// Returns the trimmed field, or '' when it is missing, not a string, or not valid UTF-8.
function field(string $name): string
{
    $value = $_POST[$name] ?? '';
    if (!is_string($value) || !preg_match('//u', $value)) {
        return '';
    }
    return trim($value);
}

function oneLine(string $value): string
{
    return trim((string) preg_replace('/[\r\n\t\v\f]+/', ' ', $value));
}

function chars(string $value): int
{
    return (int) preg_match_all('/./su', $value);
}

function encodeHeader(string $value): string
{
    return '=?UTF-8?B?' . base64_encode($value) . '?=';
}

function sendMail(string $subject, string $body, array $headers): bool
{
    $mode = getenv('RFQ_DEV');
    if ($mode === 'fail') {
        return false;
    }
    if ($mode === '1') {
        $raw = 'To: ' . RFQ_TO . "\r\nSubject: " . $subject . "\r\n";
        foreach ($headers as $key => $value) {
            $raw .= $key . ': ' . $value . "\r\n";
        }
        $raw .= "\r\n" . $body . "\r\n=====\r\n";
        return file_put_contents(__DIR__ . '/rfq-dev.log', $raw, FILE_APPEND | LOCK_EX) !== false;
    }
    return mail(RFQ_TO, $subject, $body, $headers);
}

$namn = oneLine(field('namn'));
$epost = oneLine(field('epost'));
$telefon = oneLine(field('telefon'));
$typ = field('typ');
$plats = oneLine(field('plats'));
$beskrivning = (string) preg_replace('/\r\n?|\n/', "\r\n", field('beskrivning'));
$fornamn = explode(' ', $namn)[0];

// Spam: a filled honeypot, or a JS-measured fill time under RFQ_MIN_MS, is dropped silently.
$elapsed = field('t');
if (field('webbplats') !== '' || ($elapsed !== '' && (int) $elapsed < RFQ_MIN_MS)) {
    respond($wantsJson, 200, ['ok' => true, 'fornamn' => $fornamn]);
}

$errors = [];
if ($namn === '' || chars($namn) > 100) {
    $errors['namn'] = 'Fyll i ditt namn.';
}
if (filter_var($epost, FILTER_VALIDATE_EMAIL) === false) {
    $errors['epost'] = 'Ange en giltig e-postadress.';
}
if (chars($telefon) > 30) {
    $errors['telefon'] = 'Telefonnumret är för långt.';
}
if (chars($plats) > 150) {
    $errors['plats'] = 'Platsen är för lång (högst 150 tecken).';
}
if ($beskrivning === '') {
    $errors['beskrivning'] = 'Beskriv kort vad du vill ha hjälp med.';
} elseif (chars($beskrivning) > 5000) {
    $errors['beskrivning'] = 'Beskrivningen är för lång (högst 5000 tecken).';
}
if (!in_array($typ, RFQ_TYPES, true)) {
    $typ = 'Annat';
}
if ($errors) {
    respond($wantsJson, 422, ['ok' => false, 'errors' => $errors]);
}

$subject = encodeHeader("Offertförfrågan: {$typ} – {$namn}");
$headers = [
    'From' => encodeHeader(RFQ_FROM_NAME) . ' <' . RFQ_FROM . '>',
    'Reply-To' => encodeHeader($namn) . ' <' . $epost . '>',
    'MIME-Version' => '1.0',
    'Content-Type' => 'text/plain; charset=UTF-8',
    'Content-Transfer-Encoding' => '8bit',
    'X-Mailer' => 'byggresursen.com',
];
$body = implode("\r\n", [
    'Ny offertförfrågan från byggresursen.com',
    '',
    'Namn:      ' . $namn,
    'E-post:    ' . $epost,
    'Telefon:   ' . ($telefon !== '' ? $telefon : '–'),
    'Typ:       ' . $typ,
    'Plats:     ' . ($plats !== '' ? $plats : '–'),
    '',
    'Beskrivning:',
    $beskrivning,
    '',
    '—',
    'Skickad ' . date('Y-m-d H:i') . ' från IP ' . ($_SERVER['REMOTE_ADDR'] ?? 'okänd'),
]);

if (!sendMail($subject, $body, $headers)) {
    respond($wantsJson, 500, ['ok' => false, 'error' => 'send']);
}
respond($wantsJson, 200, ['ok' => true, 'fornamn' => $fornamn]);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/rfq_test.sh`
Expected: `All RFQ tests passed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add skicka.php tests/rfq_test.sh
git commit -m "Add skicka.php quote request handler with dev-mode tests

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Quote request form on the page

**Files:**
- Modify: `index.html` (replace the `<!-- RFQ form (Task 4) -->` line; add a script tag before `</body>`)
- Modify: `styles.css` (append the form block at the end of the file)
- Create: `rfq.js`
- Modify: `tests/page_check.sh` (add form checks)

**Interfaces:**
- Consumes: the `skicka.php` contract from Task 3, and the tokens and `#kontakt` from Task 2.
- Produces: the classes `.rfq .field .field-error .rfq-status .rfq-button .rfq-sent .rfq-sent-title`, which `rfq.js` selects.

- [ ] **Step 1: Add the failing form checks**

In `tests/page_check.sh`, insert above the final `if [ "$FAILS" -eq 0 ]` line:

```bash
has   index.html 'action="skicka.php"'                   'form posts to skicka.php'
for name in namn epost telefon typ plats beskrivning webbplats t; do
  has index.html "name=\"$name\"" "form field $name"
done
for opt in Bygg Snickeri Måleri Annat; do
  has index.html "<option>$opt</option>" "project type $opt"
done
has   index.html 'Skicka förfrågan'                      'submit button label'
has   index.html '<script src="rfq.js" defer>'           'form script loaded'
lacks index.html 'novalidate'                            'native validation kept for no-JS visitors'
if [ -f rfq.js ]; then pass "rfq.js exists"; else fail "rfq.js missing"; fi
```

Run: `bash tests/page_check.sh`
Expected: exit 1, with FAIL on the form checks.

- [ ] **Step 2: Insert the form in `index.html`**

Replace the line `            <!-- RFQ form (Task 4) -->` with:

```html
            <form class="rfq" action="skicka.php" method="post">
                <div class="field">
                    <label for="rfq-namn">Namn <span aria-hidden="true">*</span></label>
                    <input id="rfq-namn" name="namn" type="text" autocomplete="name" maxlength="100" required
                        aria-describedby="rfq-namn-fel">
                    <p class="field-error" id="rfq-namn-fel"></p>
                </div>
                <div class="field">
                    <label for="rfq-epost">E-post <span aria-hidden="true">*</span></label>
                    <input id="rfq-epost" name="epost" type="email" autocomplete="email" required
                        aria-describedby="rfq-epost-fel">
                    <p class="field-error" id="rfq-epost-fel"></p>
                </div>
                <div class="field">
                    <label for="rfq-telefon">Telefon</label>
                    <input id="rfq-telefon" name="telefon" type="tel" autocomplete="tel" maxlength="30"
                        aria-describedby="rfq-telefon-fel">
                    <p class="field-error" id="rfq-telefon-fel"></p>
                </div>
                <div class="field">
                    <label for="rfq-typ">Typ av projekt</label>
                    <select id="rfq-typ" name="typ">
                        <option value="" selected>Välj…</option>
                        <option>Bygg</option>
                        <option>Snickeri</option>
                        <option>Måleri</option>
                        <option>Annat</option>
                    </select>
                </div>
                <div class="field field--full">
                    <label for="rfq-plats">Var ligger projektet?</label>
                    <input id="rfq-plats" name="plats" type="text" autocomplete="street-address" maxlength="150"
                        aria-describedby="rfq-plats-fel">
                    <p class="field-error" id="rfq-plats-fel"></p>
                </div>
                <div class="field field--full">
                    <label for="rfq-beskrivning">Beskriv projektet <span aria-hidden="true">*</span></label>
                    <textarea id="rfq-beskrivning" name="beskrivning" rows="5" maxlength="5000" required
                        aria-describedby="rfq-beskrivning-fel"></textarea>
                    <p class="field-error" id="rfq-beskrivning-fel"></p>
                </div>
                <div class="rfq-trap" aria-hidden="true">
                    <label for="rfq-webbplats">Lämna tomt</label>
                    <input id="rfq-webbplats" name="webbplats" type="text" tabindex="-1" autocomplete="off">
                </div>
                <input type="hidden" name="t" value="">
                <p class="rfq-status" role="alert" hidden></p>
                <div class="rfq-actions">
                    <p class="rfq-note">Vi använder dina uppgifter enbart för att besvara din förfrågan.</p>
                    <button class="rfq-button" type="submit">Skicka förfrågan</button>
                </div>
            </form>

            <div class="rfq-sent" hidden>
                <h3 class="rfq-sent-title" tabindex="-1">Tack.</h3>
                <p>Vi har tagit emot din förfrågan och hör av oss så snart vi kan.</p>
            </div>
```

Before `</body>`, add:

```html
    <script src="rfq.js" defer></script>
```

- [ ] **Step 3: Write `rfq.js`**

```js
// Quote request form: Swedish validation messages, sending without a page reload,
// and the sent/error states. Without JS the form posts normally to skicka.php.
(() => {
    const form = document.querySelector('.rfq');
    if (!form) return;

    const loadedAt = Date.now();
    const sent = document.querySelector('.rfq-sent');
    const sentTitle = sent.querySelector('.rfq-sent-title');
    const status = form.querySelector('.rfq-status');
    const button = form.querySelector('.rfq-button');
    const buttonLabel = button.textContent;
    const requiredMessages = {
        namn: 'Fyll i ditt namn.',
        epost: 'Ange en giltig e-postadress.',
        beskrivning: 'Beskriv kort vad du vill ha hjälp med.',
    };
    const sendError = 'Förfrågan kunde inte skickas. Försök igen eller mejla info@byggresursen.com.';

    form.noValidate = true;

    function showSent(fornamn) {
        sentTitle.textContent = fornamn ? `Tack, ${fornamn}.` : 'Tack.';
        form.hidden = true;
        sent.hidden = false;
        sentTitle.focus();
    }

    function showStatus(text) {
        status.textContent = text;
        status.hidden = false;
    }

    function setFieldError(name, text) {
        const input = form.elements[name];
        const field = input && input.closest('.field');
        if (!field) return;
        const out = field.querySelector('.field-error');
        if (out) out.textContent = text;
        field.classList.toggle('has-error', Boolean(text));
        input.setAttribute('aria-invalid', text ? 'true' : 'false');
    }

    function clearErrors() {
        for (const input of form.querySelectorAll('input, select, textarea')) {
            if (input.name) setFieldError(input.name, '');
        }
        status.hidden = true;
    }

    function focusFirstError() {
        const first = form.querySelector('[aria-invalid="true"]');
        if (first) first.focus();
    }

    // Result of a no-JS-style redirect from skicka.php (e.g. JS loaded late).
    const params = new URLSearchParams(location.search);
    if (params.has('skickat')) showSent('');
    if (params.has('fel')) showStatus(sendError);
    if (params.has('skickat') || params.has('fel')) {
        history.replaceState(null, '', location.pathname + '#kontakt');
    }

    form.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (button.disabled) return;
        clearErrors();

        let valid = true;
        for (const [name, message] of Object.entries(requiredMessages)) {
            const input = form.elements[name];
            if (!input.value.trim() || !input.checkValidity()) {
                setFieldError(name, message);
                valid = false;
            }
        }
        if (!valid) {
            focusFirstError();
            return;
        }

        form.elements.t.value = String(Date.now() - loadedAt);
        button.disabled = true;
        button.textContent = 'Skickar…';
        try {
            const response = await fetch(form.action, {
                method: 'POST',
                body: new FormData(form),
                headers: { Accept: 'application/json' },
            });
            const data = await response.json().catch(() => ({}));
            if (response.ok && data.ok) {
                showSent(data.fornamn);
            } else if (response.status === 422 && data.errors) {
                for (const [name, message] of Object.entries(data.errors)) setFieldError(name, message);
                focusFirstError();
            } else {
                showStatus(sendError);
            }
        } catch {
            showStatus(sendError);
        } finally {
            button.disabled = false;
            button.textContent = buttonLabel;
        }
    });
})();
```

- [ ] **Step 4: Append the form styles to the end of `styles.css`**

```css
/* Quote request form */
.rfq {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.9rem 1.75rem;
    max-width: 36rem;
    margin: 0 auto;
    text-align: left;
}

.field--full,
.rfq-status,
.rfq-actions {
    grid-column: 1 / -1;
}

.field label {
    display: block;
    margin-bottom: 0.5rem;
    font: 300 0.75rem/1.4 var(--sans);
    letter-spacing: 0.06em;
    color: var(--pewter);
}

.field input,
.field select,
.field textarea {
    width: 100%;
    padding: 0.4rem 0 0.6rem;
    border: 0;
    border-bottom: 1px solid var(--hair);
    border-radius: 0;
    background-color: transparent;
    color: var(--shine);
    font: 300 1.2rem/1.5 var(--serif-text);
    appearance: none;
}

.field select {
    padding-right: 1.25rem;
    background-image: linear-gradient(45deg, transparent 50%, var(--pewter) 50%),
        linear-gradient(135deg, var(--pewter) 50%, transparent 50%);
    background-position: calc(100% - 10px) 55%, calc(100% - 5px) 55%;
    background-size: 5px 5px;
    background-repeat: no-repeat;
}

.field select option {
    background-color: var(--deep);
    color: var(--shine);
}

.field textarea {
    min-height: 7.5rem;
    resize: vertical;
}

.field input:focus-visible,
.field select:focus-visible,
.field textarea:focus-visible {
    outline: none;
    border-bottom-color: var(--steel);
}

.field.has-error input,
.field.has-error textarea {
    border-bottom-color: var(--err);
}

.field-error {
    margin: 0.4rem 0 0;
    font: 300 0.75rem/1.4 var(--sans);
    color: var(--err);
}

.field-error:empty {
    display: none;
}

.rfq-trap {
    position: absolute;
    left: -9999px;
    width: 1px;
    height: 1px;
    overflow: hidden;
}

.rfq-status {
    margin: 0;
    font: 300 0.85rem/1.5 var(--sans);
    color: var(--err);
}

.rfq-actions {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 1.25rem;
}

.rfq-note {
    max-width: 18rem;
    margin: 0;
    font: 300 0.75rem/1.7 var(--sans);
    color: var(--pewter);
}

.rfq-button {
    padding: 0.95rem 2.1rem;
    border: 1px solid var(--steel);
    background-color: transparent;
    color: var(--shine);
    font: 400 0.95rem/1 var(--serif-display);
    letter-spacing: 0.06em;
    cursor: pointer;
    transition: background-color 0.2s, color 0.2s;
}

.rfq-button:hover:not(:disabled) {
    background-color: var(--shine);
    color: var(--deep);
}

.rfq-button:disabled {
    opacity: 0.6;
    cursor: progress;
}

.rfq-sent {
    max-width: 30rem;
    margin: 0 auto;
    padding: 3.5rem 0;
    border-top: 1px solid var(--hair);
    border-bottom: 1px solid var(--hair);
}

.rfq-sent-title {
    margin: 0 0 0.75rem;
    font: italic 300 1.9rem/1.3 var(--serif-text);
    color: var(--shine);
}

.rfq-sent-title:focus {
    outline: none;
}

.rfq-sent p {
    margin: 0;
}

@media (max-width: 600px) {
    .rfq {
        grid-template-columns: 1fr;
    }

    .rfq-actions {
        flex-direction: column;
        text-align: center;
    }
}
```

- [ ] **Step 5: Run both test scripts**

Run: `bash tests/page_check.sh && bash tests/rfq_test.sh`
Expected: both report all passed.

- [ ] **Step 6: Browser check against the dev handler**

Start `RFQ_DEV=1 php -S 127.0.0.1:8000` in the background and open `http://127.0.0.1:8000/#kontakt`:
1. **Empty submit:** messages appear under Namn, E-post and Beskriv projektet, focus moves to Namn, and `rfq-dev.log` is unchanged.
2. **Invalid email:** with `anna@exempel`, only the email message remains.
3. **Valid submit:** fill in valid data, wait more than 3 s, and submit. "Tack, {förnamn}." appears with focus, and the log gains exactly one message.
4. **Double submit:** reload, fill in, wait more than 3 s, and double-click quickly. `grep -c '^=====' rfq-dev.log` goes up by exactly 1.
5. **Redirect results:** `/?skickat=1` shows the sent state, `/?fel=1` shows the error line, and the address bar is cleaned to `/#kontakt`.
6. **Phone width (375px):** one column, with the privacy note and button centred and stacked.

Stop the server and run `rm -f rfq-dev.log`.

- [ ] **Step 7: Commit**

```bash
git add index.html styles.css rfq.js tests/page_check.sh
git commit -m "Add quote request form to Kontakt

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Final verification and deployment handoff

- [ ] **Step 1:** `bash tests/page_check.sh && bash tests/rfq_test.sh`. Both must pass.
- [ ] **Step 2: Full visual pass at 1440px and 375px.**
  - **Reduced motion:** with Chrome DevTools → Rendering → reduced motion, anchor jumps are instant.
  - **Keyboard:** tab through the whole page. Focus is visible everywhere, and the honeypot is never reached.
- [ ] **Step 3:** `git status --short` prints nothing.
- [ ] **Step 4: Hand over the deployment steps from the spec** (*Quote request form → Deployment*) to the user. Don't upload anything yourself.
