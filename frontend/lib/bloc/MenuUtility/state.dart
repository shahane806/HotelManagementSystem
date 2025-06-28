import '../../models/menu_model.dart';

abstract class MenuState {}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuModel> menus;
  MenuLoaded(this.menus);
}

class MenuError extends MenuState {
  final String message;
  MenuError(this.message);
}