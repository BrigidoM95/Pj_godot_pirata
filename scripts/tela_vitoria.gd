extends Control

func _ready() -> void:
	$Fundo/Centralizar/Painel/Titulo.text = "VITÓRIA!"
	$Fundo/Centralizar/Painel/Mensagem.text = "Você derrotou todos os esqueletos!"

	$Fundo/Centralizar/Painel/BotaoNovamente.text = "Jogar novamente"
	$Fundo/Centralizar/Painel/BotaoSair.text = "Sair"

	$Fundo/Centralizar/Painel/BotaoNovamente.pressed.connect(jogar_novamente)
	$Fundo/Centralizar/Painel/BotaoSair.pressed.connect(sair)


func jogar_novamente() -> void:
	get_tree().change_scene_to_file("res://mapas/mapaZ.tscn")


func sair() -> void:
	get_tree().quit()
