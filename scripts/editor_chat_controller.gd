class_name EditorChatController
extends RefCounted

## Chat, AI, and Streaming controller for the editor

const ChatMarkdown = preload("res://scripts/chat_markdown_renderer.gd")
const AgentWorkspace = preload("res://scripts/agent_workspace_service.gd")

const CHAT_SLASH_COMMANDS: Array[Dictionary] = [
	{"cmd": "/tools", "desc": "List all available AI agent tools"},
	{"cmd": "/git status", "desc": "Show repository status, branch & GitHub remote"},
	{"cmd": "/git diff", "desc": "Show repository diff and code changes"},
	{"cmd": "/git log", "desc": "Show recent commit history"},
	{"cmd": "/git commit", "desc": "Generate intelligent Git commit or commit with message"},
	{"cmd": "/git push", "desc": "Push local commits to GitHub repository"},
	{"cmd": "/git pull", "desc": "Pull latest changes from GitHub repository"},
	{"cmd": "/git sync", "desc": "Synchronise with GitHub (Pull & Push)"},
	{"cmd": "/git fetch", "desc": "Fetch remote branches from GitHub"},
	{"cmd": "/git branch", "desc": "List or switch/create branches"},
	{"cmd": "/git checkout ", "desc": "Switch to branch (/git checkout <branch>)"},
	{"cmd": "/git remote", "desc": "Show configured GitHub remotes & URLs"},
	{"cmd": "/git config ", "desc": "Set Git user name and email (/git config <name> <email>)"},
	{"cmd": "/git clone ", "desc": "Clone GitHub repository (/git clone <url>)"},
	{"cmd": "/github", "desc": "Display GitHub repository links and details"},
	{"cmd": "/search ", "desc": "Search the live Internet & web for up-to-date information (/search <query>)"},
	{"cmd": "/web ", "desc": "Search the live Internet & web for up-to-date information (/web <query>)"},
	{"cmd": "/save", "desc": "Save the active file in editor"},
	{"cmd": "/files", "desc": "Refresh workspace file explorer"},
	{"cmd": "/open ", "desc": "Open file by path (/open <path>)"},
	{"cmd": "/goto ", "desc": "Go to line number (/goto <line>)"},
	{"cmd": "/clear", "desc": "Clear conversation history & chat context"},
	{"cmd": "/compact", "desc": "Compact older conversation context while preserving recent messages"},
	{"cmd": "/cancel", "desc": "Abort running AI request"},
	{"cmd": "/quit", "desc": "Quit SSCodeIDE"},
]

var _e

func _init(editor: Control) -> void:
	_e = editor

func start_chat_stream(payload_json: String) -> bool:
	stop_chat_stream()
	var err = _e._stream_http.connect_to_host("integrate.api.nvidia.com", 443, TLSOptions.client())
	if err != OK:
		return false
	_e._stream_active = true
	_e._sse_buf = ""
	_e._stream_reply = ""
	_e._thinking_text = ""
	## Handshake is completed in poll_chat_stream; stash payload on the client via meta.
	_e._stream_http.set_meta("payload", payload_json)
	_e._stream_http.set_meta("sent", false)
	return true


func stop_chat_stream() -> void:
	_e._stream_active = false
	if _e._stream_http.get_status() != HTTPClient.STATUS_DISCONNECTED:
		_e._stream_http.close()
	_e._sse_buf = ""


func poll_chat_stream() -> void:
	_e._stream_http.poll()
	var st = _e._stream_http.get_status()
	if st == HTTPClient.STATUS_CONNECTING or st == HTTPClient.STATUS_RESOLVING:
		return
	if st == HTTPClient.STATUS_CONNECTED and not bool(_e._stream_http.get_meta("sent", false)):
		var headers = PackedStringArray([
			"Content-Type: application/json",
			"Authorization: Bearer " + AIService.get_nvidia_api_key(),
			"Accept: text/event-stream",
		])
		var payload: String = str(_e._stream_http.get_meta("payload", ""))
		var req_err = _e._stream_http.request(HTTPClient.METHOD_POST, "/v1/chat/completions", headers, payload)
		_e._stream_http.set_meta("sent", true)
		if req_err != OK:
			stop_chat_stream()
			on_ai_chat_http_completed(HTTPRequest.RESULT_CONNECTION_ERROR, 0, PackedStringArray(), PackedByteArray())
		return
	if st == HTTPClient.STATUS_BODY:
		var chunk = _e._stream_http.read_response_body_chunk()
		if chunk.size() > 0:
			_e._sse_buf += chunk.get_string_from_utf8()
			consume_sse_buffer()
		if not _e._stream_http.has_response() or _e._stream_http.get_status() == HTTPClient.STATUS_DISCONNECTED:
			finish_chat_stream()
		return
	if st == HTTPClient.STATUS_DISCONNECTED or st == HTTPClient.STATUS_CONNECTION_ERROR or st == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
		if not _e._stream_reply.is_empty() or not _e._thinking_text.is_empty():
			finish_chat_stream()
		else:
			stop_chat_stream()
			on_ai_chat_http_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())


func consume_sse_buffer() -> void:
	while true:
		var nl = _e._sse_buf.find("\n")
		if nl < 0:
			break
		var line = _e._sse_buf.substr(0, nl).strip_edges()
		_e._sse_buf = _e._sse_buf.substr(nl + 1)
		if line.is_empty() or not line.begins_with("data:"):
			continue
		var data = line.substr(5).strip_edges()
		if data == "[DONE]":
			finish_chat_stream()
			return
		var json = JSON.new()
		if json.parse(data) != OK or not (json.data is Dictionary):
			continue
		var parsed: Dictionary = json.data
		var choices: Array = parsed.get("choices", [])
		if choices.is_empty() or not (choices[0] is Dictionary):
			continue
		var choice: Dictionary = choices[0]
		var delta: Dictionary = choice.get("delta", {}) if choice.get("delta", {}) is Dictionary else {}
		var msg: Dictionary = choice.get("message", {}) if choice.get("message", {}) is Dictionary else {}
		for src in [delta, msg]:
			var thought = extract_reasoning(src)
			if not thought.is_empty():
				if thought.begins_with(_e._thinking_text):
					_e._thinking_text = thought
				else:
					var separator = "" if _e._thinking_text.is_empty() or _e._thinking_text.ends_with(" ") or thought.begins_with(" ") else " "
					_e._thinking_text += separator + thought
			var piece = str(src.get("content", ""))
			if not piece.is_empty() and piece != "<null>":
				_e._stream_reply += piece


func finish_chat_stream() -> void:
	if _e._response_rendered:
		return
	if not _e._stream_active and _e._stream_reply.is_empty() and _e._thinking_text.is_empty():
		return
	stop_chat_stream()
	var elapsed: float = maxf(0.1, (Time.get_ticks_msec() / 1000.0) - _e._request_start_time)
	if _e._current_prompt.begins_with("__SMART_COMMIT__:"):
		if _e._stream_reply.strip_edges().is_empty():
			_e.git.fallback_smart_commit("Empty AI reply.")
			return
		_e.git.finish_smart_commit(_e._stream_reply.strip_edges(), true)
		return
	var reply = _e._stream_reply.strip_edges()
	if reply.is_empty() and not _e._thinking_text.is_empty():
		reply = _e._thinking_text.strip_edges()
	if reply.is_empty():
		if try_next_ai_candidate("Empty stream. Attempting candidate model…"):
			return
		append_chat(_e._ai_provider.to_upper(), "Empty server response. Please retry.", Color("#ed333b"))
		return
	_e._response_rendered = true
	reply = execute_agent_file_writes(reply)
	_e._chat_history.append({"role": "assistant", "content": reply})
	clear_ai_busy()
	append_ai_response(_e._ai_provider, reply, elapsed)


