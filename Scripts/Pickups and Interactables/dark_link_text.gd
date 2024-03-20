extends Node2D

@onready var text = $text
var characters = 'abd#&,[/eh_ijlmpqtu?vwxz*~`'
@onready var scrambletimer = $scrambletimer
var txt1 = "eiw"
var txt2 = "s?f"
var lastupdate1 : bool = false
var txtdic = {"txt1":txt1, "txt2":txt2}

func _ready():
	var textscramble = generate_word(characters,6)
	text.text = "http://" +textscramble
	
func generate_word(chars, length):
	var word: String
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word

func _updatetext(txt):
	if lastupdate1 == false:
		txt1 = txt
		lastupdate1 = true
	elif lastupdate1 == true:
		txt2 = txt
		lastupdate1 = false
	text.text = txtdic.values()
	

func _on_scrambletimer_timeout():
	var textscramble = generate_word(characters,3)
	_updatetext(textscramble)
	scrambletimer.start()
