extends Area2D

signal paraca_recogido

func _on_body_entered(body):
	if (body.get_name() == "Player"):
		paraca_recogido.emit()
		queue_free()
