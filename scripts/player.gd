
extends CharacterBody2D

enum PlayerState {
	walk,
	idle,
	hurt,
	attack,
	death
}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe

@export var velocidade: float = 70.0
@export var vida_maxima: int = 5
@export var tempo_hurt: float = 0.4
@export var dano_do_golpe: int = 2
@export var quadro_do_golpe: int = 3

var vida: int
var status: PlayerState
var tempo_no_hurt: float = 0.0
var golpe_aplicado: bool = false

var direcao: Vector2 = Vector2.ZERO
var ultima_direcao: Vector2 = Vector2.DOWN
var direcao_ataque: Vector2 = Vector2.DOWN

func _ready() -> void:
	vida = vida_maxima
	area_golpe.monitoring = false
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if status == PlayerState.death:
		velocity = Vector2.ZERO
		return

	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.attack:
			attack_state()
		PlayerState.death:
			death_state()

	move_and_slide()

func go_to_idle_state() -> void:
	status = PlayerState.idle
	velocity = Vector2.ZERO
	anim.modulate = Color.WHITE
	area_golpe.monitoring = false
	anim.play(animacao_direcional("idle"))

func go_to_walk_state() -> void:
	status = PlayerState.walk
	anim.modulate = Color.WHITE
	anim.play(animacao_direcional("walk"))

func go_to_attack_state() -> void:
	status = PlayerState.attack
	velocity = Vector2.ZERO
	golpe_aplicado = false
	direcao_ataque = ultima_direcao
	atualizar_area_golpe()
	area_golpe.monitoring = true
	anim.play(animacao_direcional("attack"))

func idle_state() -> void:
	velocity = Vector2.ZERO
	ler_direcao()

	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return

	if direcao != Vector2.ZERO:
		go_to_walk_state()
		return

func walk_state() -> void:
	ler_direcao()
	velocity = direcao * velocidade

	if direcao != Vector2.ZERO:
		ultima_direcao = direcao
		anim.play(animacao_direcional("walk"))
	else:
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return

func hurt_state(delta: float) -> void:
	velocity = Vector2.ZERO
	tempo_no_hurt += delta

	var quantidade_frames := anim.sprite_frames.get_frame_count("hurt")

	if tempo_no_hurt >= tempo_hurt or anim.frame >= quantidade_frames - 1:
		go_to_idle_state()

func attack_state() -> void:
	velocity = Vector2.ZERO

	if not golpe_aplicado and anim.frame >= quadro_do_golpe:
		golpe_aplicado = true

		for corpo in area_golpe.get_overlapping_bodies():
			if corpo != self and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano_do_golpe)

	var nome_animacao := animacao_direcional("attack")
	var quantidade_frames := anim.sprite_frames.get_frame_count(nome_animacao)

	if anim.frame >= quantidade_frames - 1:
		area_golpe.monitoring = false
		golpe_aplicado = false
		go_to_idle_state()

func ler_direcao() -> void:
	direcao = Input.get_vector(
		"esquerda",
		"direita",
		"cima",
		"baixo"
	)

	if direcao != Vector2.ZERO:
		ultima_direcao = direcao

func animacao_direcional(acao: String) -> String:
	var prefixo := "down"

	if abs(ultima_direcao.x) > abs(ultima_direcao.y):
		prefixo = "right" if ultima_direcao.x > 0 else "left"
	else:
		prefixo = "down" if ultima_direcao.y > 0 else "up"

	if acao == "idle" or acao == "walk" or acao == "attack":
		var nome := prefixo if acao == "idle" else acao
		var nome_completo := nome if acao == "idle" else prefixo + "_" + acao

		if anim.sprite_frames.has_animation(nome_completo):
			return nome_completo

		if acao == "idle" and anim.sprite_frames.has_animation(prefixo):
			return prefixo

	return prefixo if anim.sprite_frames.has_animation(prefixo) else acao

func atualizar_area_golpe() -> void:
	var distancia := 20.0
	area_golpe.position = direcao_ataque.normalized() * distancia

func go_to_hurt_state() -> void:
	status = PlayerState.hurt
	tempo_no_hurt = 0.0
	velocity = Vector2.ZERO
	anim.modulate = Color(1, 0.4, 0.4)
	area_golpe.monitoring = false
	anim.play("hurt")

func levar_dano(quantidade: int) -> void:
	if status == PlayerState.hurt:
		return

	if status == PlayerState.attack:
		return

	if status == PlayerState.death:
		return

	vida -= quantidade
	print("vida do jogador: ", vida)

	if vida <= 0:
		morrer()
		return

	go_to_hurt_state()

func morrer() -> void:
	if status == PlayerState.death:
		return

	status = PlayerState.death
	velocity = Vector2.ZERO
	area_golpe.monitoring = false
	collision_shape.set_deferred("disabled", true)
	anim.modulate = Color.WHITE
	anim.play("death")

func death_state() -> void:
	velocity = Vector2.ZERO
