import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business.dart';
import '../models/decor_event.dart';
import '../models/decor_item.dart';
import '../models/quote.dart';

/// The client may download the quotation once they have approved it,
/// and for every step after that.
bool canDownloadQuotation(Quote q) => switch (q.status) {
      QuoteStatus.approved ||
      QuoteStatus.depositPaid ||
      QuoteStatus.eventInProgress ||
      QuoteStatus.completed =>
        true,
      _ => false,
    };

/// "QUO-AB12CD34": the first 8 characters of the quote id.
String quoteReference(Quote q) {
  final id = q.id.length > 8 ? q.id.substring(0, 8) : q.id;
  return 'QUO-${id.toUpperCase()}';
}

String quoteFileName(Quote q) => '${quoteReference(q)}.pdf';

const _ink = PdfColor.fromInt(0xFF332923); // espresso
const _line = PdfColor.fromInt(0xFFB8A99A); // taupe
const _soft = PdfColor.fromInt(0xFFF8F5EF); // cream

/// Builds the approved quotation as a PDF. Pure Dart (no Firebase, no
/// network), so it can be tested. Freelancer costs are internal and are
/// never included.
Future<Uint8List> buildQuotePdf(
  Quote q, {
  BusinessProfile? business,
  PaymentDetails? payment,
  DateTime? issuedAt,
}) async {
  final price = q.price;
  final deposit = (price.total * q.depositPercent + 50) ~/ 100;
  final businessName =
      (business?.name ?? '').isEmpty ? 'Decorra' : business!.name;
  final issued = issuedAt ?? DateTime.now();

  pw.TextStyle style({double size = 10, bool bold = false, PdfColor? color}) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? _ink,
      );

  pw.Widget row(String label, String value, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: pw.Text(label, style: style(bold: bold))),
            pw.SizedBox(width: 12),
            pw.Text(value, style: style(bold: bold)),
          ],
        ),
      );

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
        child: pw.Text(text, style: style(size: 12, bold: true)),
      );

  pw.Widget cell(String text,
          {bool right = false, bool bold = false, bool header = false}) =>
      pw.Container(
        alignment:
            right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text, style: style(bold: bold || header)),
      );

  final eventRows = <List<String>>[
    if (q.themeName.isNotEmpty) ['Theme', q.themeName],
    ['Event type', q.eventType],
    ['Date', dateText(q.date)],
    ['Guests', q.guests == 0 ? '-' : '${q.guests}'],
    if (q.venue.isNotEmpty) ['Venue', q.venue],
    if (q.location.isNotEmpty) ['Location', q.location],
    ['Catering', q.catering ? 'Yes' : 'No'],
  ];

  final doc = pw.Document(
    title: 'Quotation ${quoteReference(q)}',
    author: businessName,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: style(size: 8, color: _line),
        ),
      ),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(businessName, style: style(size: 20, bold: true)),
                  if ((business?.address ?? '').isNotEmpty)
                    pw.Text(business!.address, style: style()),
                  if ((business?.email ?? '').isNotEmpty)
                    pw.Text(business!.email, style: style()),
                  if ((business?.phone ?? '').isNotEmpty)
                    pw.Text(business!.phone, style: style()),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('QUOTATION', style: style(size: 18, bold: true)),
                pw.Text(quoteReference(q), style: style(bold: true)),
                pw.Text('Date: ${dateText(issued)}', style: style()),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: _soft,
                    border: pw.Border.all(color: _line),
                  ),
                  child: pw.Text('APPROVED', style: style(size: 9, bold: true)),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(color: _line, height: 28),
        heading('Prepared for'),
        pw.Text(q.clientName, style: style(bold: true)),
        if (q.clientEmail.isNotEmpty) pw.Text(q.clientEmail, style: style()),
        if (q.clientPhone.isNotEmpty) pw.Text(q.clientPhone, style: style()),
        heading('Event details'),
        for (final r in eventRows) row(r[0], r[1]),
        heading('Items'),
        pw.Table(
          border: pw.TableBorder.all(color: _line, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _soft),
              children: [
                cell('Item', header: true),
                cell('Qty', right: true, header: true),
                cell('Unit price', right: true, header: true),
                cell('Total', right: true, header: true),
              ],
            ),
            if (q.lines.isEmpty)
              pw.TableRow(children: [
                cell('No items listed.'),
                cell(''),
                cell(''),
                cell(''),
              ])
            else
              for (final l in q.lines)
                pw.TableRow(children: [
                  cell(l.name),
                  cell('${l.quantity}', right: true),
                  cell(moneyText(l.unitCents), right: true),
                  cell(moneyText(l.lineCents), right: true),
                ]),
          ],
        ),
        heading('Price breakdown'),
        row('Items', moneyText(q.subtotalCents)),
        if (q.transportCents > 0) row('Transport', moneyText(q.transportCents)),
        if (q.workingCents > 0)
          row('Labour / working', moneyText(q.workingCents)),
        if (price.discount > 0)
          row('Discount (${q.discountPercent}%)',
              '-${moneyText(price.discount)}'),
        row('VAT ($vatPercent%)', moneyText(price.vat)),
        pw.Divider(color: _line, height: 16),
        row('Total', moneyText(price.total), bold: true),
        row('Deposit (${q.depositPercent}%)', moneyText(deposit)),
        row('Remaining balance', moneyText(price.total - deposit)),
        if (payment != null && payment.accountNumber.isNotEmpty) ...[
          heading('Pay your deposit'),
          row('Account holder', payment.accountHolder),
          row('Bank', payment.bankName),
          row('Account type', payment.accountType),
          row('Account number', payment.accountNumber),
          if (payment.branchCode.isNotEmpty)
            row('Branch code', payment.branchCode),
          if (payment.reference.isNotEmpty) row('Reference', payment.reference),
        ],
        if (q.notes.isNotEmpty) ...[
          heading('Notes'),
          pw.Text(q.notes, style: style()),
        ],
        pw.SizedBox(height: 24),
        pw.Text(
          'This quotation was approved by the client in the Decorra app.',
          style: style(size: 8, color: _line),
        ),
      ],
    ),
  );

  return doc.save();
}