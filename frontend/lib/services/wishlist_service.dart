import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<Category> createCategory(String name, String icon) async {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final response = await _dio.post(
      ApiConfig.categories,
      data: {'name': name, 'icon': icon, 'slug': slug},
      options: await _authOptions(),
    );
    return Category.fromJson(response.data);
  }

  Future<WishlistItem> createItem(WishlistItem item) async {
    final response = await _dio.post(
      ApiConfig.items,
      data: item.toJson(),
      options: await _authOptions(),
    );
    return WishlistItem.fromJson(response.data);
  }

  Future<WishlistItem> updateStatus(String id, ItemStatus status) async {
    final response = await _dio.patch(
      '${ApiConfig.items}/$id/status',
      queryParameters: {'status': status.name},
      options: await _authOptions(),
    );
    return WishlistItem.fromJson(response.data);
  }

  Future<void> deleteItem(String id) async {
    await _dio.delete('${ApiConfig.items}/$id', options: await _authOptions());
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiConfig.profile, options: await _authOptions());
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({String? username, String? avatarUrl}) async {
    final response = await _dio.patch(
      ApiConfig.profile,
      data: {
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      options: await _authOptions(),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<bool> hasPartner() async {
    final response = await _dio.get(ApiConfig.inviteStatus, options: await _authOptions());
    return (response.data as Map<String, dynamic>)['hasPartner'] == true;
  }

  Future<Map<String, dynamic>> getCoupleStatus() async {
    final response = await _dio.get(ApiConfig.inviteStatus, options: await _authOptions());
    return response.data as Map<String, dynamic>;
  }

  Future<String> generateInviteToken() async {
    final response = await _dio.post(ApiConfig.inviteGenerate, options: await _authOptions());
    return (response.data as Map<String, dynamic>)['token'] as String;
  }

  Future<void> acceptInvite(String token) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/invite/accept/$token',
      options: await _authOptions(),
    );
  }

  Future<String> uploadImage(XFile imageFile) async {
    // Read bytes directly — avoids Android content URI issues with fromFile()
    final bytes = await imageFile.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
      ),
    });

    final response = await _dio.post(
      ApiConfig.upload,
      data: formData,
      options: await _authOptions(),
    );
    return response.data['url'] as String;
  }
}
