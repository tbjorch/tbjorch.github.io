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
