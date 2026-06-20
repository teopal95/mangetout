import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/wishlist_item.dart';
import 'auth_service.dart';

class WishlistService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  Future<Options> _authOptions() async {
    final token = await _authService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Category>> getCategories() async {
    final response = await _dio.get(ApiConfig.categories, options: await _authOptions());
    return (response.data as List).map((j) => Category.fromJson(j)).toList();
  }

  Future<List<WishlistItem>> getItems({String? category, String? status}) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      ApiConfig.items,
      queryParameters: queryParams.isEmpty ? null : queryParams,
      options: await _authOptions(),
    );
    return (response.data as List).map((j) => WishlistItem.fromJson(j)).toList();
  }

  Future<WishlistItem> createItem(WishlistItem item) async {
    final response = await _dio.post(
      ApiConfig.items,
      data: item.toJson(),
      options: await _authOptions(),
    );
    return WishlistItem.fromJson(response.data);
  }

  Future<WishlistItem> updateStatus(int id, ItemStatus status) async {
    final response = await _dio.patch(
      '${ApiConfig.items}/$id/status',
      queryParameters: {'status': status.name},
      options: await _authOptions(),
    );
    return WishlistItem.fromJson(response.data);
  }

  Future<void> deleteItem(int id) async {
    await _dio.delete('${ApiConfig.items}/$id', options: await _authOptions());
  }
}
