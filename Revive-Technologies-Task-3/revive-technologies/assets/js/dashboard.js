/**
 * assets/js/dashboard.js
 * Small behaviours shared by every portal page.
 */
(function () {
    'use strict';

    document.addEventListener('DOMContentLoaded', function () {

        /* ---- Menu dropdown ---- */
        var wrap = document.querySelector('.menu-wrap');
        var btn = document.getElementById('menuBtn');
        if (wrap && btn) {
            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                var open = wrap.classList.toggle('open');
                btn.setAttribute('aria-expanded', open ? 'true' : 'false');
            });
            document.addEventListener('click', function (e) {
                if (!wrap.contains(e.target)) { wrap.classList.remove('open'); btn.setAttribute('aria-expanded', 'false'); }
            });
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') { wrap.classList.remove('open'); btn.setAttribute('aria-expanded', 'false'); }
            });
        }

        /* ---- Quotation "itemised breakdown" toggle ---- */
        Array.prototype.forEach.call(document.querySelectorAll('.q-toggle'), function (t) {
            t.addEventListener('click', function () {
                var card = t.closest('.q-card');
                var collapsed = card.classList.toggle('collapsed');
                var label = t.querySelector('.q-toggle-label');
                if (label) label.textContent = collapsed ? 'View itemised breakdown' : 'Hide itemised breakdown';
            });
        });

        /* ---- Modals: [data-open-modal="id"] opens #id, [data-close-modal] / backdrop / Esc closes ---- */
        function setModal(el, open) {
            if (!el) return;
            el.classList.toggle('open', open);
            el.setAttribute('aria-hidden', open ? 'false' : 'true');
            if (open) { var f = el.querySelector('input'); if (f) setTimeout(function () { f.focus(); }, 50); }
        }
        Array.prototype.forEach.call(document.querySelectorAll('[data-open-modal]'), function (b) {
            b.addEventListener('click', function () { setModal(document.getElementById(b.getAttribute('data-open-modal')), true); });
        });
        Array.prototype.forEach.call(document.querySelectorAll('.modal-overlay'), function (m) {
            m.addEventListener('click', function (e) {
                if (e.target === m || e.target.hasAttribute('data-close-modal')) setModal(m, false);
            });
        });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') Array.prototype.forEach.call(document.querySelectorAll('.modal-overlay.open'), function (m) { setModal(m, false); });
        });

        /* ---- Live search: <input data-filter-input="listId"> filters [data-filter-item] rows ---- */
        Array.prototype.forEach.call(document.querySelectorAll('[data-filter-input]'), function (input) {
            input.addEventListener('input', function () {
                var list = document.getElementById(input.getAttribute('data-filter-input'));
                if (!list) return;
                var q = input.value.trim().toLowerCase();
                Array.prototype.forEach.call(list.querySelectorAll('[data-filter-item]'), function (row) {
                    row.style.display = row.getAttribute('data-filter-item').indexOf(q) === -1 ? 'none' : '';
                });
            });
        });

        /* ---- Chats open scrolled to the newest message ---- */
        Array.prototype.forEach.call(document.querySelectorAll('.chat-messages'), function (c) { c.scrollTop = c.scrollHeight; });

        /* ---- Confirm dialogs on forms marked data-confirm="..." ---- */
        Array.prototype.forEach.call(document.querySelectorAll('form[data-confirm]'), function (f) {
            f.addEventListener('submit', function (e) {
                if (!window.confirm(f.getAttribute('data-confirm'))) e.preventDefault();
            });
        });

        /* ---- Admin quotation builder (line items + live total) ---- */
        Array.prototype.forEach.call(document.querySelectorAll('[data-items-builder]'), function (builder) {
            var rows = builder.querySelector('.item-rows');
            var totalEl = builder.querySelector('.items-total strong');
            var addBtn = builder.querySelector('[data-add-item]');

            function rand(n) {
                return 'R ' + Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
            }
            function recalc() {
                var total = 0;
                Array.prototype.forEach.call(rows.querySelectorAll('.item-row'), function (row) {
                    var qty = parseFloat(row.querySelector('.item-qty').value) || 0;
                    var cost = parseFloat(row.querySelector('.item-cost').value) || 0;
                    var sub = qty * cost;
                    total += sub;
                    row.querySelector('.item-sub').textContent = rand(sub);
                });
                if (totalEl) totalEl.textContent = rand(total);
            }
            function newRow() {
                var div = document.createElement('div');
                div.className = 'item-row';
                div.innerHTML =
                    '<input type="text" name="item_desc[]" placeholder="e.g. Custom Floral Feature Backdrop (3m x 2.5m)">' +
                    '<input type="number" class="item-qty" name="item_qty[]" min="1" step="1" value="1">' +
                    '<input type="number" class="item-cost" name="item_cost[]" min="0" step="0.01" placeholder="0.00">' +
                    '<span class="item-sub">R 0</span>' +
                    '<button type="button" class="item-del" title="Remove line">&times;</button>';
                return div;
            }
            if (addBtn) addBtn.addEventListener('click', function () { rows.appendChild(newRow()); recalc(); });
            builder.addEventListener('input', recalc);
            builder.addEventListener('click', function (e) {
                if (e.target.classList.contains('item-del')) {
                    if (rows.querySelectorAll('.item-row').length > 1) { e.target.closest('.item-row').remove(); recalc(); }
                }
            });
            if (!rows.querySelector('.item-row')) rows.appendChild(newRow());
            recalc();
        });
    });
})();
