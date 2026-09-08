class_name WebSearchService
extends RefCounted

## WebSearchService — Live Internet and Web Search Service for SSCodeIDE
## Fetches up-to-date web snippets, real-time documentation, and internet search results.

static func search_web(query: String, max_results: int = 5) -> Array[Dictionary]:
	var q := query.strip_edges()
	if q.is_empty():
		return []

	var results: Array[Dictionary] = []

	# 1. Try dedicated python script
	var script_paths := [
		ProjectSettings.globalize_path("res://scripts/web_search.py"),
		OS.get_executable_path().get_base_dir().path_join("scripts/web_search.py"),
		"./scripts/web_search.py",
		"scripts/web_search.py"
	]

	var py_script_path := ""
	for path in script_paths:
		if FileAccess.file_exists(path):
			py_script_path = path
			break

	if not py_script_path.is_empty():
		var output: Array = []
		var exit_code := OS.execute("python3", [py_script_path, q, str(max_results)], output, true)
		if exit_code == 0 and not output.is_empty():
			var raw_json: String = str(output[0]).strip_edges()
			var json := JSON.new()
			if json.parse(raw_json) == OK and json.data is Array:
				for item in json.data:
					if item is Dictionary:
						results.append(item)
				if not results.is_empty():
					return results

	# 2. Direct curl fallback
	var curl_output: Array = []
	var curl_exit := OS.execute("curl", [
		"-s", "-L", "https://html.duckduckgo.com/html/",
		"--data", "q=" + q,
		"-A", "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0"
	], curl_output, true)

	if curl_exit == 0 and not curl_output.is_empty():
		var html_content: String = str(curl_output[0])
		var regex := RegEx.new()
		regex.compile("<a[^>]+class=\"[^\"]*result__snippet[^\"]*\"[^>]*href=\"([^\"]*)\"[^>]*>(.*?)</a>")
		var matches := regex.search_all(html_content)
		var tag_regex := RegEx.new()
		tag_regex.compile("<[^>]+>")

		for m in matches:
			if results.size() >= max_results:
				break
			var href := m.get_string(1)
			var snip_raw := m.get_string(2)
			var clean_text := tag_regex.sub(snip_raw, "", true).strip_edges()
			if not clean_text.is_empty():
				var title := clean_text.substr(0, 60) + ("..." if clean_text.length() > 60 else "")
				var actual_url := href
				if "uddg=" in href:
					var uddg_start := href.find("uddg=") + 5
					var uddg_end := href.find("&", uddg_start)
					if uddg_end < 0:
						uddg_end = href.length()
					actual_url = href.substr(uddg_start, uddg_end - uddg_start).uri_decode()
				results.append({
					"title": title,
					"snippet": clean_text,
					"url": actual_url
				})

	return results


static func format_search_results_bbcode(query: String, results: Array[Dictionary]) -> String:
	if results.is_empty():
		return "[color=#ffa348]Nenhum resultado encontrado na Internet para:[/color] [b]%s[/b]" % query.replace("[", "[lb]")

	var bbcode := "[b][color=#57e389]🌐 Resultados da Pesquisa na Internet para:[/color] '%s'[/b]\n\n" % query.replace("[", "[lb]")
	for i in range(results.size()):
		var item := results[i]
		var title: String = str(item.get("title", "")).replace("[", "[lb]")
		var snippet: String = str(item.get("snippet", "")).replace("[", "[lb]")
		var url: String = str(item.get("url", ""))
		bbcode += "[b]%d. %s[/b]\n" % [i + 1, title]
		bbcode += "%s\n" % snippet
		if not url.is_empty():
			bbcode += "[color=#62a0ea][url=%s]%s[/url][/color]\n" % [url, url]
		bbcode += "\n"
	return bbcode.strip_edges()


static func format_search_context_for_prompt(query: String, results: Array[Dictionary]) -> String:
	if results.is_empty():
		return ""
	var ctx := "=== LIVE INTERNET SEARCH RESULTS for '%s' ===\n" % query
	for i in range(results.size()):
		var item := results[i]
		ctx += "[%d] Title: %s\n" % [i + 1, str(item.get("title", ""))]
		ctx += "Snippet: %s\n" % str(item.get("snippet", ""))
		ctx += "URL: %s\n\n" % str(item.get("url", ""))
	ctx += "===============================================\n"
	return ctx
