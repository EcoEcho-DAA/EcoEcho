with open(r'c:\Users\jo\EcoEcho\frontend\lib\features\leaderboard\presentation\leaderboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if 'Widget ' in line or 'chip' in line.lower():
        print(f"Line {idx+1}: {line.strip()}")
