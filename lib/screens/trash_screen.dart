import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final Set<String> _selectedIds = {};

  void _toggleSelectAll(List<PhotoItem> trashedPhotos) {
    setState(() {
      if (_selectedIds.length == trashedPhotos.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(trashedPhotos.map((p) => p.id));
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final trashedPhotos = provider.trashedPhotos;
    final isAllSelected = trashedPhotos.isNotEmpty && _selectedIds.length == trashedPhotos.length;

    final totalTrashMB = trashedPhotos.fold<double>(0, (sum, item) => sum + item.sizeInMB);
    final selectedMB = trashedPhotos
        .where((item) => _selectedIds.contains(item.id))
        .fold<double>(0, (sum, item) => sum + item.sizeInMB);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ถังขยะ (Trash Bin)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'เตรียมเคลียร์พื้นที่คืน ${totalTrashMB.toStringAsFixed(1)} MB',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (trashedPhotos.isNotEmpty)
            TextButton(
              onPressed: () => _toggleSelectAll(trashedPhotos),
              child: Text(
                isAllSelected ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: trashedPhotos.isEmpty
          ? _buildEmptyTrashState()
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เลือกอยู่: ${_selectedIds.length} รายการ (${selectedMB.toStringAsFixed(1)} MB)',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'ทั้งหมด ${trashedPhotos.length} รูป',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: trashedPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = trashedPhotos[index];
                      final isSelected = _selectedIds.contains(photo.id);

                      return GestureDetector(
                        onTap: () => _toggleSelect(photo.id),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AssetEntityImage(
                                photo.entity,
                                isOriginal: false,
                                fit: BoxFit.cover,
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                color: isSelected
                                    ? Colors.blueAccent.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.1),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Text(
                                  photo.sizeInMB >= 1
                                      ? '${photo.sizeInMB.toStringAsFixed(1)} MB'
                                      : '${(photo.sizeInBytes / 1024).toStringAsFixed(0)} KB',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.blueAccent : Colors.black38,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: isSelected ? Colors.white : Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomActionBar(context, provider, trashedPhotos),
              ],
            ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, PhotoProvider provider, List<PhotoItem> trashedPhotos) {
    final hasSelection = _selectedIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: hasSelection
                    ? () {
                        final idsToRestore = _selectedIds.toList();
                        provider.restorePhotos(idsToRestore);
                        setState(() => _selectedIds.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('กู้คืนรูปภาพ ${idsToRestore.length} รายการแล้ว'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.restore_rounded, size: 20),
                label: const Text('กู้คืนที่เลือก', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: hasSelection
                    ? () => _confirmDeleteDialog(context, provider)
                    : null,
                icon: const Icon(Icons.delete_forever_rounded, size: 20),
                label: const Text('ลบออกถาวร', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context, PhotoProvider provider) {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบรูปภาพ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'คุณต้องการสั่งลบรูปภาพ $count รายการนี้ออกจากความจำเครื่องจริงหรือไม่? (รูปจะถูกย้ายไปที่ Recently Deleted)',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final idsToDelete = _selectedIds.toList();
              await provider.confirmPermanentDelete(idsToDelete);
              setState(() => _selectedIds.clear());

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ส่งคำสั่งลบไปยังระบบ iOS/Android เรียบร้อยแล้ว'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('ยืนยันลบ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTrashState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_sweep_outlined, size: 80, color: Color(0xFF475569)),
          SizedBox(height: 16),
          Text('ถังขยะว่างเปล่า', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('ไม่มีรูปภาพที่ถูกปัดทิ้งในขณะนี้', style: TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}