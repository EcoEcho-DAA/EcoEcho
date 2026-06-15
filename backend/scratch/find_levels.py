def trace_levels(filepath, start, end):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    level = 0
    for idx, line in enumerate(lines):
        line_num = idx + 1
        clean = line.split('//')[0]
        # Ignore comments and simple quotes
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
        
        for char in clean:
            if char == '{':
                level += 1
            elif char == '}':
                level -= 1
        if start <= line_num <= end:
            print(f"Line {line_num:3d} (Level {level:2d}): {line.rstrip()}")

if __name__ == '__main__':
    trace_levels(r'c:\Users\jo\EcoEcho\frontend\lib\features\missions\presentation\mission_board_screen.dart', 680, 705)
