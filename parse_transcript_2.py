import json
import re
import os

transcript_path = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\4edb2d7d-0f01-47a6-a4ff-f98de7f32fba\.system_generated\logs\transcript_full.jsonl'

latest_versions = {}

print('Reading transcript...')
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            event = json.loads(line.strip())
            # Parse VIEW_FILE
            if event.get('type') == 'VIEW_FILE':
                content = event.get('content', '')
                if 'File Path:' in content:
                    path_match = re.search(r"File Path:\s*ile:///([^]+)", content)
                    if path_match:
                        path = path_match.group(1).replace('%3A', ':')
                        if 'The above content shows the entire, complete file contents' in content:
                            lines = []
                            for text_line in content.split('\n'):
                                match = re.match(r'^\d+:\s(.*)$', text_line)
                                if match:
                                    lines.append(match.group(1))
                            if lines and len('\n'.join(lines)) > 1000:
                                latest_versions[path] = '\n'.join(lines)
            
            # Parse tool_calls for write_to_file and multi_replace_file_content/replace_file_content
            if event.get('type') == 'PLANNER_RESPONSE':
                for tc in event.get('tool_calls', []):
                    func_name = tc.get('name', '')
                    args = tc.get('arguments', {})
                    if isinstance(args, str):
                        try:
                            args = json.loads(args)
                        except:
                            pass
                    
                    if func_name == 'write_to_file':
                        target = args.get('TargetFile')
                        code = args.get('CodeContent')
                        if target and code and len(code) > 1000:
                            path = target.replace('\\\\', '/').replace('\\', '/')
                            latest_versions[path] = code
                            
                    elif func_name in ('replace_file_content', 'multi_replace_file_content'):
                        # Can't easily replay them all from scratch without state, but if we have the file state we could.
                        # Since it's complicated, we just log it
                        pass
        except Exception as e:
            pass

print(f"Found {len(latest_versions)} full files in transcript.")
for path, content in latest_versions.items():
    if os.path.exists(path):
        if os.path.getsize(path) <= 1000:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Recovered from transcript: {path}")

