class_name WebView
extends TextureRect

## WebView — 100% Native GDScript Headless Browser Node for Godot 4.7
## Communicates directly with Chrome/Chromium via Chrome DevTools Protocol (CDP)
## over a native WebSocketPeer connection. Zero Python dependencies.

signal url_changed(new_url: String)
signal oauth_callback_detected(callback_url: String)
signal frame_updated()
signal load_started(url: String)
signal browser_ready()

const CDP_PORT := 19222
const CDP_HOST := "127.0.0.1"
const PAGE_W := 1024.0
const PAGE_H := 720.0

@export var poll_interval: float = 0.15
@export var auto_start_browser: bool = true

var current_url: String = ""
var is_active: bool = false

var _ws: WebSocketPeer
var _http_discovery: HTTPRequest
var _poll_timer: Timer

var _msg_id: int = 0
var _cdp_connected: bool = false
var _browser_pid: int = 0
var _pending_navigation: String = ""
var _screenshot_in_flight: bool = false


func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


func _ready() -> void:
	_setup_internal_nodes()
	gui_input.connect(_on_gui_input)
	if auto_start_browser:
		ensure_browser()


func _setup_internal_nodes() -> void:
	if not _http_discovery:
		_http_discovery = HTTPRequest.new()
		_http_discovery.name = "CDPDiscovery"
		_http_discovery.timeout = 5.0
		add_child(_http_discovery)
		_http_discovery.request_completed.connect(_on_discovery_completed)

	if not _poll_timer:
		_poll_timer = Timer.new()
		_poll_timer.name = "CDPPollTimer"
		_poll_timer.wait_time = poll_interval
		add_child(_poll_timer)
		_poll_timer.timeout.connect(_on_poll_timer)

	_ws = WebSocketPeer.new()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		close_browser()


func _process(_delta: float) -> void:
	if not _ws or _ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		return

	_ws.poll()
	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _cdp_connected:
			_cdp_connected = true
			_initialize_cdp_session()

		while _ws.get_available_packet_count() > 0:
			var packet := _ws.get_packet()
			var text := packet.get_string_from_utf8()
			_handle_cdp_message(text)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED and _cdp_connected:
		_cdp_connected = false


func _get_chrome_binary() -> String:
	var binaries := [
		"/usr/bin/google-chrome",
		"/usr/bin/google-chrome-stable",
		"/usr/bin/chromium",
		"/usr/bin/chromium-browser",
		"/usr/bin/brave-browser",
		"/usr/bin/microsoft-edge",
	]
	for b in binaries:
		if FileAccess.file_exists(b):
			return b
	return "google-chrome"


func _get_profile_path() -> String:
	var home := OS.get_environment("HOME")
	return home + "/.config/sscodeide-chrome-profile"


func _clean_profile_locks() -> void:
	var dir: String = _get_profile_path()
	if DirAccess.dir_exists_absolute(dir):
		var lock_names: Array[String] = ["SingletonLock", "SingletonCookie", "SingletonSocket"]
		for lock_file: String in lock_names:
			var lock_path: String = dir + "/" + lock_file
			if FileAccess.file_exists(lock_path):
				DirAccess.remove_absolute(lock_path)


func ensure_browser() -> void:
	var profile_dir := _get_profile_path()
	DirAccess.make_dir_recursive_absolute(profile_dir)
	_clean_profile_locks()

	var chrome_bin := _get_chrome_binary()
	var args := PackedStringArray([
		"--remote-debugging-port=%d" % CDP_PORT,
		"--remote-debugging-address=%s" % CDP_HOST,
		"--user-data-dir=%s" % profile_dir,
		"--headless=new",
		"--disable-gpu",
		"--no-first-run",
		"--no-default-browser-check",
		"--disable-extensions",
		"--disable-popup-blocking",
		"--disable-blink-features=AutomationControlled",
		"--window-size=%d,%d" % [int(PAGE_W), int(PAGE_H)],
		"about:blank",
	])
	_browser_pid = OS.create_process(chrome_bin, args)
	_connect_cdp()


func _connect_cdp() -> void:
	if _cdp_connected or not _http_discovery:
		return
	_http_discovery.request("http://%s:%d/json/list" % [CDP_HOST, CDP_PORT])


func _on_discovery_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		# Retry discovery after short delay if Chrome is still booting
		get_tree().create_timer(0.3).timeout.connect(_connect_cdp)
		return

	var json_text := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(json_text)
	var ws_url: String = ""

	if parsed is Array:
		for item in parsed:
			if item is Dictionary and item.get("type") == "page":
				ws_url = str(item.get("webSocketDebuggerUrl", ""))
				if not ws_url.is_empty():
					break

	if ws_url.is_empty():
		_http_discovery.request("http://%s:%d/json/new?about:blank" % [CDP_HOST, CDP_PORT])
		return

	var err := _ws.connect_to_url(ws_url)
	if err != OK:
		get_tree().create_timer(0.3).timeout.connect(_connect_cdp)


func _initialize_cdp_session() -> void:
	_send_cdp("Page.enable")
	_send_cdp("Runtime.enable")
	_send_cdp("Emulation.setDeviceMetricsOverride", {
		"width": int(PAGE_W),
		"height": int(PAGE_H),
		"deviceScaleFactor": 1,
		"mobile": false,
	})
	browser_ready.emit()

	if not _pending_navigation.is_empty():
		var url_to_nav := _pending_navigation
		_pending_navigation = ""
		navigate(url_to_nav)

	start_polling()


