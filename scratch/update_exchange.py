import os
import re

filepath = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\explore\presentation\exchange_hub_page.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _activeFilters
if 'Map<String, dynamic>? _activeFilters;' not in content:
    content = re.sub(r'(class _ExchangeHubPageState extends State<ExchangeHubPage> \{)',
                     r'\1\n  Map<String, dynamic>? _activeFilters;',
                     content, count=1)

# Modify _showFilters to receive result
content = re.sub(r'void _showFilters\(\) \{', r'Future<void> _showFilters() async {', content)
content = re.sub(r'(showModalBottomSheet\([^;]+;)', 
                 r'''final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExchangeFiltersBottomSheet(),
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
    }''', content, flags=re.DOTALL, count=1)

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
content = re.sub(
    r'(\s*var listings = [^;]+;)(\s*if \(_selectedCategory != null\) \{[^}]+\})?',
    r'\1\n' + filter_logic,
    content, count=1)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated exchange_hub_page.dart")
