import '../../models/user_model.dart';

abstract class StaffState {}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<UserModel> staff;

  StaffLoaded(this.staff);
}

class StaffError extends StaffState {
  final String message;

  StaffError(this.message);
}