with open(r'c:\Users\jo\EcoEcho\frontend\lib\features\home\presentation\pages\home_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for idx in range(1469, 1475):
    line = lines[idx]
    clean = line.split('//')[0]
    in_double = False
    in_single = False
    processed = []
    i = 0
    while i < len(clean):
        char = clean[i]
        if char == '\\' and i + 1 < len(clean):
            i += 2
            continue
        if char == '"' and not in_single:
            in_double = not in_double
        elif char == "'" and not in_double:
            in_single = not in_single
        elif not in_double and not in_single:
            processed.append(char)
        i += 1
    print(f"Line {idx+1}: original: {line.rstrip()} | processed: {''.join(processed).rstrip()}")
