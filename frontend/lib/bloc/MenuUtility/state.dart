import 'package:equatable/equatable.dart';
import '../../models/menu_model.dart';

abstract class MenusState extends Equatable {
  const MenusState();

  @override
  List<Object?> get props => [];
}

class MenusInitial extends MenusState {}

class MenusLoading extends MenusState {}

class MenusLoaded extends MenusState {
  final List<MenuModel> menus;

  const MenusLoaded(this.menus);

  @override
  List<Object?> get props => [menus];
}

class MenusError extends MenusState {
  final String message;

  const MenusError(this.message);

  @override
  List<Object?> get props => [message];
}