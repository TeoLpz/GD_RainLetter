extends Node2D

var pause_button : Button
var pause_menu : Control
var close_button : Button
var salir_button : Button

# ------------------------------
# Variables para controlar el juego
# ------------------------------
var total_letters: int = 5  # Total de letras a manejar (solo vocales)
var fall_speed_range: Vector2 = Vector2(50, 200)  # Rango de velocidades de caída
var letters: Array = []  # Lista de letras que caen

# Temporizador para crear letras
var letter_timer: Timer

# Nodo para la música de fondo
var background_music: AudioStreamPlayer

# Tiempo de juego
var elapsed_time: float = 0.0  # Tiempo transcurrido desde el inicio

# ------------------------------
# Clase para letras que caen
# ------------------------------
class FallingLetter extends Label:
	var speed: float = 0.0  # Velocidad de caída
	var spawn_time: float = 0.0  # Tiempo de aparición de la letra

	# Método que se ejecuta al crear la letra
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
var max_letters: int = 10  # Número máximo de letras en pantalla
var additional_letters: int = 0  # Letras adicionales a generar

# Límite de letras perdidas (vidas)
var max_lives: int = 5  # Máximo de vidas
var remaining_lives: int = max_lives  # Vidas restantes

# Contador de letras eliminadas
var letters_removed: int = 0

# Etiquetas para mostrar información del juego
var timer_label: Label
var letters_removed_label: Label
var letters_lost_label: Label

# Variables para el sonido
var pop_sound: AudioStreamPlayer  # Sonido al eliminar una letra
var life_loss_sound: AudioStreamPlayer  # Sonido para la pérdida de vida

# Panel de nivel completado
var completion_panel: Panel
var continue_button: Button
var retry_button: Button
var exit_button: Button

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
	background_texture = preload("res://assets/fondo4.jpg")
	var background_rect = TextureRect.new()
	background_rect.texture = background_texture
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.anchor_left = 0.5
	background_rect.anchor_top = 0.5
	background_rect.position = Vector2(0, 0)
	background_rect.set_size(get_viewport().size)
	add_child(background_rect)

	# Configurar temporizador de letras
	letter_timer = Timer.new()
	letter_timer.wait_time = randf_range(0.5, 2)
	letter_timer.connect("timeout", Callable(self, "_on_letter_timer_timeout"))
	add_child(letter_timer)
	letter_timer.start()

	# Inicializar etiquetas de información
	timer_label = Label.new()
	timer_label.position = Vector2(10, 10)
	timer_label.add_theme_font_size_override("font_size", 20) 
	add_child(timer_label)

	letters_removed_label = Label.new()
	letters_removed_label.position = Vector2(10, 30)
	letters_removed_label.add_theme_font_size_override("font_size", 20) 
	add_child(letters_removed_label)

	letters_lost_label = Label.new()
	letters_lost_label.position = Vector2(10, 50)
	letters_lost_label.add_theme_font_size_override("font_size", 20) 
	add_child(letters_lost_label)

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
	completion_label.text = "Nivel 1 Completado"
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
	retry_button  = Button.new()
	retry_button.text = "Reintentar"
	retry_button.set_custom_minimum_size(Vector2(200, 60))
	retry_button.connect("pressed", Callable(self, "_on_retry_button_pressed"))
	vbox.add_child(retry_button)
	
	exit_button = Button.new()
	exit_button.text = "Salir"
	exit_button.set_custom_minimum_size(Vector2(200, 60))
	exit_button.connect("pressed", Callable(self, "_on_salir_button_pressed"))
	vbox.add_child(exit_button)

	# Establecer el tamaño del VBoxContainer para que ajuste su contenido
	vbox.size = Vector2(800, 300)  # Asegúrate de que el VBox tenga un tamaño definido

	completion_panel.add_child(vbox)
	add_child(completion_panel)
	
	
	# MENU DE PAUSA
	# Crear el botón de pausa
	pause_button = Button.new()
	pause_button.text = "Pausar"
	pause_button.name = "pause_button" 
	pause_button.text = "||"  # Texto inicial (ícono de pausa)
	pause_button.position = Vector2(get_viewport().size.x - 110, 10)  # Posición en la parte superior derecha
	pause_button.set_custom_minimum_size(Vector2(100, 40))  # Tamaño del botón


	# Asegúrate de agregar el botón de pausa al nodo principal solo una vez
	if not has_node("PauseButton"):
		pause_button.name = "PauseButton"
		add_child(pause_button)
		pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))

	# Crear el menú de pausa
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false  # Iniciar oculto


	# Asegúrate de agregar el menú de pausa al nodo principal solo una vez
	if not has_node("PauseMenu"):
		add_child(pause_menu)

	# Crear fondo para el menú de pausa
	var menu_bg = ColorRect.new()
	menu_bg.color = Color(0, 0, 0, 0)  # Fondo semi-transparente
	

	# Asegúrate de agregar el fondo del menú de pausa solo una vez
	if not pause_menu.has_node("MenuBG"):
		menu_bg.name = "MenuBG"
		pause_menu.add_child(menu_bg)

	# Crear el botón para cerrar el menú de pausa
	close_button = Button.new()
	close_button.text = "Continuar"


	# Modificar color de fondo y bordes
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.5, 1.0)  # Cambia el color de fondo
	style_box.set_border_width_all(4) 
	style_box.border_color = Color(1, 1, 1)  # Cambia el color del borde
	
	style_box.content_margin_left = 15  # Margen izquierdo
	style_box.content_margin_right = 15  # Margen derecho
	style_box.content_margin_top = 8    # Margen superior
	style_box.content_margin_bottom = 8 # Margen inferior
	
	style_box.set_corner_radius_all(16) 
	
	# Aplicar estilo al botón
	close_button.add_theme_stylebox_override("normal", style_box)

	# Cambiar el color del texto y la fuente
	close_button.add_theme_color_override("font_color", Color(1, 1, 1))  # Color del texto
	var font = FontFile.new()
	font.font_data = load("res://fonts/OpenSans.ttf")  # Ruta a tu fuente
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.set("custom_fonts/font", font)
	
	
	# Asegúrate de agregar el botón de cerrar solo una vez
	if not pause_menu.has_node("CloseButton"):
		close_button.name = "CloseButton"
		pause_menu.add_child(close_button)
		close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
		
		
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Crear el botón para salir al menú principal
	salir_button = Button.new()
	salir_button.text = "Ir al menú"
	salir_button.position = Vector2(
	salir_button.position.x,  # Mantener la posición X actual
	salir_button.position.y + 80  # Sumar 80 a la componente Y
)


	# Aplicar estilo al botón de salir (opcional)
	var styles_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.5, 1.0)  # Cambia el color de fondo
	style_box.set_border_width_all(4)
	style_box.border_color = Color(1, 1, 1)  # Cambia el color del borde
	style_box.set_corner_radius_all(16)
	salir_button.add_theme_stylebox_override("normal", style_box)

	salir_button.add_theme_color_override("font_color", Color(1, 1, 1))  # Cambia el color del texto
	salir_button.add_theme_font_size_override("font_size", 30)
	
	# Agregar el botón al menú de pausa
	if not pause_menu.has_node("SalirButton"):
		salir_button.name = "SalirButton"
		pause_menu.add_child(salir_button)
		salir_button.connect("pressed", Callable(self, "_on_salir_button_pressed"))
