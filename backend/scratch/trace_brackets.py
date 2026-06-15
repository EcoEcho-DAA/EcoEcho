def trace_details(filepath, start, end):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    parens_stack = []
    brackets_stack = []
    braces_stack = []

    for idx, line in enumerate(lines):
        line_num = idx + 1
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
        clean = "".join(processed)

        for pos, char in enumerate(clean):
            if char == '{':
                braces_stack.append(line_num)
            elif char == '}':
                if braces_stack:
                    braces_stack.pop()
            elif char == '(':
                parens_stack.append(line_num)
            elif char == ')':
                if parens_stack:
                    parens_stack.pop()
            elif char == '[':
                brackets_stack.append(line_num)
            elif char == ']':
                if brackets_stack:
                    brackets_stack.pop()
                    
        if start <= line_num <= end:
            print(f"Line {line_num:4d} | Parens: {len(parens_stack):2d} (starts: {parens_stack[-3:]}) | Brackets: {len(brackets_stack):2d} (starts: {brackets_stack[-3:]}) | {line.rstrip()}")

if __name__ == '__main__':
    trace_details(r'c:\Users\jo\EcoEcho\frontend\lib\features\home\presentation\pages\home_page.dart', 1430, 1530)
