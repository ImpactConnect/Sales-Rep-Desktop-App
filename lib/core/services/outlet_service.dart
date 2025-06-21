import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/outlet_model.dart';
import '../constants/app_constants.dart';

class OutletService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<Outlet> getOutletById(String id) async {
    try {
      final response =
          await _supabaseClient.from('outlets').select().eq('id', id).single();
      return Outlet.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch outlet: ${e.toString()}');
    }
  }
}
