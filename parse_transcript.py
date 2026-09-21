import json
import re
import os

transcript_path = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\4edb2d7d-0f01-47a6-a4ff-f98de7f32fba\.system_generated\logs\transcript_full.jsonl'

latest_versions = {}

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            event = json.loads(line)
            # Check for tool_calls
            if 'tool_calls' in event:
                for tc in event['tool_calls']:
                    args = tc.get('function', {}).get('arguments', '{}')
                    if isinstance(args, str):
                        try:
                            args_json = json.loads(args)
                        except:
                            continue
                    else:
                        args_json = args
                        
                    func_name = tc.get('function', {}).get('name', '')
                    
                    if func_name == 'default_api:write_to_file':
                        target = args_json.get('TargetFile')
                        content = args_json.get('CodeContent')
                        if target and content and 'neighbor_share' in target:
                            latest_versions[target.replace('\\\\', '/').replace('\\', '/')] = content
            
            # Check for tool responses
            if event.get('type') == 'TOOL_RESPONSE':
                content = event.get('content', '')
                if 'File Path:' in content and 'The following code has been modified' in content:
                    # extract path
                    path_match = re.search(r"File Path:\s*ile:///([^]+)", content)
                    if path_match:
                        path = path_match.group(1).replace('%3A', ':')
                        # check if it shows entire file
                        if 'The above content shows the entire, complete file contents' in content:
                            lines = []
                            for text_line in content.split('\n'):
                                match = re.match(r'^\d+:\s(.*)$', text_line)
                                if match:
                                    lines.append(match.group(1))
                            if lines:
                                latest_versions[path] = '\n'.join(lines)
        except Exception as e:
            pass

print(f"Found {len(latest_versions)} files in transcript.")
for path, content in latest_versions.items():
    if os.path.exists(path) and os.path.getsize(path) <= 1000:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Recovered from transcript: {path}")