func extract_reasoning(msg: Dictionary) -> String:
	for key in ["reasoning_content", "reasoning", "thinking", "reasoning_text"]:
		if msg.has(key) and str(msg[key]).strip_edges() != "":
			return str(msg[key]).strip_edges()
	var content = str(msg.get("content", ""))
	var start = content.find("<think>")
	var end = content.find("</think>")
	if start >= 0 and end > start:
		return content.substr(start + 7, end - start - 7).strip_edges()
	return ""


func refresh_thinking_panel() -> void:
	if _e._chat_thinking_label == null:
		return
	var body: String = format_thinking_text(_e._thinking_text)
	if body.is_empty():
		body = "Waiting for the model’s reasoning tokens…"
	_e._chat_thinking_label.text = "[color=#9a9996][i]%s[/i][/color]" % body.replace("[", "[lb]")


func format_thinking_text(raw: String) -> String:
	var body = raw.replace("\r\n", "\n").replace("\r", "\n")
	body = body.replace("<think>", "").replace("</think>", "")
	var lines: PackedStringArray = []
	for line in body.split("\n"):
		var clean = line.strip_edges()
		clean = clean.trim_prefix("###").strip_edges()
		clean = clean.trim_prefix("**").trim_suffix("**").strip_edges()
		if clean.is_empty() or (not lines.is_empty() and lines[-1] == clean):
			continue
		lines.append(clean)
	var result = "\n".join(lines)
	var spacing = RegEx.new()
	spacing.compile("([a-z])([A-Z])")
	result = spacing.sub(result, "$1 $2", true)
	if result.length() > 1800:
		result = result.substr(result.length() - 1800, 1800)
		result = "… " + result
	return result


func on_chat_submitted(text: String) -> void:
	var prompt: String = text.strip_edges()
	if prompt.is_empty() or _e._ai_busy:
		return
	if _e._prompt_history.is_empty() or _e._prompt_history.back() != prompt:
		_e._prompt_history.append(prompt)
	_e._prompt_history_idx = -1
	_e._prompt_draft = ""
	_e._chat_input.text = ""
	_e._chat_suggestions_popup.visible = false
	append_user_message(prompt)
	if prompt.begins_with("/"):
		handle_slash(prompt)
		return
	_e._chat_history.append({"role": "user", "content": prompt})
	_e.dialog.ensure_api_key(func() -> void: ask_ai(prompt))


func on_chat_send_pressed() -> void:
	var txt = _e._chat_input.text.strip_edges()
	if not txt.is_empty():
		on_chat_submitted(txt)
	elif _e._ai_busy:
		cancel_ai_request()


func on_chat_input_text_changed(new_text: String) -> void:
	if not _e._ai_busy:
		_e._chat_send.text = "↑"
	update_chat_suggestions(new_text)


func update_chat_suggestions(input_text: String) -> void:
	var query = input_text.strip_edges()
	_e._chat_suggestions_list.clear()
	
	if query.begins_with("/"):
		for item: Dictionary in CHAT_SLASH_COMMANDS:
			var cmd: String = str(item.get("cmd", ""))
			if query == "/" or cmd.begins_with(query):
				_e._chat_suggestions_list.add_item(cmd + "  —  " + str(item.get("desc", "")))
				_e._chat_suggestions_list.set_item_metadata(_e._chat_suggestions_list.get_item_count() - 1, cmd)
	elif query.contains("@") or query.begins_with("open ") or query.begins_with("read "):
		var at_idx = query.rfind("@")
		var filter = ""
		if at_idx != -1:
			filter = query.substr(at_idx + 1).to_lower()
		var files = _e.files.get_workspace_files_list()
		for f in files:
			if filter.is_empty() or f.to_lower().contains(filter):
				_e._chat_suggestions_list.add_item("📁 @" + f)
				_e._chat_suggestions_list.set_item_metadata(_e._chat_suggestions_list.get_item_count() - 1, "@" + f)
				if _e._chat_suggestions_list.get_item_count() >= 8:
					break
	
	_e._chat_suggestions_popup.visible = _e._chat_suggestions_list.get_item_count() > 0


func on_chat_suggestion_selected(index: int) -> void:
	if index < 0 or index >= _e._chat_suggestions_list.get_item_count():
		return
	var meta: Variant = _e._chat_suggestions_list.get_item_metadata(index)
	if meta is String:
		var insert_val: String = meta
		if insert_val.begins_with("@") and _e._chat_input.text.contains("@"):
			var at_idx = _e._chat_input.text.rfind("@")
			_e._chat_input.text = _e._chat_input.text.substr(0, at_idx) + insert_val + " "
		else:
			_e._chat_input.text = insert_val + " "
		_e._chat_input.caret_column = _e._chat_input.text.length()
	_e._chat_suggestions_popup.visible = false
	_e._chat_input.grab_focus()


func on_chat_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key: InputEventKey = event
	if key.keycode == KEY_UP and not _e._chat_suggestions_popup.visible:
		if _e._prompt_history.is_empty():
			return
		if _e._prompt_history_idx == -1:
			_e._prompt_draft = _e._chat_input.text
			_e._prompt_history_idx = _e._prompt_history.size() - 1
		elif _e._prompt_history_idx > 0:
			_e._prompt_history_idx -= 1
		_e._chat_input.text = _e._prompt_history[_e._prompt_history_idx]
		_e._chat_input.caret_column = _e._chat_input.text.length()
		_e._chat_input.accept_event()
	elif key.keycode == KEY_DOWN and not _e._chat_suggestions_popup.visible:
		if _e._prompt_history_idx == -1:
			return
		if _e._prompt_history_idx < _e._prompt_history.size() - 1:
			_e._prompt_history_idx += 1
			_e._chat_input.text = _e._prompt_history[_e._prompt_history_idx]
		else:
			_e._prompt_history_idx = -1
			_e._chat_input.text = _e._prompt_draft
		_e._chat_input.caret_column = _e._chat_input.text.length()
		_e._chat_input.accept_event()


func append_chat(who: String, msg_body: String, _color: Color = Color()) -> void:
	var tag = who.to_upper()
	if tag in ["YOU", "USER"]:
		_e._chat_history.append({"role": "user", "content": msg_body})
		append_user_message_to_log(msg_body)
	elif tag in ["SYSTEM", "TOOL", "IDE", "WEB"]:
		_e._chat_history.append({"role": "system", "content": msg_body})
		var sys_col = "#6c6c70" if _e._theme_is_light(_e._active_theme) else "#8e8e93"
		_e._chat_log.append_text("[color=%s]%s[/color]\n\n" % [sys_col, format_markdown_to_bbcode(msg_body)])
	else:
		_e._chat_history.append({"role": "assistant", "content": msg_body})
		append_ai_response_to_log(msg_body)
	_e._chat_log.scroll_to_line(_e._chat_log.get_line_count() - 1)


