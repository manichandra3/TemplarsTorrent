import re

files = ['scripts/pawn.gd', 'scripts/knight.gd', 'scripts/archer.gd']

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Extends BaseUnit
    content = content.replace('extends CharacterBody2D', 'extends "res://scripts/base_unit.gd"')
    
    # Remove vars
    content = re.sub(r'@export var health: float = .*\n', '', content)
    content = re.sub(r'@export var movement_speed: float = .*\n', '', content)
    content = re.sub(r'@export var acceleration: float = .*\n', '', content)
    content = re.sub(r'var is_selected: bool = false\n', '', content)
    
    # Assign sprite and health bar in _ready
    # For pawn it's $pawn_animated, for knight $knight_animated, archer $ArcherAnimated
    
    sprite_name = 'pawn_animated' if 'pawn' in f else 'knight_animated' if 'knight' in f else 'ArcherAnimated'
    
    ready_func = f"""func _ready():
	animated_sprite = ${sprite_name}
	health_bar = $HealthBar
"""
    content = content.replace('func _ready():\n', ready_func)
    
    # Remove duplicate methods
    for method in ['select', 'deselect', 'take_damage', 'die']:
        # This regex matches the function until the next function definition or EOF
        pattern = r'func ' + method + r'\(\)?[^f]*?(?=func |$)'
        content = re.sub(pattern, '', content, flags=re.DOTALL)
    
    with open(f, 'w') as file:
        file.write(content)
