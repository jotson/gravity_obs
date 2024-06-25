extends TextureRect

@export var DEVICE: int = 0
@export var DEADZONE: float = 0.2

var ANALOG_MOVE = 8
var ls_pos : Vector2
var rs_pos : Vector2

func _ready():
	ls_pos = $LS.position
	rs_pos = $RS.position


func _process(_delta):
	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_A):
		$A.button_pressed = true
	else:
		$A.button_pressed = false

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_B):
		$B.button_pressed = true
	else:
		$B.button_pressed = false

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_X):
		$X.button_pressed = true
	else:
		$X.button_pressed = false

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_Y):
		$Y.button_pressed = true
	else:
		$Y.button_pressed = false

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_LEFT_SHOULDER):
		$LB.show()
	else:
		$LB.hide()

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_RIGHT_SHOULDER):
		$RB.show()
	else:
		$RB.hide()

	if Input.get_joy_axis(DEVICE, JOY_AXIS_TRIGGER_LEFT):
		$LT.show()
		$LT/Label.text = "%d" % [Input.get_joy_axis(DEVICE, JOY_AXIS_TRIGGER_LEFT) * 100]
	else:
		$LT.hide()

	if Input.get_joy_axis(DEVICE, JOY_AXIS_TRIGGER_RIGHT):
		$RT.show()
		$RT/Label.text = "%d" % [Input.get_joy_axis(DEVICE, JOY_AXIS_TRIGGER_RIGHT) * 100]
	else:
		$RT.hide()

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_GUIDE):
		$Select.button_pressed = true
	else:
		$Select.button_pressed = false

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_START):
		$Start.button_pressed = true
	else:
		$Start.button_pressed = false

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_DPAD_UP):
		$Dpad/Up.show()
	else:
		$Dpad/Up.hide()

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_DPAD_DOWN):
		$Dpad/Down.show()
	else:
		$Dpad/Down.hide()

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_DPAD_LEFT):
		$Dpad/Left.show()
	else:
		$Dpad/Left.hide()

	if Input.is_joy_button_pressed(DEVICE, JOY_BUTTON_DPAD_RIGHT):
		$Dpad/Right.show()
	else:
		$Dpad/Right.hide()
		
	# 0,1 left stick
	# 2,3 right stick
	var v = Vector2(Input.get_joy_axis(DEVICE, JOY_AXIS_LEFT_X), Input.get_joy_axis(DEVICE, JOY_AXIS_LEFT_Y))
	if v.length() > DEADZONE:
		$LS.button_pressed = true
		$LS.position = ls_pos + v * ANALOG_MOVE
		$LS/Label.text = "%d,%d" % [v.x * 100, v.y * 100]
	else:
		$LS.button_pressed = false
		$LS.position = ls_pos
		$LS/Label.text = ""

	v = Vector2(Input.get_joy_axis(DEVICE, JOY_AXIS_RIGHT_X), Input.get_joy_axis(DEVICE, JOY_AXIS_RIGHT_Y))
	if v.length() > DEADZONE:
		$RS.button_pressed = true
		$RS.position = rs_pos + v * ANALOG_MOVE
		$RS/Label.text = "%d,%d" % [v.x * 100, v.y * 100]
	else:
		$RS.button_pressed = false
		$RS.position = rs_pos
		$RS/Label.text = ""
