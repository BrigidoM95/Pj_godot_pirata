
extends CharacterBody2D

enum PlayerState {
	walk,
	idle,
	hurt,
	attack,
	death
}

@onready var label_vida: Label = $CanvasLayer/LabelVida
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = $AreaGolpe
@onready var forma_golpe: CollisionShape2D = $AreaGolpe/CollisionShape2D

@export var velocidade: float = 70.0
@export var vida_maxima: int = 5
@export var tempo_hurt: float = 0.4
@export var duracao_invulnerabilidade: float = 1.0
@export var dano_do_golpe: int = 2
@export var quadro_do_golpe: int = 3
@export var distancia_golpe: float = 24.0

var vida: int
var status: PlayerState
var tempo_no_hurt: float = 0.0
var tempo_invulneravel: float = 0.0
var golpe_aplicado: bool = false

var direcao: Vector2 = Vector2.ZERO
var ultima_direcao: Vector2 = Vector2.DOWN
var direcao_ataque: Vector2 = Vector2.DOWN
var tempo_piscar: float = 0.0
var jogador_visivel: bool = true


func _ready() -> void:
	vida = vida_maxima
	atualizar_hud_vida()

	if not is_in_group("jogador"):
		add_to_group("jogador")

	area_golpe.monitoring = false

	if forma_golpe.shape is CircleShape2D:
		forma_golpe.shape = forma_golpe.shape.duplicate()
		forma_golpe.shape.radius = 18.0

	go_to_idle_state()


func _physics_process(delta: float) -> void:
	if tempo_invulneravel > 0.0:
		tempo_invulneravel = maxf(0.0, tempo_invulneravel - delta)
		atualizar_piscar(delta)
	else:
		anim.visible = true
		jogador_visivel = true

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
	area_golpe.set_deferred("monitoring", false)
	anim.play(animacao_direcional("idle"))


func go_to_walk_state() -> void:
	status = PlayerState.walk
	anim.modulate = Color.WHITE
	anim.play(animacao_direcional("walk"))


func go_to_attack_state() -> void:
	status = PlayerState.attack
	velocity = Vector2.ZERO
	golpe_aplicado = false

	direcao_ataque = direcao_cardinal(ultima_direcao)
	atualizar_area_golpe()

	anim.play(animacao_direcional("attack"))
	area_golpe.set_deferred("monitoring", true)


func idle_state() -> void:
	velocity = Vector2.ZERO
	ler_direcao()

	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return

	if direcao != Vector2.ZERO:
		go_to_walk_state()


func walk_state() -> void:
	ler_direcao()
	velocity = direcao * velocidade

	if direcao != Vector2.ZERO:
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

	var nome_animacao := animacao_direcional("attack")
	var quantidade_frames := anim.sprite_frames.get_frame_count(nome_animacao)

	if quantidade_frames <= 0:
		print("ERRO: animação sem quadros: ", nome_animacao)
		area_golpe.set_deferred("monitoring", false)
		go_to_idle_state()
		return

	var quadro_acerto := clampi(
		quadro_do_golpe,
		0,
		quantidade_frames - 1
	)

	if not golpe_aplicado and anim.frame >= quadro_acerto:
		golpe_aplicado = true

		var corpos := area_golpe.get_overlapping_bodies()

		for corpo in corpos:
			if corpo != self and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano_do_golpe)

	if anim.frame >= quantidade_frames - 1:
		area_golpe.set_deferred("monitoring", false)
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


func direcao_cardinal(vetor: Vector2) -> Vector2:
	if vetor == Vector2.ZERO:
		return Vector2.DOWN

	if abs(vetor.x) > abs(vetor.y):
		return Vector2.RIGHT if vetor.x > 0 else Vector2.LEFT

	return Vector2.DOWN if vetor.y > 0 else Vector2.UP


func animacao_direcional(acao: String) -> String:
	var cardinal := direcao_cardinal(
		direcao_ataque if acao == "attack" else ultima_direcao
	)

	if acao == "attack":
		if cardinal == Vector2.LEFT:
			return "attack_e"
		elif cardinal == Vector2.RIGHT:
			return "attack_d"
		elif cardinal == Vector2.UP:
			return "attack_c"
		else:
			return "attack_b"

	if cardinal == Vector2.LEFT:
		return "left"
	elif cardinal == Vector2.RIGHT:
		return "right"
	elif cardinal == Vector2.UP:
		return "up"
	else:
		return "down"


func atualizar_area_golpe() -> void:
	area_golpe.position = direcao_ataque * distancia_golpe


func go_to_hurt_state() -> void:
	status = PlayerState.hurt
	tempo_no_hurt = 0.0
	velocity = Vector2.ZERO

	tempo_piscar = 0.0
	jogador_visivel = true
	anim.visible = true
	anim.modulate = Color.WHITE

	area_golpe.set_deferred("monitoring", false)

	anim.play("hurt")



func levar_dano(quantidade: int) -> void:
	if tempo_invulneravel > 0.0:
		return

	if status == PlayerState.attack:
		return

	if status == PlayerState.death:
		return

	vida -= quantidade
	atualizar_hud_vida()

	tempo_invulneravel = duracao_invulnerabilidade

	print("Vida do jogador: ", vida)

	if vida <= 0:
		morrer()

		var cena_atual := get_tree().current_scene

		if cena_atual != null and cena_atual.has_method("mostrar_derrota"):
			cena_atual.call_deferred("mostrar_derrota")

		return

	go_to_hurt_state()


func morrer() -> void:
	if status == PlayerState.death:
		return

	status = PlayerState.death
	velocity = Vector2.ZERO

	area_golpe.set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)

	anim.modulate = Color.WHITE
	anim.play("death")


func death_state() -> void:
	velocity = Vector2.ZERO


func atualizar_hud_vida() -> void:
	var coracoes := ""

	for i in range(vida_maxima):
		if i < vida:
			coracoes += "♥ "
		else:
			coracoes += "♡ "

	label_vida.text = coracoes.strip_edges()
	
	
func atualizar_piscar(delta: float) -> void:
	tempo_piscar += delta

	if tempo_piscar >= 0.1:
		tempo_piscar = 0.0
		jogador_visivel = not jogador_visivel
		anim.visible = jogador_visivel
