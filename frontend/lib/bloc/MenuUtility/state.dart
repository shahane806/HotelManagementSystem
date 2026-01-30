import 'package:equatable/equatable.dart';
import '../../models/menu_model.dart';

abstract class MenusState extends Equatable {
  const MenusState();

  @override
  List<Object?> get props => [];
}

class MenusInitial extends MenusState {
  // Initial state before any menu operations are performed
}

class MenusLoading extends MenusState {
  // Loading state used during fetch, add, delete, or delete item operations
}

class MenusLoaded extends MenusState {
  final List<MenuModel> menus;

  const MenusLoaded(this.menus);

  // Used to display the updated list of menus after fetch, add, delete, or delete item operations
  @override
  List<Object?> get props => [menus];
}

class MenusError extends MenusState {
  final String message;

  const MenusError(this.message);

  // Used to display errors from fetch, add, delete, or delete item operations
  @override
  List<Object?> get props => [message];
}
