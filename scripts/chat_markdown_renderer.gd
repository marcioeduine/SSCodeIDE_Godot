class_name ChatMarkdownRenderer
extends RefCounted

## Transforms the lightweight chat Markdown dialect into RichTextLabel BBCode.
## Fully theme-aware to ensure high contrast in both Dark and Light modes.

static func render(raw_text: String, is_light: bool = false) -> String:
	if raw_text.is_empty():
		return ""
	var output := ""
	var in_code_block := false
	var code_block_lang := ""
	var code_block_lines: Array[String] = []

	var heading_color := "#005fb8" if is_light else "#56a8f5"
	var quote_bar := "#005fb8" if is_light else "#5bc8af"
	var quote_text := "#48484a" if is_light else "#c0bfbc"
	var check_ok := "#16a34a" if is_light else "#22c55e"
	var check_no := "#6c6c70" if is_light else "#8e8e93"

	for line in raw_text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("```"):
			if in_code_block:
				in_code_block = false
				output += format_code_block("\n".join(code_block_lines), code_block_lang if not code_block_lang.is_empty() else "code", is_light)
				code_block_lines.clear()
			else:
				in_code_block = true
				code_block_lang = trimmed.substr(3).strip_edges()
				code_block_lines.clear()
			continue
		if in_code_block:
			code_block_lines.append(line)
			continue

		var formatted_line := line
		if formatted_line.begins_with("### "):
			formatted_line = "[color=%s][b]%s[/b][/color]" % [heading_color, formatted_line.substr(4)]
		elif formatted_line.begins_with("## "):
			formatted_line = "[font_size=14][color=%s][b]%s[/b][/color][/font_size]" % [heading_color, formatted_line.substr(3)]
		elif formatted_line.begins_with("# "):
			formatted_line = "[font_size=16][color=%s][b]%s[/b][/color][/font_size]" % [heading_color, formatted_line.substr(2)]
		elif formatted_line.begins_with("> "):
			formatted_line = "[color=%s]▎[/color] [color=%s]%s[/color]" % [quote_bar, quote_text, formatted_line.substr(2)]
		elif formatted_line.begins_with("- [ ] ") or formatted_line.begins_with("* [ ] "):
			formatted_line = "  [color=%s]☐ %s[/color]" % [check_no, formatted_line.substr(6)]
		elif formatted_line.begins_with("- [x] ") or formatted_line.begins_with("* [x] ") or formatted_line.begins_with("- [X] "):
			formatted_line = "  [color=%s]✔ %s[/color]" % [check_ok, formatted_line.substr(6)]
		elif formatted_line.begins_with("- ") or formatted_line.begins_with("* "):
			formatted_line = "  [color=%s]•[/color] %s" % [check_ok, formatted_line.substr(2)]
		output += replace_links(replace_italic(replace_bold(replace_inline_code(formatted_line, is_light))), is_light) + "\n"
	if in_code_block and not code_block_lines.is_empty():
		output += format_code_block("\n".join(code_block_lines), code_block_lang if not code_block_lang.is_empty() else "code", is_light)
	return output.strip_edges(false, true)


static func format_code_block(code: String, language: String, is_light: bool = false) -> String:
	var safe_code := code.replace("[", "[lb]").replace("]", "[rb]")
	var copy_id := Marshalls.raw_to_base64(code.to_utf8_buffer())
	var hdr_bg := "#e0e0e6" if is_light else "#1e1e24"
	var hdr_fg := "#48484a" if is_light else "#8b949e"
	var body_bg := "#f3f3f6" if is_light else "#141418"
	var body_fg := "#111113" if is_light else "#e6edf3"
	var link_col := "#005fb8" if is_light else "#58a6ff"
	return "\n[bgcolor=%s][color=%s]  %s[/color]  [url=copy:%s][color=%s]📋 Copy[/color][/url]\n[bgcolor=%s][color=%s]  %s\n[/color][/bgcolor]\n\n" % [hdr_bg, hdr_fg, language, copy_id, link_col, body_bg, body_fg, safe_code.replace("\n", "\n  ")]


static func replace_bold(text: String) -> String:
	var result := text
	while true:
		var first := result.find("**")
		var second := result.find("**", first + 2)
		if first < 0 or second < 0:
			break
		result = result.substr(0, first) + "[b]" + result.substr(first + 2, second - first - 2) + "[/b]" + result.substr(second + 2)
	return result


static func replace_inline_code(text: String, is_light: bool = false) -> String:
	var result := text
	var code_bg := "#e3e5ea" if is_light else "#222329"
	var code_fg := "#005fb8" if is_light else "#56a8f5"
	while true:
		var first := result.find("`")
		var second := result.find("`", first + 1)
		if first < 0 or second < 0:
			break
		result = result.substr(0, first) + "[bgcolor=%s][color=%s] %s [/color][/bgcolor]" % [code_bg, code_fg, result.substr(first + 1, second - first - 1)] + result.substr(second + 1)
	return result


static func replace_italic(text: String) -> String:
	var result := text
	while true:
		var first := result.find("*")
		var second := result.find("*", first + 1)
		if first < 0 or second < 0:
			break
		result = result.substr(0, first) + "[i]" + result.substr(first + 1, second - first - 1) + "[/i]" + result.substr(second + 1)
	return result


static func replace_links(text: String, is_light: bool = false) -> String:
	var link_col := "#005fb8" if is_light else "#56a8f5"
	var result := text
	while true:
		var open := result.find("[")
		var close := result.find("]", open + 1)
		if open < 0 or close < 0 or close + 1 >= result.length() or result[close + 1] != "(":
			break
		var target_end := result.find(")", close + 2)
		if target_end < 0:
			break
		var label := result.substr(open + 1, close - open - 1)
		var target := result.substr(close + 2, target_end - close - 2)
		result = result.substr(0, open) + "[url=" + target + "][color=" + link_col + "]" + label + "[/color][/url]" + result.substr(target_end + 1)
	return result
