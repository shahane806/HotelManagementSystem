import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/apiServicesCheckout.dart';
import 'event.dart';
import 'state.dart';

class BillBloc extends Bloc<BillEvent, BillState> {
  BillBloc() : super(BillState(isLoading: true)) {
    on<FetchBills>(_fetchBills);
    on<AddBill>(_addBill);
    on<UpdateBill>(_updateBill);
  }

  Future<void> _fetchBills(FetchBills event, Emitter<BillState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final bills = await Apiservicescheckout.getAllBills();
      emit(state.copyWith(bills: bills, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void _addBill(AddBill event, Emitter<BillState> emit) {
    final newBills = List<Map<String, dynamic>>.from(state.bills)
      ..add(event.bill);
    emit(state.copyWith(bills: newBills));
  }

  void _updateBill(UpdateBill event, Emitter<BillState> emit) {
    final updatedBills = state.bills.map((bill) {
      if (bill['billId'] == event.billId) {
        final updated = {
          ...bill,
          'status': event.status,
          if (event.paymentMethod != null) 'paymentMethod': event.paymentMethod,
          if (event.transaction != null)
            'transaction': event.transaction, // store transaction info
        };
        return updated;
      }
      return bill;
    }).toList();

    // If you want to remove Paid bills from the list, keep this line
    // updatedBills.removeWhere((bill) => bill['status'] == 'Paid');

    emit(state.copyWith(bills: updatedBills));
  }
}
