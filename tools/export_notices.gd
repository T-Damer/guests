extends SceneTree

## Include license notices returned by the exact engine used for the export.
func _initialize() -> void:
	var path: String = ProjectSettings.globalize_path("res://").path_join("build/GODOT-LICENSES.txt")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("GUESTS_NOTICES_FAILED")
		quit(1)
		return
	file.store_string(Engine.get_license_text() + "\n\nTHIRD-PARTY COPYRIGHTS\n")
	file.store_string(JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\nLICENSE TEXTS\n")
	file.store_string(JSON.stringify(Engine.get_license_info(), "\t") + "\n")
	file.close()
	print("GUESTS_NOTICES_OK")
	quit(0)
