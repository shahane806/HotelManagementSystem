import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/services/socketService.dart';
import '../bloc/KitchenBloc/bloc.dart';
import '../bloc/KitchenBloc/event.dart';
import '../bloc/KitchenBloc/state.dart';
import '../widgets/kitchen_widgets.dart';

class KitchenDashboardView extends StatefulWidget {
  const KitchenDashboardView({super.key});

  @override
  State<KitchenDashboardView> createState() => _KitchenDashboardViewState();
}

class _KitchenDashboardViewState extends State<KitchenDashboardView> {
  @override
  void initState() {
    super.initState();

    // Delay attachment + initial load until AFTER the first frame is built
    // This ensures context.read() can find the real BLoC instance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<KitchenDashboardBloc>();

      // Attach the correct bloc instance
      SocketService().attachBloc(bloc);

      // Trigger initial data load
      bloc.add(InitializeDashboard());
    });
  }

  @override
  void dispose() {
    // Optional: You can detach the bloc reference if you have multiple screens
    // SocketService().attachBloc(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return BlocBuilder<KitchenDashboardBloc, KitchenDashboardState>(
      builder: (context, state) {
        final allOrders = state.orders;

        final newOrders =
            allOrders.where((o) => o['status'] != 'Served').toList();

        final filteredOrders = state.selectedStatusFilter == 'All'
            ? allOrders
            : allOrders
                .where((o) => o['status'] == state.selectedStatusFilter)
                .toList();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: buildAppBar(context, screenWidth),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                vertical: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildHeader(context, screenWidth, filteredOrders.length),
                    const SizedBox(height: 20),
                    buildFilterRow(context, screenWidth, isTablet),
                    const SizedBox(height: 20),
                    if (newOrders.isNotEmpty &&
                        state.selectedStatusFilter != 'Served') ...[
                      Text(
                        'New Orders',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildOrdersList(
                        context,
                        newOrders,
                        screenWidth,
                        isTablet,
                        isDesktop,
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      state.selectedStatusFilter == 'All'
                          ? 'All Orders'
                          : '${state.selectedStatusFilter} Orders',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    filteredOrders.isEmpty
                        ? const Center(child: Text("No Orders Yet"))
                        : buildOrdersList(
                            context,
                            filteredOrders,
                            screenWidth,
                            isTablet,
                            isDesktop,
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              "Kitchen Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1565C0),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<KitchenDashboardBloc>().add(RefreshDashboard());
          },
        ),
        if (screenWidth > 600)
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
