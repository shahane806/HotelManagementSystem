import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/KitchenBloc/bloc.dart';
import 'package:frontend/services/apiServicesRoom.dart';
import 'package:frontend/services/socketService.dart';
import '../bloc/AmenitiesUtility/bloc.dart';
import '../bloc/BillBloc/bloc.dart';
import '../bloc/CustomersBloc/bloc.dart';
import '../bloc/MenuUtility/bloc.dart';
import '../bloc/OrderBloc/bloc.dart';
import '../bloc/RoomUtility/bloc.dart';
import '../bloc/RoomsBloc/bloc.dart';
import '../bloc/StaffBloc/bloc.dart';
import '../bloc/TableUtility/bloc.dart';
import '../repositories/in_memory_repository.dart';

Widget wrapper(Widget child) {
  return MultiBlocProvider(providers: [
    BlocProvider(create: (_) => AmenitiesBloc()),
    BlocProvider(create: (_) => MenusBloc()),
    BlocProvider(create: (_) => TablesBloc()),
    BlocProvider(create: (_) => RoomsBloc()),
    BlocProvider(
        create: (_) => OrdersBloc(repository: InMemoryOrderRepository())),
    BlocProvider(create: (_) => CustomerBloc()),
    BlocProvider(create: (_) => BillBloc()),
    BlocProvider(create: (_) => StaffBloc()),
    BlocProvider(create: (_) => RoomBloc(ApiServiceRooms())),
    BlocProvider(create: (_) => KitchenDashboardBloc(SocketService()))
  ], child: child);
}
