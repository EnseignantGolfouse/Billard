extends Control


var width: int
var height: int


func _ready() -> void:
	$BillBoard.hide()

func _on_Width_text_changed(new_text: String) -> void:
	self.width = int(new_text)

func _on_Height_text_changed(new_text: String) -> void:
	self.height = int(new_text)

func _on_StartButton_pressed() -> void:
	if self.width == 0 or self.height == 0:
		return
	var max_width: float = self.rect_size.x
	var max_height: float = self.rect_size.y - ($Buttons.rect_position.y + $Buttons.rect_size.y) - 20
	var scale_x: float = max_width / self.width
	var scale_y: float = max_height / self.height
	var scale: float = min(scale_x, scale_y)
	$BillBoard.initialize(scale, self.width, self.height)
	$BillBoard.show()
	var offset_x: float = (max_width - scale * self.width) / 2
	$BillBoard.position.x = offset_x
	$BillBoard.position.y = $Buttons.rect_position.y + $Buttons.rect_size.y + 20

func _on_ResetButton_pressed() -> void:
	$BillBoard.hide()

func _on_Speed_value_changed(value: float) -> void:
	$BillBoard.turtle_speed = value

func _on_Deplie_toggled(button_pressed: bool) -> void:
	$BillBoard.deplie = button_pressed
