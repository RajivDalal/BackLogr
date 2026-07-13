import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/schema.dart';
import 'database/supabase_connector.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'debug_screen.dart';

// Global reference to the database to use anywhere in your app
late final PowerSyncDatabase db;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 1. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // 2. Find a safe place to store the SQLite file on Linux/Android
  final dir = await getApplicationDocumentsDirectory();
  final path = join(dir.path, 'media_tracker.db');

  // 3. Initialize PowerSync
  db = PowerSyncDatabase(schema: schema, path: path);
  await db.initialize();

  // 4. Connect PowerSync to Supabase
  final connector = SupabaseConnector(Supabase.instance.client);
  db.connect(connector: connector);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BackLogr',
      home: const DebugScreen(),
    );
  }
}
