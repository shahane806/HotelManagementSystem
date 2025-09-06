import '../../models/user_model.dart';

abstract class CustomerEvent {}

class FetchCustomers extends CustomerEvent {}

class AddCustomer extends CustomerEvent {
  final UserModel customer;

  AddCustomer(this.customer);
}

class UpdateCustomer extends CustomerEvent {
  final UserModel customer;

  UpdateCustomer(this.customer);
}

class DeleteCustomer extends CustomerEvent {
  final String userId;

  DeleteCustomer(this.userId);
}