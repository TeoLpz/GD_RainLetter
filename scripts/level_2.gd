extends Node2D

# Variables para controlar las letras
var total_letters: int = 5  # Solo vocales (A, E, I, O, U)
var fall_speed_range: Vector2 = Vector2(50, 200)  # Rango de velocidades de caída
var letters: Array = []  # Lista de nodos FallingLetter que representan las letras

# Temporizador para crear letras
var letter_timer: Timer

# Nodo para la música de fondo
var background_music: AudioStreamPlayer

# Tiempo de juego
var elapsed_time: float = 0.0  # Tiempo transcurrido desde el inicio

# Clase para letras que caen
class FallingLetter extends Label:
	var speed: float = 0.0  # Velocidad de caída
	var spawn_time: float = 0.0  # Tiempo de aparición de la letra

	# Método que se ejecuta al crear la letra
	func _ready():
		self.add_theme_color_override("font_color", get_random_color())  # Color aleatorio
		var font = load("res://OpenSans.ttf")  # Cambia la ruta al archivo de fuente
		self.add_theme_font_override("font", font)
		self.add_theme_font_size_override("font_size", 64)
		self.add_theme_color_override("outline_color", Color.BLACK)
		self.add_theme_constant_override("outline_size", 2)

	func get_random_color() -> Color:
		var red = randi() % 256 / 255.0
		var green = randi() % 256 / 255.0
		var blue = randi() % 256 / 255.0
		return Color(red, green, blue)

# Número máximo de letras en pantalla
var max_letters: int = 10
var additional_letters: int = 0

# Límite de letras perdidas (vidas)
var max_lives: int = 5
var remaining_lives: int = max_lives  # Vidas restantes

# Contador de letras eliminadas
var letters_removed: int = 0

# Etiquetas para mostrar el tiempo transcurrido, letras eliminadas y vidas restantes
var timer_label: Label
var letters_removed_label: Label
var letters_lost_label: Label

# Variables para el sonido
var pop_sound: AudioStreamPlayer
var life_loss_sound: AudioStreamPlayer  # Sonido para la pérdida de vida

# Panel de nivel completado
var completion_panel: Panel
var continue_button: Button

# Fondo del juego
var background_texture: Texture

# Variable para controlar si el nivel ha sido completado
var level_completed: bool = false

# Variable para el sonido de victoria
var victory_sound: AudioStreamPlayer

func _ready():
	background_music = AudioStreamPlayer.new()
	var audio_stream = preload("res://happysound.mp3")
	if audio_stream is AudioStream:
		audio_stream.loop = true
	background_music.stream = audio_stream
	add_child(background_music)
	background_music.play()

	# Cargar y establecer el fondo
	#background_texture = preload("res://assets/fondo_2.jpg")
	var background_rect = TextureRect.new()
	background_rect.texture = background_texture
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED  # Mantener proporciones
	background_rect.anchor_left = 0.5
	background_rect.anchor_top = 0.5
	background_rect.position = Vector2(0, 0)  # Establecer la posición a (0, 0)
	background_rect.set_size(get_viewport().size)  # Ajustar al tamaño de la pantalla
	add_child(background_rect)

	letter_timer = Timer.new()
	letter_timer.wait_time = randf_range(0.5, 2)
	letter_timer.connect("timeout", Callable(self, "_on_letter_timer_timeout"))
	add_child(letter_timer)
	letter_timer.start()

	timer_label = Label.new()
	timer_label.position = Vector2(10, 10)
	add_child(timer_label)

	letters_removed_label = Label.new()
	letters_removed_label.position = Vector2(10, 30)
	add_child(letters_removed_label)

	letters_lost_label = Label.new()
	letters_lost_label.position = Vector2(10, 50)
	add_child(letters_lost_label)

	pop_sound = AudioStreamPlayer.new()
	pop_sound.stream = preload("res://pop.mp3")
	add_child(pop_sound)

	# Cargar el sonido de victoria
	victory_sound = AudioStreamPlayer.new()
	victory_sound.stream = preload("res://level-win-6416.mp3")  # Cambia la ruta al archivo de sonido de victoria
	victory_sound.volume_db = 5  # Aumenta el volumen en 5 decibelios
	add_child(victory_sound)

	# Cargar el sonido para la pérdida de vida
	life_loss_sound = AudioStreamPlayer.new()
	life_loss_sound.stream = preload("res://error-10-206498.mp3")  # Cambia la ruta al archivo de sonido de pérdida de vida
	life_loss_sound.volume_db = 5  # Aumenta el volumen en 5 decibelios
	add_child(life_loss_sound)

	completion_panel = Panel.new()
	completion_panel.size = Vector2(800, 300)
	completion_panel.anchor_left = 0.5
	completion_panel.anchor_top = 0.5
	completion_panel.anchor_right = 0.5
	completion_panel.anchor_bottom = 0.5
	completion_panel.offset_left = -completion_panel.size.x / 2
	completion_panel.offset_top = -completion_panel.size.y / 2
	add_child(completion_panel)
	completion_panel.visible = false

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_FILL
	vbox.size_flags_vertical = Control.SIZE_FILL
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -vbox.size.x / 2
	vbox.offset_top = -vbox.size.y / 2

	var completion_label = Label.new()
	completion_label.text = "Nivel 2 Completado"
	completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(completion_label)

	continue_button = Button.new()
	continue_button.text = "Siguiente nivel"
	continue_button.set_custom_minimum_size(Vector2(200, 60))
	continue_button.connect("pressed", Callable(self, "_on_continue_button_pressed"))
	vbox.add_child(continue_button)

	completion_panel.add_child(vbox)
	add_child(completion_panel)

