extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0
@export var ACCELERATION: float = 400.0
@export var DECELERATION: float = 800.0
@export var TOP_SPEED: float = 700.0
@export var JUMP_CUTOFF: float = 0.25
@export var GRAVITY: float = 1000.0  # Set gravity manually for better control.
@export var SLOPE_ACCELERATION: float = 300.0 # Acceleration on slopes
@export var SLOPE_LIMIT_ANGLE: float = 30.0 # Max angle before sliding on slope
@export var BRAKE_THRESHOLD: float = 100.0 # Minimum speed to trigger brake animation
@export var BRAKE_DECELERATION: float = 1000.0 # Extra deceleration when braking

func _physics_process(delta: float) -> void:
	# Add gravity if not on the floor
	if not is_on_floor():
		
		if velocity.y < -50:
			anim.play("jump")
		elif velocity.y > -50 and velocity.y < 50:
			anim.play("curlout")
		elif velocity.y > 50:
			anim.play("fall")
		velocity.y += GRAVITY * delta

	# Jump logic
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Mid-air jump release for jump cutoff
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= JUMP_CUTOFF

	# Get input direction (-1 for left, 1 for right)
	var direction := Input.get_axis("Left", "Right")
	if velocity.x < 0:
		anim.flip_h = true
	elif velocity.x > 0:
		anim.flip_h = false
	
	# Horizontal movement
	var target_speed: float = direction * TOP_SPEED
	var current_velocity: float = abs(velocity.x)
	var is_braking: bool = false
	
	if direction != 0 and sign(velocity.x) != sign(direction) and current_velocity > BRAKE_THRESHOLD:
		if not is_braking:
			is_braking = true
			if is_on_floor():
				anim.play("brake")  # Play braking animation
			# Apply stronger deceleration while braking
			velocity.x = move_toward(velocity.x, 0, BRAKE_DECELERATION * delta)
	else:
		is_braking = false
		if direction != 0:
			# Accelerate towards the target speed based on input
			velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
		else:
			# Decelerate when no input is pressed
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
	
	if is_on_floor() and not is_braking:
		if current_velocity == 0:
			anim.play("idle")
		elif current_velocity > 0 and current_velocity < 100:
			anim.play("walk")
		elif current_velocity > 200 and current_velocity < 300:
			anim.play("slowjog")
		elif current_velocity > 300 and current_velocity < 400:
			anim.play("jog")
		elif current_velocity > 400 and current_velocity < 500:
			anim.play("run")
		elif current_velocity > 600:
			anim.play("topspeed")
		
	# Slope handling - adjust velocity and rotation when on slopes
	if is_on_floor():
		var floor_normal = get_floor_normal()
#
		# Check if the character is on a slope by comparing the normal
		if floor_normal != Vector2.UP:  # If the normal is not vertical (meaning not flat ground)
			var slope_angle = rad_to_deg(floor_normal.angle_to(Vector2.UP))  # Get the angle relative to vertical
			rotation_degrees = -slope_angle  # Rotate the character to align with the slope
		else:
			rotation_degrees = 0  # Reset rotation to horizontal when on flat ground

		# If the angle is within the slope limit, apply extra force
		if abs(rad_to_deg(floor_normal.angle_to(Vector2.UP))) <= SLOPE_LIMIT_ANGLE:
			velocity.x += SLOPE_ACCELERATION * delta * floor_normal.x

	# Move the character with the current velocity
	move_and_slide()
