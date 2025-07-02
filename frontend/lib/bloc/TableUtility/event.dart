import 'package:equatable/equatable.dart';

abstract class TablesEvents extends Equatable {
  const TablesEvents();

  @override
  List<Object?> get props => [];
}

class FetchTables extends TablesEvents {
  // Triggers fetching all table utilities from the API
}

class AddTableItem extends TablesEvents {
  final String utilityId;
  final String name;
  final int count;

  const AddTableItem(this.utilityId, this.name, this.count);

  @override
  List<Object?> get props => [utilityId, name, count];
}

class DeleteTableItem extends TablesEvents {
  final String utilityId;
  final String itemName;

  const DeleteTableItem(this.utilityId, this.itemName);

  @override
  List<Object?> get props => [utilityId, itemName];
}