# ------------------------------
# Función que se ejecuta al tiempo del temporizador de letras
# ------------------------------
func _on_letter_timer_timeout():
	if letters.size() < max_letters + additional_letters and not level_completed:
		# Generar letras dentro de un rango definido
		var min_x = 130
		var max_x = get_viewport().size.x - 130
		var start_y = -50

		var letter = FallingLetter.new()
		var vowels = ['A', 'E', 'I', 'O', 'U']  # Array con las vocales
		letter.text = vowels[randi() % vowels.size()]  # Seleccionar vocal al azar
		letter.position = Vector2(randf_range(min_x, max_x), start_y)
		letter.speed = randf_range(fall_speed_range.x, fall_speed_range.y)  # Velocidad original
		letter.spawn_time = elapsed_time
		add_child(letter)
		letters.append(letter)
		
		# Ajustar tiempo del temporizador dinámicamente
		letter_timer.wait_time = randf_range(0.5, 1.5)  # Cambiar tiempo de espera del temporizador




# ------------------------------
# Función para obtener la velocidad de la letra
# ------------------------------
func get_letter_speed() -> float:
	if elapsed_time < 30:
		return randf_range(10, 30)  # Velocidad inicial
	else:
		return randf_range(40, 55)  # Velocidad después de 30 segundos

