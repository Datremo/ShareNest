import os, glob, re

scratch_dir = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\4edb2d7d-0f01-47a6-a4ff-f98de7f32fba\scratch'
out_dir = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib'

print('Scanning scratch for recoverable files...')

for fpath in glob.glob(os.path.join(scratch_dir, '*.py')):
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # extract content assigned to string literals
    matches = re.findall(r"content\s*=\s*(r?'''|r?\"\"\")(.*?)(\1)", content, flags=re.DOTALL)
    for match in matches:
        dart_code = match[1]
        if 'import ' in dart_code and 'class ' in dart_code:
            # try to find file path
            path_match = re.search(r"r?['\"]([A-Za-z]:\\[^'\"]+\.dart)['\"]", content)
            if path_match:
                target_path = path_match.group(1)
                print(f'Recovering {target_path} from {os.path.basename(fpath)}')
                # overwrite only if it's currently corrupted (938 bytes)
                if os.path.exists(target_path) and os.path.getsize(target_path) <= 1000:
                    with open(target_path, 'w', encoding='utf-8') as tf:
                        tf.write(dart_code)
                    print(f' -> Wrote {len(dart_code)} bytes')
            else:
                print(f'Found dart code in {os.path.basename(fpath)} but unknown path')
