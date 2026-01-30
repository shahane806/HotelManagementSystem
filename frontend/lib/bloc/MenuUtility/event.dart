import 'package:equatable/equatable.dart';

abstract class MenusEvents extends Equatable {
  const MenusEvents();

  @override
  List<Object?> get props => [];
}

class FetchMenus extends MenusEvents {}

class AddMenus extends MenusEvents {
  final String menuName;
  final String menuType;
  const AddMenus(this.menuName, this.menuType);

  @override
  List<Object?> get props => [menuName, menuType];
}

class AddMenuItem extends MenusEvents {
  final String menuName;
  final String itemName;
  final String price;
  final String menuType;
  const AddMenuItem(
      this.menuName, this.itemName, this.price, result, this.menuType);

  @override
  List<Object?> get props => [menuName, itemName, price, menuType];
}

class DeleteMenus extends MenusEvents {
  final String menuName;

  const DeleteMenus(this.menuName);

  @override
  List<Object?> get props => [menuName];
}

class DeleteMenuItem extends MenusEvents {
  final String menuName;
  final String itemName;

  const DeleteMenuItem(this.menuName, this.itemName);

  @override
  List<Object?> get props => [menuName, itemName];
}