func append_ai_response(_provider: String, reply_text: String, _elapsed: float = 0.0, _tokens_in: int = 0, _tokens_out: int = 0) -> void:
	append_ai_response_to_log(reply_text)


func append_ai_response_to_log(reply_text: String) -> void:
	var formatted_body = format_markdown_to_bbcode(reply_text)
	_e._chat_log.append_text("\n%s\n\n" % formatted_body)
	_e._chat_log.scroll_to_line(_e._chat_log.get_line_count() - 1)


func append_user_message(prompt: String) -> void:
	if _e._chat_history.is_empty():
		_e._chat_log.clear()
	append_user_message_to_log(prompt)


func append_user_message_to_log(prompt: String) -> void:
	var sanitized: String = prompt.replace("[", "[lb]")
	var is_light = _e._theme_is_light(_e._active_theme)
	var bg_col = "#252830" if not is_light else "#e2e4e9"
	var fg_col = "#ffffff" if not is_light else "#111113"
	var user_bubble = "\n[right][bgcolor=%s][color=%s]  %s  [/color][/bgcolor][/right]\n\n" % [bg_col, fg_col, sanitized.replace("\n", "\n  ")]
	_e._chat_log.append_text(user_bubble)
	_e._chat_log.scroll_to_line(_e._chat_log.get_line_count() - 1)


func append_tool_badge(action: String, target: String) -> void:
	_e._chat_log.append_text("[color=#57e389]●[/color] [b]%s[/b][color=#9a9996](%s)[/color]\n\n" % [action, target])
	_e._chat_log.scroll_to_line(_e._chat_log.get_line_count() - 1)


func rebuild_chat_log() -> void:
	if _e._chat_log == null:
		return
	_e._chat_log.clear()
	if _e._chat_history.is_empty():
		show_chat_welcome()
		return
	for entry in _e._chat_history:
		var role: String = str(entry.get("role", "assistant"))
		var content: String = str(entry.get("content", ""))
		if role == "user":
			append_user_message_to_log(content)
		elif role == "system":
			var sys_col = "#6c6c70" if _e._theme_is_light(_e._active_theme) else "#8e8e93"
			_e._chat_log.append_text("[color=%s]%s[/color]\n\n" % [sys_col, format_markdown_to_bbcode(content)])
		else:
			append_ai_response_to_log(content)


func on_chat_meta_clicked(meta: Variant) -> void:
	var value = str(meta)
	if value.begins_with("copy:"):
		DisplayServer.clipboard_set(Marshalls.base64_to_raw(value.trim_prefix("copy:")).get_string_from_utf8())
		_e.dialog.show_toast("Code copied to clipboard.", false)
	elif value == "action_like":
		_e.dialog.show_toast("Feedback received: Liked!", false)
	elif value == "action_dislike":
		_e.dialog.show_toast("Feedback received: Disliked.", false)
	elif value == "action_pin":
		_e.dialog.show_toast("Message pinned to context.", false)
	elif value.begins_with("action_download:"):
		var text = Marshalls.base64_to_raw(value.trim_prefix("action_download:")).get_string_from_utf8()
		DisplayServer.clipboard_set(text)
		_e.dialog.show_toast("Response text copied for export.", false)
	elif value == "action_retry":
		if not _e._chat_history.is_empty():
			var last_user_prompt = ""
			for entry in _e._chat_history:
				if entry.get("role") == "user":
					last_user_prompt = str(entry.get("content", ""))
			if not last_user_prompt.is_empty():
				ask_ai(last_user_prompt)


func show_chat_welcome() -> void:
	_e._chat_log.clear()
	var welcome = "\n\n\n\n\n[center][font_size=28][b]Let's Talk[/b][/font_size]\n[color=#7a7e85][font_size=13]Ask any question or start coding with AI[/font_size][/color][/center]\n"
	_e._chat_log.append_text(welcome)


func on_clear_chat_pressed() -> void:
	_e._chat_history.clear()
	show_chat_welcome()
	_e._send_os_notification("Chat", "Chat history cleared.")


func on_compact_chat_pressed() -> void:
	compact_chat_history()


func format_markdown_to_bbcode(raw_text: String) -> String:
	var is_light = _e._theme_is_light(_e._active_theme)
	return ChatMarkdown.render(raw_text, is_light)


func format_code_block(code: String, language: String) -> String:
	return ChatMarkdown.format_code_block(code, language)


func replace_bold(text: String) -> String:
	return ChatMarkdown.replace_bold(text)


func replace_inline_code(text: String) -> String:
	return ChatMarkdown.replace_inline_code(text)


func replace_italic(text: String) -> String:
	return ChatMarkdown.replace_italic(text)


func replace_links(text: String) -> String:
	return ChatMarkdown.replace_links(text)


func ask_ai(prompt: String) -> void:
	_e._ai_busy = true
	_e._response_rendered = false
	_e._request_start_time = Time.get_ticks_msec() / 1000.0
	_e._spinner_time = 0.0
	_e._chat_status_banner.visible = true
	_e._chat_send.text = "■"
	_e._status_left.text = "Generating response…"
	_e._current_prompt = prompt
	_e._model_candidates = AIService.get_candidate_models(_e._ai_provider)
	_e._model_candidate_index = 0

	var lower = prompt.to_lower()
	var needs_web = (
		lower.contains("pesquisa") or lower.contains("busca") or lower.contains("internet")
		or lower.contains("web") or lower.contains("notícia") or lower.contains("noticia")
		or lower.contains("última") or lower.contains("recente") or lower.contains("novidade")
		or lower.contains("versão actual") or lower.contains("versao actual") or lower.contains("online")
	)
	if needs_web:
		var search_q = prompt.replace("pesquisa na web", "").replace("pesquisa na internet", "").replace("busca na internet", "").replace("procura na internet", "").strip_edges()
		if search_q.length() > 2:
			var web_res = WebSearchService.search_web(search_q, 4)
			if not web_res.is_empty():
				var web_context = WebSearchService.format_search_context_for_prompt(search_q, web_res)
				_e._chat_history.append({"role": "system", "content": web_context})

	send_chat_completion()


