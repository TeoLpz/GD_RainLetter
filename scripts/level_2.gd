extends Node2D

var pause_button : Button
var pause_menu : Control
var close_button : Button

# ------------------------------
# Variables para controlar el juego
# ------------------------------
var total_numbers: int = 10  # Total de números a manejar
var fall_speed_range: Vector2 = Vector2(50, 200)  # Rango de velocidades de caída
var numbers: Array = []  # Lista de números que caen

# Temporizador para crear números
var number_timer: Timer

# Nodo para la música de fondo
var background_music: AudioStreamPlayer

# Tiempo de juego
var elapsed_time: float = 0.0  # Tiempo transcurrido desde el inicio

# ------------------------------
# Clase para números que caen
# ------------------------------
class FallingNumber extends Label:
	var speed: float = 0.0  # Velocidad de caída
	var spawn_time: float = 0.0  # Tiempo de aparición del número

	# Método que se ejecuta al crear el número
	func _ready():
		self.add_theme_color_override("font_color", get_random_color())  # Color aleatorio
		var font = load("res://fonts/OpenSans.ttf")  # Cargar fuente
		self.add_theme_font_override("font", font)
		self.add_theme_font_size_override("font_size", 64)
		self.add_theme_color_override("outline_color", Color.BLACK)
		self.add_theme_constant_override("outline_size", 2)
		

	func get_random_color() -> Color:
		# Generar un color aleatorio
		var red = randi() % 256 / 255.0
		var green = randi() % 256 / 255.0
		var blue = randi() % 256 / 255.0
		return Color(red, green, blue)

# ------------------------------
# Variables para el juego
# ------------------------------
var max_numbers: int = 10  # Número máximo de números en pantalla
var additional_numbers: int = 0  # Números adicionales a generar

# Límite de números perdidos (vidas)
var max_lives: int = 5  # Máximo de vidas
var remaining_lives: int = max_lives  # Vidas restantes

# Contador de números eliminados
var numbers_removed: int = 0

# Etiquetas para mostrar información del juego
var timer_label: Label
var numbers_removed_label: Label
var numbers_lost_label: Label

# Variables para el sonido
var pop_sound: AudioStreamPlayer  # Sonido al eliminar un número
var life_loss_sound: AudioStreamPlayer  # Sonido para la pérdida de vida

# Panel de nivel completado
var completion_panel: Panel
var continue_button: Button

# Fondo del juego
var background_texture: Texture

# Control del estado del nivel
var level_completed: bool = false  # Si el nivel ha sido completado

# Variable para el sonido de victoria
var victory_sound: AudioStreamPlayer

