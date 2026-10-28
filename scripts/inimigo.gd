
extends CharacterBody2D

@export var velocidade: float = 40.0
@export var vida: int = 1

var jogador: Node2D


func _ready() -> void:
	add_to_group("inimigo")
	jogador = get_tree().get_first_node_in_group("jogador") as Node2D


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Node2D

	if jogador == null:
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(jogador.global_position) * velocidade
	move_and_slide()


func levar_dano(quantidade: int = 1) -> void:
	vida -= quantidade
	print("Esqueleto recebeu dano! Vida restante: ", vida)

	if vida <= 0:
		var cena_atual := get_tree().current_scene

		if cena_atual != null and cena_atual.has_method("inimigo_morreu"):
			cena_atual.inimigo_morreu(self)

		queue_free()
