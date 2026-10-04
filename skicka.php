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

// True when the field was sent but is not a valid UTF-8 string (e.g. an array, or stray bytes).
function isInvalid(string $name): bool
{
    return array_key_exists($name, $_POST)
        && (!is_string($_POST[$name]) || !preg_match('//u', $_POST[$name]));
}

function oneLine(string $value): string
{
    // The u flag is required: without it \v matches byte 0x85, the second byte of "Å" in UTF-8.
    return trim((string) preg_replace('/[\r\n\t\v\f]+/u', ' ', $value));
}

function chars(string $value): int
{
    return (int) preg_match_all('/./su', $value);
}

// Wraps lines at $width characters (at a space when possible) so no mail line
// exceeds the 998-byte limit for 8bit transfer, without splitting UTF-8 characters.
function wrapLines(string $text, int $width = 76): string
{
    $out = [];
    foreach (explode("\r\n", $text) as $line) {
        while (chars($line) > $width) {
            if (!preg_match('/^(.{1,' . $width . '})\s+(.*)$/su', $line, $m)) {
                preg_match('/^(.{' . $width . '})(.*)$/su', $line, $m);
            }
            $out[] = $m[1];
            $line = $m[2];
        }
        $out[] = $line;
    }
    return implode("\r\n", $out);
}

// Converts a Swedish domain such as företag.se to its ASCII form (xn--fretag-wxa.se) so the
// address validates and works in Reply-To. Needs the intl extension; without it the
// address is returned unchanged (and an IDN domain is then rejected by validation).
function asciiEmail(string $email): string
{
    $at = strrpos($email, '@');
    if ($at === false || !function_exists('idn_to_ascii')) {
        return $email;
    }
    $domain = idn_to_ascii(substr($email, $at + 1), IDNA_DEFAULT, INTL_IDNA_VARIANT_UTS46);
    return $domain === false ? $email : substr($email, 0, $at + 1) . $domain;
}

// The reverse, for showing the address readably in the email body (anna@företag.se).
function readableEmail(string $email): string
{
    $at = strrpos($email, '@');
    if ($at === false || !function_exists('idn_to_utf8')) {
        return $email;
    }
    $domain = idn_to_utf8(substr($email, $at + 1), IDNA_DEFAULT, INTL_IDNA_VARIANT_UTS46);
    return $domain === false ? $email : substr($email, 0, $at + 1) . $domain;
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
$epostAscii = asciiEmail($epost);
$telefon = oneLine(field('telefon'));
$typ = field('typ');
$plats = oneLine(field('plats'));
$beskrivning = wrapLines((string) preg_replace('/\r\n?|\n/', "\r\n", field('beskrivning')));
$fornamn = explode(' ', $namn)[0];

// Spam: a filled or malformed honeypot, a malformed t, or a JS-measured fill time under
// RFQ_MIN_MS is dropped silently.
$elapsed = field('t');
if (field('webbplats') !== '' || isInvalid('webbplats') || isInvalid('t')
    || ($elapsed !== '' && (int) $elapsed < RFQ_MIN_MS)) {
    respond($wantsJson, 200, ['ok' => true, 'fornamn' => $fornamn]);
}

$errors = [];
if ($namn === '' || chars($namn) > 100) {
    $errors['namn'] = 'Fyll i ditt namn.';
}
if (filter_var($epostAscii, FILTER_VALIDATE_EMAIL) === false) {
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
foreach (['telefon' => 'Ange ett giltigt telefonnummer.', 'typ' => 'Välj en typ av projekt i listan.', 'plats' => 'Ange en giltig plats.'] as $name => $message) {
    if (isInvalid($name)) {
        $errors[$name] = $message;
    }
}
if ($errors) {
    respond($wantsJson, 422, ['ok' => false, 'errors' => $errors]);
}

$subject = encodeHeader("Offertförfrågan: {$typ} – {$namn}");
$headers = [
    'From' => encodeHeader(RFQ_FROM_NAME) . ' <' . RFQ_FROM . '>',
    'Reply-To' => encodeHeader($namn) . ' <' . $epostAscii . '>',
    'MIME-Version' => '1.0',
    'Content-Type' => 'text/plain; charset=UTF-8',
    'Content-Transfer-Encoding' => '8bit',
    'X-Mailer' => 'byggresursen.com',
];
$body = implode("\r\n", [
    'Ny offertförfrågan från byggresursen.com',
    '',
    'Namn:      ' . $namn,
    'E-post:    ' . readableEmail($epostAscii),
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
