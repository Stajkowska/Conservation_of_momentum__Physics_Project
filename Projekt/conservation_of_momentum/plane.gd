extends Node2D

var velocity       = Vector2( 0.0, 0.0 )
var mass_plane     = 1000.0
var mass_rocket    = 100.0

var drop_angle     = deg2rad(-45)
var drop_direction = Vector2.RIGHT
var drop_speed     = 120.0

var rocket_object = load("res://rocket.tscn")

# target position
#onready var target      = $"../target".position
onready var rocket_spawn = $plane/rocket
onready var target   = $"../target"
onready var diffX = $"../Node2D"


var gravity  = 100.0

var SolveQuatric = [1,1,1,1]
var t0 = 1
var t1 = 1

var maxRan = 0

var punktStrzalu = Vector2.ZERO

func _ready():
	pass

func _physics_process(delta):
	var a = target.position - position
	

#	TODO: solve the equation of motion
	position += velocity * delta
	
	if self.position[0] < 0 :
		$plane.scale.x = $plane.scale.x * -1
		velocity      *= -1
	if self.position[0] > get_viewport_rect().size.x :
		$plane.scale.x = $plane.scale.x * -1
		velocity      *= -1

func calculateRange():
	var cs = cos(-drop_angle)
	var sn = sin(-drop_angle)
	var speed = drop_speed
	var Ran = (speed * cs/gravity) * (speed*sn + sqrt(speed*speed*sn*sn + 2 *gravity * (target.global_position.y-rocket_spawn.global_position.y) ))
	return Ran
	
func calculateAngleStationary():
	var diff = rocket_spawn.global_position - target.global_position
	var y = diff.y
	var x = diff.x
	var gx = gravity * x

	var speed = drop_speed
	var speed2 = speed * speed
	var speed4 = speed * speed * speed * speed

	var root = speed4 - gravity*(gravity*x*x + 2 * y *speed2)

	if (root < 0):
		return 0
	var sq = sqrt(root)
	var lowAng = atan((speed2 - sq)/gx)
	var highAng = atan((speed2 + sq)/gx)
	
	drop_angle = lowAng
	
func calculateAngleForX(givenX):
	var diff = target.global_position - rocket_spawn.global_position

	var y = -diff.y
	var x = givenX
	var gx = gravity * x

	var speed = drop_speed
	var speed2 = speed * speed
	var speed4 = speed * speed * speed * speed
	
	var root = speed4 - gravity*(gravity*x*x + 2 * y *speed2)

	if (root < 0):
		return 0
	var sq = sqrt(root)
	var lowAng = atan2((speed2 - sq),gx)        
	var highAng = atan2((speed2 + sq),gx)

	return lowAng
	
	
func deltaX():
	var speed = (velocity + drop_direction * drop_speed).length()
	var diff = target.global_position - rocket_spawn.global_position
	var y = diff.y
	var Xp = diff.x
	
	var sn = sin(-drop_angle)

	var root = speed*speed*sn + 2*gravity*y
	if (root<0):
		return 0
	var dropTime = speed*sn/gravity + (sqrt(root))/gravity
	
	var deltaX = target.velocity.x * dropTime
	
	if (0.9 * get_viewport_rect().size.x < target.global_position.x+deltaX):
		var temp = deltaX - 0.9 * get_viewport_rect().size.x 
		Xp = Xp+temp
	elif (0.1*get_viewport().size.x > target.global_position.x+deltaX):
		var temp = 0.1 * get_viewport_rect().size.x + deltaX
		Xp = Xp+temp
	else:
		Xp = Xp + deltaX


	var angle = 0
	angle = -calculateAngleForX(Xp)
	drop_angle = angle

	
func _process(delta):
	if Input.is_action_just_released("release_rocket"):
		release_rocket()
	if Input.is_action_pressed("rotate_velocity_left"):
		drop_angle += 1.0 * delta
	if Input.is_action_pressed("rotate_velocity_right"):
		drop_angle -= 1.0 * delta
		
	drop_direction = Vector2(cos(drop_angle),sin(drop_angle))
	maxRan = calculateRange()
	diffX.get_child(2).text = "Distance: " + str(target.global_position.x - rocket_spawn.global_position.x)
	diffX.get_child(3).text = "Angle: " + str(rad2deg(drop_angle))
	deltaX()
	update()


func release_rocket():
	if mass_plane > mass_rocket:
		var new_rocket = rocket_object.instance()
		new_rocket.global_position = rocket_spawn.global_position
		new_rocket.velocity = velocity + drop_direction * drop_speed
		
		mass_plane -= mass_rocket
		velocity -= (mass_rocket / mass_plane) * (drop_direction * drop_speed)

		get_parent().add_child( new_rocket )
		
func _draw():
	draw_line( Vector2.ZERO, velocity, Color( 0.56, 0.89, 0.42, 0.7 ), 3)
	draw_line( Vector2.ZERO, drop_direction * drop_speed , Color(0.42, 0.42, 0.95, 0.7), 3 )
	draw_line( Vector2.ZERO, Vector2.DOWN* 800, Color(1,1,1,0.2), 1 )
	draw_line( Vector2.ZERO, Vector2.RIGHT*maxRan, Color(Color.red), 3 )


func _on_HSlider_value_changed(value):
	drop_speed = value


func _on_HSlider2_value_changed(value):
	global_position.y = value
