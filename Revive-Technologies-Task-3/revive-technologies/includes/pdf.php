<?php
/**
 * includes/pdf.php
 * -------------------------------------------------
 * A tiny, dependency-free PDF writer (no Composer / libraries needed on XAMPP)
 * plus output_quotation_pdf(), which draws a quotation like the on-screen card.
 *
 * Uses the built-in Helvetica fonts, so nothing has to be embedded.
 * -------------------------------------------------
 */

class SimplePDF {
    const W = 595.28;   // A4 width in points
    const H = 841.89;   // A4 height in points

    private $pages = [];
    private $buf = '';
    private $img = null;      // one JPEG logo: ['data' => bytes, 'w' => px, 'h' => px]

    // Helvetica glyph widths (1000 units per em) for ASCII 32..126
    private $wReg = [278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,556,556,333,500,278,556,500,722,500,500,500,334,260,334,584];
    private $wBold = [278,333,474,556,556,889,722,238,333,333,389,584,278,333,278,278,556,556,556,556,556,556,556,556,556,556,333,333,584,584,584,611,975,722,722,722,722,667,611,778,722,278,556,722,611,833,722,778,667,778,722,667,611,722,667,944,667,667,611,333,278,333,584,556,333,556,611,556,611,556,333,611,611,278,278,556,278,889,611,611,611,611,389,556,333,611,556,778,556,556,500,389,280,389,584];

    /** Start a fresh page (the first page exists already). */
    public function newPage() {
        $this->pages[] = $this->buf;
        $this->buf = '';
    }

    /** Convert UTF-8 text to the single-byte encoding the PDF fonts use. */
    private function enc($s) {
        $s = (string)$s;
        $out = function_exists('iconv') ? @iconv('UTF-8', 'windows-1252//TRANSLIT//IGNORE', $s) : false;
        if ($out === false || $out === null) {
            $out = preg_replace('/[^\x20-\x7E]/', '?', $s);
        }
        return $out;
    }

    private function esc($s) {
        return str_replace(['\\', '(', ')', "\r", "\n"], ['\\\\', '\\(', '\\)', ' ', ' '], $s);
    }

    private function col($rgb) {
        return sprintf('%.3F %.3F %.3F', $rgb[0] / 255, $rgb[1] / 255, $rgb[2] / 255);
    }

    /** Width of a string in points. */
    public function width($s, $size, $bold = false) {
        $s = $this->enc($s);
        $table = $bold ? $this->wBold : $this->wReg;
        $w = 0;
        $len = strlen($s);
        for ($i = 0; $i < $len; $i++) {
            $c = ord($s[$i]);
            $w += ($c >= 32 && $c <= 126) ? $table[$c - 32] : 556;
        }
        return $w * $size / 1000;
    }

    /** Split text into lines no wider than $maxW. */
    public function wrap($text, $maxW, $size, $bold = false) {
        $lines = [];
        $line = '';
        foreach (preg_split('/\s+/', trim((string)$text)) as $word) {
            $try = $line === '' ? $word : $line . ' ' . $word;
            if ($line !== '' && $this->width($try, $size, $bold) > $maxW) {
                $lines[] = $line;
                $line = $word;
            } else {
                $line = $try;
            }
        }
        if ($line !== '') $lines[] = $line;
        return $lines ?: [''];
    }

    /** Draw text. $y is the baseline measured from the TOP of the page. $align: L, R or C. */
    public function text($x, $y, $s, $size = 10, $bold = false, $rgb = [0, 0, 0], $align = 'L') {
        $w = $this->width($s, $size, $bold);
        if ($align === 'R') $x -= $w;
        elseif ($align === 'C') $x -= $w / 2;
        $this->buf .= sprintf(
            "BT /%s %.2F Tf %s rg %.2F %.2F Td (%s) Tj ET\n",
            $bold ? 'F2' : 'F1', $size, $this->col($rgb), $x, self::H - $y, $this->esc($this->enc($s))
        );
    }

    /** Filled rectangle. $y is the TOP edge measured from the top of the page. */
    public function rect($x, $y, $w, $h, $fill, $stroke = null) {
        $this->buf .= sprintf('%s rg %.2F %.2F %.2F %.2F re f' . "\n", $this->col($fill), $x, self::H - $y - $h, $w, $h);
        if ($stroke) {
            $this->buf .= sprintf('%s RG 0.8 w %.2F %.2F %.2F %.2F re S' . "\n", $this->col($stroke), $x, self::H - $y - $h, $w, $h);
        }
    }

