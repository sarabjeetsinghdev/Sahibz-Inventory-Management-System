// ignore_for_file: constant_identifier_names

enum PaymentMethodPurchase {
  cash('Cash'),
  banktransfer('Bank Transfer'),
  debitcard('Debit Card'),
  creditcard('Credit Card'),
  other('Other');
  
  const PaymentMethodPurchase(this.name);
  final String name;
}

enum PaymentMethodSale {
  cash('Cash'),
  banktransfer('Bank Transfer'),
  debitcard('Debit Card'),
  creditcard('Credit Card'),
  other('Other');
  
  const PaymentMethodSale(this.name);
  final String name;
}
