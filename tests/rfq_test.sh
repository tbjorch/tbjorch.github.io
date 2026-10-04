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

# --- Swedish Å survives (PCRE \v must not eat UTF-8 byte 0x85) ---
before=$(messages)
expect "name with Å returns 200" "$(post_json --data-urlencode 'namn=Åke Ström' --data-urlencode 'epost=ake@exempel.se' --data-urlencode 'plats=Åkersberga' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 200
body_has "first name with Å in JSON" '"fornamn":"Åke"'
log_has "body keeps Å in name" 'Namn:      Åke Ström'
log_has "body keeps Å in place" 'Plats:     Åkersberga'
subject_b64=$(printf '%s' 'Offertförfrågan: Annat – Åke Ström' | base64)
log_has "subject keeps Å" "Subject: =?UTF-8?B?${subject_b64}?="

# --- long description lines are wrapped below the 998-byte limit, UTF-8 intact ---
words=$(printf 'ändå %.0s' $(seq 1 300))
run=$(printf 'ä%.0s' $(seq 1 400))
rm -f "$LOG"
expect "long description returns 200" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode "beskrivning=$words$run" --data-urlencode 't=8000')" 200
longest=$(LC_ALL=C awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }' "$LOG")
if [ "$longest" -le 998 ]; then pass "no mail line over 998 bytes ($longest)"; else fail "no mail line over 998 bytes ($longest)"; fi
if iconv -f UTF-8 -t UTF-8 "$LOG" >/dev/null 2>&1; then pass "wrapped mail is valid UTF-8"; else fail "wrapped mail is valid UTF-8"; fi
expect "wrapped mail keeps every ä" "$(grep -o 'ä' "$LOG" | wc -l | tr -d ' ')" 700

# --- invalid optional fields are rejected, invalid spam fields dropped ---
before=$(messages)
expect "invalid UTF-8 place returns 422" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data 'plats=%FF' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
body_has "invalid place has a field error" '"plats":'
expect "array phone returns 422" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'telefon[]=1' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
expect "array type returns 422" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'typ[]=Bygg' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422
expect "array honeypot returns 200" "$(post_json "${VALID[@]}" --data-urlencode 'webbplats[]=x')" 200
expect "array t returns 200" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't[]=9000')" 200
expect "invalid optional or spam fields write nothing" "$(messages)" "$before"

# --- the full Swedish alphabet survives every field, the subject and the JSON reply ---
ALPHA='abcdefghijklmnopqrstuvwxyzåäö ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ é ü'
DESC=$(printf 'Ölandsgatan, Årstaviken och Ängsvägen: %s. Étagère från Müller. ' "$ALPHA" "$ALPHA" "$ALPHA" "$ALPHA")
rm -f "$LOG"
expect "full alphabet request returns 200" "$(post_json --data-urlencode 'namn=Åsa-Märta Öberg Ärlig' --data-urlencode 'epost=asa@exempel.se' --data-urlencode "plats=$ALPHA" --data-urlencode 'typ=Måleri' --data-urlencode "beskrivning=$DESC" --data-urlencode 't=8000')" 200
body_has "first name keeps åäö in JSON" '"fornamn":"Åsa-Märta"'
log_has "name line keeps åäö" 'Namn:      Åsa-Märta Öberg Ärlig'
log_has "place keeps the whole alphabet" "Plats:     $ALPHA"
log_has "type keeps å" 'Typ:       Måleri'
subject_b64=$(printf '%s' 'Offertförfrågan: Måleri – Åsa-Märta Öberg Ärlig' | base64)
log_has "subject keeps the whole name" "Subject: =?UTF-8?B?${subject_b64}?="
replyto_b64=$(printf '%s' 'Åsa-Märta Öberg Ärlig' | base64)
log_has "Reply-To name keeps åäö" "Reply-To: =?UTF-8?B?${replyto_b64}?= <asa@exempel.se>"
sent_desc=$(awk '/^Beskrivning:/{f=1;next} /^—/{f=0} f' "$LOG" | tr -d ' \r\n')
expect "description arrives with every letter, wrapped only at spaces" "$sent_desc" "$(printf '%s' "$DESC" | tr -d ' \r\n')"

# --- email addresses on Swedish domains (IDN) ---
expect "Swedish domain email returns 200" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@företag.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 200
log_has "Reply-To uses the ASCII form of the domain" '^Reply-To: .*<anna@xn--fretag-wxa.se>'
log_has "body shows the address as typed" 'E-post:    anna@företag.se'
expect "ASCII-form Swedish domain (as Chrome sends it) returns 200" "$(post_json --data-urlencode 'namn=Anna' --data-urlencode 'epost=anna@xn--fretag-wxa.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 200
expect "body shows the ASCII-form domain readably" "$(grep -c 'E-post:    anna@företag.se' "$LOG")" 2
expect "å before the @ is rejected (mail servers cannot deliver it)" "$(post_json --data-urlencode 'namn=Åsa' --data-urlencode 'epost=åsa@exempel.se' --data-urlencode 'beskrivning=Hej' --data-urlencode 't=8000')" 422

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
