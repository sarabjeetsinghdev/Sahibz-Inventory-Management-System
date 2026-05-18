// ignore_for_file: constant_identifier_names

enum PaymentMethodPurchase {
  cash('Cash'),
  debitcard('Debit Card'),
  creditcard('Credit Card'),
  other('Other');
  
  const PaymentMethodPurchase(this.name);
  final String name;
}
