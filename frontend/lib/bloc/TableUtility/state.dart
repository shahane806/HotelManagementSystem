import 'package:equatable/equatable.dart';
import '../../models/table_model.dart';

abstract class TablesState extends Equatable {
  const TablesState();

  @override
  List<Object?> get props => [];
}

class TablesInitial extends TablesState {
  // Initial state before any table operations
}

class TablesLoading extends TablesState {
  // Loading state for fetch, add, or delete operations
}

class TablesLoaded extends TablesState {
  final List<TableModel> tables;

  const TablesLoaded(this.tables);

  // Displays the updated list of table utilities and their items
  @override
  List<Object?> get props => [tables];
}

class TablesError extends TablesState {
  final String message;

  const TablesError(this.message);

  // Displays errors from table or table item operations
  @override
  List<Object?> get props => [message];
}