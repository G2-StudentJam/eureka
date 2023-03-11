extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const CLIMB_VELOCITY = -100.0
const CLIMB_WALL = "WallClimb"
var is_climbing = false
var current_animation = "idle"



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D
@onready var coyotetimer = $CoyoteTimer
@onready var right_wall = $RightWall
@onready var left_wall = $LeftWall
@onready var top_right_wall = $TopRightWall
@onready var top_left_wall = $TopLeftWall

var rng = RandomNumberGenerator.new()
var can_jump = true
var first_cycle = true

func animate(animation):
	if (animation == "idle"):
		animated_sprite.play(animation)
		return
		
	if velocity.x >= 0:
		animated_sprite.play(animation + "_right")
	else:
		animated_sprite.play(animation + "_left")

func nextToWall():
	return is_raycast_colliding(right_wall, CLIMB_WALL) or is_raycast_colliding(left_wall, CLIMB_WALL)

func is_raycast_colliding(raycaster, object_name):
	return raycaster.is_colliding() and raycaster.get_collider().get("name") == object_name

func aboutToFinishClimb():
	var right_side = is_raycast_colliding(right_wall, CLIMB_WALL) and not is_raycast_colliding(top_right_wall, CLIMB_WALL)
	var left_side = is_raycast_colliding(left_wall, CLIMB_WALL) and not is_raycast_colliding(top_left_wall, CLIMB_WALL)
	return right_side or left_side
	
func jump(multiplier=1.0, play_sound=true):
	can_jump = false
	velocity.y = JUMP_VELOCITY * multiplier
	if (play_sound):
		var jump_sound = rng.randi_range(1, 3)
		if jump_sound == 1:
			$Background/Jump1.play()
		if jump_sound == 2:
			$Background/Jump2.play()
		if jump_sound == 3:
			$Background/Jump3.play()
	

func _physics_process(delta): 	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
		if (velocity.y <= 0):
			current_animation = "jump"
		else:
			current_animation = "fall"
			
			
		if (coyotetimer.is_stopped() and can_jump and first_cycle):
			coyotetimer.start()
			first_cycle = false	
					
	else:
		can_jump = true
		first_cycle = true
		
		if not is_climbing:
			if (velocity.x == 0):
				current_animation = "idle"
			else:
				current_animation = "run"

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or (!coyotetimer.is_stopped() and can_jump)):
		jump()
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")

	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		
	# comprobar que no caiga al vacio
	if position.y > 600:
		get_tree().reload_current_scene()	
	move_and_slide()
	wall_climb()
	animate(current_animation)

func wall_climb():
	var vertical_direction = Input.get_axis("ui_down", "ui_up")
	
	if (Input.is_action_pressed("climb") and nextToWall()):
		if current_animation != "climb":
			current_animation = "climb"
		is_climbing = true
	else:
		is_climbing = false
	
	if is_climbing:
		velocity.y = vertical_direction * CLIMB_VELOCITY;
		if aboutToFinishClimb():
			jump(0.6,false)
	
	
