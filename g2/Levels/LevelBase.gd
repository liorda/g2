extends Node2D

# not "onready" so that we can use it in _enter_tree
#onready var GameManager = get_node("/root/GameManager")
var GameManager

export(String, "shooter", "obstacles") var level_type = "shooter"
export(float, 0.0, 1000.0, 10.0) var level_speed = 90.0

export(Vector2) var initial_pos = Vector2(640.0, 360.0)
export(Vector2) var initial_rot = 0.0

enum LEVEL_TYPE {
	invalid = 0
	shooter = 1
	obstacles = 2
}
var type = LEVEL_TYPE.invalid

const layer0_speed = 10.0
const layer1_speed = 5.0
const layer1_default_speed = 50.0
const layer2_speed = 3.5

onready var time_countdown = 30
onready var timer = get_node("LevelCountdown")

onready var parallax_layer0 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background0")
onready var parallax_layer1 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background1")
onready var parallax_layer2 = get_node("GameLayer").get_node("ParallaxBackground").get_node("Background2")

func init_type():
	if level_type == "shooter":
		type = LEVEL_TYPE.shooter
	elif level_type == "obstacles":
		type = LEVEL_TYPE.obstacles

func setup():
	if type == LEVEL_TYPE.obstacles:
		var ship = GameManager.get_current_ship()
		ship.fake_speed = level_speed
	elif type == LEVEL_TYPE.shooter:
		var ship = GameManager.get_current_ship()
		assert(ship)
		if GameManager.ship_pos_on_level_end != null:
			ship.set_pos(GameManager.ship_pos_on_level_end)
			ship.set_rot(GameManager.ship_rot_on_level_end)
	GameManager.level_ready(self)
	get_hud().set_time(time_countdown)
	timer.start()

func _enter_tree():
	GameManager = get_node("/root/GameManager")
	var v = get_name();
	var h = hash(v)
	GameManager.dbg(v + " starting with seed " + String(h))
	seed(h)

func _ready():
	init_type()
	setup()
	set_process(true)
	if type == LEVEL_TYPE.obstacles:
		var meteors = get_tree().get_nodes_in_group("meteors")
		for m in meteors:
			m.set_linear_velocity(m.get_linear_velocity() + Vector2(0.0, level_speed))

func _process(delta):
	var ship = GameManager.get_current_ship()
	
	var layer0_offset = Vector2(0.0,0.0)
	var layer1_offset = Vector2(0.0,0.0)
	var layer2_offset = Vector2(0.0,0.0)
	
	if ship:
		layer0_offset = ship.movement_offset / layer0_speed
		layer1_offset = ship.movement_offset / layer1_speed
		layer2_offset = ship.movement_offset / layer2_speed
		
	# move the stars and clouds based on the ship's movement
	parallax_layer0.set_motion_offset(parallax_layer0.get_motion_offset() - layer0_offset)
	parallax_layer2.set_motion_offset(parallax_layer2.get_motion_offset() - layer2_offset)
	
	# the middle layer has a fixed movement regardless of the ship's direction
	var asteroids_background_movement = (Vector2(layer1_default_speed,0) * delta) - layer1_offset
	parallax_layer1.set_motion_offset(parallax_layer1.get_motion_offset() + asteroids_background_movement)

func on_game_over():
	timer.stop()

# called by GameManager
func level_lost():
	return false

# called by GameManager
func level_won():
	var ship = GameManager.get_current_ship()
	if !ship or !ship.active():
		return false
	if type == LEVEL_TYPE.shooter:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.empty():
			return true
	elif type == LEVEL_TYPE.obstacles:
		var meteors = get_tree().get_nodes_in_group("meteors")
		for m in meteors:
			if m.get_global_pos().y < get_viewport_rect().size.y:
				return false
		return true
	return false

# called by GameManager
func get_hud():
	var hud = get_tree().get_nodes_in_group("hud")
	if hud.empty():
		return null
	return hud[0]

func resume_parallax():
	pass
	# resume camera based on current level type
	#if level_type == "shooter":
	#	get_node("GameLayer/DirectionCamera").make_current()
	#elif level_type == "obstacles":
	#	get_node("GameLayer/VerticalCamera").make_current()
	#else:
	#	GameManager.dbg("resume_parallax: unknown level type " + level_type)

func _on_LevelCountdown_timeout():
	if time_countdown > 0:
		time_countdown -= 1
		get_hud().set_time(time_countdown)
		