func send_chat_completion() -> void:
	if _e._model_candidate_index >= _e._model_candidates.size():
		if _e._is_smart_commit_pending():
			_e.git.fallback_smart_commit("NVIDIA NIM models exhausted.")
			return
		_e._smart_commit_prompt = ""
		clear_ai_busy()
		append_chat(_e._ai_provider.to_upper(), "Could not retrieve response from NVIDIA NIM models. Please retry.", Color("#ed333b"))
		return

	var model_name: String = _e._model_candidates[_e._model_candidate_index]
	var target_url: String = AIService.NVIDIA_BASE_URL
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + AIService.get_nvidia_api_key(),
		"Accept: application/json"
	])
	var is_smart_commit = _e._current_prompt.begins_with("__SMART_COMMIT__:")
	var messages_payload: Array[Dictionary] = []
	var payload_dict: Dictionary = {}

	if is_smart_commit:
		messages_payload = [
			{"role": "system", "content": "You are an expert Git commit message writer. Output ONLY the commit message with no extra text or markdown."},
			{"role": "user", "content": _e._smart_commit_prompt}
		]
		payload_dict = {
			"model": model_name,
			"messages": messages_payload,
			"temperature": 0.2,
			"top_p": 0.9,
			"max_tokens": 256,
			"stream": false
		}
	else:
		var current_datetime: String = Time.get_datetime_string_from_system(false, true)
		var current_year: String = str(Time.get_date_dict_from_system().get("year", 2026))
		var workspace_info: String = get_workspace_context()
		var system_role_content: String = ""
		if _e._agent_mode:
			system_role_content = (
				"You are SSBot, an elite autonomous AI programming partner and agent integrated directly into SSCodeIDE created by Ser Superior (SS).\n" +
				"You have direct access and visibility to the project workspace files, directory tree, active file, and real-time Internet search capabilities.\n\n" +
				"=== CONTEXTO TEMPORAL & ACESSO À INTERNET (TEMPO REAL) ===\n" +
				"Data e Hora Actual: " + current_datetime + " (Ano: " + current_year + ")\n" +
				"Ambiente: SSCodeIDE sobre Godot Engine nativo em GDScript.\n" +
				"Tens acesso total a informações actualizadas em tempo real da Internet através do WebSearchService do SSCodeIDE. Responde sempre com conhecimento moderno, rigoroso e actualizado.\n\n" +
				"=== WORKSPACE CONTEXT ===\n" +
				workspace_info + "\n" +
				"=========================\n\n" +
				"=== REGRAS CRÍTICAS DE COMUNICAÇÃO, TRATAMENTO E LINGUAGEM ===\n" +
				"1. VARIEDADE LINGUÍSTICA E NORMA CULTA (PORTUGUÊS DE ANGOLA - pt-AO):\n" +
				"   - DEVES SEMPRE comunicar e responder em Português de Angola (pt-AO), aderindo estritamente à norma culta.\n" +
				"   - Aplica com rigor absoluto as regras ortográficas anteriores ao acordo de 2012, preservando as consoantes mudas em palavras como 'acção', 'directo', 'projecto', 'objecto', 'adopção', 'correcção', 'facto', 'actualização', 'óptimo', 'eléctrico', 'consecutivamente', 'exacto', 'redacção', 'arquitectura'.\n" +
				"2. TRATAMENTO SEGUNDO O PRONOME PESSOAL 'TU' (RIGOR GRAMATICAL):\n" +
				"   - Trata SEMPRE o utilizador pela segunda pessoa do singular ('tu').\n" +
				"   - Usa obrigatoriamente a regência pronominal e as formas corretas em Português: usa 'contigo' (NUNCA digas 'com tu'), 'teu/tua/teus/tuas', 'te' (e.g. 'estou contigo', 'como estás?', 'o que precisas para o teu projecto?').\n" +
				"   - NUNCA uses construções brasileiras como 'você' ou 'com tu'.\n" +
				"3. PROIBIÇÃO ABSOLUTA DE EMOJIS E GÍRIAS:\n" +
				"   - NUNCA uses emojis ou bonecos gráficos nas tuas respostas. Mantém um tom altamente culto, sóbrio, cortês, elegante e profissional.\n" +
				"4. CÓDIGO E IDENTIFICADORES TÉCNICOS EM INGLÊS BRITÂNICO (en-GB):\n" +
				"   - Todo o código-fonte, nomes de variáveis, funções, classes, docstrings e comentários técnicos no código DEVEM SEMPRE estar em Inglês Britânico técnico (en-GB) (e.g., 'colour', 'behaviour', 'initialise', 'serialisation', 'optimise', 'centre').\n" +
				"5. PRIVACIDADE E SEGREDOS DE FERRAMENTAS INTERNAS (TOOLS):\n" +
				"   - NUNCA listes, reveles ou exibas as tuas tags de ferramentas internas (como `<sscode-write>`, `<sscode-delete>`), nem esquemas ou especificações internas de ferramentas ao utilizador. Se o utilizador perguntar quais são as tuas ferramentas ou como funcionas, resume apenas as tuas capacidades em linguagem natural amigável.\n" +
				"==============================================================\n\n" +
				"Provide detailed technical guidance, plan development tasks with checklists, review code, execute slash commands, and format responses clearly with Markdown/BBCode.\n" +
				"When you need to create or edit a workspace file, emit one or more blocks exactly as `<sscode-write path=\"relative/path\">file contents</sscode-write>`. Use workspace-relative paths only. The IDE executes these blocks; do not merely describe the change.\n" +
				"To delete a file, emit `<sscode-delete path=\"relative/path\"/>`. Use this only when the user explicitly requests deletion.\n" +
				"Always consider the full workspace context, active file contents, and current real-time data when responding."
			)
		else:
			system_role_content = (
				"You are SSBot, a helpful AI programming partner embedded in SSCodeIDE created by Ser Superior (SS).\n\n" +
				"=== CONTEXTO TEMPORAL & ACESSO À INTERNET (TEMPO REAL) ===\n" +
				"Data e Hora Actual: " + current_datetime + " (Ano: " + current_year + ")\n" +
				"Ambiente: SSCodeIDE sobre Godot Engine nativo em GDScript.\n" +
				"Tens acesso total a informações actualizadas em tempo real da Internet através do WebSearchService do SSCodeIDE.\n\n" +
				"=== REGRAS CRÍTICAS DE COMUNICAÇÃO, TRATAMENTO E LINGUAGEM ===\n" +
				"1. VARIEDADE LINGUÍSTICA E NORMA CULTA (PORTUGUÊS DE ANGOLA - pt-AO):\n" +
				"   - DEVES SEMPRE comunicar e responder em Português de Angola (pt-AO), aderindo estritamente à norma culta.\n" +
				"   - Segue as regras ortográficas anteriores ao acordo de 2012, preservando as consoantes mudas em palavras como 'acção', 'directo', 'projecto', 'objecto', 'adopção', 'correcção', 'facto', 'actualização', 'óptimo', 'eléctrico', 'consecutivamente', 'exacto', 'redacção'.\n" +
				"2. TRATAMENTO SEGUNDO O PRONOME 'TU' (RIGOR GRAMATICAL):\n" +
				"   - Trata SEMPRE o utilizador por 'tu'. Usa obrigatoriamente 'contigo' (NUNCA digas 'com tu'), 'teu/tua', 'te'.\n" +
				"3. PROIBIÇÃO DE EMOJIS:\n" +
				"   - NUNCA uses emojis nas tuas respostas. Mantém um tom sóbrio, culto e profissional.\n" +
				"4. CÓDIGO E IDENTIFICADORES TÉCNICOS EM INGLÊS BRITÂNICO (en-GB):\n" +
				"   - Todo o código-fonte, nomes de variáveis, funções, docstrings e comentários técnicos DEVEM SEMPRE estar em Inglês Britânico técnico (en-GB) (e.g., 'colour', 'behaviour', 'initialise', 'serialisation', 'optimise', 'centre').\n" +
				"==============================================================\n\n" +
				"Responde de forma clara, prestativa e amigável às questões e tarefas de programação."
			)
		messages_payload = [
			{"role": "system", "content": system_role_content}
		]
		var history_limit: int = 60 if _e._agent_mode else 30
		var start_idx: int = maxi(0, _e._chat_history.size() - history_limit)
		for i in range(start_idx, _e._chat_history.size()):
			messages_payload.append(_e._chat_history[i])
		payload_dict = {
			"model": model_name,
			"messages": messages_payload,
			"temperature": 0.7 if _e._agent_mode else 0.5,
			"top_p": 0.95,
			"max_tokens": 4096,
			"stream": false
		}
		if model_name.begins_with("nvidia/nemotron"):
			payload_dict["chat_template_kwargs"] = {"thinking": true}

	var payload_json = JSON.stringify(payload_dict)
	if not is_smart_commit:
		_e._thinking_text = ""
		refresh_thinking_panel()
	var err: Error = _e._ai_chat_http.request(target_url, headers, HTTPClient.METHOD_POST, payload_json)
	if err != OK:
		if _e._is_smart_commit_pending():
			_e.git.fallback_smart_commit("Failed to start HTTP request (code %d)." % err)
			return
		_e._smart_commit_prompt = ""
		clear_ai_busy()
		_e.dialog.show_toast("Failed to initiate HTTP request (Code %d)." % err, true)
		append_chat(_e._ai_provider.to_upper(), "Failed to initiate HTTP request (Code %d)." % err, Color("#ed333b"))


