import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/AmenitiesUtility/bloc.dart';
import 'package:frontend/bloc/MenuUtility/bloc.dart';
import 'package:frontend/bloc/OrderBloc/bloc.dart';
import 'package:frontend/bloc/RoomUtility/bloc.dart';
import 'package:frontend/bloc/TableUtility/bloc.dart';
import 'package:frontend/repositories/in_memory_repository.dart';

Widget wrapper(Widget child) {
  return MultiBlocProvider(providers: [
    BlocProvider(create: (_) => AmenitiesBloc()),
    BlocProvider(create: (_) => MenusBloc()),
    BlocProvider(create: (_) => TablesBloc()),
    BlocProvider(create: (_) => RoomsBloc()),
    BlocProvider(create: (_) => OrdersBloc(repository: InMemoryOrderRepository()))
  ], child: child);
}
