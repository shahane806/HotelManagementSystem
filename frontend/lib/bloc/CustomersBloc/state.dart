import '../../models/user_model.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<UserModel> customers;

  CustomerLoaded(this.customers);
}

class CustomerError extends CustomerState {
  final String message;

  CustomerError(this.message);
}
