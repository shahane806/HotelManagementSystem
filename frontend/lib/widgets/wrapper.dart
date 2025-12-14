import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/AmenitiesUtility/bloc.dart';
import '../bloc/MenuUtility/bloc.dart';
import '../bloc/RoomUtility/bloc.dart';
import '../bloc/TableUtility/bloc.dart';
Widget wrapper(Widget child) {
  return MultiBlocProvider(providers: [
    BlocProvider(create: (_) => AmenitiesBloc()),
    BlocProvider(create: (_) => MenusBloc()),
    BlocProvider(create: (_) => TablesBloc()),
    BlocProvider(create: (_) => RoomsBloc()),
    // BlocProvider(create: (_) => OrdersBloc(repository: InMemoryOrderRepository())),
    // BlocProvider(create: (_) => CustomerBloc()),
    // BlocProvider(create: (_) => BillBloc()),
    // BlocProvider(create: (_) => StaffBloc()),
  ], child: child);
}
