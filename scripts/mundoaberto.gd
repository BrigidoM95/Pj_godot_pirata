
extends Node2D

@export var objetivo_abates: int = 1
@export var limite_inimigos_criados: int = 50

const CENA_INIMIGO: PackedScene = preload("res://entidades/inimigo.tscn")

@onready var label_abates: Label = $CanvasLayer/LabelAbates
@onready var timer_spawn: Timer = $Nascedouros/TimerSpawn

@onready var pontos_spawn: Array[Marker2D] = [
	$Nascedouros/esquerda,
	$Nascedouros/direita,
	$Nascedouros/cima,
	$Nascedouros/baixo
]

var abates: int = 0
var inimigos_criados: int = 0
var jogo_finalizado: bool = false


func _ready() -> void:
	atualizar_contador()

	timer_spawn.wait_time = 0.8
	timer_spawn.timeout.connect(criar_inimigo)
	timer_spawn.start()


func criar_inimigo() -> void:
	if jogo_finalizado:
		timer_spawn.stop()
		return

	if inimigos_criados >= limite_inimigos_criados:
		timer_spawn.stop()
		print("Limite de inimigos criados atingido!")
		return

	var ponto_escolhido: Marker2D = pontos_spawn.pick_random()

	var novo_inimigo := CENA_INIMIGO.instantiate() as Node2D

	add_child(novo_inimigo)
	novo_inimigo.global_position = ponto_escolhido.global_position

	inimigos_criados += 1

	print(
		"Inimigos criados: ",
		inimigos_criados,
		"/",
		limite_inimigos_criados
	)


func inimigo_morreu(_inimigo: Node2D) -> void:
	if jogo_finalizado:
		return

	abates += 1
	atualizar_contador()

	print("Abates registrados: ", abates, "/", objetivo_abates)

	if abates >= objetivo_abates:
		vencer()


func atualizar_contador() -> void:
	label_abates.text = "Abates: %d/%d" % [
		abates,
		objetivo_abates
	]


func vencer() -> void:
	if jogo_finalizado:
		return

	jogo_finalizado = true
	timer_spawn.stop()

	call_deferred("mostrar_vitoria")


func mostrar_vitoria() -> void:
	get_tree().change_scene_to_file("res://menus/tela_vitoria.tscn")


func mostrar_derrota() -> void:
	if jogo_finalizado:
		return

	jogo_finalizado = true
	timer_spawn.stop()

	get_tree().change_scene_to_file("res://menus/tela_derrota.tscn")
