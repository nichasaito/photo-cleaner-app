import 'package:photo_manager/photo_manager.dart';

class PhotoService {
  // ขอ สิทธิ์การเข้าถึงรูปภาพในเครื่อง
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  // ดึงรูปภาพจากคลังภาพในเครื่อง
  static Future<List<AssetEntity>> fetchPhotos({int page = 0, int size = 1000}) async {
    final isAuth = await requestPermission();
    if (!isAuth) return [];

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isNotEmpty) {
      return await albums[0].getAssetListPaged(page: page, size: size);
    }
    return [];
  }

  // สั่งลบรูปออกจากเครื่อง (ย้ายเข้า Recently Deleted)
  static Future<List<String>> deletePhotos(List<String> assetIds) async {
    return await PhotoManager.editor.deleteWithIds(assetIds);
  }
}