import os

files = ['scripts/pawn.gd', 'scripts/knight.gd', 'scripts/archer.gd']

funcs_to_remove = ['func select(', 'func deselect(', 'func take_damage(', 'func die(']

for f in files:
    with open(f, 'r') as file:
        lines = file.readlines()
    
    new_lines = []
    skip = False
    
    for line in lines:
        if any(line.startswith(func) for func in funcs_to_remove):
            skip = True
        elif skip and line.startswith('func '):
            skip = False
            
        if not skip:
            new_lines.append(line)
            
    with open(f, 'w') as file:
        file.writelines(new_lines)

