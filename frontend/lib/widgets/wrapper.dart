import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/AmenitiesUtility/bloc.dart';
import 'package:frontend/bloc/MenuUtility/bloc.dart';
import 'package:frontend/bloc/TableUtility/bloc.dart';

Widget wrapper(Widget child) {
  return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AmenitiesBloc()),
        BlocProvider(create: (_) => MenusBloc()),
        BlocProvider(create: (_) => TablesBloc()),
      ], child: child);
}
