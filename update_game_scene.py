import re

with open('scenes/game.tscn', 'r') as f:
    content = f.read()

# Add script to ext_resource
# Check max ext_resource id
ext_ids = [int(i) for i in re.findall(r'ext_resource.*?id="(\d+)_', content)]
next_id = max(ext_ids) + 1 if ext_ids else 1
script_id = f"{next_id}_player_controller"

ext_resource_str = f'[ext_resource type="Script" path="res://scripts/player_controller.gd" id="{script_id}"]\n'

# Find the last ext_resource
last_ext_idx = content.rfind('[ext_resource')
end_of_last_ext = content.find('\n', last_ext_idx) + 1

content = content[:end_of_last_ext] + ext_resource_str + content[end_of_last_ext:]

# Add node
node_str = f'\n[node name="PlayerController" type="Node2D" parent="." groups=["player_controller"]]\nscript = ExtResource("{script_id}")\n'

content += node_str

with open('scenes/game.tscn', 'w') as f:
    f.write(content)
