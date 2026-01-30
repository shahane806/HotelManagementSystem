import '../../models/user_model.dart';

abstract class StaffEvent {}

class FetchStaff extends StaffEvent {}

class AddStaff extends StaffEvent {
  final UserModel staff;

  AddStaff(this.staff);
}

class UpdateStaff extends StaffEvent {
  final UserModel staff;

  UpdateStaff(this.staff);
}

class DeleteStaff extends StaffEvent {
  final String id;

  DeleteStaff(this.id);
}
