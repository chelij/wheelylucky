extends SceneTree

func _init():
	# Give the scene time to load, then capture
	await get_tree().create_timer(2.0).timeout
	
	# Find the main node and start a new game
	var root = get_tree().root.get_child(0)
	if root != null:
		var script = root.get_script()
		if script != null:
			if "start_new_game" in root:
				root.start_new_game()
			elif "new_game" in root:
				root.new_game()
	
	# Wait for gameplay to initialize
	await get_tree().create_timer(2.0).timeout
	
	# Capture screenshot
	var image = get_tree().root.get_image()
	image.save_png("res://gameplay_screenshot.png")
	print("Screenshot saved!")
	
	# Quit after capture
	await get_tree().create_timer(1.0).timeout
	quit()
