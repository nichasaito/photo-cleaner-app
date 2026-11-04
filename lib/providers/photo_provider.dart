import 'package:flutter/foundation.dart';
import '../models/photo_item.dart';
import '../services/photo_service.dart';

class PhotoProvider with ChangeNotifier {
  List<PhotoItem> _allPhotos = [];
  List<PhotoItem> _trashedPhotos = [];
  List<PhotoItem> _keptPhotos = [];
  
  PhotoItem? _lastActionItem;
  String? _lastActionType;

  List<PhotoItem> get trashedPhotos => _trashedPhotos;
  double get totalMBFreed => _trashedPhotos.fold(0, (sum, item) => sum + item.sizeInMB);

  // ดึงรูปภาพทั้งหมดตอนเริ่มแอป
  Future<void> initPhotos() async {
    final assets = await PhotoService.fetchPhotos();
    _allPhotos = await Future.wait(assets.map((asset) async {
      final file = await asset.file;
      final size = await file?.length() ?? 0;
      return PhotoItem(
        id: asset.id,
        entity: asset,
        sizeInBytes: size,
        createDateTime: asset.createDateSecond != null
            ? DateTime.fromMillisecondsSinceEpoch(asset.createDateSecond! * 1000)
            : DateTime.now(),
      );
    }));
    notifyListeners();
  }

  // Filter & Sort รูปภาพสำหรับแสดงใน Card Swiper
  List<PhotoItem> getFilteredAndSortedPhotos(PhotoCategory category, String sortBy) {
    List<PhotoItem> filtered = _allPhotos.where((p) {
      if (_trashedPhotos.any((t) => t.id == p.id) || _keptPhotos.any((k) => k.id == p.id)) {
        return false;
      }
      if (category == PhotoCategory.all) return true;
      return p.category == category;
    }).toList();

    switch (sortBy) {
      case 'largest':
        filtered.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
        break;
      case 'smallest':
        filtered.sort((a, b) => a.sizeInBytes.compareTo(b.sizeInBytes));
        break;
      case 'newest':
        filtered.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
        break;
    }
    return filtered;
  }

  void trashPhoto(PhotoItem item) {
    _allPhotos.removeWhere((p) => p.id == item.id);
    _trashedPhotos.add(item);
    _lastActionItem = item;
    _lastActionType = 'trash';
    notifyListeners();
  }

  void keepPhoto(PhotoItem item) {
    _allPhotos.removeWhere((p) => p.id == item.id);
    _keptPhotos.add(item);
    _lastActionItem = item;
    _lastActionType = 'keep';
    notifyListeners();
  }

  void undoLastAction() {
    if (_lastActionItem == null) return;
    if (_lastActionType == 'trash') {
      _trashedPhotos.removeWhere((p) => p.id == _lastActionItem!.id);
      _allPhotos.insert(0, _lastActionItem!);
    } else if (_lastActionType == 'keep') {
      _keptPhotos.removeWhere((p) => p.id == _lastActionItem!.id);
      _allPhotos.insert(0, _lastActionItem!);
    }
    _lastActionItem = null;
    _lastActionType = null;
    notifyListeners();
  }

  void restorePhotos(List<String> ids) {
    final toRestore = _trashedPhotos.where((p) => ids.contains(p.id)).toList();
    _trashedPhotos.removeWhere((p) => ids.contains(p.id));
    _allPhotos.addAll(toRestore);
    notifyListeners();
  }

  Future<void> confirmPermanentDelete(List<String> idsToDelete) async {
    final deletedIds = await PhotoService.deletePhotos(idsToDelete);
    _trashedPhotos.removeWhere((item) => deletedIds.contains(item.id));
    notifyListeners();
  }
}