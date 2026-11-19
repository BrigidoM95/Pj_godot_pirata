#Código feito por i.a
extends CharacterBody2D

enum Estado {
	PROCURANDO,
	PERSEGUINDO,
	PARADO
}

@export var velocidade: float = 40.0
@export var vida: int = 1
@export var dano_contato: int = 1
@export var intervalo_dano: float = 1.0

@onready var agente: NavigationAgent2D = $NavigationAgent2D
@onready var timer_navegacao: Timer = $TimerNavegacao
@onready var area_dano: Area2D = $AreaDano

var jogador: Node2D = null
var estado: Estado = Estado.PROCURANDO
var tempo_para_dano: float = 0.0


func _ready() -> void:
	add_to_group("inimigo")

	timer_navegacao.wait_time = 0.2
	timer_navegacao.timeout.connect(atualizar_destino)
	timer_navegacao.start()

	area_dano.body_entered.connect(ao_tocar_jogador)
	area_dano.body_exited.connect(ao_sair_jogador)


func _physics_process(delta: float) -> void:
	if tempo_para_dano > 0.0:
		tempo_para_dano = maxf(0.0, tempo_para_dano - delta)

	match estado:
		Estado.PROCURANDO:
			procurar_jogador()

		Estado.PERSEGUINDO:
			perseguir_jogador()

		Estado.PARADO:
			velocity = Vector2.ZERO
			move_and_slide()

	if is_instance_valid(jogador):
		if area_dano.overlaps_body(jogador):
			causar_dano()


func procurar_jogador() -> void:
	jogador = get_tree().get_first_node_in_group("jogador") as Node2D

	if jogador != null:
		estado = Estado.PERSEGUINDO
		agente.target_position = jogador.global_position


func atualizar_destino() -> void:
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Node2D

	if jogador == null:
		return

	agente.target_position = jogador.global_position


func perseguir_jogador() -> void:
	if not is_instance_valid(jogador):
		jogador = null
		estado = Estado.PROCURANDO
		velocity = Vector2.ZERO
		return

	if agente.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var proximo := agente.get_next_path_position()
	var direcao := global_position.direction_to(proximo)

	velocity = direcao * velocidade
	move_and_slide()


func ao_tocar_jogador(corpo: Node2D) -> void:
	if not corpo.is_in_group("jogador"):
		return

	jogador = corpo


func ao_sair_jogador(corpo: Node2D) -> void:
	if corpo == jogador:
		jogador = null


func causar_dano() -> void:
	if tempo_para_dano > 0.0:
		return

	if not is_instance_valid(jogador):
		return

	if jogador.has_method("levar_dano"):
		jogador.levar_dano(dano_contato)
		tempo_para_dano = intervalo_dano


func levar_dano(quantidade: int = 1) -> void:
	vida -= quantidade
	print("Esqueleto recebeu dano! Vida restante: ", vida)

	if vida <= 0:
		var cena_atual := get_tree().current_scene

		if cena_atual != null and cena_atual.has_method("inimigo_morreu"):
			cena_atual.inimigo_morreu(self)

		timer_navegacao.stop()
		area_dano.set_deferred("monitoring", false)
		queue_free()
