import 'package:cloud_firestore/cloud_firestore.dart';

const accountTypes = ['Cheque', 'Savings', 'Current'];

class BusinessProfile {
  const BusinessProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.about = '',
    this.logoUrl,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String about;
  final String? logoUrl;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'about': about,
        'logoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static BusinessProfile fromMap(Map<String, dynamic> d) => BusinessProfile(
        name: d['name'] as String? ?? '',
        email: d['email'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        address: d['address'] as String? ?? '',
        about: d['about'] as String? ?? '',
        logoUrl: d['logoUrl'] as String?,
      );
}

class PaymentDetails {
  const PaymentDetails({
    this.accountHolder = '',
    this.bankName = '',
    this.accountType = 'Cheque',
    this.accountNumber = '',
    this.branchCode = '',
    this.reference = '',
    this.depositPercent = 40,
  });

  final String accountHolder;
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String branchCode;
  final String reference;
  final int depositPercent;

  Map<String, dynamic> toMap() => {
        'accountHolder': accountHolder,
        'bankName': bankName,
        'accountType': accountType,
        'accountNumber': accountNumber,
        'branchCode': branchCode,
        'reference': reference,
        'depositPercent': depositPercent,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static PaymentDetails fromMap(Map<String, dynamic> d) => PaymentDetails(
        accountHolder: d['accountHolder'] as String? ?? '',
        bankName: d['bankName'] as String? ?? '',
        accountType: d['accountType'] as String? ?? 'Cheque',
        accountNumber: d['accountNumber'] as String? ?? '',
        branchCode: d['branchCode'] as String? ?? '',
        reference: d['reference'] as String? ?? '',
        depositPercent: (d['depositPercent'] as num?)?.toInt() ?? 40,
      );
}