func on_ai_chat_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _e._response_rendered:
		return
	var is_smart_commit = _e._current_prompt.begins_with("__SMART_COMMIT__:")
	var elapsed: float = maxf(0.1, (Time.get_ticks_msec() / 1000.0) - _e._request_start_time)

	if result != HTTPRequest.RESULT_SUCCESS:
		var timeout_toast = "Request timeout. Attempting candidate model…"
		if try_next_ai_candidate(timeout_toast):
			return
		if is_smart_commit:
			_e.git.fallback_smart_commit("The model timed out.")
			return
		_e.dialog.show_toast("Response timeout exceeded. Request cancelled.", true)
		append_chat(_e._ai_provider.to_upper(), "The model timed out. The request was cancelled automatically.", Color("#ff7800"))
		return

	if body.is_empty():
		if try_next_ai_candidate("Empty response. Attempting candidate model…"):
			return
		if is_smart_commit:
			_e.git.fallback_smart_commit("Empty server response.")
			return
		_e.dialog.show_toast("Empty server response.", true)
		append_chat(_e._ai_provider.to_upper(), "Empty server response. Please retry.", Color("#ed333b"))
		return

	var text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_err = json.parse(text)
	var parsed: Variant = json.data if parse_err == OK else null

	if response_code in [200, 201] and parsed is Dictionary:
		var choices: Array = parsed.get("choices", [])
		if choices.size() > 0 and choices[0] is Dictionary:
			var msg: Dictionary = choices[0].get("message", {})
			var thought = extract_reasoning(msg)
			if not thought.is_empty():
				_e._thinking_text = thought
				refresh_thinking_panel()
			var reply_text: String = str(msg.get("content", "")).strip_edges()
			if reply_text.is_empty() and not thought.is_empty():
				reply_text = thought
			if not reply_text.is_empty():
				reply_text = execute_agent_file_writes(reply_text)

				if _e._current_prompt.begins_with("__SMART_COMMIT__:") :
					var commit_msg = reply_text.strip_edges()
					commit_msg = commit_msg.trim_prefix("```").trim_suffix("```").strip_edges()
					if commit_msg.is_empty():
						_e.git.fallback_smart_commit("The AI returned an empty message.")
						return
					_e.git.finish_smart_commit(commit_msg, true)
					return

				_e._chat_history.append({"role": "assistant", "content": reply_text})
				var usage: Dictionary = parsed.get("usage", {})
				var prompt_tokens: int = int(usage.get("prompt_tokens", float(_e._current_prompt.length()) / 4.0))
				var completion_tokens: int = int(usage.get("completion_tokens", float(reply_text.length()) / 4.0))
				clear_ai_busy()
				append_ai_response(_e._ai_provider, reply_text, elapsed, prompt_tokens, completion_tokens)
				return
	elif response_code in [200, 201] and not text.strip_edges().is_empty() and not text.begins_with("{"):
		var plain_reply = execute_agent_file_writes(text.strip_edges())
		_e._chat_history.append({"role": "assistant", "content": plain_reply})
		clear_ai_busy()
		append_ai_response(_e._ai_provider, plain_reply, elapsed)
		return

	if response_code == 401:
		AIService.invalidate_cached_api_key()
		if is_smart_commit:
			_e.git.fallback_smart_commit("The NVIDIA NIM key was rejected (HTTP 401).")
			_e.dialog.prompt_api_key(true, Callable())
			return
		_e._smart_commit_prompt = ""
		clear_ai_busy()
		_e.dialog.show_toast("NVIDIA NIM rejected the API key (HTTP 401). Enter a new key.", true)
		append_chat(_e._ai_provider.to_upper(), "Could not retrieve response (HTTP 401). The API key was rejected. Paste a new NVIDIA NIM key to continue.", Color("#ed333b"))
		var retry_prompt = _e._current_prompt
		_e.dialog.prompt_api_key(true, func() -> void:
			if retry_prompt.is_empty() or retry_prompt.begins_with("__SMART_COMMIT__:"):
				return
			ask_ai(retry_prompt)
		)
		return

	if try_next_ai_candidate("Server busy. Attempting candidate model…"):
		return
	if is_smart_commit:
		_e.git.fallback_smart_commit("AI service error (HTTP %d)." % response_code)
		return
	var err_detail: String = ""
	if parsed is Dictionary and parsed.has("error"):
		var err_dict: Dictionary = parsed["error"] if parsed["error"] is Dictionary else {}
		err_detail = " — " + str(err_dict.get("message", parsed["error"]))
	_e.dialog.show_toast("AI Service Error (HTTP %d)" % response_code, true)
	append_chat(_e._ai_provider.to_upper(), "Could not retrieve response (HTTP %d)%s." % [response_code, err_detail], Color("#ed333b"))


func try_next_ai_candidate(toast_message: String) -> bool:
	_e._model_candidate_index += 1
	if _e._model_candidate_index < _e._model_candidates.size():
		_e._ai_busy = true
		_e._chat_status_banner.visible = true
		_e._chat_send.text = "■"
		_e.dialog.show_toast(toast_message, true)
		send_chat_completion()
		return true
	if _e._is_smart_commit_pending():
		_e.git.fallback_smart_commit("Todos os modelos candidatos falharam.")
		return false
	_e._smart_commit_prompt = ""
	clear_ai_busy()
	return false


func cancel_ai_request() -> void:
	var pending_smart = _e._is_smart_commit_pending()
	_e._ai_chat_http.cancel_request()
	stop_chat_stream()
	if pending_smart:
		_e.git.fallback_smart_commit("Request cancelled.")
		return
	_e._smart_commit_prompt = ""
	clear_ai_busy()
	_e.dialog.show_toast("Request cancelled.", false)
	append_chat("IDE", "Request cancelled.", Color("#ffa348"))


