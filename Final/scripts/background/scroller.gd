extends ParallaxBackground
class_name BackgroundScroller

## 3-layer parallax background scroller with procedural stars
## Creates depth illusion with different scroll speeds per layer
## Viewport-aware: regenerates stars on resize

var viewport_size: Vector2

# Layer references
var far_layer: ParallaxLayer
var mid_layer: ParallaxLayer
var near_layer: ParallaxLayer


func _ready() -> void:
	# Get initial viewport size
	viewport_size = get_viewport().get_visible_rect().size

	# Setup parallax layers
	setup_layers()

	# Generate stars for each layer
	generate_layer_blocks("FarLayer", GameConstants.BG_FAR_COLOR_1, GameConstants.BG_FAR_COLOR_2)
	generate_layer_blocks("MidLayer", GameConstants.BG_MID_COLOR_1, GameConstants.BG_MID_COLOR_2)
	generate_layer_blocks("NearLayer", GameConstants.BG_NEAR_COLOR_1, GameConstants.BG_NEAR_COLOR_2)

	# Connect to viewport resize
	get_viewport().size_changed.connect(_on_viewport_resized)


func setup_layers() -> void:
	## Setup references to parallax layers using unique names (%)
	far_layer = %FarLayer
	mid_layer = %MidLayer
	near_layer = %NearLayer

	# Update mirroring to match current viewport size
	far_layer.motion_mirroring = Vector2(0, viewport_size.y * 2)
	mid_layer.motion_mirroring = Vector2(0, viewport_size.y * 2)
	near_layer.motion_mirroring = Vector2(0, viewport_size.y * 2)


func _process(delta: float) -> void:
	# Scroll the background
	scroll_offset.y += GameConstants.BASE_SCROLL_SPEED * delta


func _on_viewport_resized() -> void:
	## Handle viewport resize - regenerate stars for new dimensions
	viewport_size = get_viewport().get_visible_rect().size

	# Update layer mirroring
	if far_layer:
		far_layer.motion_mirroring = Vector2(0, viewport_size.y * 2)
	if mid_layer:
		mid_layer.motion_mirroring = Vector2(0, viewport_size.y * 2)
	if near_layer:
		near_layer.motion_mirroring = Vector2(0, viewport_size.y * 2)

	# Regenerate stars
	regenerate_all_blocks()


func regenerate_all_blocks() -> void:
	## Clear and regenerate all stars
	clear_layer_blocks("FarLayer")
	clear_layer_blocks("MidLayer")
	clear_layer_blocks("NearLayer")

	generate_layer_blocks("FarLayer", GameConstants.BG_FAR_COLOR_1, GameConstants.BG_FAR_COLOR_2)
	generate_layer_blocks("MidLayer", GameConstants.BG_MID_COLOR_1, GameConstants.BG_MID_COLOR_2)
	generate_layer_blocks("NearLayer", GameConstants.BG_NEAR_COLOR_1, GameConstants.BG_NEAR_COLOR_2)


func clear_layer_blocks(layer_name: String) -> void:
	## Remove all stars from a layer
	var layer = get_node_or_null(layer_name)
	if not layer:
		return

	var blocks_container = layer.get_node_or_null("ColoredBlocks")
	if not blocks_container:
		return

	for child in blocks_container.get_children():
		child.queue_free()


func generate_layer_blocks(layer_name: String, color1: Color, color2: Color) -> void:
	## Generate random stars for a parallax layer
	##
	## Args:
	##   layer_name: Name of the parallax layer
	##   color1: Primary colour for reference
	##   color2: Secondary colour for reference
	var layer = get_node_or_null(layer_name)
	if not layer:
		return

	var blocks_container = layer.get_node_or_null("ColoredBlocks")
	if not blocks_container:
		# Create container if it doesn't exist
		blocks_container = Node2D.new()
		blocks_container.name = "ColoredBlocks"
		layer.add_child(blocks_container)

	# Determine star count based on layer (far layers have fewer stars)
	var block_count = 20
	var min_size = 40
	var max_size = 120

	if layer_name == "FarLayer":
		block_count = 15
		min_size = 30
		max_size = 80
	elif layer_name == "NearLayer":
		block_count = 25
		min_size = 60
		max_size = 150

	# Generate random stars
	for i in range(block_count):
		var block = create_colored_block(color1, color2, min_size, max_size)
		blocks_container.add_child(block)


func create_colored_block(color1: Color, color2: Color, min_size: float, max_size: float) -> Polygon2D:
	## Create a single star polygon (mix of dots and 4-point stars)
	var star = Polygon2D.new()

	# Random position across viewport (X and Y)
	var x = randf_range(0, viewport_size.x)
	var y = randf_range(0, viewport_size.y * 2)  # Double height for seamless mirroring

	# Decide star type: 70% small dots, 30% larger 4-point stars
	var is_dot = randf() < 0.7

	if is_dot:
		# Small circular dot (distant star)
		var radius = randf_range(1.0, 3.0)
		star.polygon = create_circle_polygon(x, y, radius, 6)  # 6 points = rough circle
	else:
		# Larger 4-point star (closer star)
		var size = randf_range(4.0, 8.0)
		star.polygon = create_4point_star(x, y, size)

	# Use white/yellow star colors instead of provided colors
	var star_colors = [
		Color.WHITE,
		Color(1.0, 1.0, 0.9),  # Slightly warm white
		Color(0.9, 0.95, 1.0),  # Slightly cool white
		Color(1.0, 1.0, 0.8)   # Yellow-white
	]
	star.color = star_colors[randi() % star_colors.size()]

	# Varying brightness for depth (distant stars dimmer, close stars brighter)
	var brightness = randf_range(0.4, 1.0)
	star.color.a = brightness

	return star


func create_circle_polygon(center_x: float, center_y: float, radius: float, points: int) -> PackedVector2Array:
	## Create a circular polygon (for dot stars)
	var polygon = PackedVector2Array()
	for i in range(points):
		var angle = (i / float(points)) * TAU
		var px = center_x + cos(angle) * radius
		var py = center_y + sin(angle) * radius
		polygon.append(Vector2(px, py))
	return polygon


func create_4point_star(center_x: float, center_y: float, size: float) -> PackedVector2Array:
	## Create a 4-point star (diamond with pointy tips)
	var outer = size
	var inner = size * 0.4  # Inner points closer to center

	return PackedVector2Array([
		Vector2(center_x, center_y - outer),        # Top point
		Vector2(center_x + inner, center_y - inner), # Top-right inner
		Vector2(center_x + outer, center_y),        # Right point
		Vector2(center_x + inner, center_y + inner), # Bottom-right inner
		Vector2(center_x, center_y + outer),        # Bottom point
		Vector2(center_x - inner, center_y + inner), # Bottom-left inner
		Vector2(center_x - outer, center_y),        # Left point
		Vector2(center_x - inner, center_y - inner)  # Top-left inner
	])
