import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/table_model.dart';
import '../../services/apiServicesTable.dart';
import 'event.dart';
import 'state.dart';

class TablesBloc extends Bloc<TablesEvents, TablesState> {
  TablesBloc() : super(TablesInitial()) {
    on<FetchTables>(_onFetchTables);
    on<AddTableItem>(_onAddTableItem);
    on<DeleteTableItem>(_onDeleteTableItem);
  }

  final ApiServiceTables apiService = ApiServiceTables();

  Future<void> _onFetchTables(
    FetchTables event,
    Emitter<TablesState> emit,
  ) async {
    emit(TablesLoading());
    try {
      final List<TableModel> tables = await apiService.getTables();
      emit(TablesLoaded(tables));
    } catch (e) {
      emit(TablesError('Failed to load tables: $e'));
    }
  }

  Future<void> _onAddTableItem(
    AddTableItem event,
    Emitter<TablesState> emit,
  ) async {
    emit(TablesLoading());
    try {
      await apiService.addTableItem(event.name, event.count);
      final List<TableModel> tables = await apiService.getTables();
      emit(TablesLoaded(tables));
    } catch (e) {
      emit(TablesError('Failed to add table item: $e'));
    }
  }

  Future<void> _onDeleteTableItem(
    DeleteTableItem event,
    Emitter<TablesState> emit,
  ) async {
    emit(TablesLoading());
    try {
      await apiService.deleteTableItem(event.utilityId, event.itemName);
      final List<TableModel> tables = await apiService.getTables();
      emit(TablesLoaded(tables));
    } catch (e) {
      emit(TablesError('Failed to delete table item: ${e.toString()}'));
    }
  }
}
