#Código feito por i.a
extends Control

@onready var titulo: Label = $Fundo/Centralizar/Painel/Titulo
@onready var mensagem: Label = $Fundo/Centralizar/Painel/Mensagem
@onready var botao_novamente: Button = $Fundo/Centralizar/Painel/BotaoNovamente
@onready var botao_sair: Button = $Fundo/Centralizar/Painel/BotaoSair


func _ready() -> void:
	titulo.text = "DERROTA!"
	mensagem.text = "Sua aventura chegou ao fim!"

	botao_novamente.text = "Tentar novamente"
	botao_sair.text = "Sair"

	botao_novamente.pressed.connect(jogar_novamente)
	botao_sair.pressed.connect(sair)


func jogar_novamente() -> void:
	get_tree().change_scene_to_file("res://mapas/mapaZ.tscn")


func sair() -> void:
	get_tree().quit()
