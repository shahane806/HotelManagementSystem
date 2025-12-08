import '../../models/user_model.dart';

abstract class StaffEvent {}

class FetchStaff extends StaffEvent {}

class AddStaff extends StaffEvent {
  final UserModel Staff;

  AddStaff(this.Staff);
}

class UpdateStaff extends StaffEvent {
  final UserModel Staff;

  UpdateStaff(this.Staff);
}

class DeleteStaff extends StaffEvent {
  final String id;

  DeleteStaff(this.id);
}