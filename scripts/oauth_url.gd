class_name OAuthUrl
extends RefCounted

## Valida o URL de callback OAuth colado (loopback). Sem nós de UI.


static func is_loopback_callback(url: String) -> bool:
	var raw: String = url.strip_edges()
	if raw.is_empty():
		return false
	var lower: String = raw.to_lower()
	if not lower.begins_with("http://127.0.0.1:") and not lower.begins_with("http://localhost:"):
		return false
	if lower.find("/callback") < 0:
		return false
	if lower.find("code=") < 0:
		return false
	if lower.find("state=") < 0:
		return false
	return true
