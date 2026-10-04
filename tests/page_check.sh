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

if [ "$FAILS" -eq 0 ]; then echo "All page checks passed"; else echo "$FAILS check(s) failed"; exit 1; fi
