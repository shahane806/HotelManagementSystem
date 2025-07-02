import 'package:equatable/equatable.dart';

abstract class MenusEvents extends Equatable {
  const MenusEvents();

  @override
  List<Object?> get props => [];
}

class FetchMenus extends MenusEvents {}

class AddMenus extends MenusEvents {
  final String menuName;
  const AddMenus(this.menuName);

  @override
  List<Object?> get props => [menuName];
}

class AddMenuItem extends MenusEvents {
  final String menuName;
  final String itemName;
  final String price;

  const AddMenuItem(this.menuName, this.itemName, this.price);

  @override
  List<Object?> get props => [menuName, itemName, price];
}

class DeleteMenus extends MenusEvents {
  final String menuName;

  const DeleteMenus(this.menuName);

  @override
  List<Object?> get props => [menuName];
}