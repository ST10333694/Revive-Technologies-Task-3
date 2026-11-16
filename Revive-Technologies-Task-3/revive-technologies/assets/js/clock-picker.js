/**
 * assets/js/clock-picker.js
 * Turns any <input data-clock name="..."> into a clock-face time picker.
 * The visible box shows "02:30 PM"; the form submits 24-hour "14:30".
 */
(function () {
    'use strict';

    var CLOCK_SVG = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>';
    var openPicker = null;

    function pad(n) { return (n < 10 ? '0' : '') + n; }

    function init(input) {
        if (input.dataset.clockReady) return;
        input.dataset.clockReady = '1';

        var name = input.getAttribute('name');
        var initial = input.getAttribute('value') || '';

        // State (12-hour clock internally)
        var state = { h: 10, m: 0, pm: false, mode: 'h', has: false };
        var match = /^(\d{1,2}):(\d{2})/.exec(initial);
        if (match) {
            var h24 = parseInt(match[1], 10);
            state.m = parseInt(match[2], 10);
            state.pm = h24 >= 12;
            state.h = h24 % 12 === 0 ? 12 : h24 % 12;
            state.has = true;
        }

        // Build DOM: wrapper, visible readonly box, hidden real field, popover
        var wrap = document.createElement('div');
        wrap.className = 'cp-wrap';
        input.parentNode.insertBefore(wrap, input);
        wrap.appendChild(input);

        var hidden = document.createElement('input');
        hidden.type = 'hidden';
        if (name) hidden.name = name;
        wrap.appendChild(hidden);

        input.removeAttribute('name');
        input.removeAttribute('value');
        input.type = 'text';
        input.readOnly = true;
        input.autocomplete = 'off';
        input.classList.add('cp-input');
        if (!input.placeholder) input.placeholder = 'Select time';

        var icon = document.createElement('span');
        icon.className = 'cp-icon';
        icon.innerHTML = CLOCK_SVG;
        wrap.appendChild(icon);

        var pop = document.createElement('div');
        pop.className = 'cp-pop';
        wrap.appendChild(pop);

        function commit() {
            var h24 = (state.h % 12) + (state.pm ? 12 : 0);
            hidden.value = pad(h24) + ':' + pad(state.m);
            input.value = pad(state.h) + ':' + pad(state.m) + ' ' + (state.pm ? 'PM' : 'AM');
        }
        function clearValue() {
            hidden.value = '';
            input.value = '';
            state.has = false;
        }
        if (state.has) commit();

        function render() {
            var cx = 110, cy = 110, rr = 82;
            var isHour = state.mode === 'h';
            var value = isHour ? state.h : state.m;
            var angle = isHour ? (state.h % 12) * 30 : state.m * 6;
            var rad = angle * Math.PI / 180;
            var hx = cx + rr * Math.sin(rad);
            var hy = cy - rr * Math.cos(rad);

            var nums = '';
            for (var i = 0; i < 12; i++) {
                var a = i * 30 * Math.PI / 180;
                var x = cx + rr * Math.sin(a);
                var y = cy - rr * Math.cos(a);
                var label = isHour ? (i === 0 ? 12 : i) : pad(i * 5);
                var selected = isHour ? ((i === 0 ? 12 : i) === state.h) : (i * 5 === state.m);
                nums += '<text x="' + x.toFixed(1) + '" y="' + (y + 5).toFixed(1) + '" text-anchor="middle" font-size="15" font-weight="600" fill="' + (selected ? '#fff' : '#2b2724') + '" pointer-events="none">' + label + '</text>';
            }

            var svg = '<svg class="cp-face" width="220" height="220" viewBox="0 0 220 220">' +
                '<circle cx="110" cy="110" r="106" fill="#f3f0eb"/>' +
                '<line x1="110" y1="110" x2="' + hx.toFixed(1) + '" y2="' + hy.toFixed(1) + '" stroke="#1c1917" stroke-width="2"/>' +
                '<circle cx="110" cy="110" r="4" fill="#1c1917"/>' +
                '<circle cx="' + hx.toFixed(1) + '" cy="' + hy.toFixed(1) + '" r="18" fill="#1c1917"/>' +
                nums + '</svg>';

            pop.innerHTML =
                '<div class="cp-display">' +
                    '<button type="button" class="cp-seg ' + (isHour ? 'on' : '') + '" data-mode="h">' + pad(state.h) + '</button>' +
                    '<span class="cp-colon">:</span>' +
                    '<button type="button" class="cp-seg ' + (!isHour ? 'on' : '') + '" data-mode="m">' + pad(state.m) + '</button>' +
                    '<div class="cp-ampm">' +
                        '<button type="button" class="' + (!state.pm ? 'on' : '') + '" data-ampm="am">AM</button>' +
                        '<button type="button" class="' + (state.pm ? 'on' : '') + '" data-ampm="pm">PM</button>' +
                    '</div>' +
                '</div>' + svg +
                '<div class="cp-actions">' +
                    '<button type="button" class="cp-clear">Clear</button>' +
                    '<span><button type="button" class="cp-cancel">Cancel</button><button type="button" class="cp-ok">OK</button></span>' +
                '</div>';

            var face = pop.querySelector('.cp-face');
            var dragging = false;

            function pick(e) {
                var r = face.getBoundingClientRect();
                var dx = e.clientX - (r.left + r.width / 2);
                var dy = e.clientY - (r.top + r.height / 2);
                var deg = (Math.atan2(dx, -dy) * 180 / Math.PI + 360) % 360;
                if (state.mode === 'h') {
                    var h = Math.round(deg / 30) % 12;
                    state.h = h === 0 ? 12 : h;
                } else {
                    state.m = Math.round(deg / 6) % 60;
                }
                render();
            }
            face.addEventListener('pointerdown', function (e) {
                dragging = true;
                try { face.setPointerCapture(e.pointerId); } catch (err) {}
                pick(e);
            });
            face.addEventListener('pointermove', function (e) { if (dragging) pick(e); });
            face.addEventListener('pointerup', function () {
                if (!dragging) return;
                dragging = false;
                if (state.mode === 'h') { state.mode = 'm'; render(); }
            });
        }

        function open() {
            if (openPicker && openPicker !== close) openPicker();
            state.mode = 'h';
            render();
            pop.classList.add('open');
            openPicker = close;
        }
        function close() {
            pop.classList.remove('open');
            if (openPicker === close) openPicker = null;
        }

        input.addEventListener('click', function () { pop.classList.contains('open') ? close() : open(); });
        input.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(); } });

        pop.addEventListener('click', function (e) {
            var t = e.target;
            if (t.dataset.mode) { state.mode = t.dataset.mode; render(); }
            else if (t.dataset.ampm) { state.pm = t.dataset.ampm === 'pm'; render(); }
            else if (t.classList.contains('cp-ok')) { commit(); state.has = true; close(); }
            else if (t.classList.contains('cp-cancel')) { close(); }
            else if (t.classList.contains('cp-clear')) { clearValue(); close(); }
        });

        wrap.addEventListener('click', function (e) { e.stopPropagation(); });
    }

    document.addEventListener('click', function () { if (openPicker) openPicker(); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && openPicker) openPicker(); });

    document.addEventListener('DOMContentLoaded', function () {
        Array.prototype.forEach.call(document.querySelectorAll('input[data-clock]'), init);
    });
    // Expose so dynamically-added inputs can be activated
    window.initClockPickers = function (root) {
        Array.prototype.forEach.call((root || document).querySelectorAll('input[data-clock]'), init);
    };
})();
