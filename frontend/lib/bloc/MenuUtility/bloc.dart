import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/menu_model.dart';
import '../../services/apiServicesMenu.dart';
import 'event.dart';
import 'state.dart';

class MenusBloc extends Bloc<MenusEvents, MenusState> {
  MenusBloc() : super(MenusInitial()) {
    on<FetchMenus>(_onFetchMenus);
    on<AddMenus>(_onAddMenus);
    on<AddMenuItem>(_onAddMenuItem);
    on<DeleteMenus>(_onDeleteMenus);
    on<DeleteMenuItem>(_onDeleteMenuItem); // Added handler for DeleteMenuItem
  }

  final ApiServiceMenus apiService = ApiServiceMenus();

  Future<void> _onFetchMenus(
    FetchMenus event,
    Emitter<MenusState> emit,
  ) async {
    emit(MenusLoading());
    try {
      final List<MenuModel> menus = await apiService.getMenuModel();
      emit(MenusLoaded(menus));
    } catch (e) {
      emit(MenusError('Failed to load menus: $e'));
    }
  }

  Future<void> _onAddMenus(
    AddMenus event,
    Emitter<MenusState> emit,
  ) async {
    emit(MenusLoading());
    try {
      await apiService.addMenu(event.menuName, event.menuType);
      final List<MenuModel> menus = await apiService.getMenuModel();
      emit(MenusLoaded(menus));
    } catch (e) {
      emit(MenusError('Failed to add menu: $e'));
    }
  }

  Future<void> _onAddMenuItem(
    AddMenuItem event,
    Emitter<MenusState> emit,
  ) async {
    emit(MenusLoading());
    try {
      await apiService.addMenuItem(
          event.menuName, event.itemName, event.price, event.menuType);
      final List<MenuModel> menus = await apiService.getMenuModel();
      emit(MenusLoaded(menus));
    } catch (e) {
      emit(MenusError('Failed to add menu item: $e'));
    }
  }

  Future<void> _onDeleteMenus(
    DeleteMenus event,
    Emitter<MenusState> emit,
  ) async {
    emit(MenusLoading());
    try {
      await apiService.deleteMenu(event.menuName);
      final List<MenuModel> menus = await apiService.getMenuModel();
      emit(MenusLoaded(menus));
    } catch (e) {
      emit(MenusError("Failed to delete menu: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteMenuItem(
    DeleteMenuItem event,
    Emitter<MenusState> emit,
  ) async {
    emit(MenusLoading());
    try {
      await apiService.deleteMenuItem(event.menuName, event.itemName);
      final List<MenuModel> menus = await apiService.getMenuModel();
      emit(MenusLoaded(menus));
    } catch (e) {
      emit(MenusError("Failed to delete menu item: ${e.toString()}"));
    }
  }
}
