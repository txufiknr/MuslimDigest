import 'package:muslimdigest/services/api.dart';

Future<bool> markRead(String clusterId) async {
  final response = await ApiService.post('history', {'clusterId': clusterId});
  return response.successful;
}

Future<bool> like(String clusterId, bool value) async {
  final response = await ApiService.post('like', {'cluster_id': clusterId, 'value': value});
  return response.successful;
}

Future<bool> save(String clusterId, bool value) async {
  final response = await ApiService.post('save', {'cluster_id': clusterId, 'value': value});
  return response.successful;
}