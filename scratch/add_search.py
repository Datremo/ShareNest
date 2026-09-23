import re

# 1. Update ListingRepository
with open('lib/core/data/repositories/listing_repository.dart', 'r', encoding='utf-8') as f:
    repo_content = f.read()

search_method = """
  Future<List<Listing>> searchListings(String query, {String? mode}) async {
    if (query.isEmpty) return [];
    var queryBuilder = _client
        .from('listings')
        .select()
        .eq('status', 'ACTIVE')
        .ilike('title', '%$query%')
        .order('created_at', ascending: false)
        .limit(10);
    
    if (mode != null && mode.isNotEmpty) {
      queryBuilder = queryBuilder.eq('mode', mode);
    }
    
    final response = await queryBuilder;
    return (response as List).map((e) => Listing.fromJson(e)).toList();
  }
"""
if "searchListings" not in repo_content:
    repo_content = repo_content.replace("}\n", search_method + "\n}\n", 1)
    with open('lib/core/data/repositories/listing_repository.dart', 'w', encoding='utf-8') as f:
        f.write(repo_content)

# 2. Update explore_page.dart
with open('lib/features/explore/presentation/explore_page.dart', 'r', encoding='utf-8') as f:
    explore_content = f.read()

explore_content = explore_content.replace("import 'package:supabase_flutter/supabase_flutter.dart';", "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:flutter_typeahead/flutter_typeahead.dart';")

search_bar_old = r'GestureDetector\(\s*onTap: \(\) => context\.push\(\'/search_results\?mode=\'\),\s*child: Container\(.*?Icon\(CupertinoIcons\.search.*?\),\s*const SizedBox\(width: 12\),\s*Expanded\(child: Text\(\'Search for items.*?\)\),\s*Icon\(Icons\.mic_none.*?\),\s*\],\s*\),\s*\),\s*\)'
search_bar_new = """
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: TypeAheadField<Listing>(
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search for items...',
                                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                                  prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primaryDark, size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_forward, color: AppColors.primaryDark),
                                    onPressed: () {
                                      context.push('/search_results?mode=&query=${controller.text}');
                                    }
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              );
                            },
                            suggestionsCallback: (pattern) async {
                              if (pattern.isEmpty) return [];
                              return await _listingRepo.searchListings(pattern);
                            },
                            itemBuilder: (context, Listing item) {
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                elevation: 0,
                                color: Colors.grey[50],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: item.photoUrls.isNotEmpty 
                                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.photoUrls.first, width: 50, height: 50, fit: BoxFit.cover)) 
                                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                                  subtitle: Text(item.mode == 'GIVE' ? 'Free' : item.mode == 'LEND' ? 'Borrow' : 'Exchange', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                ),
                              );
                            },
                            onSelected: (Listing item) {
                              context.push('/item', extra: item);
                            },
                            emptyBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No items found', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        )
"""
explore_content = re.sub(search_bar_old, search_bar_new, explore_content, flags=re.DOTALL)

# Fix Filters
filters_old = r'Container\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 14\),\s*decoration: BoxDecoration\(\s*color: Colors\.white,\s*borderRadius: BorderRadius\.circular\(30\),\s*boxShadow: \[BoxShadow\(color: Colors\.black\.withValues\(alpha: 0\.1\), blurRadius: 15, offset: const Offset\(0, 5\)\)\],\s*\),\s*child: const Row\(\s*children: \[\s*Icon\(Icons\.tune, color: AppColors\.primaryDark, size: 20\),\s*SizedBox\(width: 8\),\s*Text\(\'Filters\'.*?\),\s*\],\s*\),\s*\)'
filters_new = """
                      GestureDetector(
                        onTap: () => context.push('/search_results?mode='),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.tune, color: AppColors.primaryDark, size: 20),
                              SizedBox(width: 8),
                              Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
"""
explore_content = re.sub(filters_old, filters_new, explore_content, flags=re.DOTALL)
with open('lib/features/explore/presentation/explore_page.dart', 'w', encoding='utf-8') as f:
    f.write(explore_content)
