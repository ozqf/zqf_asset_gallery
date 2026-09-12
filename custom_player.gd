extends CharacterBody3D

const ACCELERATION_GROUND:float = 200
const ACCELERATION_AIR:float = 25
const FRICTION_FLOOR:float = 0.9
const MOUSE_STATIC_SCALAR:float = 0.0005

@onready var _head:Node3D = $head

@export var mouseSensitivity:float = 5.0
@export var runSpeed:float = 12.0
@export var jumpSpeed:float = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity:float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _start:Transform3D = Transform3D.IDENTITY

func _ready():
	_start = self.global_transform
	pass
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	if Input.is_action_pressed("attack_2"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var inputDir:Vector3 = Vector3()
	inputDir.x = Input.get_axis("move_left", "move_right")
	inputDir.y = Input.get_axis("move_down", "move_up")
	inputDir.z = Input.get_axis("move_forward", "move_backward")
	
	# horizontal movement (X and Z)
	# translate input axes to axes of object
	# Basis is a 3x3 matrix storing x/y/z orientation vectors.
	# we multiply the forward and left of our current orientation
	# to scale them by the input
	var rot:Basis = global_transform.basis
	var pushDir:Vector3 = Vector3()
	pushDir += inputDir.x * rot.x
	pushDir += inputDir.z * rot.z
	pushDir = pushDir.normalized()
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		inputDir = Vector3()
		pushDir = Vector3()
	else:
		if Input.is_action_just_pressed("reset"):
			self.velocity = Vector3()
			self.global_transform = _start
			_head.rotation_degrees = Vector3()
			return
	
	# separate out horizontal component of velocity, calculate it
	# and apply it back. Y is handled independently
	var horizontal:Vector3 = self.velocity
	horizontal.y = 0
	
	# apply friction to slow teh player if required.
	# this is a straight multiply with no delta and thus framerate dependent
	if pushDir == Vector3.ZERO:
		if is_on_floor():
			horizontal = horizontal * FRICTION_FLOOR
	else:
		# apply current input push
		var pushStrength:float = ACCELERATION_GROUND
		if !is_on_floor():
			pushStrength = ACCELERATION_AIR
		horizontal += pushDir * pushStrength * delta
	
	# cap horizontal speed
	horizontal = horizontal.limit_length(runSpeed)
	
	# apply new hoizontal motion back to velocity
	self.velocity.x = horizontal.x
	self.velocity.z = horizontal.z
	
	# vertical
	if is_on_floor():
		if inputDir.y > 0:
			self.velocity.y = jumpSpeed
	else:
		# +y is up so gravity strength is negative when applied. 
		self.velocity += Vector3(0, -_gravity, 0) * delta
	
	# do
	move_and_slide()

func _input(event):
	var motion:InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	# motion.relative is movement from last cursor position.
	# value is in pixels and thus not resolution dependent!
	# sensitivity will go down as resolution goes up here.
	var yawRadians:float = -motion.relative.x * MOUSE_STATIC_SCALAR
	yawRadians *= mouseSensitivity
	self.rotate(Vector3.UP, yawRadians)
	
	var pitchRadians:float = motion.relative.y * MOUSE_STATIC_SCALAR
	pitchRadians *= mouseSensitivity
	var limit:float = deg_to_rad(89.0)
	var headRot:Vector3 = _head.rotation
	headRot.x = clampf(headRot.x + pitchRadians, -limit, limit)
	_head.rotation = headRot
