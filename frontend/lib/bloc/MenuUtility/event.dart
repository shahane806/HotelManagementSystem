abstract class MenuEvent {}

class FetchMenu extends MenuEvent {}

class AddMenuItem extends MenuEvent {
  final String item;
  AddMenuItem(this.item);
}

class DeleteMenuItem extends MenuEvent {
  final String item;
  DeleteMenuItem(this.item);
}
