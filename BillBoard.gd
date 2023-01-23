extends Node2D


# Threshold for float equality
const THRESHOLD: float = 0.01

# Increase the precision of the computation
# 4 seems to be more than enough, supporting 90x91 grid on speed 2000
var step_number: int = 4

var width: int
var height: int
var tile_scale: float
var bounds: Vector2

var turtle_position: Vector2
var turtle_direction: Vector2
var turtle_speed: float = 200.0
var turtle_escaped: bool = true

var current_starting_point: Vector2
var finished_lines: Array

var deplie: bool = false
var deplie_step: float
var vertical_symmetry: bool
var close_to_zero: bool


func initialize(s: float, w: int, h: int):
	self.tile_scale = s
	self.width = w
	self.height = h
	self.bounds = Vector2(s*w, s*h)
	
	self.turtle_position = Vector2(0, 0)
	self.turtle_direction = Vector2(1,1)
	self.turtle_escaped = false
	self.current_starting_point = Vector2(0,0)
	self.finished_lines = []
	
	self.deplie_step = 1.0
	self.close_to_zero = false
	
	self.update()

func to_render_coordinates(v: Vector2) -> Vector2:
	return Vector2(v.x, self.bounds.y - v.y)

func _process(delta: float):
	for _i in range(0, self.step_number):
		if self.deplie:
			self.step_deplie(delta / self.step_number)
		else:
			self.step(delta / self.step_number)
	self.update()

func step_deplie(delta: float):
	if self.turtle_escaped or self.deplie_step < 1.0:
		return
	
	var turtle_movement: Vector2 = self.turtle_speed * delta * self.turtle_direction
	self.turtle_position += turtle_movement
	
	var bounce_x: bool = false
	var bounce_y: bool = false
	if self.turtle_position.x > self.bounds.x:
		bounce_x = true
	if self.turtle_direction.y > self.bounds.y:
		bounce_y = true
	if bounce_x and bounce_y:
		self.turtle_escaped = true
		return
	elif bounce_x:
		self.deplie_step = 0.0
		self.vertical_symmetry = true
	elif bounce_y:
		self.deplie_step = 0.0
		self.vertical_symmetry = false

func _draw_deplie(delta: float):
	self.deplie_step += delta
	if self.deplie_step >= 1.0:
		if self.vertical_symmetry:
			self.width *= 2
			self.bounds.x *= 2
		else:
			self.height *= 2
			self.bounds.y *= 2
		return
	self.draw_grid_deplie()

func step(delta: float):
	if self.turtle_escaped:
		return
	
	var turtle_movement: Vector2 = self.turtle_speed * delta * self.turtle_direction
	self.turtle_position += turtle_movement
	
	# Address bounds checking
	var to_remove: float = 0
	var bounce_x: bool = false
	var bounce_y: bool = false
	if self.turtle_position.x > self.bounds.x:
		to_remove = self.turtle_position.x - self.bounds.x
		bounce_x = true
	elif self.turtle_position.x < 0:
		to_remove = -self.turtle_position.x
		bounce_x = true
	elif self.turtle_position.y > self.bounds.y:
		to_remove = self.turtle_position.y - self.bounds.y
		bounce_y = true
	elif self.turtle_position.y < 0:
		to_remove = -self.turtle_position.y
		bounce_y = true

	to_remove = abs(to_remove / turtle_movement.x)
	self.turtle_position -= to_remove * turtle_movement
	
	var finished: bool = false
	if bounce_x || bounce_y:
		finished = (
			abs(self.turtle_position.x) < THRESHOLD or
			abs(self.turtle_position.x - self.bounds.x) < THRESHOLD
		) and (
			abs(self.turtle_position.y) < THRESHOLD or
			abs(self.turtle_position.y - self.bounds.y) < THRESHOLD
		)
	
	if finished:
		self.turtle_escaped = true
		self.finished_lines.append([
			self.to_render_coordinates(self.current_starting_point),
			self.to_render_coordinates(self.turtle_position)])
		return
	if bounce_x:
		self.turtle_direction.x = int(-self.turtle_direction.x)
		self.finished_lines.append([
			self.to_render_coordinates(self.current_starting_point),
			self.to_render_coordinates(self.turtle_position)])
		self.current_starting_point = self.turtle_position
		self.vertical_symmetry = true
		if self.turtle_position.x < THRESHOLD:
			self.close_to_zero = true
	if bounce_y:
		self.turtle_direction.y = int(-self.turtle_direction.y)
		self.finished_lines.append([
			self.to_render_coordinates(self.current_starting_point),
			self.to_render_coordinates(self.turtle_position)])
		self.current_starting_point = self.turtle_position
		self.vertical_symmetry = false
		if self.turtle_position.y < THRESHOLD:
			self.close_to_zero = true

