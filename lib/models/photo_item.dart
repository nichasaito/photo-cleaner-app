import 'package:photo_manager/photo_manager.dart';

enum PhotoCategory { all, duplicates, screenshots, blurry }

class PhotoItem {
  final String id;
  final AssetEntity entity;
  final int sizeInBytes;
  final DateTime createDateTime;
  final PhotoCategory category;

  PhotoItem({
    required this.id,
    required this.entity,
    required this.sizeInBytes,
    required this.createDateTime,
    this.category = PhotoCategory.all,
  });

  double get sizeInMB => sizeInBytes / (1024 * 1024);
}