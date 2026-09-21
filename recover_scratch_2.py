import os, glob, re

scratch_dir = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\4edb2d7d-0f01-47a6-a4ff-f98de7f32fba\scratch'

mapping = {
    'transform_my_requests_page.py': r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\profile\presentation\my_requests_page.dart',
    'transform_request_borrow_page.py': r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\requests\presentation\request_borrow_page.dart',
    'transform_request_borrow_page_2.py': r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\requests\presentation\request_borrow_page.dart',
    'update_main_scaffold.py': r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\core\presentation\main_scaffold.dart',
    'update_main_scaffold_glass.py': r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\core\presentation\main_scaffold.dart',
}

for fname, target_path in mapping.items():
    fpath = os.path.join(scratch_dir, fname)
    if not os.path.exists(fpath): continue
    
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    matches = re.findall(r"content\s*=\s*(r?'''|r?\"\"\")(.*?)(\1)", content, flags=re.DOTALL)
    for match in matches:
        dart_code = match[1]
        if 'import ' in dart_code and 'class ' in dart_code:
            if os.path.exists(target_path) and os.path.getsize(target_path) <= 1000:
                with open(target_path, 'w', encoding='utf-8') as tf:
                    tf.write(dart_code)
                print(f'Recovered {target_path} from {fname} ({len(dart_code)} bytes)')