static func symmetry(point: Vector2, axis_point: Vector2, axis_vertical: bool) -> Vector2:
	point -= axis_point
	if axis_vertical:
		point.x = -point.x
	else:
		point.y = -point.y
	point += axis_point
	return point

static func deplie_across(point: Vector2, axis_point: Vector2, axis_vertical: bool, step: float) -> Vector2:
	var symmetric = symmetry(point, axis_point, axis_vertical)
	return (point * (1.0 - step) + symmetric * step)

func _draw():
	# axis
	for x in range(0, self.width + 1):
		self.draw_line(
			Vector2(
				x * self.tile_scale,
				0),
			Vector2(
				x * self.tile_scale,
				self.height * self.tile_scale),
			Color.darkgray, 1.0
		)
	for y in range(0, self.height + 1):
		self.draw_line(
			Vector2(
				0,
				y * self.tile_scale),
			Vector2(
				self.width * self.tile_scale,
				y * self.tile_scale),
			Color.darkgray, 1.0
		)
	if not self.turtle_escaped:
		self.draw_line(
			self.to_render_coordinates(self.current_starting_point),
			self.to_render_coordinates(self.turtle_position),
			Color.red, 2.0)
	if self.deplie:
		if self.deplie_step < 1.0:
			self._draw_deplie(0.03)
	else:
		for line in self.finished_lines:
			self.draw_line(line[0], line[1], Color.red, 2.0)

func draw_grid_deplie():
	var length: int = ppcm(self.width, self.height)
	# axis
	for x in range(0, length + 1):
		var line_width: float = 1.0
		if x % self.width == 0:
			line_width = 2.0
		self.draw_line(
			Vector2(
				x * self.tile_scale,
				0),
			Vector2(
				x * self.tile_scale,
				self.height * self.tile_scale),
			Color.darkgray, line_width
		)
	for y in range(0, self.height + 1):
		var line_width: float = 1.0
		if y % self.height == 0:
			line_width = 2.0
		self.draw_line(
			Vector2(
				0,
				y * self.tile_scale),
			Vector2(
				self.width * self.tile_scale,
				y * self.tile_scale),
			Color.darkgray, line_width
		)

func draw_deplie(line):
	var axis_point: Vector2 = line[1]
	# axis
	for x in range(0, self.width + 1):
		self.draw_line(
			deplie_across(Vector2(
				x * self.tile_scale,
				0), axis_point, self.vertical_symmetry, self.deplie_step),
			deplie_across(Vector2(
				x * self.tile_scale,
				self.height * self.tile_scale), axis_point, self.vertical_symmetry, self.deplie_step),
			Color.darkgray, 1.0
		)
	for y in range(0, self.height + 1):
		self.draw_line(
			deplie_across(Vector2(
				0,
				y * self.tile_scale), axis_point, self.vertical_symmetry, self.deplie_step),
			deplie_across(Vector2(
				self.width * self.tile_scale,
				y * self.tile_scale), axis_point, self.vertical_symmetry, self.deplie_step),
			Color.darkgray, 1.0
		)
	self.draw_line(
		deplie_across(line[0], axis_point, self.vertical_symmetry, self.deplie_step),
		deplie_across(line[1], axis_point, self.vertical_symmetry, self.deplie_step),
		Color.red, 2.0)

static func pgcd(x: int, y: int) -> int:
	while x != y:
		if x > y:
			x -= y
		else:
			y -= x
	return x

static func ppcm(x: int, y: int) -> int:
	return x * y / pgcd(x, y)
