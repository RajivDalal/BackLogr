import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient supabase;

  SupabaseConnector(this.supabase);

  // 1. Fetch the Auth Token so PowerSync can download data
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final token = session.accessToken;

    return PowerSyncCredentials(
      endpoint: dotenv.env['POWERSYNC_URL']!,
      token: token,
    );
  }

  // 2. Upload local changes to Supabase
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (var op in transaction.crud) {
        final table = supabase.from(op.table);
        if (op.op == UpdateType.put) {
          await table.upsert({'id': op.id, ...op.opData!});
        } else if (op.op == UpdateType.patch) {
          await table.update(op.opData!).eq('id', op.id);
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }
      }
      await transaction.complete();
    } catch (e) {
      // If a network error occurs, PowerSync will automatically retry later
      print('Upload error: $e');
    }
  }
}
