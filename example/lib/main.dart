import 'package:flutter/material.dart';
import 'package:encore_flutter_sdk/encore_flutter_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encore Flutter Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Not configured';

  @override
  void initState() {
    super.initState();
    _initEncore();
  }

  Future<void> _initEncore() async {
    await Encore.shared.configure(
      apiKey: 'pk_live_1ran4aj5ike2s201z28r5j76',
      logLevel: LogLevel.debug,
    );

    Encore.shared.onPurchaseComplete((result, productId) {
      debugPrint('Purchase complete: $productId (token: ${result.purchaseToken})');
      if (mounted) {
        setState(() => _status = 'Purchased: $productId');
      }
    });

    Encore.shared.onPassthrough((placementId) {
      debugPrint('Passthrough for placement: $placementId');
    });

    await Encore.shared.identify(
      userId: 'example_user_123',
      attributes: const UserAttributes(
        email: 'user@example.com',
        subscriptionTier: 'premium',
      ),
    );

    setState(() => _status = 'Configured & identified');
  }

  Future<void> _showOffer() async {
    setState(() => _status = 'Presenting offer...');
    final result = await Encore.shared.placement('example_placement').show();

    final message = switch (result) {
      PresentationResultGranted() => 'Offer granted!',
      PresentationResultNotGranted(:final reason) => 'Not granted: $reason',
    };

    if (mounted) setState(() => _status = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encore Flutter Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _showOffer,
              child: const Text('Show Offer'),
            ),
          ],
        ),
      ),
    );
  }
}
