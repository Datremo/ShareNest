import os
import glob
import re

files = glob.glob('lib/features/share/presentation/*.dart')

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Replace the bang operator with null-conditional and default false
    new_content = re.sub(r'(_formKey\d\.currentState)!\.validate\(\)', r'(\1?.validate() ?? false)', content)
    
    if new_content != content:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(new_content)
        print(f"Fixed null checks in {f}")
