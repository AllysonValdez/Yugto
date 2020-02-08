extends Area2D

enum BulletDamage { 
	BULLET_DAMAGE_NORMAL = 6,
	BULLET_DAMAGE_UPPERCUT = 10,
	BULLET_DAMAGE_STRATO = 18,
	BULLET_DAMAGE_MOTHER = 32
}

export var damage = BulletDamage.BULLET_DAMAGE_NORMAL
var speed = 540

func _process(delta: float) -> void:
	position.y -= speed * delta

func set_damage_level(damage_category):
	match damage_category:
		BulletDamage.BULLET_DAMAGE_NORMAL:
			damage = BulletDamage.BULLET_DAMAGE_NORMAL
		BulletDamage.BULLET_DAMAGE_UPPERCUT:
			damage = BulletDamage.BULLET_DAMAGE_UPPERCUT
		BulletDamage.BULLET_DAMAGE_STRATO:
			damage = BulletDamage.BULLET_DAMAGE_STRATO
		BulletDamage.BULLET_DAMAGE_MOTHER:
			damage = BulletDamage.BULLET_DAMAGE_MOTHER
	
func _on_Bomb_body_entered(body: Node) -> void:
	if body.is_in_group("blimp"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