# ------------------------------
# Función que se ejecuta al iniciar el juego
# ------------------------------
func _ready():
	# Inicializar música de fondo
	background_music = AudioStreamPlayer.new()
	var audio_stream = preload("res://sounds/happysound.mp3")
	if audio_stream is AudioStream:
		audio_stream.loop = true
	background_music.stream = audio_stream
	add_child(background_music)
	background_music.play()

	# Configurar el fondo del juego
	var background_rect = TextureRect.new()
	background_rect.texture = background_texture
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.anchor_left = 0.5
	background_rect.anchor_top = 0.5
	background_rect.position = Vector2(0, 0)
	background_rect.set_size(get_viewport().size)
	add_child(background_rect)

	# Configurar temporizador de números
	number_timer = Timer.new()
	number_timer.wait_time = randf_range(0.5, 2)
	number_timer.connect("timeout", Callable(self, "_on_number_timer_timeout"))
	add_child(number_timer)
	number_timer.start()

	# Inicializar etiquetas de información
	timer_label = Label.new()
	timer_label.position = Vector2(10, 10)
	add_child(timer_label)

	numbers_removed_label = Label.new()
	numbers_removed_label.position = Vector2(10, 30)
	add_child(numbers_removed_label)

	numbers_lost_label = Label.new()
	numbers_lost_label.position = Vector2(10, 50)
	add_child(numbers_lost_label)

	# Cargar sonidos
	pop_sound = AudioStreamPlayer.new()
	pop_sound.stream = preload("res://sounds/pop.mp3")
	add_child(pop_sound)

	victory_sound = AudioStreamPlayer.new()
	victory_sound.stream = preload("res://sounds/level-win-6416.mp3")
	victory_sound.volume_db = 5
	add_child(victory_sound)

	life_loss_sound = AudioStreamPlayer.new()
	life_loss_sound.stream = preload("res://sounds/error-10-206498.mp3")
	life_loss_sound.volume_db = 5
	add_child(life_loss_sound)

	# Configurar panel de nivel completado
	completion_panel = Panel.new()
	completion_panel.size = Vector2(800, 300)  # Tamaño del panel
	add_child(completion_panel)
	completion_panel.visible = false

	# Centrar el panel en la pantalla
	completion_panel.anchor_left = 0.5
	completion_panel.anchor_top = 0.5
	completion_panel.anchor_right = 0.5
	completion_panel.anchor_bottom = 0.5

	# VBoxContainer para el contenido del panel
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	completion_panel.add_child(vbox)

	# Crear etiqueta de finalización
	var completion_label = Label.new()
	completion_label.text = "Nivel 2 Completado"
	completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(completion_label)
	
	# Crear etiqueta para mostrar el tiempo
	var time_label = Label.new()
	time_label.text = "¡Ganaste! Tiempo: " + str(elapsed_time) + "s"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(time_label)

	# Botón para continuar
	continue_button = Button.new()
	continue_button.text = "Siguiente nivel"
	continue_button.set_custom_minimum_size(Vector2(200, 60))
	continue_button.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	vbox.add_child(continue_button)
	
	# Botón para reintentar
	var retry_button = Button.new()
	retry_button.text = "Reintentar"
	retry_button.set_custom_minimum_size(Vector2(200, 60))
	retry_button.connect("pressed", Callable(self, "_on_retry_button_pressed"))
	vbox.add_child(retry_button)

	# Establecer el tamaño del VBoxContainer para que ajuste su contenido
	vbox.size = Vector2(800, 300)  # Asegúrate de que el VBox tenga un tamaño definido

	completion_panel.add_child(vbox)
	add_child(completion_panel)

	# MENU DE PAUSA
	# Crear el botón de pausa
	pause_button = Button.new()
	pause_button.text = "Pausar"
	
	pause_button.position = Vector2(20, 20)  # Posicionar el botón en pantalla
	add_child(pause_button)
	pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))

	# Crear el menú de pausa
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false  # Iniciar oculto
	pause_menu.anchor_right = 1
	pause_menu.anchor_bottom = 1
	add_child(pause_menu)

	# Crear fondo para el menú de pausa
	var menu_bg = ColorRect.new()
	menu_bg.color = Color(0, 0, 0, 0.7)  # Fondo semi-transparente
	menu_bg.anchor_right = 1
	menu_bg.anchor_bottom = 1
	pause_menu.add_child(menu_bg)

	# Crear el botón para cerrar el menú de pausa
	close_button = Button.new()
	close_button.text = "Cerrar"
	
	close_button.position = Vector2(200, 200)
	pause_menu.add_child(close_button)
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
# ------------------------------
# Función que se ejecuta al tiempo del temporizador de números
# ------------------------------
func _on_number_timer_timeout():
	if numbers.size() < max_numbers + additional_numbers and not level_completed:
		# Generar números dentro de un rango definido
		var min_x = 130
		var max_x = get_viewport().size.x - 130
		var start_y = -50

		var number = FallingNumber.new()
		number.text = str(randi() % 10)  # Seleccionar un número aleatorio entre 0-9
		number.position = Vector2(randf_range(min_x, max_x), start_y)
		number.speed = get_number_speed()  # Obtener velocidad de caída
		number.spawn_time = elapsed_time  # Registrar el tiempo de aparición
		add_child(number)
		numbers.append(number)
		number_timer.wait_time = randf_range(0.5, 1.5)  # Cambiar tiempo de espera del temporizador

# ------------------------------
# Función para obtener la velocidad del número
# ------------------------------
func get_number_speed() -> float:
	if elapsed_time < 30:
		return randf_range(10, 30)  # Velocidad inicial
	else:
		return randf_range(40, 55)  # Velocidad después de 30 segundos

# ------------------------------
# Función que se ejecuta cada frame
# ------------------------------
func _process(delta):
	elapsed_time += delta  # Aumentar el tiempo transcurrido
	if int(elapsed_time) % 60 == 0 and elapsed_time > 60:
		additional_numbers += 2  # Aumentar números adicionales cada 60 segundos

	# Actualizar la posición de cada número
	for number in numbers:
		number.position.y += number.speed * delta
		var number_text = number.text
		var input_action = "ui_accept_" + number_text

		if Input.is_action_just_pressed(input_action):  # Verificar si se presionó la tecla correspondiente
			var number_to_remove: FallingNumber = null
			for n in numbers:
				if n.text == number_text and (number_to_remove == null or n.spawn_time < number_to_remove.spawn_time):
					number_to_remove = n

			if number_to_remove != null:
				number_to_remove.hide()  # Ocultar número
				numbers.erase(number_to_remove)  # Eliminar de la lista
				numbers_removed += 1  # Aumentar el contador de números eliminados
				pop_sound.play()  # Reproducir sonido de eliminación
				update_labels()  # Actualizar etiquetas de información

				# Verificar si se han eliminado suficientes números para completar el nivel
				if numbers_removed >= 3:
					level_completed = true  # Marcar el nivel como completado
					show_completion_panel()  # Mostrar panel de finalización
					number_timer.stop()  # Detener el temporizador
				break

		# Comprobar si el número ha caído fuera de la pantalla
		if number.position.y > get_viewport().size.y:
			number_lost(number)  # Manejar la pérdida de número

	update_labels()  # Actualizar etiquetas de información

