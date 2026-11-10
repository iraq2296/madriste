import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  SchoolStage _selectedStage = SchoolStage.preparatory;
  int _selectedGrade = 5;
  String? _selectedSubjectId;
  int _selectedRound = 1; // 1, 2, 3 for ministerial exams

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final store = ref.watch(dataStoreProvider);
    final theme = Theme.of(context);

    final userFavorites = store.favorites[user.id] ?? <String>{};

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('lib.title')),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'الكتب والملازم والملخصات'),
              Tab(text: context.tr('lib.ministerialTitle')),
            ],
          ),
          actions: [
            if (user.role.isTeaching)
              IconButton(
                icon: const Icon(Icons.upload_file_rounded),
                tooltip: context.tr('lib.uploadResource'),
                onPressed: () => _showUploadResourceDialog(context, user, store),
              ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr('lib.searchInPdf'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        )
                      : null,
                ),
              ),
            ),

            // Stage and Grade Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...SchoolStage.values.map((st) {
                    final isSelected = st == _selectedStage;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(context.tr(st.l10nKey)),
                        onSelected: (_) => setState(() {
                          _selectedStage = st;
                          _selectedGrade = st.firstGrade;
                        }),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _selectedGrade,
                    items: _selectedStage.grades
                        .map((g) => DropdownMenuItem(value: g, child: Text('الصف $g')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGrade = v ?? _selectedGrade),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Books & Summaries
                  _buildGeneralLibraryTab(context, user, store, userFavorites),
                  // Tab 2: Iraqi Ministerial Exams (Rounds 1, 2, 3)
                  _buildMinisterialExamsTab(context, user, store, userFavorites),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralLibraryTab(
    BuildContext context,
    AppUser user,
    dynamic store,
    Set<String> userFavorites,
  ) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final items = store.library.where((r) {
      if (r.removedByOwner) return false;
      if (r.stage != _selectedStage) return false;
      if (r.grade != _selectedGrade) return false;
      if (query.isNotEmpty) {
        final inTitle = r.title.toLowerCase().contains(query);
        final inBody = r.extractedText.toLowerCase().contains(query);
        return inTitle || inBody;
      }
      return true;
    }).toList();

    if (items.isEmpty) {
      return const EmptyState(
        title: 'لا توجد مصادر مطابقة لبحثك',
        message: 'جرّب تغيير المرحلة أو البحث بكلمات أخرى.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final res = items[i];
        final isFav = userFavorites.contains(res.id);
        final sub = store.subjectById(res.subjectId);

        return Card(
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            ),
            title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${sub?.name.of(context.language) ?? ""} • ${res.pages} صفحة • ${res.yearLabel}',
            ),
            trailing: IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? AppColors.danger : Colors.grey,
              ),
              tooltip: isFav ? context.tr('lib.removeFromFavorites') : context.tr('lib.addToFavorites'),
              onPressed: () {
                final favs = store.favorites[user.id] ?? <String>{};
                if (isFav) {
                  favs.remove(res.id);
                } else {
                  favs.add(res.id);
                }
                store.favorites[user.id] = favs;
                store.commit();
                setState(() {});
              },
            ),
            onTap: () => _openResourceViewer(context, res.title, res.fileName),
          ),
        );
      },
    );
  }

  Widget _buildMinisterialExamsTab(
    BuildContext context,
    AppUser user,
    dynamic store,
    Set<String> userFavorites,
  ) {
    final items = store.ministerialExams.where((m) {
      if (m.stage != _selectedStage) return false;
      if (m.grade != _selectedGrade) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Rounds selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [1, 2, 3].map((r) {
              final isSelected = r == _selectedRound;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  selected: isSelected,
                  label: Text(context.tr('lib.round', {'n': r})),
                  onSelected: (_) => setState(() => _selectedRound = r),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(title: 'لا توجد أسئلة وزارية لهذه المرحلة بعد')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ex = items[i];
                    final isFav = userFavorites.contains(ex.id);
                    final sub = store.subjectById(ex.subjectId);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: Icon(
                            ex.isImage ? Icons.image_rounded : Icons.description_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          'وزاري ${sub?.name.of(context.language) ?? ""} — عام ${ex.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${context.tr("lib.round", {"n": ex.round})} • ${ex.fileName}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.danger : Colors.grey,
                          ),
                          onPressed: () {
                            final favs = store.favorites[user.id] ?? <String>{};
                            if (isFav) {
                              favs.remove(ex.id);
                            } else {
                              favs.add(ex.id);
                            }
                            store.favorites[user.id] = favs;
                            store.commit();
                            setState(() {});
                          },
                        ),
                        onTap: () => _openResourceViewer(context, '${sub?.name.of(context.language)} ${ex.year}', ex.fileName),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openResourceViewer(BuildContext context, String title, String fileName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 68, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يتم فتح المحتوى وقراءته مباشرة داخل التطبيق دون اشتراط التنزيل الخارجي.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadResourceDialog(BuildContext context, AppUser user, dynamic store) {
    final titleCtrl = TextEditingController();
    final fileCtrl = TextEditingController(text: 'resource.pdf');
    final subjects = store.subjects;
    String selectedSub = user.subjectIds.isNotEmpty ? user.subjectIds.first : subjects.first.id;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('lib.uploadResource')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('lib.uploadSubjectRule'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المصدر التعليمي')),
            const SizedBox(height: 10),
            TextField(controller: fileCtrl, decoration: const InputDecoration(labelText: 'اسم الملف المرفوع')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              store.library.insert(
                0,
                LibraryResource(
                  id: store.newId('lib'),
                  title: titleCtrl.text.trim(),
                  type: ResourceType.booklet,
                  stage: _selectedStage,
                  grade: _selectedGrade,
                  subjectId: selectedSub,
                  yearLabel: '2026–2027',
                  uploaderId: user.id,
                  fileName: fileCtrl.text.trim(),
                  pages: 45,
                ),
              );
              store.commit();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نشر المصدر التعليمي في المكتبة فوراً')),
              );
            },
            child: Text(context.tr('common.publish')),
          ),
        ],
      ),
    );
  }
}