    /** Rounded filled rectangle. $y is the TOP edge measured from the top of the page. */
    public function rrect($x, $y, $w, $h, $r, $fill) {
        $k  = 0.5523 * $r;
        $x1 = $x;      $y1 = self::H - $y - $h;     // bottom-left corner
        $x2 = $x + $w; $y2 = self::H - $y;          // top-right corner
        $o  = $this->col($fill) . ' rg ';
        $o .= sprintf('%.2F %.2F m ', $x1 + $r, $y1);
        $o .= sprintf('%.2F %.2F l ', $x2 - $r, $y1);
        $o .= sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c ', $x2 - $r + $k, $y1, $x2, $y1 + $r - $k, $x2, $y1 + $r);
        $o .= sprintf('%.2F %.2F l ', $x2, $y2 - $r);
        $o .= sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c ', $x2, $y2 - $r + $k, $x2 - $r + $k, $y2, $x2 - $r, $y2);
        $o .= sprintf('%.2F %.2F l ', $x1 + $r, $y2);
        $o .= sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c ', $x1 + $r - $k, $y2, $x1, $y2 - $r + $k, $x1, $y2 - $r);
        $o .= sprintf('%.2F %.2F l ', $x1, $y1 + $r);
        $o .= sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c ', $x1, $y1 + $r - $k, $x1 + $r - $k, $y1, $x1 + $r, $y1);
        $this->buf .= $o . "h f\n";
    }

    /** Load a JPEG file to use with drawImage(). Returns false if it can't be read. */
    public function loadJpeg($path) {
        $info = is_file($path) ? @getimagesize($path) : false;
        if (!$info || $info[2] !== IMAGETYPE_JPEG) return false;
        $this->img = ['data' => file_get_contents($path), 'w' => $info[0], 'h' => $info[1]];
        return true;
    }

    /** Draw the loaded JPEG. $y is the TOP edge measured from the top of the page. */
    public function drawImage($x, $y, $w, $h) {
        if (!$this->img) return;
        $this->buf .= sprintf("q %.2F 0 0 %.2F %.2F %.2F cm /Im1 Do Q\n", $w, $h, $x, self::H - $y - $h);
    }

    /** Thin horizontal line. */
    public function hline($x1, $x2, $y, $rgb = [229, 226, 218]) {
        $this->buf .= sprintf('%s RG 0.6 w %.2F %.2F m %.2F %.2F l S' . "\n", $this->col($rgb), $x1, self::H - $y, $x2, self::H - $y);
    }

