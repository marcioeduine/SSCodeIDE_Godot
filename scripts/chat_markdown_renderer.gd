class_name ChatMarkdownRenderer
extends RefCounted

## Transforms the lightweight chat Markdown dialect into RichTextLabel BBCode.


static func render(raw_text: String) -> String:
	if raw_text.is_empty():
		return ""
	var output := ""
	var in_code_block := false
	var code_block_lang := ""
	var code_block_lines: Array[String] = []
	for line in raw_text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("```"):
			if in_code_block:
				in_code_block = false
				output += format_code_block("\n".join(code_block_lines), code_block_lang if not code_block_lang.is_empty() else "code")
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
			formatted_line = "[color=#ffffff][b]" + formatted_line.substr(4) + "[/b][/color]"
		elif formatted_line.begins_with("## "):
			formatted_line = "[font_size=14][color=#ffffff][b]" + formatted_line.substr(3) + "[/b][/color][/font_size]"
		elif formatted_line.begins_with("# "):
			formatted_line = "[font_size=16][color=#ffffff][b]" + formatted_line.substr(2) + "[/b][/color][/font_size]"
		elif formatted_line.begins_with("> "):
			formatted_line = "[color=#5bc8af]▎[/color] [color=#c0bfbc]" + formatted_line.substr(2) + "[/color]"
		elif formatted_line.begins_with("- [ ] ") or formatted_line.begins_with("* [ ] "):
			formatted_line = "  [color=#9a9996]☐ " + formatted_line.substr(6) + "[/color]"
		elif formatted_line.begins_with("- [x] ") or formatted_line.begins_with("* [x] ") or formatted_line.begins_with("- [X] "):
			formatted_line = "  [color=#57e389]✔ " + formatted_line.substr(6) + "[/color]"
		elif formatted_line.begins_with("- ") or formatted_line.begins_with("* "):
			formatted_line = "  [color=#57e389]•[/color] " + formatted_line.substr(2)
		output += replace_links(replace_italic(replace_bold(replace_inline_code(formatted_line)))) + "\n"
	if in_code_block and not code_block_lines.is_empty():
		output += format_code_block("\n".join(code_block_lines), code_block_lang if not code_block_lang.is_empty() else "code")
	return output.strip_edges(false, true)


static func format_code_block(code: String, language: String) -> String:
	var safe_code := code.replace("[", "[lb]").replace("]", "[rb]")
	var copy_id := Marshalls.raw_to_base64(code.to_utf8_buffer())
	return "\n[bgcolor=#25292e][color=#8b949e]  %s[/color]  [url=copy:%s][color=#58a6ff][u]Copy[/u][/color][/url]\n[bgcolor=#161b22][color=#e6edf3]  %s\n[/color][/bgcolor]\n\n" % [language, copy_id, safe_code.replace("\n", "\n  ")]


static func replace_bold(text: String) -> String:
	var result := text
	while true:
		var first := result.find("**")
		var second := result.find("**", first + 2)
		if first < 0 or second < 0:
			break
		result = result.substr(0, first) + "[b]" + result.substr(first + 2, second - first - 2) + "[/b]" + result.substr(second + 2)
	return result


static func replace_inline_code(text: String) -> String:
	var result := text
	while true:
		var first := result.find("`")
		var second := result.find("`", first + 1)
		if first < 0 or second < 0:
			break
		result = result.substr(0, first) + "[bgcolor=#23232b][color=#99c1f1] " + result.substr(first + 1, second - first - 1) + " [/color][/bgcolor]" + result.substr(second + 1)
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


static func replace_links(text: String) -> String:
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
		result = result.substr(0, open) + "[url=" + target + "][color=#62a0ea][u]" + label + "[/u][/color][/url]" + result.substr(target_end + 1)
	return result
