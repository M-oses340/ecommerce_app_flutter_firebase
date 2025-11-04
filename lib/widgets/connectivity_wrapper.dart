import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/providers/connectivity_provider.dart';

import 'no_internet_widget.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400), // Smooth fade like Jumia
          child: connectivity.isOnline
              ? child
              : NoConnectionScreen(onRetry: connectivity.checkConnection),
        );
      },
    );
  }
}
