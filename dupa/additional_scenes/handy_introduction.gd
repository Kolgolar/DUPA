extends Control

signal handy_showed


func _ready() -> void:
	var anim: AnimationPlayer = $Handy/AnimationPlayer
	anim.play("appearing")
	await anim.animation_finished
	await Utillity.wait(1, self)
	handy_showed.emit()
	
