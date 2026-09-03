class_name MarkdownPreviewRenderer
extends RefCounted

## GitHub-like Markdown to BBCode renderer for the editor preview pane.

static func render(markdown: String) -> String:
	var lines: PackedStringArray = markdown.replace("\r\n", "\n").split("\n")
	var output := ""
	var in_code_block := false
	var language := ""
	var code := ""
	var index := 0
	while index < lines.size():
		var line := lines[index]
		var stripped := line.strip_edges()
		if stripped.begins_with("```") or stripped.begins_with("~~~"):
			if in_code_block:
				in_code_block = false
				var label := "[color=#8b949e][i]%s[/i][/color]\n" % language.to_upper() if not language.is_empty() else ""
				output += label + "[bgcolor=#161b22][color=#7ee787][code]" + code.strip_edges() + "[/code][/color][/bgcolor]\n\n"
			else:
				in_code_block = true
				language = stripped.substr(3).strip_edges()
				code = ""
			index += 1
			continue
		if in_code_block:
			code += line + "\n"
			index += 1
			continue
		if is_table_row(stripped):
			var table_lines: Array[String] = []
			while index < lines.size() and is_table_row(lines[index]):
				table_lines.append(lines[index])
				index += 1
			output += render_table(table_lines)
			continue
		if _is_horizontal_rule(stripped):
			output += "[color=#30363d]────────────────────────────────────────────────[/color]\n\n"
			index += 1
			continue
		if stripped.begins_with("#"):
			var heading_level := 0
			while heading_level < stripped.length() and stripped[heading_level] == "#":
				heading_level += 1
			if heading_level <= 6 and heading_level < stripped.length() and stripped[heading_level] == " ":
				output += _heading(inline(stripped.substr(heading_level + 1)), heading_level)
				index += 1
				continue
		if stripped.begins_with(">"):
			var quote := ""
			while index < lines.size() and lines[index].strip_edges().begins_with(">"):
				var quote_line := lines[index].strip_edges().trim_prefix(">").strip_edges()
				quote += inline(quote_line) + "\n"
				index += 1
			output += "[indent][color=#388bfd]▎ [/color][color=#8b949e][i]" + quote.strip_edges() + "[/i][/color][/indent]\n\n"
			continue
		if stripped.begins_with("- ") or stripped.begins_with("* ") or stripped.begins_with("+ "):
			while index < lines.size():
				var item := lines[index].strip_edges()
				if item.begins_with("- [ ] ") or item.begins_with("- [x] ") or item.begins_with("- [X] "):
					var checked := item.begins_with("- [x] ") or item.begins_with("- [X] ")
					var marker := "[color=#3fb950]☑[/color] " if checked else "[color=#8b949e]☐[/color] "
					output += "  " + marker + inline(item.substr(6)) + "\n"
				elif item.begins_with("- ") or item.begins_with("* ") or item.begins_with("+ "):
					output += "  [color=#58a6ff]•[/color] " + inline(item.substr(2)) + "\n"
				else:
					break
				index += 1
			output += "\n"
			continue
		if _ordered_list_item(stripped):
			var number := 1
			while index < lines.size() and _ordered_list_item(lines[index].strip_edges()):
				var item := lines[index].strip_edges()
				output += "  [color=#58a6ff]%d.[/color] %s\n" % [number, inline(item.substr(item.find(". ") + 2))]
				number += 1
				index += 1
			output += "\n"
			continue
		if stripped.is_empty():
			output += "\n"
		else:
			output += inline(stripped) + "\n\n"
		index += 1
	return output


static func is_table_row(line: String) -> bool:
	var value := line.strip_edges()
	return value.begins_with("|") and value.ends_with("|") and value.length() >= 3


static func is_table_separator(line: String) -> bool:
	var value := line.strip_edges()
	return value.begins_with("|") and value.ends_with("|") and value.replace(" ", "").replace(":", "").replace("-", "").replace("|", "").is_empty()


