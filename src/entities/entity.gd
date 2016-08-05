extends KinematicBody

var hp = 0
var max_hp = 0
var regenerable_hp = 0
var stamina = 0
var max_stamina = 0

var hp_regeneration = 1
var hp_regeneration_interval = 5

var time_hit = 0

var velocity = Vector3()
var on_floor = false
var floor_vel = Vector3()

const MAX_SLOPE_ANGLE = 40

func init(hp, stamina):
	self.hp = hp
	self.max_hp = hp
	self.stamina = stamina
	self.max_stamina = stamina

func move_entity(delta):
	var motion = move(velocity * delta)
	on_floor = false
	floor_vel = Vector3()
	if is_colliding():
		var n = get_collision_normal()
		if (rad2deg(acos(n.dot(Vector3(0, 1, 0)))) < MAX_SLOPE_ANGLE):
			on_floor = true
			floor_vel = get_collider_velocity()
			move(floor_vel * delta)
			var fall = int(- velocity.y - 10)
			if fall > 0:
				damage(fall, 0.5)
			motion = n.slide(motion)
			velocity = n.slide(velocity)
			move(motion)
		else:
			motion = n.slide(motion)
			move(motion)

func die(net=true):
	print("die: ", get_name())
	hp = 0
	regenerable_hp = 0
	if networking.multiplayer and net:
		if networking.server:
			var pckt = networking.new_packet(networking.CMD_SC_DIE, get_name())
			networking.server_broadcast(pckt, get_name())
		else:
			var pckt = networking.new_packet(networking.CMD_CS_DIE, get_name())
			networking.udp.put_var(pckt)
	set_process(false)

func damage(dmg, reg, net=true):
	if hp > 0:
		print("%s: damage of %s" % [get_name(), dmg])
		time_hit = 0
		hp -= dmg
		regenerable_hp = int(hp + dmg * reg)
		if hp <= 0:
			die()
		if networking.multiplayer and net:
			var name = get_parent().get_name()
			var args = {'player': get_name(), 'damage': dmg, 'regenerable': reg}
			if networking.server:
				var pckt = networking.new_packet(networking.CMD_SC_DAMAGE, args)
				networking.server_broadcast(pckt)
			else:
				var pckt = networking.new_packet(networking.CMD_CS_DAMAGE, args)
				networking.udp.put_var(pckt)
	else:
		print(get_name(), " is already dead")

func _process(delta):
	time_hit += delta
	if time_hit > hp_regeneration_interval:
		time_hit = 0
		if regenerable_hp - hp > 0:
			hp += hp_regeneration

func _ready():
	set_process(true)