func clear_ai_busy() -> void:
	_e._ai_busy = false
	stop_chat_stream()
	_e._chat_status_banner.visible = false
	_e._thinking_text = ""
	_e._chat_thinking_label.text = ""
	_e._chat_send.text = "↑"
	_e._status_left.text = "READY"


func get_workspace_context() -> String:
	var context_str: String = "Workspace Root: " + _e._workspace_root + "\n"
	
	var open_paths: Array[String] = []
	for f in _e._open_files:
		open_paths.append(f.get("path", ""))
	context_str += "Open Files in Tabs: " + ", ".join(open_paths) + "\n\n"
	
	if _e._active_index >= 0 and _e._active_index < _e._open_files.size():
		var active_path: String = _e._open_files[_e._active_index].get("path", "untitled")
		var active_code: String = _e._code_edit.text
		if active_code.length() > 4000:
			active_code = active_code.substr(0, 4000) + "\n... [content truncated for length]"
		context_str += "--- Active File: " + active_path + " ---\n" + active_code + "\n-------------------------\n\n"
	
	var files = _e.files.get_workspace_files_list()
	if not files.is_empty():
		context_str += "Project Directory Structure (" + str(files.size()) + " files):\n"
		for f in files.slice(0, 80):
			context_str += "  • " + f + "\n"
		if files.size() > 80:
			context_str += "  • ... and " + str(files.size() - 80) + " more files\n"
	
	return context_str


func handle_slash(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false, 1)
	var head: String = parts[0].to_lower()
	match head:
		"/tools":
			show_tools_list()
		"/github":
			_e.git.show_github_info_dialog()
		"/search", "/web":
			var q: String = parts[1].strip_edges() if parts.size() > 1 else ""
			if q.is_empty():
				append_chat("WEB", "[color=#ffa348]Uso:[/color] /search <termo de pesquisa> ou /web <termo>", Color("#ffa348"))
			else:
				_e.dialog.show_toast("A pesquisar na Internet em tempo real: " + q, false)
				var res = WebSearchService.search_web(q, 5)
				append_chat("WEB", WebSearchService.format_search_results_bbcode(q, res), Color("#57e389"))
				var web_context = WebSearchService.format_search_context_for_prompt(q, res)
				if not web_context.is_empty():
					_e._chat_history.append({"role": "system", "content": web_context})
					_e.dialog.ensure_api_key(func() -> void: ask_ai("Sintetiza de forma clara e actualizada os resultados da pesquisa sobre: " + q))
		"/git":
			var subcmd_raw: String = parts[1].strip_edges() if parts.size() > 1 else "status"
			var sub_parts: PackedStringArray = subcmd_raw.split(" ", false, 1)
			var subcmd: String = sub_parts[0].to_lower() if not sub_parts.is_empty() else "status"
			var sub_arg: String = sub_parts[1].strip_edges() if sub_parts.size() > 1 else ""
			
			match subcmd:
				"status":
					var st: Dictionary = GitService.get_status(_e._workspace_root)
					var gh: Dictionary = GitService.get_github_info(_e._workspace_root)
					_e.git.append_git_output("Git Status", GitService.format_status_bbcode(st, gh))
					_e.git.update_git_status_bar()
				"diff":
					var res: Dictionary = GitService.get_diff(sub_arg, false, _e._workspace_root)
					_e.git.append_git_output("Git Diff", GitService.format_diff_bbcode(str(res.get("output", ""))))
				"log":
					var count: int = sub_arg.to_int() if sub_arg.to_int() > 0 else 10
					var log_entries: Array[Dictionary] = GitService.get_log(count, _e._workspace_root)
					_e.git.append_git_output("Git Log", GitService.format_log_bbcode(log_entries))
				"commit":
					if sub_arg.is_empty():
						_e.git.generate_smart_commit()
					else:
						_e.git.set_git_panel_busy(true)
						GitService.stage_all(_e._workspace_root)
						var commit_res: Dictionary = GitService.commit(sub_arg, _e._workspace_root)
						if bool(commit_res.get("success", false)):
							_e.git.append_git_output("Git Commit", "Commit created successfully:\n" + sub_arg)
							_e.dialog.show_toast("Git commit: " + sub_arg, false)
						else:
							_e.git.append_git_output("Git Commit Error", str(commit_res.get("output", "")), true)
						_e.git.set_git_panel_busy(false)
						_e.git.update_git_status_bar()
				"push":
					var push_args: PackedStringArray = sub_arg.split(" ", false)
					var remote_name: String = push_args[0] if push_args.size() > 0 else "origin"
					var branch_name: String = push_args[1] if push_args.size() > 1 else ""
					_e.git._git_push(remote_name, branch_name)
				"pull":
					var pull_args: PackedStringArray = sub_arg.split(" ", false)
					var remote_name: String = pull_args[0] if pull_args.size() > 0 else "origin"
					var branch_name: String = pull_args[1] if pull_args.size() > 1 else ""
					_e.git._git_pull(remote_name, branch_name)
				"sync":
					var sync_args: PackedStringArray = sub_arg.split(" ", false)
					var remote_name: String = sync_args[0] if sync_args.size() > 0 else "origin"
					var branch_name: String = sync_args[1] if sync_args.size() > 1 else ""
					_e.git._git_sync(remote_name, branch_name)
				"fetch":
					var remote_name: String = sub_arg if not sub_arg.is_empty() else "origin"
					_e.git._git_fetch(remote_name)
				"branch":
					if sub_arg.is_empty():
						var branches: Array[Dictionary] = GitService.get_branches(_e._workspace_root)
						var b_out = "[b][color=#62a0ea]Git Branches:[/color][/b]\n"
						for b in branches:
							var prefix = "● " if bool(b.get("is_current", false)) else "  "
							var col = "#57e389" if bool(b.get("is_current", false)) else "#deddda"
							b_out += "[color=%s]%s%s[/color]\n" % [col, prefix, str(b.get("display_name", ""))]
						_e.git.append_git_output("Git Branches", b_out)
					else:
						_e.git.set_git_panel_busy(true)
						var create_res: Dictionary = GitService.create_branch(sub_arg, _e._workspace_root)
						if bool(create_res.get("success", false)):
							_e.git.append_git_output("Git Branch", "Branch '%s' created successfully." % sub_arg)
						else:
							_e.git.append_git_output("Git Branch Error", str(create_res.get("output", "")), true)
						_e.git.set_git_panel_busy(false)
						_e.git.update_git_status_bar()
				"checkout", "switch":
					if sub_arg.is_empty():
						_e.git._prompt_git_branch()
					else:
						_e.git.set_git_panel_busy(true)
						var create_new = sub_arg.begins_with("-b ") or sub_arg.begins_with("+")
						var branch_target = sub_arg.trim_prefix("-b ").trim_prefix("+").strip_edges()
						var co_res: Dictionary = GitService.checkout_branch(branch_target, create_new, _e._workspace_root)
						if bool(co_res.get("success", false)):
							_e.git.append_git_output("Git Branch", "Switched to branch '%s' successfully." % branch_target)
							_e.dialog.show_toast("Branch: " + branch_target, false)
						else:
							_e.git.append_git_output("Git Branch Error", str(co_res.get("output", "")), true)
						_e.git.set_git_panel_busy(false)
						_e.git.update_git_status_bar()
				"remote":
					var remotes: Array[Dictionary] = GitService.get_remotes(_e._workspace_root)
					var gh: Dictionary = GitService.get_github_info(_e._workspace_root)
					var r_out = "[b][color=#62a0ea]Git Remotes & GitHub:[/color][/b]\n\n"
					for r in remotes:
						r_out += "• [b]%s[/b] (%s): `%s`\n" % [str(r.get("name", "")), str(r.get("type", "")), str(r.get("url", ""))]
					if bool(gh.get("is_github", false)):
						r_out += "\n[color=#57e389]GitHub Repo:[/color] %s\n" % str(gh.get("web_url", ""))
					_e.git.append_git_output("Git Remotes", r_out)
				"config":
					if sub_arg.is_empty():
						var u: Dictionary = GitService.get_user_config(_e._workspace_root)
						_e.git.append_git_output("Git Config", "Git User: `%s <%s>`" % [str(u.get("name", "")), str(u.get("email", ""))])
					else:
						var name_val = sub_arg
						var email_val = ""
						if sub_arg.contains("<") and sub_arg.contains(">"):
							var s_idx = sub_arg.find("<")
							var e_idx = sub_arg.find(">")
							name_val = sub_arg.substr(0, s_idx).strip_edges()
							email_val = sub_arg.substr(s_idx + 1, e_idx - s_idx - 1).strip_edges()
						var cfg_res: Dictionary = GitService.set_user_config(name_val, email_val, false, _e._workspace_root)
						if bool(cfg_res.get("success", false)):
							_e.git.append_git_output("Git Config", "Git user configured: %s <%s>" % [name_val, email_val])
						else:
							_e.git.append_git_output("Git Config Error", "Failed to configure Git user.", true)
				"clone":
					if sub_arg.is_empty():
						_e.git._prompt_git_clone()
					else:
						_e.git.set_git_panel_busy(true)
						var target_dir: String = _e._workspace_root.path_join(sub_arg.get_file().trim_suffix(".git"))
						_e.dialog.show_toast("Cloning repository…", false)
						var cl_res: Dictionary = GitService.clone_repository(sub_arg, target_dir)
						if bool(cl_res.get("success", false)):
							_e.git.append_git_output("Git Clone", "Repository cloned to %s" % target_dir)
							_e.files.refresh_file_tree()
						else:
							_e.git.append_git_output("Git Clone Error", str(cl_res.get("output", "")), true)
						_e.git.set_git_panel_busy(false)
				_:
					_e.git.set_git_panel_busy(true)
					var res: Dictionary = _e.git._execute_git_command(subcmd_raw.split(" ", false))
					var out_txt: String = str(res.get("output", "")).strip_edges()
					if out_txt.is_empty():
						out_txt = "Git command executed."
					_e.git.append_git_output("Git Command Output", out_txt, int(res.get("exit_code", 0)) != 0)
					_e.git.set_git_panel_busy(false)
					_e.git.update_git_status_bar()
		"/theme":
			append_chat("IDE", "[color=#9a9996]Themes are now selected from the [b]Themes[/b] menu in the navigation bar.[/color]", Color("#9a9996"))
		"/save":
			_e.files.save_active()
			var p: String = _e._open_files[_e._active_index]["path"] if _e._active_index >= 0 else "untitled"
			append_tool_badge("Save", p)
		"/files":
			_e.files.refresh_file_tree()
			append_tool_badge("Explorer", "refreshed")
		"/open":
			if parts.size() > 1:
				_e.files.open_path(parts[1])
				append_tool_badge("Open", parts[1])
		"/goto":
			if parts.size() > 1:
				var line_num: int = parts[1].strip_edges().to_int()
				if line_num > 0 and _e._code_edit:
					var target_idx: int = clampi(line_num - 1, 0, maxi(0, _e._code_edit.get_line_count() - 1))
					_e._code_edit.set_caret_line(target_idx)
					_e._code_edit.grab_focus()
					append_tool_badge("Go to Line", str(line_num))
		"/clear":
			_e._chat_history.clear()
			_e._chat_log.clear()
			append_chat("IDE", "Chat history and context cleared.", Color("#57e389"))
		"/compact":
			compact_chat_history()
		"/cancel":
			cancel_ai_request()
		"/quit", "/exit":
			_e.get_tree().quit()
		_:
			append_chat("IDE", "Commands: `/tools`, `/github`, `/git status`, `/git diff`, `/git log`, `/git commit`, `/git push`, `/git pull`, `/git sync`, `/git branch`, `/save`, `/files`, `/open <path>`, `/goto <line>`, `/clear`, `/compact`, `/quit`", Color("#ffa348"))