static func render_table(rows: Array[String]) -> String:
	if rows.is_empty():
		return ""
	var headers := split_table_row(rows[0])
	if headers.is_empty():
		return ""
	var result := "\n[table=%d]\n" % headers.size()
	for header in headers:
		result += "[cell][bgcolor=#161b22][color=#58a6ff][b]  %s  [/b][/color][/bgcolor][/cell]" % inline(header)
	result += "\n"
	var row_start := 2 if rows.size() > 1 and is_table_separator(rows[1]) else 1
	var count := 0
	for row_index in range(row_start, rows.size()):
		var cells := split_table_row(rows[row_index])
		var background := "#0d1117" if count % 2 == 0 else "#161b22"
		for column in range(headers.size()):
			var cell := cells[column] if column < cells.size() else ""
			result += "[cell][bgcolor=%s][color=#c9d1d9]  %s  [/color][/bgcolor][/cell]" % [background, inline(cell)]
		result += "\n"
		count += 1
	return result + "[/table]\n\n"


static func split_table_row(row: String) -> Array[String]:
	var trimmed := row.strip_edges().trim_prefix("|").trim_suffix("|")
	var values: Array[String] = []
	for value in trimmed.split("|"):
		values.append(value.strip_edges())
	return values


static func inline(text: String) -> String:
	var result := text
	for pair in [
		["(?i)<kbd>(.*?)</kbd>", "[bgcolor=#21262d][color=#f0f6fc][b] $1 [/b][/color][/bgcolor]"],
		["(?i)<code>(.*?)</code>", "[bgcolor=#161b22][color=#79c0ff][code] $1 [/code][/color][/bgcolor]"],
		["(?i)<(?:b|strong)>(.*?)</(?:b|strong)>", "[b]$1[/b]"],
		["(?i)<(?:i|em)>(.*?)</(?:i|em)>", "[i]$1[/i]"],
		["(?i)<(?:s|del|strike)>(.*?)</(?:s|del|strike)>", "[s]$1[/s]"],
		["(?i)<br\\s*/?>", "\n"],
		["`([^`]+)`", "[bgcolor=#1f242c][color=#79c0ff][code] $1 [/code][/color][/bgcolor]"],
		["\\*\\*\\*(.+?)\\*\\*\\*", "[b][i]$1[/i][/b]"],
		["___(.+?)___", "[b][i]$1[/i][/b]"],
		["\\*\\*(.+?)\\*\\*", "[b]$1[/b]"],
		["__(.+?)__", "[b]$1[/b]"],
		["\\*(.+?)\\*", "[i]$1[/i]"],
		["(?<![\\w])_(.+?)_(?![\\w])", "[i]$1[/i]"],
		["~~(.+?)~~", "[s]$1[/s]"],
		["\\[([^\\]]+)\\]\\(([^)]+)\\)", "[color=#58a6ff][url=$2]$1[/url][/color]"],
		["!\\[([^\\]]*?)\\]\\(([^)]+)\\)", "[color=#79c0ff]🖼 $1[/color]"],
		["<[^>]+>", ""],
	]:
		var regex := RegEx.new()
		regex.compile(pair[0])
		result = regex.sub(result, pair[1], true)
	return result


static func _heading(text: String, level: int) -> String:
	var sizes: Array[int] = [24, 20, 17, 15, 14, 13]
	var colours: Array[String] = ["#f0f6fc", "#58a6ff", "#79c0ff", "#d2a8ff", "#d2a8ff", "#d2a8ff"]
	var colour: String = colours[level - 1]
	var result := "\n[font_size=%d][b][color=%s]%s[/color][/b][/font_size]\n" % [sizes[level - 1], colour, text]
	return result + "[color=#30363d]────────────────────────────────────────────────[/color]\n\n" if level <= 2 else result + "\n"


static func _is_horizontal_rule(text: String) -> bool:
	if text.length() < 3 or not text[0] in ["-", "*", "_"]:
		return false
	for character in text:
		if character != text[0]:
			return false
	return true


static func _ordered_list_item(text: String) -> bool:
	var separator := text.find(". ")
	return separator > 0 and separator <= 4 and text.substr(0, separator).is_valid_int()
