abstract class BillEvent {}

class FetchBills extends BillEvent {}

class AddBill extends BillEvent {
  final Map<String, dynamic> bill;
  AddBill(this.bill);
}

class UpdateBill extends BillEvent {
  final String billId;
  final String status;
  final String? paymentMethod;
  UpdateBill(this.billId, this.status, {this.paymentMethod});
}