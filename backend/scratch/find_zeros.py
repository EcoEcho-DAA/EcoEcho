def trace_zeros(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    level = 0
    stack = []
    
    for idx, line in enumerate(lines):
        line_num = idx + 1
        clean = line.split('//')[0]
        # Ignore string literals that might have braces
        # A simple way is to replace contents of single and double quoted strings
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
        
        clean = "".join(processed)
        
        for pos, char in enumerate(clean):
            if char == '{':
                level += 1
                stack.append(line_num)
            elif char == '}':
                if level > 0:
                    level -= 1
                    stack.pop()
                    if level == 0:
                        print(f"Level 0 at line {line_num}: {line.rstrip()}")
                else:
                    print(f"Extra closing brace at line {line_num}: {line.rstrip()}")

if __name__ == '__main__':
    trace_zeros(r'c:\Users\jo\EcoEcho\frontend\lib\features\missions\presentation\mission_board_screen.dart')
