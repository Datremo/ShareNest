import json
import re
import os
import glob

brain_dir = r'C:\Users\Shubham\.gemini\antigravity-ide\brain'
latest_versions = {}

print('Scanning all transcripts for run_command python scripts...')
for transcript_path in glob.glob(os.path.join(brain_dir, '*', '.system_generated', 'logs', 'transcript_full.jsonl')):
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                event = json.loads(line.strip())
                if event.get('type') == 'PLANNER_RESPONSE':
                    for tc in event.get('tool_calls', []):
                        func_name = tc.get('name', '')
                        args = tc.get('arguments', {})
                        if isinstance(args, str):
                            try:
                                args = json.loads(args)
                            except:
                                pass
                        
                        if func_name in ('run_command', 'default_api:run_command'):
                            cmd = args.get('CommandLine', '')
                            # Extract file paths and content from python scripts
                            # e.g., path = r'C:\...\file.dart'
                            # f.write('''...''') or f.write(\"\"\"...\"\"\")
                            matches = re.findall(r"path\s*=\s*r?['\"]([A-Za-z]:\\[^'\"]+\.dart)['\"][\s\S]*?with open[\s\S]*?write\((r?'''|r?\"\"\")(.*?)(\2)\)", cmd, flags=re.DOTALL)
                            for match in matches:
                                target = match[0]
                                code = match[2]
                                if len(code) > 200:
                                    path_os = os.path.normpath(target)
                                    latest_versions[path_os] = code
                                    
                            # what if it's assigned to a variable first? content = '''...'''
                            matches2 = re.findall(r"(?:path|file_path)\s*=\s*r?['\"]([A-Za-z]:\\[^'\"]+\.dart)['\"][\s\S]*?content\s*=\s*(r?'''|r?\"\"\")(.*?)(\2)[\s\S]*?with open[\s\S]*?write\(content\)", cmd, flags=re.DOTALL)
                            for match in matches2:
                                target = match[0]
                                code = match[2]
                                if len(code) > 200:
                                    path_os = os.path.normpath(target)
                                    latest_versions[path_os] = code
                                    
            except Exception as e:
                pass

print(f"Found {len(latest_versions)} files in run_command scripts.")
count = 0
for path, content in latest_versions.items():
    if os.path.exists(path) and os.path.getsize(path) <= 1000:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Recovered from run_command: {path}")
        count += 1
print(f"Total recovered: {count}")
