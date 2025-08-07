import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      print('Connectivity changed: $result');
      _verifyConnectionAndShowDialog();
    });

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
    // List of endpoints to try
    final endpoints = [
      'https://jsonplaceholder.typicode.com/todos/1',
      'https://api.github.com',
      'https://www.cloudflare.com/cdn-cgi/trace',
    ];

    // Use a longer timeout for mobile devices
    const timeout = Duration(seconds: kIsWeb ? 3 : 5);

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(Uri.parse(endpoint)).timeout(timeout);
        print('Internet check response for $endpoint: ${response.statusCode}');
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        print('Internet check failed for $endpoint: $e');
      }
    }

    // Fallback: If all endpoints fail, check connectivity result
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasNetwork = !connectivityResult.contains(ConnectivityResult.none);
    print('Fallback connectivity check: $hasNetwork');
    return hasNetwork && kIsWeb; // Trust navigator.onLine for web, but not mobile
  }

  Future<void> _verifyConnectionAndShowDialog() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    print('Current connectivity: $connectivityResult');

    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!_dialogShown) {
        _showNoInternetDialog();
      }
      return;
    }

    final isOnline = await _hasRealInternetConnection();
    if (!isOnline && !_dialogShown) {
      _showNoInternetDialog();
    } else if (isOnline && _dialogShown) {
      if (mounted && Navigator.canPop(context)) {
        print('Dismissing no internet dialog');
        Navigator.of(context, rootNavigator: true).pop();
        _dialogShown = false;
      }
    }
  }

  void _showNoInternetDialog() {
    print('Showing no internet dialog');
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
              print('Retry button pressed');
              final isOnline = await _hasRealInternetConnection();
              if (isOnline && mounted && Navigator.canPop(context)) {
                print('Internet restored, dismissing dialog');
                Navigator.of(context, rootNavigator: true).pop();
                _dialogShown = false;
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