func show_tools_list() -> void:
	var desc = "[b][color=#57E389]SSBot Assistant — IDE Capabilities[/color][/b]\n\n"
	desc += "• [b]Code Analysis & Inspection:[/b] Full workspace access, file structure, and project context.\n"
	desc += "• [b]Autonomous File Editing:[/b] Creation, modification, and refactoring of code with syntax validation.\n"
	desc += "• [b]Real-Time Web Search:[/b] Query live documentation and web search results via `/web` or `/search`.\n"
	desc += "• [b]Git & GitHub Integration:[/b] Version control in the Source Control panel with Smart Commit message generation.\n"
	desc += "\n[color=#8E8E93]Use `/web <query>` to search the Web or use the chat to request modifications to your project.[/color]"
	append_chat("SSBot", desc, Color("#57E389"))


func compact_chat_history() -> void:
	const RECENT_MESSAGES := 12
	const SUMMARY_LIMIT := 6000
	if _e._chat_history.size() <= RECENT_MESSAGES:
		append_chat("IDE", "Context is already compact (%d messages)." % _e._chat_history.size(), Color("#9a9996"))
		return

	var compact_count = _e._chat_history.size() - RECENT_MESSAGES
	var summary = "Conversation summary (generated by /compact):\n"
	for i in range(compact_count):
		var entry: Dictionary = _e._chat_history[i]
		var role = str(entry.get("role", "message")).capitalize()
		var content = str(entry.get("content", "")).strip_edges()
		if content.is_empty():
			continue
		if content.length() > 700:
			content = content.substr(0, 700) + "…"
		summary += "%s: %s\n" % [role, content]
		if summary.length() >= SUMMARY_LIMIT:
			summary += "[Earlier details truncated.]\n"
			break

	var recent: Array[Dictionary] = []
	for i in range(compact_count, _e._chat_history.size()):
		recent.append(_e._chat_history[i])
	_e._chat_history.clear()
	_e._chat_history.append({"role": "user", "content": summary.strip_edges()})
	_e._chat_history.append({"role": "assistant", "content": "Summary recorded. Continue from the preserved recent context."})
	_e._chat_history.append_array(recent)
	append_chat("IDE", "Context compacted: %d older messages summarised; %d recent messages preserved." % [compact_count, RECENT_MESSAGES], Color("#57e389"))


func execute_agent_file_writes(reply: String) -> String:
	var result = AgentWorkspace.execute_markup(reply, _e._workspace_root)
	for path: String in result.written_paths:
		reload_open_file(path)
	for path: String in result.deleted_paths:
		close_open_file_path(path)
	if not result.written_paths.is_empty() or not result.deleted_paths.is_empty():
		_e.files.refresh_file_tree()
	return str(result.reply) + str(result.report)