# ------------------------------
# Función que maneja la pérdida de un número
# ------------------------------
func number_lost(number):
	numbers.erase(number)  # Eliminar número de la lista
	number.queue_free()  # Liberar número de la escena
	remaining_lives -= 1  # Disminuir el número de vidas

	life_loss_sound.play()  # Reproducir sonido de pérdida de vida

	if remaining_lives <= 0:
		restart_game()  # Reiniciar juego si no quedan vidas

# ------------------------------
# Función para reiniciar el juego
# ------------------------------
func restart_game():
	remaining_lives = max_lives  # Reiniciar vidas
	numbers_removed = 0  # Reiniciar contador de letras eliminadas
	elapsed_time = 0  # Reiniciar tiempo
	additional_numbers = 0  # Reiniciar letras adicionales
	level_completed = false  # Reiniciar estado del nivel

	for number in numbers:
		number.queue_free()  # Liberar todas las letras en pantalla
	numbers.clear()  # Limpiar lista de letras

	update_labels()  # Actualizar etiquetas de información
	background_music.stop()  # Detener música de fondo
	background_music.play()  # Reproducir música de fondo
	number_timer.start()  # Asegúrate de reiniciar el temporizador
	number_timer.wait_time = randf_range(0.5, 2)  # Establecer tiempo de espera

# ------------------------------
# Función para actualizar las etiquetas de información
# ------------------------------
func update_labels():
	timer_label.text = "Tiempo: " + str(int(elapsed_time)) + "s"
	numbers_removed_label.text = "Puntaje: " + str(numbers_removed)
	numbers_lost_label.text = "Vidas: " + str(remaining_lives)

# ------------------------------
# Función para mostrar el panel de nivel completado
# ------------------------------
func show_completion_panel():
	
	number_timer.stop()  # Detener el temporizador
	completion_panel.visible = true  # Mostrar panel de completado

	background_music.stop()  # Detener música de fondo
	victory_sound.play()  # Reproducir sonido de victoria

	# Eliminar todos los números en pantalla
	for number in numbers:
		number.queue_free()
	numbers.clear()

	# Aplicar la fuente personalizada al texto del panel de victoria y al botón
	var font = load("res://fonts/OpenSans.ttf")  # Ruta a la fuente
	var completion_label = completion_panel.get_child(0).get_child(0)
	completion_label.add_theme_font_override("font", font)  # Fuente para el texto de "Nivel 1 Completado"
	completion_label.add_theme_font_size_override("font_size", 64)  # Tamaño de la fuente
	completion_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Cambiar color del texto

	continue_button.add_theme_font_override("font", font)  # Fuente para el botón "Continuar"
	continue_button.add_theme_font_size_override("font_size", 40)  # Tamaño de la fuente para el botón
	continue_button.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # Cambiar color del texto del botón
	
# Actualizar el label de tiempo
	var time_label = completion_panel.get_child(0).get_child(1)
	time_label.text = "¡Ganaste! Tiempo: " + str(int(elapsed_time)) + "s"  # Actualiza el tiempo mostrado

# Asegúrate de que el tamaño del panel sea correcto
	completion_panel.size = Vector2(800, 300)  # Establecer tamaño del panel

# Calcular la posición para centrar el panel manualmente
	completion_panel.position = (Vector2(get_viewport().size.x, get_viewport().size.y) - completion_panel.size) / 2

# ------------------------------
# Función que se ejecuta al presionar el botón de continuar
# ------------------------------
func _on_continue_button_pressed():
	restart_game()  # Reiniciar juego
	completion_panel.visible = false  # Ocultar panel de completado
	get_tree().change_scene_to_file("res://scene/level_3.tscn")
	
func _on_retry_button_pressed():
	completion_panel.visible = false  # Ocultar panel de completado
	restart_game()  # Reiniciar juego
	
# Métodos de pausa
func _on_pause_button_pressed():
	get_tree().paused = true
	pause_menu.visible = true
	pause_button.disabled = true 

func _on_close_button_pressed():
	pause_menu.visible = false
	get_tree().paused = false
	pause_button.disabled = false 
