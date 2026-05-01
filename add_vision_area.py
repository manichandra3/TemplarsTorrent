import re

with open('scenes/torch_goblin.tscn', 'r') as f:
    content = f.read()

# Add VisionArea
vision_area_str = """
[node name="VisionArea" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="VisionArea"]
shape = SubResource("CircleShape2D_vision")
"""

# Find a good place to insert (before the end)
content += vision_area_str

# Add SubResource for the circle shape at the top
subresource_str = '\n[sub_resource type="CircleShape2D" id="CircleShape2D_vision"]\nradius = 200.0\n'

# Find the last load_steps or sub_resource at the top
match = re.search(r'\[ext_resource.*?\]\n', content)
if match:
    insert_pos = match.end()
    content = content[:insert_pos] + subresource_str + content[insert_pos:]

with open('scenes/torch_goblin.tscn', 'w') as f:
    f.write(content)