# ------------------------------
# Función que se ejecuta cada frame
# ------------------------------
func _process(delta):
		# Alinear dinamicamente boton de pausa
	pause_button.position = Vector2(get_viewport().size.x - pause_button.get_combined_minimum_size().x - 20, 10)

	# Centrar dinamicamente menu de pausa
	pause_menu.position = Vector2(
	(get_viewport().size.x - pause_button.get_combined_minimum_size().x) / 2,
	(get_viewport().size.y - pause_button.get_combined_minimum_size().y) / 2
	)

	elapsed_time += delta  # Aumentar el tiempo transcurrido
	if int(elapsed_time) % 60 == 0 and elapsed_time > 60:
		additional_letters += 2  # Aumentar letras adicionales cada 60 segundos

	# Actualizar la posición de cada letra
	for letter in letters:
		letter.position.y += letter.speed * delta
		var letter_text = letter.text.to_upper()
		var input_action = "ui_accept_" + letter_text

		if Input.is_action_just_pressed(input_action):  # Verificar si se presionó la tecla correspondiente
			var letter_to_remove: FallingLetter = null
			for l in letters:
				if l.text == letter_text and (letter_to_remove == null or l.spawn_time < letter_to_remove.spawn_time):
					letter_to_remove = l

			if letter_to_remove != null:
				letter_to_remove.hide()  # Ocultar letra
				letters.erase(letter_to_remove)  # Eliminar de la lista
				letters_removed += 1  # Aumentar el contador de letras eliminadas
				pop_sound.play()  # Reproducir sonido de eliminación
				update_labels()  # Actualizar etiquetas de información

				# Verificar si se han eliminado suficientes letras para completar el nivel
				if letters_removed >= 3:
					level_completed = true  # Marcar el nivel como completado
					if show_completion_panel:
						show_completion_panel() # Mostrar panel de finalización
						pause_button.disabled = true
					letter_timer.stop()  # Detener el temporizador
				break

		# Comprobar si la letra ha caído fuera de la pantalla
		if letter.position.y > get_viewport().size.y:
			letter_lost(letter)  # Manejar la pérdida de letra

	update_labels()  # Actualizar etiquetas de información

# ------------------------------
# Función que maneja la pérdida de una letra
# ------------------------------
func letter_lost(letter):
	letters.erase(letter)  # Eliminar letra de la lista
	letter.queue_free()  # Liberar letra de la escena
	remaining_lives -= 1  # Disminuir el número de vidas

	life_loss_sound.play()  # Reproducir sonido de pérdida de vida

	if remaining_lives <= 0:
		restart_game()  # Reiniciar juego si no quedan vidas

# ------------------------------
# Función para reiniciar el juego
# ------------------------------
func restart_game():
	remaining_lives = max_lives  # Reiniciar vidas
	letters_removed = 0  # Reiniciar contador de letras eliminadas
	elapsed_time = 0  # Reiniciar tiempo
	additional_letters = 0  # Reiniciar letras adicionales
	level_completed = false  # Reiniciar estado del nivel

	for letter in letters:
		letter.queue_free()  # Liberar todas las letras en pantalla
	letters.clear()  # Limpiar lista de letras

	update_labels()  # Actualizar etiquetas de información
	background_music.stop()  # Detener música de fondo
	background_music.play()  # Reproducir música de fondo
	letter_timer.start()  # Asegúrate de reiniciar el temporizador
	letter_timer.wait_time = randf_range(0.5, 2)  # Establecer tiempo de espera

# ------------------------------
# Función para actualizar las etiquetas de información
# ------------------------------
func update_labels():
	timer_label.text = "Tiempo: " + str(int(elapsed_time)) + "s"
	letters_removed_label.text = "Puntaje: " + str(letters_removed)
	letters_lost_label.text = "Vidas: " + str(remaining_lives)

# ------------------------------
# Función para mostrar el panel de nivel completado
# ------------------------------
func show_completion_panel():
	letter_timer.stop()  # Detener el temporizador
	completion_panel.visible = true  # Mostrar panel de completado

	background_music.stop()  # Detener música de fondo
	victory_sound.play()  # Reproducir sonido de victoria

	# Eliminar todas las letras en pantalla
	for letter in letters:
		letter.queue_free()
	letters.clear()

	# Aplicar la fuente personalizada al texto del panel de victoria y al botón
	var font = load("res://fonts/OpenSans.ttf")  # Ruta a la fuente
	var completion_label = completion_panel.get_child(0).get_child(0)
	completion_label.add_theme_font_override("font", font)  # Fuente para el texto de "Nivel 1 Completado"
	completion_label.add_theme_font_size_override("font_size", 64)  # Tamaño de la fuente
	completion_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.5))  # Cambiar color del texto

	continue_button.add_theme_font_override("font", font)  # Fuente para el botón "Continuar"
	continue_button.add_theme_font_size_override("font_size", 40)  # Tamaño de la fuente para el botón
	continue_button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))  # Cambiar color del texto del botón
	
	retry_button.add_theme_font_override("font", font)  # Fuente para el botón "Continuar"
	retry_button.add_theme_font_size_override("font_size", 40)  # Tamaño de la fuente para el botón
	retry_button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))  # Cambiar color del texto del botón
	
	exit_button.add_theme_font_override("font", font)  # Fuente para el botón "Continuar"
	exit_button.add_theme_font_size_override("font_size", 40)  # Tamaño de la fuente para el botón
	exit_button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))  # Cambiar color del texto del botón
	
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
	completion_panel.visible = false  # Ocultar panel de completado
	get_tree().change_scene_to_file("res://scene/level_2.tscn")
	
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

func _on_salir_button_pressed():
	get_tree().paused = false  # Asegúrate de despausar antes de cambiar de escena
	get_tree().change_scene_to_file("res://level_select.tscn")  # Cambia esto a la ruta de tu escena principal
	
