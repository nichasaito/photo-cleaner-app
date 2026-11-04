import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_item.dart';
import '../providers/photo_provider.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  PhotoCategory _selectedCategory = PhotoCategory.all;
  String _sortBy = 'largest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().initPhotos();
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = context.watch<PhotoProvider>();
    final photos = photoProvider.getFilteredAndSortedPhotos(_selectedCategory, _sortBy);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context, photoProvider),
            _buildCategoryTabs(),
            _buildSortBar(photos.length),
            Expanded(
              child: photos.isEmpty
                  ? _buildEmptyState(photoProvider)
                  : CardSwiper(
                      controller: _swiperController,
                      cardsCount: photos.length,
                      numberOfCardsDisplayed: photos.length > 1 ? 2 : 1,
                      backCardOffset: const Offset(0, -20),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final photo = photos[previousIndex];
                        if (direction == CardSwiperDirection.left) {
                          photoProvider.trashPhoto(photo);
                          _showUndoToast(context, photo, isTrash: true);
                        } else if (direction == CardSwiperDirection.right) {
                          photoProvider.keepPhoto(photo);
                          _showUndoToast(context, photo, isTrash: false);
                        }
                        return true;
                      },
                      cardBuilder: (context, index, percentX, percentY) {
                        final photo = photos[index];
                        return _buildPhotoCard(photo, percentX);
                      },
                    ),
            ),
            if (photos.isNotEmpty) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, PhotoProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cleaning_services_rounded, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photo Cleaner', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    'เคลียร์ได้แล้ว ${provider.totalMBFreed.toStringAsFixed(1)} MB',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // ปุ่ม Refresh / Load More รูปเพิ่มเติม
              IconButton(
                onPressed: provider.isLoadingMore ? null : () => provider.loadMorePhotos(),
                icon: provider.isLoadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                tooltip: 'ดึงรูปภาพเพิ่มเติม',
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                    ),
                    if (provider.trashedPhotos.isNotEmpty)
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.redAccent,
                        child: Text(
                          '${provider.trashedPhotos.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'type': PhotoCategory.all, 'label': 'ทั้งหมด'},
      {'type': PhotoCategory.duplicates, 'label': 'รูปซ้ำ'},
      {'type': PhotoCategory.screenshots, 'label': 'แคปหน้าจอ'},
      {'type': PhotoCategory.blurry, 'label': 'รูปเบลอ'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['type'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat['label'] as String),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: const Color(0xFF1E293B),
              selectedColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = cat['type'] as PhotoCategory);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('เหลือ $count รูป', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          DropdownButton<String>(
            value: _sortBy,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            icon: const Icon(Icons.sort_rounded, color: Colors.blueAccent, size: 18),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: const [
              DropdownMenuItem(value: 'largest', child: Text('ขนาดใหญ่สุด')),
              DropdownMenuItem(value: 'smallest', child: Text('ขนาดเล็กสุด')),
              DropdownMenuItem(value: 'newest', child: Text('ใหม่ล่าสุด')),
              DropdownMenuItem(value: 'oldest', child: Text('เก่าที่สุด')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _sortBy = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(PhotoItem photo, int percentX) {
    final isLeft = percentX < -20;
    final isRight = percentX > 20;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ใช้ isOriginal: true เพื่อให้ภาพแสดงผลคมชัดสูงเต็มประสิทธิภาพ
          AssetEntityImage(
            photo.entity,
            isOriginal: false,
            thumbnailOption: const ThumbnailOption(
              size: ThumbnailSize(1500, 1500),
              format: ThumbnailFormat.jpeg,
            ),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    photo.sizeInMB >= 1
                        ? '${photo.sizeInMB.toStringAsFixed(1)} MB'
                        : '${(photo.sizeInBytes / 1024).toStringAsFixed(0)} KB',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${photo.createDateTime.day}/${photo.createDateTime.month}/${photo.createDateTime.year}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (isLeft)
            Positioned(
              top: 40, right: 30,
              child: _buildSwipeBadge(label: 'TRASH', color: Colors.redAccent, icon: Icons.delete_outline),
            ),
          if (isRight)
            Positioned(
              top: 40, left: 30,
              child: _buildSwipeBadge(label: 'KEEP', color: const Color(0xFF10B981), icon: Icons.favorite_outline),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeBadge({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.large(
            heroTag: 'trash_btn',
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            elevation: 0,
            shape: const CircleBorder(side: BorderSide(color: Colors.redAccent, width: 2)),
            onPressed: () => _swiperController.swipe(CardSwiperDirection.left),
            child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 36),
          ),
          const SizedBox(width: 40),
          FloatingActionButton.large(
            heroTag: 'keep_btn',
            backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
            elevation: 0,
            shape: const CircleBorder(side: BorderSide(color: Color(0xFF10B981), width: 2)),
            onPressed: () => _swiperController.swipe(CardSwiperDirection.right),
            child: const Icon(Icons.favorite_rounded, color: Color(0xFF10B981), size: 36),
          ),
        ],
      ),
    );
  }

  void _showUndoToast(BuildContext context, PhotoItem photo, {required bool isTrash}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(isTrash ? Icons.delete_outline : Icons.check_circle_outline,
                 color: isTrash ? Colors.redAccent : const Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isTrash ? 'ย้ายลงถังขยะเรียบร้อย' : 'เก็บรูปไว้แล้ว',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<PhotoProvider>().undoLastAction();
                _swiperController.undo();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text('UNDO', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PhotoProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 80, color: Color(0xFF34D399)),
          const SizedBox(height: 16),
          const Text('จัดการรูปชุดนี้ครบแล้ว!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('คลังภาพของคุณสะอาดขึ้นเยอะเลย', style: TextStyle(color: Color(0xFF94A3B8))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: provider.isLoadingMore ? null : () => provider.loadMorePhotos(),
            icon: provider.isLoadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            label: Text(
              provider.isLoadingMore ? 'กำลังดึงรูปภาพ...' : 'ดึงรูปภาพเพิ่มอีก 200 รูป',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}