import json
import re
import os

transcript_path = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\4edb2d7d-0f01-47a6-a4ff-f98de7f32fba\.system_generated\logs\transcript_full.jsonl'

latest_versions = {}

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            event = json.loads(line.strip())
            
            if event.get('type') == 'VIEW_FILE':
                content = event.get('content', '')
                path_match = re.search(r"File Path:\s*ile:///([^]+)", content)
                if path_match:
                    path = path_match.group(1).replace('%3A', ':').replace('%3a', ':')
                    
                    # Ensure it shows from line 1 to the end
                    total_lines_match = re.search(r'Total Lines:\s*(\d+)', content)
                    showing_match = re.search(r'Showing lines\s+(\d+)\s+to\s+(\d+)', content)
                    
                    if total_lines_match and showing_match:
                        total = int(total_lines_match.group(1))
                        start = int(showing_match.group(1))
                        end = int(showing_match.group(2))
                        
                        if start == 1 and end == total:
                            lines = []
                            for text_line in content.split('\n'):
                                text_line = text_line.strip('\r\n')
                                match = re.match(r'^\d+:\s(.*)$', text_line)
                                if match:
                                    lines.append(match.group(1))
                            
                            full_content = '\n'.join(lines)
                            if len(full_content) > 1000:
                                path_os = os.path.normpath(path)
                                latest_versions[path_os] = full_content
                                
            if event.get('type') == 'PLANNER_RESPONSE':
                for tc in event.get('tool_calls', []):
                    func_name = tc.get('name', '')
                    args = tc.get('arguments', {})
                    if isinstance(args, str):
                        try:
                            args = json.loads(args)
                        except:
                            pass
                    
                    if func_name == 'default_api:write_to_file' or func_name == 'write_to_file':
                        target = args.get('TargetFile')
                        code = args.get('CodeContent')
                        if target and code and len(code) > 1000:
                            path_os = os.path.normpath(target)
                            latest_versions[path_os] = code
                            
        except Exception as e:
            pass

print(f"Found {len(latest_versions)} full files in transcript.")
count = 0
for path, content in latest_versions.items():
    if os.path.exists(path) and os.path.getsize(path) <= 1000:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Recovered from transcript: {path}")
        count += 1
print(f"Total recovered: {count}")

