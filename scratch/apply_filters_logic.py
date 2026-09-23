import os
import re

def update_file(filepath, filter_logic):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'Map<String, dynamic>? _activeFilters;' not in content:
        # Add the state variable
        content = re.sub(r'(class _\w+State extends State<\w+> \{)',
                         r'\1\n  Map<String, dynamic>? _activeFilters;',
                         content, count=1)
                         
        # Add the _showFilters method
        show_filters_code = """
  Future<void> _showFilters() async {
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FiltersBottomSheet(),
    );
    if (filters != null) {
      setState(() {
        _activeFilters = filters;
        if (filters['category'] != null && filters['category'] != 'All') {
          _selectedCategory = filters['category'];
        } else {
          _selectedCategory = null;
        }
      });
    }
  }
"""
        # Inject _showFilters method before build
        content = re.sub(r'(\n  @override\n  Widget build\(BuildContext context\))',
                         show_filters_code + r'\1',
                         content, count=1)
        
        # Inject the filter logic inside StreamBuilder/FutureBuilder
        content = re.sub(
            r'(\s*var listings = [^;]+;)(\s*if \(_selectedCategory != null\) \{[^}]+\})?',
            r'\1\n' + filter_logic,
            content, count=1)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# The logic to apply _activeFilters to listings
filter_logic = """          if (_activeFilters != null) {
            final category = _activeFilters!['category'];
            final condition = _activeFilters!['condition'];
            
            if (category != null && category != 'All') {
                final catId = category.toString().toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');
                listings = listings.where((l) => l.categoryId == catId || l.category == category).toList();
            }
            if (condition != null && condition != 'Any') {
                listings = listings.where((l) => l.condition == condition).toList();
            }
          } else if (_selectedCategory != null) {
            listings = listings.where((l) => l.categoryId == _selectedCategory).toList();
          }
"""

explore = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\explore\presentation\explore_page.dart'
update_file(explore, filter_logic)
print("Updated explore_page.dart")

borrow = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\explore\presentation\borrow_hub_page.dart'
update_file(borrow, filter_logic)
print("Updated borrow_hub_page.dart")

free = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\explore\presentation\free_items_page.dart'
update_file(free, filter_logic)
print("Updated free_items_page.dart")

def fix_ontap(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace context.push with _showFilters()
    content = re.sub(
        r'onTap:\s*\(\)\s*=>\s*context\.push\(\'/search_results\?mode=\w+\'\),',
        r'onTap: _showFilters,',
        content
    )
    content = re.sub(
        r'onTap:\s*\(\)\s*=>\s*context\.push\(\'/search_results\?mode=\'\),',
        r'onTap: _showFilters,',
        content
    )
    # Explore page fix for showModalBottomSheet
    content = re.sub(
        r'onTap:\s*\(\)\s*=>\s*showModalBottomSheet\([^)]+\),',
        r'onTap: _showFilters,',
        content
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_ontap(explore)
fix_ontap(borrow)
fix_ontap(free)
print("Fixed onTap for explore, borrow and free")
