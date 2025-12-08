extends Node

const SAVE_DIR = "user://circuit_saves/"
const SAVE_EXTENSION = ".json"

var current_filename: String = ""  # Last used filename

func _ready():
	_ensure_save_directory()

func _ensure_save_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("circuit_saves"):
		dir.make_dir("circuit_saves")

# Save circuit with a custom filename
func save_circuit(graph_node: Node, filename: String) -> bool:
	if filename.is_empty():
		push_error("Filename cannot be empty")
		return false
	
	# Sanitize filename (remove invalid characters)
	filename = _sanitize_filename(filename)
	
	var save_data = {
		"components": [],
		"wires": [],
		"save_time": Time.get_datetime_string_from_system(),
		"filename": filename
	}
	
	for child in graph_node.get_children():
		if child.has_method("get_save_data"):
			save_data["components"].append(child.get_save_data())
			
	for child in get_parent().get_children():
		if child is Line2D:
			save_data["wires"].append(child.get_save_data())
	
	if graph_node.has_node("Wires"):
		var wires_node = graph_node.get_node("Wires")
		for wire in wires_node.get_children():
			if wire.has_method("get_save_data"):
				save_data["wires"].append(wire.get_save_data())
	
	# Write to file
	var file_path = _get_save_path(filename)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	
	current_filename = filename
	print("Circuit saved as: " + filename)
	return true

# Load circuit from a custom filename
func load_circuit(graph_node: Node, filename: String) -> bool:
	if filename.is_empty():
		push_error("Filename cannot be empty")
		return false
	
	filename = _sanitize_filename(filename)
	var file_path = _get_save_path(filename)
	
	if not FileAccess.file_exists(file_path):
		push_warning("Save file does not exist: " + filename)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		return false
	
	var save_data = json.data
	
	for child in graph_node.get_children():
		child.queue_free()
	
	for component_data in save_data["components"]:
		var component = create_component(component_data["type"])
		if component and component.has_method("load_save_data"):
			component.load_save_data(component_data)
			graph_node.add_child(component)
	await get_tree().process_frame
	
	for wire_data in save_data["wires"]:
		var wire = create_wire(wire_data, graph_node)
		get_parent().add_child(wire)
	
	current_filename = filename
	print("Circuit loaded from: " + filename)
	return true

# Delete a save file
func delete_save(filename: String) -> bool:
	if filename.is_empty():
		return false
	
	filename = _sanitize_filename(filename)
	var file_path = _get_save_path(filename)
	
	if not FileAccess.file_exists(file_path):
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	var result = dir.remove(file_path)
	
	if result == OK:
		print("Save file deleted: " + filename)
		return true
	else:
		push_error("Failed to delete save file")
		return false

# Check if a save file exists
func has_save(filename: String) -> bool:
	if filename.is_empty():
		return false
	filename = _sanitize_filename(filename)
	return FileAccess.file_exists(_get_save_path(filename))

# Get metadata from a save without loading full circuit
func get_save_info(filename: String) -> Dictionary:
	if not has_save(filename):
		return {}
	
	var file_path = _get_save_path(filename)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	var data = json.data
	return {
		"filename": filename,
		"save_time": data.get("save_time", "Unknown"),
		"component_count": data.get("components", []).size(),
		"wire_count": data.get("wires", []).size()
	}

# Get list of all save files
func get_all_saves() -> Array:
	var saves = []
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir == null:
		return saves
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			var save_name = file_name.trim_suffix(SAVE_EXTENSION)
			saves.append(get_save_info(save_name))
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by save time (most recent first)
	saves.sort_custom(func(a, b): return a.save_time > b.save_time)
	
	return saves

# Sanitize filename to remove invalid characters
func _sanitize_filename(filename: String) -> String:
	# Remove file extension if user included it
	filename = filename.trim_suffix(SAVE_EXTENSION)
	
	# Remove invalid characters for file names
	var invalid_chars = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]
	for char in invalid_chars:
		filename = filename.replace(char, "_")
	
	# Trim whitespace
	filename = filename.strip_edges()
	
	# Ensure it's not empty after sanitization
	if filename.is_empty():
		filename = "circuit_save"
	
	return filename

func _get_save_path(filename: String) -> String:
	return SAVE_DIR + filename + SAVE_EXTENSION

func create_component(type: String):
	var component_scenes = {
		"resistor": preload("res://Components/Resistor/resistor.tscn"),
		"voltage_source": preload("res://Components/Voltage Source/voltage_source.tscn"),
		"current_source": preload("res://Components/Current Source/current_source.tscn"),
	}
	
	if component_scenes.has(type):
		return component_scenes[type].instantiate()
	else:
		push_error("Unknown component type: " + type)
		return null

func create_wire(wire_data: Dictionary, graph):
	var wire_scene = preload("res://Components/Wire/wire.tscn")
	var wire = wire_scene.instantiate()
	
	if wire.has_method("load_save_data"):
		wire.load_save_data(wire_data, graph)
	
	return wire

# Example button handlers with filename input
func _on_save_button_pressed():
	var popup = preload("res://popup_windows/saveload_popup.tscn").instantiate()
	add_child(popup)
	popup.find_child("LineEdit").text_submitted.connect(finalize_save)
	#var filename = filename_input.text
	#if filename.is_empty():
	#	filename = "my_circuit"  # Default name
	#save_circuit(%Graph, filename)

func finalize_save(text):
	var filename = text
	if filename.is_empty():
		filename = "my_circuit"  # Default name
	save_circuit(%Graph, filename)

func _on_load_button_pressed():
	var popup = preload("res://popup_windows/saveload_popup.tscn").instantiate()
	add_child(popup)
	popup.find_child("LineEdit").text_submitted.connect(finalize_load)

func finalize_load(text):
	var filename = text
	if filename.is_empty():
		print("Please enter a filename to load")
		return
	load_circuit(%Graph, filename)

# Quick save to last used filename
func quick_save() -> void:
	if current_filename.is_empty():
		current_filename = "quick_save"
	save_circuit(%Graph, current_filename)

# Quick load from last used filename
func quick_load() -> void:
	if current_filename.is_empty():
		print("No previous save to load")
		return
	load_circuit(%Graph, current_filename)
