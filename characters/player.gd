extends CharacterBody2D


var SPEED = 20
const JUMP_VELOCITY = -300.0
const CLIMB_VELOCITY = -100.0
const CLIMB_WALL = "WallClimb"
const MAX_STAMINA = 100
const STAMINA_DEPLETION_SPEED = 50
const STAMINA_RECOVERY_SPEED = 100
var is_climbing = false
var current_animation = "idle"
var animation_direction = "right"
var stamina = MAX_STAMINA

signal stamina_changed(new_value)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite = $AnimatedSprite2D
@onready var coyotetimer = $CoyoteTimer
@onready var right_wall = $RightWall
@onready var left_wall = $LeftWall
@onready var top_right_wall = $TopRightWall
@onready var top_left_wall = $TopLeftWall
@onready var stamina_bar = $Stamina/StaminaBar
@onready var stamina_show_timer = $StaminaShowTimer
@onready var calcetin = $CanvasLayer/Calcetin
@onready var bota = $CanvasLayer/Botas
@onready var guante = $CanvasLayer/Guantes


var rng = RandomNumberGenerator.new()
var can_jump = true
var first_cycle = true
var can_paraglide = true
var is_paragliding = true

func animate(animation):
	if (animation == "idle"):
		animated_sprite.play(animation)
		return
	
	animated_sprite.play(animation + "_" + animation_direction)

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

func set_stamina(new_value):
	if stamina != new_value:
		stamina = new_value
		stamina_changed.emit(new_value)
		if new_value == MAX_STAMINA && stamina_show_timer.is_stopped():
			stamina_show_timer.start()

func _physics_process(delta): 	
	if not is_on_floor():
		if (Input.is_action_pressed("paraglider")):
			if (can_paraglide):
				velocity.y = 0
				can_paraglide = false
			velocity.y += gravity/5 * delta
			is_paragliding = true
		else:
			velocity.y += gravity * delta
			is_paragliding = false
		
		if (velocity.y <= 0):
			current_animation = "jump"
		else:
			if is_paragliding:
				current_animation = "gliding"
			else:
				current_animation = "fall"
			
		if (coyotetimer.is_stopped() and can_jump and first_cycle):
			coyotetimer.start()
			first_cycle = false	
					
	else:
		can_paraglide = true
		can_jump = true
		first_cycle = true
		set_stamina(min(stamina + STAMINA_RECOVERY_SPEED * delta, MAX_STAMINA) )

		
		if not is_climbing:
			if (velocity.x == 0):
				current_animation = "idle"
			else:
				current_animation = "run"

	# Handle Jump
	if bota.visible and Input.is_action_just_pressed("ui_accept") and (is_on_floor() or (!coyotetimer.is_stopped() and can_jump)):
		jump()
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	var direction = Input.get_axis("ui_left", "ui_right")


	if (calcetin.visible):
		if (SPEED < 200):
			SPEED = 200
	else:
		SPEED = 0.2		
	if direction:
		velocity.x = direction / abs(direction) * SPEED #dividido por el valor absoluto para quedarnos solo con el signo y que la velocidad no dependa del joystick/flecha

		if (velocity.x <= 0):
			animation_direction = "left"
		else:
			animation_direction = "right"

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	# comprobar que no caiga al vacio
	if position.y > 600:
		get_tree().reload_current_scene()	
	move_and_slide()
	
	wall_climb(delta)
	animate(current_animation)

func wall_climb(delta):
	var vertical_direction = Input.get_axis("ui_down", "ui_up")
	if (Input.is_action_pressed("climb") and nextToWall() and stamina > 0 and guante.visible):
		if current_animation != "climb":
			#starts climbing
			print("empieza a escalar")
			current_animation = "climb"
		set_stamina(stamina - STAMINA_DEPLETION_SPEED * delta)
		is_climbing = true
	else:
		is_climbing = false
	
	if is_climbing:
		velocity.y = vertical_direction * CLIMB_VELOCITY;
		if aboutToFinishClimb():
			jump(0.6,false)

