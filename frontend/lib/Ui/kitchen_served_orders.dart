import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/bloc/KitchenBloc/bloc.dart';
import 'package:frontend/bloc/KitchenBloc/state.dart';
import 'package:frontend/widgets/kitchen_widgets.dart';

class KitchenServedOrders extends StatefulWidget {
  const KitchenServedOrders({super.key});

  @override
  State<KitchenServedOrders> createState() => _KitchenServedOrdersState();
}

class _KitchenServedOrdersState extends State<KitchenServedOrders> {
  
  @override
  Widget build(BuildContext context) {
     final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    return  Scaffold(
      body: SingleChildScrollView(
        child: BlocBuilder<KitchenDashboardBloc,KitchenDashboardState>
        (builder: (context,state){
          return  SingleChildScrollView(child: buildOrdersList(context, state.orders, screenWidth, isTablet, isDesktop));
        })),
    );
  }
}