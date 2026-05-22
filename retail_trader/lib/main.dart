import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';
import 'services/gateway_service.dart';
import 'services/instrument_catalog.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = InstrumentCatalog();
  final gateway = GatewayService(catalog: catalog);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<InstrumentCatalog>.value(value: catalog),
        ChangeNotifierProvider<GatewayService>.value(value: gateway),
      ],
      child: const RetailTraderApp(),
    ),
  );
}

/// Futures workstation demo + optional live TCP link to Python `Server_Side_Mock`.
class RetailTraderApp extends StatelessWidget {
  const RetailTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retail Trader',
      theme: buildTraderTheme(),
      home: const TraderShell(),
    );
  }
}
