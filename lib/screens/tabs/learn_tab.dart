import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/services/education_service.dart';
import 'package:herlife/services/profile_service.dart';
import 'package:herlife/models/api_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  String _tag = 'All';
  String _query = '';
  bool _isLoading = true;
  List<EducationResponse> _articles = [];
  String? _userLifecycleStage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Get active lifecycle stage from ProfileService or SharedPreferences
    final profile = await ProfileService.getProfile();
    final prefs = await SharedPreferences.getInstance();
    final stage = profile?.lifecycleStage ?? prefs.getString('lifecycle_stage');

    _userLifecycleStage = stage;

    // Fetch lifecycle-aware articles from backend
    final fetched = await EducationService.getArticles(lifecycleStage: stage);

    if (!mounted) return;
    setState(() {
      _articles = fetched;
      _isLoading = false;
    });
  }

  IconData _getIconForArticle(EducationResponse article) {
    final cat = article.category.toLowerCase();
    if (cat.contains('cycle')) return Icons.loop;
    if (cat.contains('symptom')) return Icons.healing_outlined;
    if (article.title.toLowerCase().contains('perimenopause') ||
        article.title.toLowerCase().contains('menopause')) {
      return Icons.timelapse;
    }
    return Icons.spa_outlined;
  }

  void _openArticle(EducationResponse article) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kWine,
                ),
              ),
              const SizedBox(height: 8),
              if (article.category.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBlush,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(fontSize: 12, color: kWine, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (article.summary != null && article.summary!.isNotEmpty) ...[
                Text(
                  article.summary!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                article.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (article.sourceName != null && article.sourceName!.isNotEmpty) ...[
                Text(
                  'Source: ${article.sourceName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              const SizedBox(height: 4),
              const Text(
                'Information only, not a diagnosis',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _articles.where((art) {
      final tagOk = _tag == 'All' || art.category.toLowerCase() == _tag.toLowerCase();
      final q = _query.toLowerCase();
      final queryOk = q.isEmpty ||
          art.title.toLowerCase().contains(q) ||
          (art.summary != null && art.summary!.toLowerCase().contains(q));
      return tagOk && queryOk;
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ScreenTitle('Learn'),
                  if (_userLifecycleStage != null && _userLifecycleStage!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kBlush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _userLifecycleStage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kWine,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search topics',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tag in ['All', 'Cycle', 'Symptoms', 'Life stages'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Pill(
                          tag,
                          selected: _tag == tag,
                          onTap: () => setState(() => _tag = tag),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('No topics found')),
                )
              else
                for (final art in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: () => _openArticle(art),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: kBlush,
                            child: Icon(_getIconForArticle(art), color: kWine, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  art.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (art.summary != null && art.summary!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    art.summary!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