func navigate(url: String) -> void:
	current_url = url
	load_started.emit(url)

	if not _cdp_connected:
		_pending_navigation = url
		ensure_browser()
		return

	_send_cdp("Page.navigate", {"url": url})
	start_polling()


func start_polling() -> void:
	is_active = true
	if _poll_timer and _poll_timer.is_inside_tree() and _poll_timer.is_stopped():
		_poll_timer.start(poll_interval)


func stop_polling() -> void:
	is_active = false
	if _poll_timer:
		_poll_timer.stop()


func close_browser() -> void:
	stop_polling()
	if _cdp_connected and _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_cdp("Browser.close")
		_ws.close()
	_cdp_connected = false
	_clean_profile_locks()


func send_click(pos: Vector2, view_size: Vector2) -> void:
	if not _cdp_connected:
		return
	var px: float = pos.x * PAGE_W / maxf(view_size.x, 1.0)
	var py: float = pos.y * PAGE_H / maxf(view_size.y, 1.0)
	_send_cdp("Input.dispatchMouseEvent", {
		"type": "mousePressed",
		"x": px,
		"y": py,
		"button": "left",
		"clickCount": 1
	})
	_send_cdp("Input.dispatchMouseEvent", {
		"type": "mouseReleased",
		"x": px,
		"y": py,
		"button": "left",
		"clickCount": 1
	})
	_request_screenshot()


func send_key(key_text: String) -> void:
	if not _cdp_connected or key_text.is_empty():
		return

	var key_codes := {
		"Enter": {"vk": 13, "code": "Enter"},
		"Backspace": {"vk": 8, "code": "Backspace"},
		"Tab": {"vk": 9, "code": "Tab"},
		"Escape": {"vk": 27, "code": "Escape"},
		"ArrowLeft": {"vk": 37, "code": "ArrowLeft"},
		"ArrowUp": {"vk": 38, "code": "ArrowUp"},
		"ArrowRight": {"vk": 39, "code": "ArrowRight"},
		"ArrowDown": {"vk": 40, "code": "ArrowDown"},
		"Delete": {"vk": 46, "code": "Delete"},
	}

	if key_codes.has(key_text):
		var info: Dictionary = key_codes[key_text]
		_send_cdp("Input.dispatchKeyEvent", {
			"type": "keyDown",
			"key": key_text,
			"code": info["code"],
			"windowsVirtualKeyCode": info["vk"],
		})
		_send_cdp("Input.dispatchKeyEvent", {
			"type": "keyUp",
			"key": key_text,
			"code": info["code"],
			"windowsVirtualKeyCode": info["vk"],
		})
	else:
		_send_cdp("Input.insertText", {"text": key_text})

	_request_screenshot()


func _send_cdp(method: String, params: Dictionary = {}) -> int:
	if not _ws or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return -1
	_msg_id += 1
	var payload := {
		"id": _msg_id,
		"method": method,
		"params": params,
	}
	_ws.send_text(JSON.stringify(payload))
	return _msg_id


func _request_screenshot() -> void:
	if _screenshot_in_flight or not _cdp_connected:
		return
	_screenshot_in_flight = true
	_send_cdp("Page.captureScreenshot", {
		"format": "jpeg",
		"quality": 75,
		"fromSurface": true,
	})


func _on_poll_timer() -> void:
	if not is_visible_in_tree() or not is_active or not _cdp_connected:
		return
	_send_cdp("Runtime.evaluate", {
		"expression": "location.href",
		"returnByValue": true,
	})
	_request_screenshot()


func _handle_cdp_message(raw_json: String) -> void:
	var parsed: Variant = JSON.parse_string(raw_json)
	if not (parsed is Dictionary):
		return
	var dict: Dictionary = parsed

	if dict.has("result"):
		var result: Dictionary = dict["result"]

		# Handle screenshot frame
		if result.has("data"):
			_screenshot_in_flight = false
			var b64_data: String = str(result["data"])
			if not b64_data.is_empty():
				var raw: PackedByteArray = Marshalls.base64_to_raw(b64_data)
				var img := Image.new()
				var err: Error = img.load_jpg_from_buffer(raw)
				if err != OK:
					err = img.load_png_from_buffer(raw)
				if err == OK:
					texture = ImageTexture.create_from_image(img)
					frame_updated.emit()

		# Handle URL evaluation
		elif result.has("result") and result["result"] is Dictionary:
			var inner: Dictionary = result["result"]
			if inner.has("value"):
				var fetched_url: String = str(inner["value"]).strip_edges()
				if not fetched_url.is_empty() and fetched_url != current_url:
					current_url = fetched_url
					url_changed.emit(current_url)
					if OAuthUrl.is_loopback_callback(current_url):
						oauth_callback_detected.emit(current_url)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			send_click(mb.position, size)
	elif event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo:
			if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
				send_key("Enter")
			elif key.keycode == KEY_BACKSPACE:
				send_key("Backspace")
			elif key.keycode == KEY_TAB:
				send_key("Tab")
			elif key.keycode == KEY_ESCAPE:
				send_key("Escape")
			elif key.keycode == KEY_LEFT:
				send_key("ArrowLeft")
			elif key.keycode == KEY_RIGHT:
				send_key("ArrowRight")
			elif key.keycode == KEY_UP:
				send_key("ArrowUp")
			elif key.keycode == KEY_DOWN:
				send_key("ArrowDown")
			elif key.keycode == KEY_DELETE:
				send_key("Delete")
			elif key.unicode > 0:
				send_key(String.chr(key.unicode))
