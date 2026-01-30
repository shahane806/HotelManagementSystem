import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/apiServicesCustomers.dart';

import 'event.dart';
import 'state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc() : super(CustomerInitial()) {
    on<FetchCustomers>(_onFetchCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }
  CustomerApiService apiService = CustomerApiService();
  Future<void> _onFetchCustomers(
      FetchCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      final customers = await apiService.getAllCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onAddCustomer(
      AddCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      await apiService.createCustomer(event.customer);
      final customers = await apiService.getAllCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
      UpdateCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    try {
      await apiService.updateCustomer(event.customer);
      final customers = await apiService.getAllCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
      DeleteCustomer event, Emitter<CustomerState> emit) async {
    print("Event UserId : ${event.id}");

    emit(CustomerLoading());
    try {
      await apiService.deleteCustomer(event.id);
      final customers = await apiService.getAllCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
