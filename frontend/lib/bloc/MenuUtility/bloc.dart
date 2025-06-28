import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/apiServicesMenu.dart';
import 'event.dart';
import 'state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  ApiServicesMenu apiService = ApiServicesMenu();

  MenuBloc() : super(MenuInitial()) {
    on<FetchMenu>(_onFetchMenu);
    on<AddMenuItem>(_onAddMenu);
    on<DeleteMenuItem>(_onDeleteMenu);
  }
  Future<void> _onFetchMenu(FetchMenu event, Emitter<MenuState> emit) async {

    emit(MenuLoading());

    try {
      final menus = await apiService.getMenuModel();

      emit(MenuLoaded(menus));
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  Future<void> _onAddMenu(AddMenuItem event, Emitter<MenuState> emit) async {
    if (state is MenuLoaded) {
      try {
        await apiService.addMenuItem(event.item);
        add(FetchMenu());
      } catch (e) {
        emit(MenuError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteMenu(DeleteMenuItem event, Emitter<MenuState> emit) async {
    if (state is MenuLoaded) {
      try {
        await apiService.deleteMenuItem(event.item);
        add(FetchMenu());
      } catch (e) {
        emit(MenuError(e.toString()));
      }
    }
  }
}