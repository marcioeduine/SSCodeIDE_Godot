class_name GoogleAuth
extends RefCounted

## GoogleAuth — 100% Native GDScript Google OAuth 2.0 Handler
## Uses loopback TCPServer for secure browser authorization and token management.

signal auth_succeeded(account_email: String)
signal auth_failed(error_message: String)

const CLIENT_ID: String = "790560907959-uqr5b5k5m3dk23egj5in47mqtbrtej7d.apps.googleusercontent.com"
const CLIENT_SECRET: String = "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"
const AUTH_URI: String = "https://accounts.google.com/o/oauth2/auth"
const TOKEN_URI: String = "https://oauth2.googleapis.com/token"
const SCOPES: String = "openid https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
const SESSION_FILE: String = "user://antigravity_google_session.json"

static var _tcp_server: TCPServer
static var _tcp_port: int = 0
static var _active_instance: GoogleAuth


func start_auth() -> String:
	_active_instance = self
	if not _tcp_server:
		_tcp_server = TCPServer.new()
	
	if _tcp_server.is_listening():
		_tcp_server.stop()
	
	# Listen on random available port on loopback
	var err := _tcp_server.listen(0, "127.0.0.1")
	if err != OK:
		# Fallback to port 8085
		err = _tcp_server.listen(8085, "127.0.0.1")
	
	if err != OK:
		auth_failed.emit("Não foi possível iniciar o servidor local de autenticação.")
		return ""
	
	_tcp_port = _tcp_server.get_local_port()
	var redirect_uri: String = "http://127.0.0.1:%d" % _tcp_port
	
	var params: Array[String] = [
		"client_id=" + CLIENT_ID.uri_encode(),
		"redirect_uri=" + redirect_uri.uri_encode(),
		"response_type=code",
		"scope=" + SCOPES.uri_encode(),
		"access_type=offline",
		"prompt=consent",
	]
	var auth_url: String = AUTH_URI + "?" + "&".join(PackedStringArray(params))
	return auth_url


static func poll_loopback(http_node: HTTPRequest) -> void:
	if not _tcp_server or not _tcp_server.is_listening():
		return
	
	if not _tcp_server.is_connection_available():
		return
	
	var peer: StreamPeerTCP = _tcp_server.take_connection()
	if not peer:
		return
	
	# Read HTTP GET request from browser redirect
	var attempts: int = 0
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and peer.get_available_bytes() == 0 and attempts < 100:
		OS.delay_msec(10)
		peer.poll()
		attempts += 1
	
	var bytes := peer.get_available_bytes()
	if bytes == 0:
		peer.disconnect_from_host()
		return
	
	var request_data := peer.get_data(bytes)
	var request_text: String = ""
	if request_data[0] == OK:
		var byte_array: PackedByteArray = request_data[1]
		request_text = byte_array.get_string_from_utf8()
	
	var code: String = _extract_query_param(request_text, "code")
	var error_param: String = _extract_query_param(request_text, "error")
	
	var html_body: String = ""
	if not code.is_empty():
		html_body = "<!DOCTYPE html><html><body style='background:#101014;color:#9ece6a;font-family:sans-serif;text-align:center;padding:50px;'><h2>Autenticação Google Antigravity Concluída com Sucesso!</h2><p style='color:#c0caf5;'>Podes fechar esta aba do navegador e voltar ao <b>SSCodeIDE</b>.</p></body></html>"
	else:
		html_body = "<!DOCTYPE html><html><body style='background:#101014;color:#f7768e;font-family:sans-serif;text-align:center;padding:50px;'><h2>Autenticação Não Concluída</h2><p style='color:#c0caf5;'>Erro: %s</p></body></html>" % error_param
	
	var response: String = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [html_body.to_utf8_buffer().size(), html_body]
	peer.put_data(response.to_utf8_buffer())
	peer.disconnect_from_host()
	
	_tcp_server.stop()
	
	if not code.is_empty():
		var redirect_uri: String = "http://127.0.0.1:%d" % _tcp_port
		exchange_code_for_tokens(code, redirect_uri, http_node)
	elif not error_param.is_empty() and _active_instance:
		_active_instance.auth_failed.emit(error_param)


static func _extract_query_param(http_request: String, param_name: String) -> String:
	var first_line: String = http_request.get_slice("\r\n", 0)
	var url_part: String = first_line.get_slice(" ", 1)
	if url_part.find("?") < 0:
		return ""
	var query: String = url_part.get_slice("?", 1)
	var pairs: PackedStringArray = query.split("&")
	for pair: String in pairs:
		var kv: PackedStringArray = pair.split("=", false, 1)
		if kv.size() == 2 and kv[0] == param_name:
			return kv[1].uri_decode()
	return ""


static func exchange_code_for_tokens(code: String, redirect_uri: String, http_node: HTTPRequest) -> void:
	var body_params: Array[String] = [
		"code=" + code.uri_encode(),
		"client_id=" + CLIENT_ID.uri_encode(),
		"client_secret=" + CLIENT_SECRET.uri_encode(),
		"redirect_uri=" + redirect_uri.uri_encode(),
		"grant_type=authorization_code"
	]
	var payload: String = "&".join(PackedStringArray(body_params))
	var headers: PackedStringArray = ["Content-Type: application/x-www-form-urlencoded"]
	http_node.request(TOKEN_URI, headers, HTTPClient.METHOD_POST, payload)


static func refresh_access_token(http_node: HTTPRequest) -> void:
	var refresh_token: String = get_refresh_token()
	if refresh_token.is_empty():
		return
	var body_params: Array[String] = [
		"client_id=" + CLIENT_ID.uri_encode(),
		"client_secret=" + CLIENT_SECRET.uri_encode(),
		"refresh_token=" + refresh_token.uri_encode(),
		"grant_type=refresh_token"
	]
	var payload: String = "&".join(PackedStringArray(body_params))
	var headers: PackedStringArray = ["Content-Type: application/x-www-form-urlencoded"]
	http_node.request(TOKEN_URI, headers, HTTPClient.METHOD_POST, payload)


static func save_tokens(token_dict: Dictionary) -> void:
	var data: Dictionary = load_session()
	for k: String in token_dict.keys():
		data[k] = token_dict[k]
	data["logged_in"] = true
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var fa := FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify(data, "\t"))


static func load_session() -> Dictionary:
	if not FileAccess.file_exists(SESSION_FILE):
		return {}
	var fa := FileAccess.open(SESSION_FILE, FileAccess.READ)
	if not fa:
		return {}
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	return parsed if parsed is Dictionary else {}


static func get_access_token() -> String:
	var session := load_session()
	return str(session.get("access_token", ""))


static func get_refresh_token() -> String:
	var session := load_session()
	return str(session.get("refresh_token", ""))


static func is_logged_in() -> bool:
	var session := load_session()
	var at: String = str(session.get("access_token", ""))
	var rt: String = str(session.get("refresh_token", ""))
	return not at.is_empty() or not rt.is_empty()


static func clear_session() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_FILE))
	if _tcp_server and _tcp_server.is_listening():
		_tcp_server.stop()
