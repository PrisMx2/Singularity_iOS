extends Node

# Autoload: drives the FMOD mixer once per frame.
#
# It deliberately does NOT initialise anything. The plugin never creates the FMOD
# system on its own -- the host project owns that step, so add one explicit call
# wherever your game starts, e.g.:
#
#     func _ready() -> void:
#         FmodServer.init_system()   # 256 channels / 1024-sample DSP buffer / 4 buffers
#
# Until that call succeeds, update() below is a harmless no-op and the Player
# factory methods return null.

func _process(_delta: float) -> void:
  FmodServer.update()
