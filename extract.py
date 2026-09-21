import json
import codecs

in_path = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\409c09b2-7f17-4f4c-8773-9d4475aa7fee\.system_generated\logs\transcript_full.jsonl'
out_path = r'C:\Users\Shubham\.gemini\antigravity-ide\brain\409c09b2-7f17-4f4c-8773-9d4475aa7fee\scratch\step63_content.txt'

with codecs.open(in_path, 'r', encoding='utf-8') as fin, codecs.open(out_path, 'w', encoding='utf-8') as fout:
    for line in fin:
        if '"step_index":63,' in line:
            obj = json.loads(line)
            fout.write(obj.get('content', ''))
