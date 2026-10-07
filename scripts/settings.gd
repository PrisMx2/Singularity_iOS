extends Node

const language_list: Array = [
	[ "en", "English" ],
	[ "zh_CN", "简体中文" ],
	[ "ja", "日本語" ],
]

var settings_dategory: Array = [ "GAMEPLAY", "AUDIO", "DISPLAY", "MISC" ]

var settings_data: Array = [
	[
		{
			type = 1, key = "settings.autoplay", default = false,
			title = "settings.autoplay",
			questioning = (func() -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 0,
					title = "settings.autoplay",
					content = "settings.autoplay.disc",
					options = [
						{ enabled = false },
						{ enabled = true },
						{ enabled = false },
					]
				}
				),
			display = (func(data: Dictionary, value: bool) -> void:
				data.text = "generic.on" if value else "generic.off"
				data.enabled = value
				),
			apply = (func(value: bool) -> bool:
				return value
				),
			connected = false,
		},
		{
			type = 2, key = "settings.judgement_method", default = 0,
			title = "settings.judgement_method",
			questioning = (func() -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 0,
					title = "settings.judgement_method",
					content = "settings.judgement_method.disc",
					options = [
						{ enabled = false },
						{ enabled = true },
						{ enabled = false },
					]
				}
				),
			display = (func(data: Dictionary, value: int) -> void:
				data.text = "settings.judgement_method_" + str(value)
				data.index = value
				),
			apply = (func(value: int) -> int:
				value = wrapi(value, 0, 3)
				return value
				),
			connected = false,
		},
		{
			type = -1,
			title = "settings.offset_test.disc",
			text = "",
			display = (func(data: Dictionary, value: Variant) -> void:
				pass
				),
			apply = (func(value: Variant) -> void:
				pass
				),
			connected = false,
		},
		{
			type = 0,
			title = "settings.offset_test",
			text = "settings.offset",
			display = (func(data: Dictionary, value: Variant) -> void:
				pass
				),
			apply = (func(value: Variant) -> void:
				var node: Node = await SceneManager.change_scene("offset_test")
				node.last_scene = "settings"
				),
			connected = false,
		},
		{
			type = 2, key = "settings.music_offset", default = 0,
			title = "settings.music_offset",
			display = (func(data: Dictionary, value: int) -> void:
				data.text = str(value) + " ms"
				data.index = value
				),
			apply = (func(value: int) -> int:
				value = clampi(value, -999, 999)
				return value
				),
			connected = true,
		},
		{
			type = 2, key = "settings.judgement_offset", default = -1,
			title = "settings.judgement_offset",
			questioning = (func() -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 0,
					title = "settings.judgement_offset",
					content = "settings.judgement_offset.disc",
					options = [
						{ enabled = false },
						{ enabled = true },
						{ enabled = false },
					]
				}
				),
			display = (func(data: Dictionary, value: int) -> void:
				data.text = str(value * 5) + " ms"
				data.index = value
				),
			apply = (func(value: int) -> int:
				value = clampi(value, -15, 15)
				return value
				),
			connected = true,
		},
		{
			type = 1, key = "settings.display_el", default = true,
			title = "settings.display_el",
			display = (func(data: Dictionary, value: bool) -> void:
				data.text = "generic.on" if value else "generic.off"
				data.enabled = value
				),
			apply = (func(value: bool) -> bool:
				return value
				),
			connected = false,
		},
		{
			type = 2, key = "settings.effect_size", default = 6,
			title = "settings.effect_size",
			display = (func(data: Dictionary, value: int) -> void:
				data.text = "generic.off" if value == 0.0 else str(value * 10 + 60) + "%"
				data.index = value
				),
			apply = (func(value: int) -> int:
				value = clampi(value, 0, 14)
				return value
				),
			connected = false,
		},
		{
			type = 2, key = "settings.judgement_rate", default = 8,
			title = "settings.judgement_rate",
			questioning = (func() -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 0,
					title = "settings.judgement_rate",
					content = "settings.judgement_rate.disc",
					options = [
						{ enabled = false },
						{ enabled = true },
						{ enabled = false },
					]
				}
				),
			display = (func(data: Dictionary, value: int) -> void:
				data.text = str(value * 30 + 60)
				data.index = value
				),
			apply = (func(value: int) -> int:
				value = clampi(value, 0, 18)
				Engine.physics_ticks_per_second = value * 30 + 60
				Engine.max_physics_steps_per_frame = 64
				return value
				),
			connected = false,
		},
	],
	[
		{
			type = 3, key = "settings.music_volume", default = 0.8,
			title = "settings.music_volume",
			display = (func(data: Dictionary, value: float) -> void:
				data.text = "generic.off" if value == 0.0 else str(int(value * 100.0)) + "%"
				data.progress = value
				),
			apply = (func(value: float) -> float:
				SoundManager.set_volume(2, value * 2.0)
				AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("music"), value)
				return value
				),
			connected = false,
		},
		{
			type = 3, key = "settings.effect_volume", default = 0.5,
			title = "settings.effect_volume",
			display = (func(data: Dictionary, value: float) -> void:
				data.text = "generic.off" if value == 0.0 else str(int(value * 200.0)) + "%"
				data.progress = value
				),
			apply = (func(value: float) -> float:
				SoundManager.set_volume(0, value * 2.0)
				return value
				),
			connected = false,
		},
		{
			type = 3, key = "settings.ui_volume", default = 0.8,
			title = "settings.ui_volume",
			display = (func(data: Dictionary, value: float) -> void:
				data.text = "generic.off" if value == 0.0 else str(int(value * 100.0)) + "%"
				data.progress = value
				),
			apply = (func(value: float) -> float:
				SoundManager.set_volume(1, value)
				return value
				),
			connected = false,
		},
		{
			type = 3, key = "settings.bgm_volume", default = 0.5,
			title = "settings.bgm_volume",
			display = (func(data: Dictionary, value: float) -> void:
				data.text = "generic.off" if value == 0.0 else str(int(value * 100.0)) + "%"
				data.progress = value
				),
			apply = (func(value: float) -> float:
				SoundManager.set_volume(3, value * 2.0)
				AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("bgm_volume"), value)
				return value
				),
			connected = false,
		},
	],
	[
		{
			type = 2, key = "settings.language", default = -2,
			title = "Language/言語設定",
			display = (func(data: Dictionary, value: int) -> void:
				if value == -2:
					value = maxi(["en", "zh", "ja"].find(OS.get_locale_language()), 0)
				data.text = language_list[value][1]
				data.index = value
				),
			apply = (func(value: int) -> int:
				if value == -2:
					value = maxi(["en", "zh", "ja"].find(OS.get_locale_language()), 0)
				value = wrapi(value, 0, 3)
				TranslationServer.set_locale(language_list[value][0])
				refresh_size()
				return value
				),
			connected = false,
		},
		{
			type = 2, key = "settings.max_fps", default = 2,
			title = "settings.max_fps",
			display = (func(data: Dictionary, value: int) -> void:
				data.text = str(value * 30 + 60)
				data.index = value
				),
			apply = (func(value: int) -> int:
				value = clampi(value, 0, 6)
				Engine.max_fps = value * 30 + 60
				return value
				),
			connected = false,
		},
		{
			type = 1, key = "settings.anti_aliasing", default = false,
			title = "settings.anti_aliasing",
			questioning = (func() -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 0,
					title = "settings.anti_aliasing",
					content = "settings.anti_aliasing.disc",
					options = [
						{ enabled = false },
						{ enabled = true },
						{ enabled = false },
					]
				}
				),
			display = (func(data: Dictionary, value: bool) -> void:
				data.text = "generic.on" if value else "generic.off"
				data.enabled = value
				),
			apply = (func(value: bool) -> bool:
				if value:
					get_viewport().msaa_3d = Viewport.MSAA_4X
				else:
					get_viewport().msaa_3d = Viewport.MSAA_DISABLED
				return value
				),
			connected = false,
		},
		{
			type = 1, key = "settings.low_resolution", default = false,
			title = "settings.low_resolution",
			questioning = (func() -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 0,
					title = "settings.low_resolution",
					content = "settings.low_resolution.disc",
					options = [
						{ enabled = false },
						{ enabled = true },
						{ enabled = false },
					]
				}
				),
			display = (func(data: Dictionary, value: bool) -> void:
				data.text = "generic.on" if value else "generic.off"
				data.enabled = value
				),
			apply = (func(value: bool) -> bool:
				if value:
					get_viewport().scaling_3d_scale = 0.75
				else:
					get_viewport().scaling_3d_scale = 1.0
				return value
				),
			connected = false,
		},
	],
	[
		{
			type = -1,
			title = "settings.thanks",
			text = "",
			display = (func(data: Dictionary, value: Variant) -> void:
				pass
				),
			apply = (func(value: Variant) -> void:
				pass
				),
			connected = false,
		},
		{
			type = 0,
			title = "settings.credits",
			text = "settings.credits",
			display = (func(data: Dictionary, value: Variant) -> void:
				pass
				),
			apply = (func(value: Variant) -> void:
				await SceneManager.insert("credits")
				),
			connected = true,
		},
		{
			type = 0,
			title = "settings.licence",
			text = "settings.licence",
			display = (func(data: Dictionary, value: Variant) -> void:
				pass
				),
			apply = (func(value: Variant) -> void:
				await SceneManager.insert("licence")
				),
			connected = true,
		},
		{
			type = 0,
			title = "settings.reset",
			text = "settings.reset_settings",
			display = (func(data: Dictionary, value: Variant) -> void:
				pass
				),
			apply = (func(value: Variant) -> void:
				var dialog: Node = await SceneManager.insert("dialog")
				dialog.data = {
					type = 1,
					title = "generic.warning",
					content = "settings.reset_settings.warning",
					options = [
						{
							enabled = true,
							function = (func() -> void:
								for category: Array in settings_data:
									for data: Dictionary in category:
										if data.has("key"):
											data.callback.call(data.default)
								),
						},
						{ enabled = false },
						{ enabled = true },
					]
				}
				),
			connected = false,
		},
	],
]

func refresh_size() -> void:
	for type: int in 4:
		for data: Dictionary in settings_data[type]:
			if data.has("item"):
				data.item.refresh_size()

func load_settings() -> void:
	for type: int in 4:
		for data: Dictionary in settings_data[type]:
			if data.has("key"):
				data.read = (func() -> void:
					var value: Variant = DataManager.get_save(data.key, data.default)
					data.display.call(data, value)
					data.item.load_data(data)
				)
				data.callback = (func(value: Variant) -> void:
					value = data.apply.call(value)
					DataManager.set_save(data.key, value)
					data.read.call()
				)
				var init_value: Variant = DataManager.get_save(data.key, data.default)
				data.apply.call(init_value)
			else:
				data.read = (func() -> void:
					var value: Variant = data.get("value", null)
					data.display.call(data, value)
					data.item.load_data(data)
				)
				data.callback = (func(value: Variant) -> void:
					data.apply.call(value)
					data.value = value
					data.read.call()
				)

func _ready() -> void:
	load_settings()
