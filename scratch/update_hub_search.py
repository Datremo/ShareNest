import re

def update_hub_search(filepath, mode, search_text):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace("import 'package:go_router/go_router.dart';", "import 'package:go_router/go_router.dart';\nimport 'package:flutter_typeahead/flutter_typeahead.dart';")

    search_bar_old = r'Widget _buildSearchBar\(\) \{.*?(?=Widget _buildCategories\(\) \{)'
    
    search_bar_new = f"""Widget _buildSearchBar() {{
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: TypeAheadField<Listing>(
            builder: (context, controller, focusNode) {{
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '{search_text}',
                  hintStyle: TextStyle(
                    color: AppColors.primaryDark.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primaryDark, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: AppColors.primaryDark),
                        onPressed: () {{
                          context.push('/search_results?mode={mode}&query=${{controller.text}}');
                        }}
                      ),
                      GestureDetector(
                        onTap: () => context.push('/search_results?mode={mode}'),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 16),
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              );
            }},
            suggestionsCallback: (pattern) async {{
              if (pattern.isEmpty) return [];
              return await _listingRepo.searchListings(pattern, mode: '{mode}');
            }},
            itemBuilder: (context, Listing item) {{
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 0,
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: item.photoUrls.isNotEmpty 
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.photoUrls.first, width: 50, height: 50, fit: BoxFit.cover)) 
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                  subtitle: Text(item.locationName ?? 'Nearby', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ),
              );
            }},
            onSelected: (Listing item) {{
              context.push('/item', extra: item);
            }},
            emptyBuilder: (context) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No items found', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }}

  """
    
    content = re.sub(search_bar_old, search_bar_new, content, flags=re.DOTALL)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


update_hub_search('lib/features/explore/presentation/borrow_hub_page.dart', 'LEND', 'Search to borrow...')
update_hub_search('lib/features/explore/presentation/free_items_page.dart', 'GIVE', 'Search free items...')

