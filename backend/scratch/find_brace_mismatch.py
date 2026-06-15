def trace_level_range(filepath, start_line, end_line):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    level = 0
    stack = []
    
    for idx, line in enumerate(lines):
        line_num = idx + 1
        clean = line.split('//')[0]
        clean = clean.replace(r'\"', '').replace(r"\'", '')
        
        for pos, char in enumerate(clean):
            if char == '{':
                level += 1
                stack.append(line_num)
            elif char == '}':
                if level > 0:
                    level -= 1
                    stack.pop()
                else:
                    print(f"Extra closing brace at line {line_num}")
                    
        if start_line <= line_num <= end_line:
            print(f"Line {line_num:3d} (Level {level:2d}): {line.rstrip()}")

if __name__ == '__main__':
    trace_level_range(r'c:\Users\jo\EcoEcho\frontend\lib\features\missions\presentation\mission_board_screen.dart', 970, 1005)