func _on_letter_timer_timeout():
	if letters.size() < max_letters + additional_letters and not level_completed:  # Solo genera letras si el nivel no está completo
		var min_x = 130
		var max_x = get_viewport().size.x - 130
		var start_y = -50

		var letter = FallingLetter.new()
		var numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
		letter.text = numbers[randi() % numbers.size()]
		letter.position = Vector2(randf_range(min_x, max_x), start_y)
		letter.speed = get_letter_speed()
		letter.spawn_time = elapsed_time
		add_child(letter)
		letters.append(letter)
		letter_timer.wait_time = randf_range(0.5, 1.5)

func get_letter_speed() -> float:
	if elapsed_time < 30:
		return randf_range(10, 30)
	else:
		return randf_range(40, 55)

func _process(delta):
	elapsed_time += delta
	if int(elapsed_time) % 60 == 0 and elapsed_time > 60:
		additional_letters += 2

	for letter in letters:
		letter.position.y += letter.speed * delta
		var letter_text = letter.text 


		# Detectar si se presionó la tecla correspondiente al número
		if is_number_key_pressed(letter_text):
			var letter_to_remove: FallingLetter = null
			for l in letters:
				if l.text == letter_text and (letter_to_remove == null or l.spawn_time < letter_to_remove.spawn_time):
					letter_to_remove = l

			if letter_to_remove != null:
				letter_to_remove.hide()
				letters.erase(letter_to_remove)
				letters_removed += 1
				pop_sound.play()
				update_labels()

				# Verificar si se han eliminado 60 numeros para mostrar el panel de nivel completado
				if letters_removed >= 20:
					level_completed = true  # Marcar el nivel como completado
					show_completion_panel()
					letter_timer.stop()  # Detener el temporizador de letras
				break

		if letter.position.y > get_viewport().size.y:
			letter_lost(letter)

	update_labels()
func is_number_key_pressed(letter_text: String) -> bool:
		# Verificar si se presionó la tecla numérica correspondiente
	var key_code = OS.find_keycode_from_string(letter_text)
	return Input.is_key_pressed(key_code)


func letter_lost(letter):
	letters.erase(letter)  # Elimina la letra de la lista
	letter.queue_free()  # Elimina la letra de la escena
	remaining_lives -= 1

	# Reproducir el sonido de pérdida de vida
	life_loss_sound.play()

	if remaining_lives <= 0:
		restart_game()

func restart_game():
	remaining_lives = max_lives
	letters_removed = 0
	elapsed_time = 0
	additional_letters = 0
	level_completed = false  # Reiniciar el estado del nivel

	for letter in letters:
		letter.queue_free()
	letters.clear()

	update_labels()
	background_music.stop()
	background_music.play()

func update_labels():
	timer_label.text = "Tiempo: " + str(int(elapsed_time)) + "s"
	letters_removed_label.text = "Puntaje: " + str(letters_removed)
	letters_lost_label.text = "Vidas: " + str(remaining_lives)

func show_completion_panel():
	letter_timer.stop()
	completion_panel.visible = true

	# Detener la música de fondo y reproducir el sonido de victoria
	background_music.stop()
	victory_sound.play()

	# Eliminar todas las letras en pantalla
	for letter in letters:
		letter.queue_free()
	letters.clear()

	# Aplicar la fuente personalizada al texto del panel de victoria y al botón
	var font = load("res://OpenSans.ttf")  # Ruta a la fuente
	completion_panel.get_child(0).get_child(0).add_theme_font_override("font", font)  # Fuente para el texto de "Nivel 1 Completado"
	completion_panel.get_child(0).get_child(0).add_theme_font_size_override("font_size", 64)  # Tamaño de la fuente
	completion_panel.get_child(0).get_child(0).add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Cambiar el color del texto (opcional)

	continue_button.add_theme_font_override("font", font)  # Fuente para el botón "Continuar"
	continue_button.add_theme_font_size_override("font_size", 40)  # Tamaño de la fuente para el botón
	continue_button.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # Cambiar el color del texto del botón (opcional)

func _on_continue_button_pressed():
	restart_game()
	completion_panel.visible = false
