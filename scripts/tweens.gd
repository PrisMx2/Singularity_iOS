extends Node
class_name TweenTrigger

static func execute_before(node: Node) -> void:
	for child: Node in node.get_children():
		execute_before(child)
	if node.has_method("_tween_before"):
		await node._tween_before()

static func execute_enter(node: Node) -> void:
	for child: Node in node.get_children():
		execute_enter(child)
	if node.has_method("_tween_enter"):
		await node._tween_enter()

static func execute_break(node: Node) -> void:
	for child: Node in node.get_children():
		execute_break(child)
	if node.has_method("_tween_break"):
		await node._tween_break()

static func execute_leave(node: Node) -> void:
	for child: Node in node.get_children():
		execute_leave(child)
	if node.has_method("_tween_leave"):
		await node._tween_leave()
