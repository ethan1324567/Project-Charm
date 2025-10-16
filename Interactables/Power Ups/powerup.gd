extends Area3D

@export_enum("speed","jump","health") var powerup_type: String ="speed"
@export var value_modifier: float = 1.5
@export var duration: float = 5.0
@export var color: Color = Color(1,1,1)

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	_set_color(color)
	
	if not is_connected("body_entered",Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
		
func _set_color(new_color: Color) -> void:
	if not mesh:
		push_warning("MeshInstance3D not found in PowerUp Node")
		return
	var mat : StandardMaterial3D
	if mesh.get_surface_override_material_count() == 0 or not mesh.get_surface_override_material(0):
		mat = StandardMaterial3D.new()
	else:
		mat = mesh.get_surface_override_material(0).duplicate()
	mat.albedo_color = new_color
	mesh.set_surface_override_material(0, mat)
		
func _on_body_entered(body: Node3D):
	#print(body)
	_apply_powerup(body)
	queue_free()
		
func _apply_powerup(player: Node3D):
	if player.has_method("apply_power_up"):
		player.apply_power_up(powerup_type, value_modifier, duration)