func reload_open_file(path: String) -> void:
	for i in _e._open_files.size():
		if str(_e._open_files[i].get("path", "")).simplify_path() == path.simplify_path():
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				_e._open_files[i]["content"] = f.get_as_text()
				_e._open_files[i]["dirty"] = false
				if i == _e._active_index:
					_e._suppress_tab = true
					_e._code_edit.text = _e._open_files[i]["content"]
					_e._suppress_tab = false
					_e._update_cursor_status()
				_e._tab_bar.set_tab_title(i, str(_e._open_files[i].get("title", "")))


func close_open_file_path(path: String) -> void:
	for i in range(_e._open_files.size() - 1, -1, -1):
		if str(_e._open_files[i].get("path", "")).simplify_path() == path.simplify_path():
			_e._on_tab_close(i)


func setup_composer_dropdowns() -> void:
	if _e._agent_mode_btn:
		var agent_popup = _e._agent_mode_btn.get_popup()
		agent_popup.clear()
		agent_popup.add_radio_check_item("Build (Agent Autopilot)", 0)
		agent_popup.add_radio_check_item("Chat (Standard Chat)", 1)
		agent_popup.set_item_checked(0, _e._agent_mode)
		agent_popup.set_item_checked(1, not _e._agent_mode)
		if not agent_popup.id_pressed.is_connected(on_agent_mode_popup_selected):
			agent_popup.id_pressed.connect(on_agent_mode_popup_selected)
		_e._agent_mode_btn.text = "Build ⌵" if _e._agent_mode else "Chat ⌵"

	if _e._model_badge_btn:
		_e._model_badge_btn.icon = preload("res://icons/sparkles.svg")
		_e._model_badge_btn.expand_icon = true
		var model_popup = _e._model_badge_btn.get_popup()
		model_popup.clear()
		model_popup.add_radio_check_item("Nemotron 3 Omni", 0)
		model_popup.add_radio_check_item("Nemotron 3.5 Lightning", 1)
		model_popup.add_radio_check_item("Kimi K3", 2)
		model_popup.add_radio_check_item("DeepSeek V4", 3)
		model_popup.add_radio_check_item("Laguna Code", 4)
		if not model_popup.id_pressed.is_connected(on_model_badge_popup_selected):
			model_popup.id_pressed.connect(on_model_badge_popup_selected)
		update_model_badge_text()


func on_agent_mode_popup_selected(id: int) -> void:
	_e._agent_mode = (id == 0)
	if _e._agent_mode_btn:
		_e._agent_mode_btn.text = "Build ⌵" if _e._agent_mode else "Chat ⌵"
		var agent_popup = _e._agent_mode_btn.get_popup()
		agent_popup.set_item_checked(0, _e._agent_mode)
		agent_popup.set_item_checked(1, not _e._agent_mode)
	if _e._agent_mode:
		_e.dialog.show_toast("Switched to Build (Agent Autopilot) mode", false)
	else:
		_e.dialog.show_toast("Switched to Chat mode", false)


func on_model_badge_popup_selected(id: int) -> void:
	on_provider_selected(id)


func update_model_badge_text() -> void:
	var titles = {
		"nemotron": "Nemotron 3 Omni",
		"nemotron_lightning": "Nemotron 3.5 Lightning",
		"kimi_k3": "Kimi K3",
		"deepseek_v4": "DeepSeek V4",
		"laguna": "Laguna Code",
	}
	var display_title: String = titles.get(_e._ai_provider, "Nemotron 3 Omni")
	if _e._model_badge_btn:
		_e._model_badge_btn.text = display_title + " ⌵"
		var model_popup = _e._model_badge_btn.get_popup()
		var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
		for i in range(names.size()):
			model_popup.set_item_checked(i, names[i] == _e._ai_provider)


func on_provider_selected(index: int) -> void:
	if _e._ai_busy:
		cancel_ai_request()
	var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
	if index >= 0 and index < names.size():
		_e._ai_provider = names[index]
	save_ai_config()
	update_ai_status()
	update_model_badge_text()


func load_ai_config() -> void:
	_e._provider_select.clear()
	_e._provider_select.add_item("Nemotron 3 Omni (NVIDIA)")
	_e._provider_select.add_item("Nemotron 3.5 Lightning (NVIDIA)")
	_e._provider_select.add_item("Kimi K3 (NVIDIA)")
	_e._provider_select.add_item("DeepSeek V4 (NVIDIA)")
	_e._provider_select.add_item("Laguna Code (NVIDIA)")
	var cfg = ConfigFile.new()
	if cfg.load("user://ai_config.cfg") == OK:
		_e._ai_provider = str(cfg.get_value("ai", "provider", "nemotron"))
	else:
		_e._ai_provider = "nemotron"
	var names: Array[String] = ["nemotron", "nemotron_lightning", "kimi_k3", "deepseek_v4", "laguna"]
	var idx: int = names.find(_e._ai_provider)
	if idx < 0:
		idx = 0
		_e._ai_provider = "nemotron"
	_e._provider_select.select(idx)
	_e._chat_send.text = "↑"


func save_ai_config() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("ai", "provider", _e._ai_provider)
	cfg.save("user://ai_config.cfg")


func update_ai_status() -> void:
	var titles = {
		"nemotron": "Nemotron 3 Omni",
		"nemotron_lightning": "Nemotron 3.5 Lightning",
		"kimi_k3": "Kimi K3",
		"deepseek_v4": "DeepSeek V4",
		"laguna": "Laguna Code",
	}
	var display_title: String = titles.get(_e._ai_provider, "Nemotron 3 Omni")
	if AIService.has_nvidia_api_key():
		_e._status_ai.text = "AI: %s · on" % display_title
	else:
		_e._status_ai.text = "AI: %s · key needed" % display_title
	if _e._model_badge_btn:
		_e._model_badge_btn.text = display_title + " ⌵"
	_e._chat_input.placeholder_text = "How can i help you today?"


func on_context_chip_pressed() -> void:
	if _e._active_index >= 0 and _e._active_index < _e._open_files.size():
		var fname: String = _e._open_files[_e._active_index].get("path", "").get_file()
		_e._chat_input.text = "Review " + fname + ": "
		_e._chat_input.caret_column = _e._chat_input.text.length()
		_e._chat_input.grab_focus()


func on_attach_btn_pressed() -> void:
	if _e._active_index >= 0 and _e._active_index < _e._open_files.size():
		var p: String = _e._open_files[_e._active_index].get("path", "")
		_e._chat_input.text += " @" + p.get_file() + " "
		_e._chat_input.caret_column = _e._chat_input.text.length()
		_e._chat_input.grab_focus()


func on_agent_mode_pressed() -> void:
	_e._agent_mode = not _e._agent_mode
	if _e._agent_mode:
		_e._agent_mode_btn.text = "</> Agent"
		if _e._chat_context_badge:
			_e._chat_context_badge.text = "Local · Autopilot"
	else:
		_e._agent_mode_btn.text = "Chat"
		if _e._chat_context_badge:
			_e._chat_context_badge.text = "Local · Chat"
