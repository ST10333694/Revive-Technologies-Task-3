</main>
<footer class="lux-footer">
    <div class="container lux-footer-inner">
        <a href="#" class="lux-logo" aria-label="Back to top"><img src="assets/img/logo-icon.png" alt="Bee's Events & Decor"></a>
        <div class="lux-center">
            <div class="lux-name">Bee's Events &amp; Décor</div>
            <div class="lux-tag">Luxury Décor &middot; Premium Events</div>
            <div class="lux-copy">&copy; <?php echo date('Y'); ?> Bee's Events &amp; Decor</div>
            <span class="built-by">Built by Revive Technologies</span>
        </div>
        <a href="#" class="lux-top">Back to top &uarr;</a>
    </div>
</footer>
<script>
document.addEventListener('DOMContentLoaded', function () {
    /* ---- Sign in / Register pop-up ---- */
    const modal = document.getElementById('authModal');
    const frame = document.getElementById('authFrame');
    if (modal && frame) {
        const open = (url) => {
            url += (url.indexOf('?') === -1 ? '?' : '&') + 'embed=1';
            frame.style.height = '460px';
            frame.src = url;
            modal.classList.add('open');
            modal.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
        };
        const close = () => {
            modal.classList.remove('open');
            modal.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
            setTimeout(() => { frame.src = 'about:blank'; }, 250);
        };
        // every link to the login / register page opens the pop-up instead
        document.querySelectorAll('a[href*="auth/login.php"], a[href*="auth/register.php"]').forEach(a => {
            a.addEventListener('click', (e) => {
                if (e.metaKey || e.ctrlKey || e.shiftKey || e.button !== 0) return;
                e.preventDefault();
                const nav = document.querySelector('.navbar');
                if (nav) nav.classList.remove('menu-open');
                open(a.getAttribute('href'));
            });
        });
        // grow / shrink the frame to fit whichever form is showing
        frame.addEventListener('load', () => {
            try {
                const doc = frame.contentDocument;
                if (!doc || !doc.body || frame.src === 'about:blank') return;
                const fit = () => { frame.style.height = doc.documentElement.scrollHeight + 'px'; };
                fit();
                if ('ResizeObserver' in window) new ResizeObserver(fit).observe(doc.body);
            } catch (err) { /* cross-origin: leave default height */ }
        });
        document.getElementById('authModalClose').addEventListener('click', close);
        modal.addEventListener('click', (e) => { if (e.target === modal) close(); });
        document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && modal.classList.contains('open')) close(); });
    }

    /* ---- Hero headline: words fly in one after another ---- */
    const h1 = document.querySelector('.hero h1');
    if (h1 && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        let i = 0;
        const wrapWords = (node) => {
            Array.from(node.childNodes).forEach(child => {
                if (child.nodeType === 3) {
                    const frag = document.createDocumentFragment();
                    child.textContent.split(/(\s+)/).forEach(part => {
                        if (/^\s+$/.test(part) || part === '') { frag.appendChild(document.createTextNode(part)); return; }
                        const span = document.createElement('span');
                        span.className = 'w';
                        span.style.setProperty('--i', i++);
                        span.textContent = part;
                        frag.appendChild(span);
                    });
                    node.replaceChild(frag, child);
                } else if (child.nodeType === 1) {
                    wrapWords(child);
                }
            });
        };
        wrapWords(h1);
        h1.classList.add('split');
    }
});
</script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    // Hamburger menu (Services / Gallery / Testimonials / Contact)
    const nav = document.querySelector('.navbar');
    const btn = document.getElementById('pubMenuBtn');
    if (nav && btn) {
        const setOpen = (open) => { nav.classList.toggle('menu-open', open); btn.setAttribute('aria-expanded', open ? 'true' : 'false'); };
        btn.addEventListener('click', (e) => { e.stopPropagation(); setOpen(!nav.classList.contains('menu-open')); });
        document.querySelectorAll('#pubMenu a').forEach(a => a.addEventListener('click', () => setOpen(false)));
        document.addEventListener('click', (e) => { if (!nav.contains(e.target)) setOpen(false); });
        document.addEventListener('keydown', (e) => { if (e.key === 'Escape') setOpen(false); });
    }
});
</script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    const targets = document.querySelectorAll('.reveal, .reveal-fade, .reveal-left, .reveal-right, .reveal-zoom');
    if (!('IntersectionObserver' in window) || !targets.length) {
        targets.forEach(el => el.classList.add('in-view'));
        return;
    }
    const io = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('in-view');
                io.unobserve(entry.target);
            }
        });
    }, { threshold: 0.15, rootMargin: '0px 0px -40px 0px' });
    targets.forEach(el => io.observe(el));
});
</script>
</body>
</html>
