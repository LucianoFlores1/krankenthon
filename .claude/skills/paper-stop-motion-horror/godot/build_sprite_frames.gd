extends SceneTree
## Builds one SpriteFrames .tres per character from folders of cleaned PNG drawings.
##
##   res://art/characters/<character>/<PREFIX-anim>/<anything>_01.png ...
##   -> res://art/characters/<character>/<character>_frames.tres
##
## Prefixes (DOGWALK naming): LOOP- loops; ACTN-, CINE-, SYNC- play once.
## Animation name = folder name without prefix, e.g. "LOOP-walk" -> "walk".
## A file ending in _x3.png holds 3 beats (frame duration 3).
##
## Run after importing (PNG must have .import files):
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_sprite_frames.gd [-- res://art/characters]

const DEFAULT_ROOT := "res://art/characters"
const PREFIXES := ["LOOP-", "ACTN-", "CINE-", "SYNC-"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var root: String = args[0] if args.size() > 0 else DEFAULT_ROOT
	var built := 0
	for character in DirAccess.get_directories_at(root):
		if _build_character(root.path_join(character), character):
			built += 1
	print("build_sprite_frames: %d character(s) built under %s" % [built, root])
	quit(0 if built > 0 else 1)


func _build_character(dir: String, character: String) -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_dir in DirAccess.get_directories_at(dir):
		var prefix := _prefix_of(anim_dir)
		if prefix.is_empty():
			continue
		var anim := StringName(anim_dir.trim_prefix(prefix))
		frames.add_animation(anim)
		frames.set_animation_loop(anim, prefix == "LOOP-")
		frames.set_animation_speed(anim, 12.0) # editor preview only; SteppedSprite3D drives frames
		var files := Array(DirAccess.get_files_at(dir.path_join(anim_dir))).filter(
			func(f: String) -> bool: return f.get_extension().to_lower() == "png")
		files.sort()
		for file: String in files:
			var tex := load(dir.path_join(anim_dir).path_join(file)) as Texture2D
			if tex == null:
				push_error("Not imported yet? Run --import first: " + file)
				continue
			frames.add_frame(anim, tex, _hold_of(file))
		print("  %s/%s: %d frames, loop=%s" % [character, anim, frames.get_frame_count(anim), prefix == "LOOP-"])
	if frames.get_animation_names().is_empty():
		return false
	var out := dir.path_join(character + "_frames.tres")
	var err := ResourceSaver.save(frames, out)
	if err != OK:
		push_error("Could not save %s (error %d)" % [out, err])
		return false
	print("  -> " + out)
	return true


func _prefix_of(folder: String) -> String:
	for p in PREFIXES:
		if folder.begins_with(p):
			return p
	return ""


func _hold_of(file: String) -> float:
	var m := RegEx.create_from_string("_x(\\d+)\\.png$").search(file.to_lower())
	return float(m.get_string(1)) if m else 1.0
