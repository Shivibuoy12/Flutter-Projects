import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/sample_data.dart';
import 'models/models.dart';
import 'screens/dashboard_workspace.dart';
import 'screens/movers_screener_page.dart';
import 'screens/orders_page.dart';
import 'screens/portfolio_page.dart';
import 'services/gateway_service.dart';
import 'services/instrument_catalog.dart';
import 'theme/trader_colors.dart';
import 'widgets/market_ticker_strip.dart';
import 'widgets/trader_app_bar.dart';

class TraderShell extends StatefulWidget {
  const TraderShell({super.key});

  @override
  State<TraderShell> createState() => _TraderShellState();
}

class _TraderShellState extends State<TraderShell> {
  int _nav = 0;

  /// User-added demo rows while catalog unavailable.
  final List<WatchRow> _manualAdds = [];

  List<NavigationRailDestination> get _railDestinations => const [
        NavigationRailDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: Text('Charts')),
        NavigationRailDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: Text('Markets')),
        NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Orders')),
        NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: Text('Portfolio')),
      ];

  List<BottomNavigationBarItem> get _bottomItems => const [
        BottomNavigationBarItem(icon: Icon(Icons.show_chart_outlined), activeIcon: Icon(Icons.show_chart), label: 'Charts'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Markets'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Portfolio'),
      ];

  List<WatchRow> _composeWatch(BuildContext context) {
    final cat = context.watch<InstrumentCatalog>();
    final base =
        (cat.ready && cat.seedWatchRows.isNotEmpty) ? cat.seedWatchRows : watchDefaults;
    return [...base, ..._manualAdds];
  }

  List<Widget> _gatewayActions(BuildContext context) {
    final gw = context.watch<GatewayService>();
    return [
      IconButton(
        tooltip: gw.connected && gw.loggedIn ? 'Disconnect FMX mock' : 'Connect to FMX mock',
        icon: Icon(
          gw.connected && gw.loggedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: gw.connected && gw.loggedIn ? TraderColors.up : TraderColors.textSecondary,
        ),
        onPressed: () async {
          if (gw.connected) {
            await gw.disconnect(clearRows: false);
          } else {
            await gw.connect();
          }
        },
      ),
      IconButton(
        tooltip: 'Gateway host / port',
        icon: const Icon(Icons.tune),
        onPressed: () => _gatewaySettings(context),
      ),
    ];
  }

  Widget _page(List<WatchRow> watch) {
    switch (_nav) {
      case 0:
        return DashboardWorkspace(watchlist: watch);
      case 1:
        return MoversScreenerPage(watchlist: watch);
      case 2:
        return const OrdersPage();
      case 3:
        return const PortfolioPage();
      default:
        return DashboardWorkspace(watchlist: watch);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<InstrumentCatalog>().loadFromAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final watch = _composeWatch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final body = AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _page(watch),
        );

        Widget content;
        if (useRail) {
          content = Row(
            children: [
              NavigationRail(
                backgroundColor: TraderColors.surface,
                selectedIndex: _nav,
                onDestinationSelected: (i) => setState(() => _nav = i),
                extended: constraints.maxWidth > 1180,
                labelType: constraints.maxWidth > 1180 ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                minWidth: 72,
                minExtendedWidth: 180,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: FloatingActionButton.small(
                    heroTag: 'watchlist',
                    elevation: 0,
                    backgroundColor: TraderColors.accent,
                    foregroundColor: Colors.white,
                    onPressed: () => _quickAddSheet(context),
                    child: const Icon(Icons.add_chart),
                  ),
                ),
                destinations: _railDestinations,
              ),
              const VerticalDivider(width: 1, thickness: 0.5),
              Expanded(
                child: Column(
                  children: [
                    TraderAppBar(extraActions: _gatewayActions(context)),
                    MarketTickerStrip(quotes: kIndexStrip),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          );
        } else {
          content = Column(
            children: [
              TraderAppBar(extraActions: _gatewayActions(context)),
              MarketTickerStrip(quotes: kIndexStrip),
              Expanded(child: body),
              NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: TraderColors.accent.withValues(alpha: 0.28),
                  backgroundColor: TraderColors.surface,
                  labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  iconTheme: WidgetStateProperty.resolveWith(
                    (s) => IconThemeData(
                      color: s.contains(WidgetState.selected) ? TraderColors.accent : TraderColors.textSecondary,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _nav,
                  onDestinationSelected: (i) => setState(() => _nav = i),
                  destinations: [
                    for (final b in _bottomItems)
                      NavigationDestination(icon: b.icon, selectedIcon: b.activeIcon, label: b.label!),
                  ],
                ),
              ),
            ],
          );
        }

        return Scaffold(backgroundColor: TraderColors.scaffold, body: SafeArea(top: false, child: content));
      },
    );
  }

  void _gatewaySettings(BuildContext context) {
    final gw = context.read<GatewayService>();
    final host = TextEditingController(text: gw.host);
    final port = TextEditingController(text: gw.port.toString());
    final user = TextEditingController(text: gw.username);
    final pass = TextEditingController(text: gw.password);
    final session = TextEditingController(text: gw.session);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FMX mock (TCP)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: host, decoration: const InputDecoration(labelText: 'Host')),
              TextField(controller: port, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
              TextField(controller: user, decoration: const InputDecoration(labelText: 'User (8 chars ok)')),
              TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: session, decoration: const InputDecoration(labelText: 'Session (10 chars ok)')),
              const SizedBox(height: 14),
              const Divider(),
              const Text(
                'Protocol probes — requires an open TCP socket (tap Connect first).',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => gw.sendWireLoginFrame(),
                    child: const Text('Login replay (seq)'),
                  ),
                  OutlinedButton(
                    onPressed: gw.sendMisalignedSeqLoginProbe,
                    child: const Text('Login (bad seq)'),
                  ),
                  OutlinedButton(
                    onPressed: gw.sendHeartbeatNow,
                    child: const Text('Heartbeat R'),
                  ),
                  OutlinedButton(
                    onPressed: gw.sendAccountRequestProbe,
                    child: const Text('Account req T'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              gw.host = host.text.trim().isEmpty ? gw.host : host.text.trim();
              gw.port = int.tryParse(port.text.trim()) ?? gw.port;
              gw.username = user.text.trim().isEmpty ? gw.username : user.text.trim();
              gw.password = pass.text.trim().isEmpty ? gw.password : pass.text.trim();
              gw.session = session.text.trim().isEmpty ? gw.session : session.text.trim();
              gw.origTrader8 = gw.username.padRight(8).substring(0, 8);
              Navigator.pop(ctx);
              gw.notifyGatewayConfigChanged();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _quickAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TraderColors.surface,
      builder: (ctx) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.paddingOf(ctx).bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add to watchlist (demo)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Symbol'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final s = controller.text.trim().toUpperCase();
                  if (s.isEmpty) return;
                  final row = WatchRow(symbol: s, name: '$s Holdings', last: 100 + s.length * 1.73, changePct: (_nav % 2 == 0) ? 0.42 : -0.33, volM: 12.8);
                  setState(() {
                    _manualAdds.add(row);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
}
