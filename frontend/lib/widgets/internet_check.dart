import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class InternetCheckWidget extends StatefulWidget {
  final Widget child;

  const InternetCheckWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<InternetCheckWidget> createState() => _InternetCheckWidgetState();
}

class _InternetCheckWidgetState extends State<InternetCheckWidget> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _periodicInternetCheck;

  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initConnectivity());

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      _verifyConnectionAndShowDialog();
    });

    // Also periodically check every 5 seconds in case connection doesn't change
    _periodicInternetCheck = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _verifyConnectionAndShowDialog(),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _periodicInternetCheck?.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    await _verifyConnectionAndShowDialog();
  }

  Future<bool> _hasRealInternetConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _verifyConnectionAndShowDialog() async {
    final isOnline = await _hasRealInternetConnection();

    if (!isOnline && !_dialogShown) {
      _showNoInternetDialog();
    } else if (isOnline && _dialogShown) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
          _dialogShown = false;
        }
      }
    }
  }

  void _showNoInternetDialog() {
    _dialogShown = true;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("No Internet Access"),
        content: const Text(
            "You are connected to a network, but there's no real internet."),
        actions: [
          TextButton(
            onPressed: () async {
              final isOnline = await _hasRealInternetConnection();
              if (isOnline) {
                if (mounted) {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context, rootNavigator: true).pop();
                    _dialogShown = false;
                  }
                }
              }
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
