import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../domain/entities/history_entry.dart';
import '../domain/repositories/history_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchCtrl = TextEditingController();
  List<HistoryItem> _items = [];
  bool _loading = true;
  bool _showBookmarkedOnly = false;

  HistoryRepository get _repo => GetIt.I<HistoryRepository>();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? query}) async {
    var items = await _repo.getAll(query: query);
    if (_showBookmarkedOnly) items = items.where((e) => e.isBookmarked).toList();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  void _onSearch() => _load(query: _searchCtrl.text);

  Future<void> _toggleBookmark(HistoryItem item) async {
    await _repo.setBookmark(item.id, bookmarked: !item.isBookmarked);
    await _load(query: _searchCtrl.text);
  }

  Future<void> _delete(HistoryItem item) async {
    await _repo.delete(item.id);
    await _load(query: _searchCtrl.text);
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text(
            'This will permanently delete all history records including bookmarks.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete all')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteAll();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('History'),
        actions: [
          IconButton(
            icon: Icon(
              _showBookmarkedOnly ? Icons.star : Icons.star_border,
              size: 18,
              color: _showBookmarkedOnly
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => setState(() {
              _showBookmarkedOnly = !_showBookmarkedOnly;
              _load(query: _searchCtrl.text);
            }),
            tooltip: _showBookmarkedOnly ? 'Show all' : 'Starred only',
          ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              onPressed: _confirmDeleteAll,
              tooltip: 'Delete all',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _emptyState(scheme)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (ctx, i) =>
                            _HistoryTile(
                              item: _items[i],
                              onBookmark: () => _toggleBookmark(_items[i]),
                              onDelete: () => _delete(_items[i]),
                            ),
                      ),
          ),
          _hint(scheme),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 40,
                color: scheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'No history yet.\nSelect any text to start.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );

  Widget _hint(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text(
          'Unstarred records are automatically deleted after 30 days.',
          style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.35)),
        ),
      );
}

class _HistoryTile extends StatefulWidget {
  const _HistoryTile({
    required this.item,
    required this.onBookmark,
    required this.onDelete,
  });

  final HistoryItem item;
  final VoidCallback onBookmark;
  final VoidCallback onDelete;

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  static final _dateFmt = DateFormat('MM/dd');
  static final _timeFmt = DateFormat('HH:mm');

  static const _langNames = {
    'auto': 'Auto',
    'en': 'EN',
    'zh-TW': '繁中',
    'zh-CN': '簡中',
    'ja': 'JP',
    'ko': 'KR',
    'fr': 'FR',
    'de': 'DE',
    'es': 'ES',
  };

  static String _langLabel(String code) => _langNames[code] ?? code;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today ${_timeFmt.format(dt)}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dateFmt.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onBookmark,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  item.isBookmarked ? Icons.star : Icons.star_border,
                  size: 18,
                  color: item.isBookmarked
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.sourceText,
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.translated,
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.65)),
                  ),
                  if (item.aiResult != null && item.aiResult!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.aiResult!,
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: scheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    '${_langLabel(item.sourceLang)} → ${_langLabel(item.targetLang)}  ·  ${_formatDate(item.createdAt)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onDelete,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: Icon(Icons.close,
                    size: 14,
                    color: scheme.onSurface.withValues(alpha: 0.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
