extends GutTest

## Unit tests for WebSearchService and internet search formatters.

const WebSearchService = preload("res://scripts/web_search_service.gd")


func test_format_search_results_bbcode_empty() -> void:
	var out := WebSearchService.format_search_results_bbcode("test", [])
	assert_true(out.contains("Nenhum resultado encontrado"))


func test_format_search_results_bbcode_with_items() -> void:
	var sample: Array[Dictionary] = [
		{"title": "Godot Docs", "snippet": "Official documentation for Godot Engine", "url": "https://docs.godotengine.org"},
		{"title": "Godot News", "snippet": "Latest releases and updates", "url": "https://godotengine.org/news"}
	]
	var out := WebSearchService.format_search_results_bbcode("Godot", sample)
	assert_true(out.contains("Resultados da Pesquisa na Internet"))
	assert_true(out.contains("Godot Docs"))
	assert_true(out.contains("https://docs.godotengine.org"))


func test_format_search_context_for_prompt() -> void:
	var sample: Array[Dictionary] = [
		{"title": "Release 4.7", "snippet": "Godot 4.7 feature release", "url": "https://godotengine.org/releases/4.7"}
	]
	var ctx := WebSearchService.format_search_context_for_prompt("Godot 4.7", sample)
	assert_true(ctx.contains("LIVE INTERNET SEARCH RESULTS"))
	assert_true(ctx.contains("Release 4.7"))