    /** Build the file and return it as a string. */
    public function render() {
        $pages = $this->pages;
        $pages[] = $this->buf;
        $n = count($pages);

        $objs = [];
        $objs[1] = '<< /Type /Catalog /Pages 2 0 R >>';
        $kids = [];
        for ($i = 0; $i < $n; $i++) $kids[] = (5 + 2 * $i) . ' 0 R';
        $objs[2] = '<< /Type /Pages /Kids [' . implode(' ', $kids) . '] /Count ' . $n . ' >>';
        $objs[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';
        $objs[4] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>';
        $imgNo = 5 + 2 * $n;
        $xobj = $this->img ? ' /XObject << /Im1 ' . $imgNo . ' 0 R >>' : '';
        for ($i = 0; $i < $n; $i++) {
            $pageNo = 5 + 2 * $i;
            $contentNo = 6 + 2 * $i;
            $objs[$pageNo] = sprintf(
                '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %.2F %.2F] /Resources << /Font << /F1 3 0 R /F2 4 0 R >>%s >> /Contents %d 0 R >>',
                self::W, self::H, $xobj, $contentNo
            );
            $objs[$contentNo] = '<< /Length ' . strlen($pages[$i]) . " >>\nstream\n" . $pages[$i] . "endstream";
        }

        if ($this->img) {
            $objs[$imgNo] = sprintf(
                "<< /Type /XObject /Subtype /Image /Width %d /Height %d /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length %d >>\nstream\n",
                $this->img['w'], $this->img['h'], strlen($this->img['data'])
            ) . $this->img['data'] . "\nendstream";
        }

        $out = "%PDF-1.4\n";
        $offsets = [];
        $count = count($objs);
        for ($k = 1; $k <= $count; $k++) {
            $offsets[$k] = strlen($out);
            $out .= $k . " 0 obj\n" . $objs[$k] . "\nendobj\n";
        }
        $xref = strlen($out);
        $out .= "xref\n0 " . ($count + 1) . "\n";
        $out .= "0000000000 65535 f \n";
        for ($k = 1; $k <= $count; $k++) {
            $out .= sprintf("%010d 00000 n \n", $offsets[$k]);
        }
        $out .= "trailer\n<< /Size " . ($count + 1) . " /Root 1 0 R >>\nstartxref\n" . $xref . "\n%%EOF";
        return $out;
    }
}

/**
 * Draw a quotation (as returned by get_quotation()) and send it to the browser as a PDF download.
 * Layout: dark header band with the company logo + contact details, QUOTATION title,
 * "Bill to" / "Event date" cards, itemised table, total, payment terms.
 */
function output_quotation_pdf($q) {
    $pdf   = new SimplePDF();
    $W     = SimplePDF::W;
    $H     = SimplePDF::H;
    $M     = 40;                // page margin
    $R     = $W - $M;           // right edge of content
    $CW    = $R - $M;           // content width
    $dark  = [28, 25, 23];
    $grey  = [120, 116, 111];
    $white = [255, 255, 255];
    $card  = [245, 244, 241];

    $company = "Bee's Events & Décor";
    $contact = 'info@beesevents.co.za  ·  +27 11 000 0000  ·  www.beesevents.co.za';
    $place   = 'Johannesburg, South Africa';

    // ---- Header band with logo tile
    $pdf->rect(0, 0, $W, 118, $dark);
    $pdf->rect($M, 20, 78, 78, $white);
    if ($pdf->loadJpeg(__DIR__ . '/../assets/img/logo-pdf.jpg')) {
        $pdf->drawImage($M + 5, 20 + (78 - 62.2) / 2, 68, 62.2);
    }
    $pdf->text($M + 98, 52, $company, 19, false, $white);
    $pdf->text($M + 98, 73, $contact, 8.5, false, [157, 176, 196]);
    $pdf->text($M + 98, 87, $place, 8.5, false, [157, 176, 196]);

    // ---- Title + reference block
    $status_label = $q['status'] === 'accepted' ? 'APPROVED' : ($q['status'] === 'rejected' ? 'NOT APPROVED' : 'PENDING APPROVAL');
    $pdf->text($M, 166, 'QUOTATION', 27, false, $dark);
    $meta = [
        ['Quotation No:', quote_ref($q['quote_id'], $q['created_at'])],
        ['Date Issued:',  nice_date($q['created_at'])],
        ['Status:',       $status_label],
    ];
    $y = 190;
    foreach ($meta as $row) {
        $pdf->text($M, $y, $row[0], 9.5, false, $grey);
        $pdf->text($M + 82, $y, $row[1], 9.5, false, $dark);
        $y += 16;
    }

    // ---- Bill-to and event-date cards
    $cy    = 252;
    $leftW = 292;
    $rx    = $M + $leftW + 20;
    $rw    = $CW - $leftW - 20;
    $pdf->rrect($M, $cy, $leftW, 70, 9, $card);
    $pdf->rrect($rx, $cy, $rw, 70, 9, $card);

    $pdf->text($M + 14, $cy + 20, 'BILL TO', 7.5, false, $grey);
    $pdf->text($M + 14, $cy + 38, $q['client_name'], 11, true, $dark);
    $evLines = $pdf->wrap('Event: ' . $q['event_type'], $leftW - 28, 8.5);
    $pdf->text($M + 14, $cy + 54, $evLines[0] . (count($evLines) > 1 ? '...' : ''), 8.5, false, $grey);

    $when = nice_date($q['event_date']);
    $pdf->text($rx + 14, $cy + 20, 'EVENT DATE', 7.5, false, $grey);
    $pdf->text($rx + 14, $cy + 40, $when, 12, true, $dark);
    $sub = !empty($q['event_time']) ? 'at ' . nice_time($q['event_time']) : '';
    if (!empty($q['venue'])) {
        $prefix = $sub !== '' ? $sub . '  ·  ' : '';
        $vl = $pdf->wrap($q['venue'], $rw - 28 - $pdf->width($prefix . '...', 8.5), 8.5);
        $sub = $prefix . $vl[0] . (count($vl) > 1 ? '...' : '');
    }
    if ($sub !== '') $pdf->text($rx + 14, $cy + 56, $sub, 8.5, false, $grey);

    // ---- Quotation title
    $y = $cy + 70 + 30;
    foreach ($pdf->wrap($q['title'], $CW, 13, true) as $line) {
        $pdf->text($M, $y, $line, 13, true, $dark);
        $y += 17;
    }
    $y += 6;

    // ---- Table
    $colQty  = $M + 322;   // centre of qty column
    $colUnit = $M + 420;   // right edge of unit cost
    $colSub  = $R - 14;    // right edge of subtotal
    $descW   = 270;

    $drawHeader = function ($y) use ($pdf, $M, $CW, $dark, $white, $colQty, $colUnit, $colSub) {
        $pdf->rect($M, $y, $CW, 30, $dark);
        $pdf->text($M + 14, $y + 19, 'ITEM / DESCRIPTION', 7.5, false, $white);
        $pdf->text($colQty, $y + 19, 'QTY', 7.5, false, $white, 'C');
        $pdf->text($colUnit, $y + 19, 'UNIT COST', 7.5, false, $white, 'R');
        $pdf->text($colSub, $y + 19, 'SUBTOTAL', 7.5, false, $white, 'R');
        return $y + 30;
    };

    $y = $drawHeader($y);
    $total = 0;
    $i = 0;
    foreach ($q['items'] as $it) {
        $qty  = (int)$it['qty'];
        $unit = (float)$it['unit_cost'];
        $sub  = $qty * $unit;
        $total += $sub;

        $lines = $pdf->wrap($it['description'], $descW, 9.5);
        $rowH  = max(30, count($lines) * 13 + 16);

        if ($y + $rowH > $H - 200) {      // leave room for total + terms on the last page
            $pdf->newPage();
            $y = $drawHeader(48);
            $i = 0;
        }
        if ($i % 2 === 0) $pdf->rect($M, $y, $CW, $rowH, [248, 247, 243]);
        $ty = $y + 19;
        foreach ($lines as $line) {
            $pdf->text($M + 14, $ty, $line, 9.5, false, $dark);
            $ty += 13;
        }
        $pdf->text($colQty, $y + 19, (string)$qty, 9.5, false, $grey, 'C');
        $pdf->text($colUnit, $y + 19, rand_short($unit), 9.5, false, $grey, 'R');
        $pdf->text($colSub, $y + 19, rand_short($sub), 9.5, true, $dark, 'R');
        $y += $rowH;
        $i++;
    }

    // ---- Total row (use the stored total when it exists so it always matches the screen)
    $grand = (float)$q['amount'] > 0 ? (float)$q['amount'] : $total;
    $pdf->rect($M, $y, $CW, 40, $dark);
    $pdf->text($colUnit, $y + 25, 'TOTAL', 9.5, true, $white, 'R');
    $pdf->text($colSub, $y + 26, rand_short($grand), 14, true, $white, 'R');
    $y += 40 + 22;

    // ---- Payment terms box
    $termLines = $pdf->wrap($q['payment_terms'], $CW - 28, 9.5);
    $boxH = 36 + count($termLines) * 13;
    $pdf->rrect($M, $y, $CW, $boxH, 9, [254, 249, 231]);
    $pdf->text($M + 14, $y + 21, 'Payment Terms', 9.5, true, [180, 83, 9]);
    $ty = $y + 38;
    foreach ($termLines as $line) {
        $pdf->text($M + 14, $ty, $line, 9.5, false, [180, 83, 9]);
        $ty += 13;
    }
    $y += $boxH + 18;

    // ---- 72-hour deposit notice (approved quotations only)
    if (!empty($q['approved_at'])) {
        $deadline = deposit_deadline($q['approved_at']);
        $pdf->text($M, $y, 'Deposit required within 72 hours of approval (by ' . date('d M Y, H:i', $deadline) . ').', 9.5, true, $dark);
    }

    // ---- Footer
    $pdf->hline($M, $R, $H - 52);
    $pdf->text($W / 2, $H - 36, $company . '  |  ' . $place . '  |  info@beesevents.co.za', 7.5, false, $grey, 'C');

    $data = $pdf->render();
    $filename = quote_ref($q['quote_id'], $q['created_at']) . '.pdf';

    while (ob_get_level() > 0) ob_end_clean();
    header('Content-Type: application/pdf');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Content-Length: ' . strlen($data));
    header('Cache-Control: private, max-age=0, must-revalidate');
    echo $data;
    exit;
}
