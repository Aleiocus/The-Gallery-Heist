extends PanelContainer

@onready var _labels_container : VBoxContainer = $MarginContainer/VBoxContainer

var _variables : Dictionary # {name:label, ..}
const _font_size : int = 12


func _ready():
	hide()

func add_var(name_ : String):
	assert(_variables.has(name_) == false, "Variable already exists")
	var label : Label = Label.new()
	label.text = name_ + ": "
	label.add_theme_font_size_override("font_size", _font_size)
	_labels_container.add_child(label)
	
	if visible == false: show()
	_variables[name_] = label

func remove_var(name_ : String):
	assert(_variables.has(name_), "Variable doesn't exist")
	
	_variables[name_].queue_free()
	_variables.erase(name_)
	
	if _variables.is_empty():
		hide()

func edit_var(name_ : String, value:):
	assert(_variables.has(name_), "Variable doesn't exist")
	
	_variables[name_].text = name_ + ": " + str(value)
