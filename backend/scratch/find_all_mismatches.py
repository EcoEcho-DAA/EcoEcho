def trace_all_tokens(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    braces = 0
    parens = 0
    brackets = 0

    braces_stack = []
    parens_stack = []
    brackets_stack = []

    for idx, line in enumerate(lines):
        line_num = idx + 1
        clean = line.split('//')[0]
        
        # Strip string literals to avoid counting characters inside strings
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
                braces += 1
                braces_stack.append(line_num)
            elif char == '}':
                if braces > 0:
                    braces -= 1
                    braces_stack.pop()
                else:
                    print(f"Mismatch: Extra '}}' at line {line_num}")
            elif char == '(':
                parens += 1
                parens_stack.append(line_num)
            elif char == ')':
                if parens > 0:
                    parens -= 1
                    parens_stack.pop()
                else:
                    print(f"Mismatch: Extra ')' at line {line_num}")
            elif char == '[':
                brackets += 1
                brackets_stack.append(line_num)
            elif char == ']':
                if brackets > 0:
                    brackets -= 1
                    brackets_stack.pop()
                else:
                    print(f"Mismatch: Extra ']' at line {line_num}")

    print("\n--- Final Status ---")
    print(f"Braces balance: {braces}")
    if braces > 0:
        print(f"Unclosed braces opened at lines: {braces_stack}")
    print(f"Parens balance: {parens}")
    if parens > 0:
        print(f"Unclosed parens opened at lines: {parens_stack}")
    print(f"Brackets balance: {brackets}")
    if brackets > 0:
        print(f"Unclosed brackets opened at lines: {brackets_stack}")

if __name__ == '__main__':
    trace_all_tokens(r'c:\Users\jo\EcoEcho\frontend\lib\features\leaderboard\presentation\leaderboard_screen.dart')
