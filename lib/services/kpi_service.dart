import 'api_service.dart';
import 'auth_service.dart';

class KpiService {
  static Future<Map<String, dynamic>?> getMyKpi() async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final res = await ApiService.get('/users/${user.id}/kpi');
    if (res.success && res.data != null) {
      return res.data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  static Future<bool> refreshKpi() async {
    final user = AuthService.currentUser;
    if (user == null) return false;

    final res = await ApiService.post('/users/${user.id}/kpi/refresh');
    return res.success;
  }
}
