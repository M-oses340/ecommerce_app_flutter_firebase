import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initConnectivity();
    _monitorConnection();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final connected = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);
      _isOnline = connected;
      notifyListeners();
    } catch (e) {
      debugPrint("Connectivity init error: $e");
    }
  }

  void _monitorConnection() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final connected = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);
       debugPrint('📶 Connectivity changed: $results (isOnline: $connected)');
      if (connected != _isOnline) {
        _isOnline = connected;
        notifyListeners();
      }
    });
  }

  Future<void> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    final connected = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    if (connected != _isOnline) {
      _isOnline = connected;
      notifyListeners();
    }
  }
}
