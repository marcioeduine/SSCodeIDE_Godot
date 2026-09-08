class_name MarkdownPreviewRenderer
extends RefCounted

## GitHub-like Markdown to BBCode renderer for the editor preview pane.
## Fully theme-aware to guarantee crisp readability in both Dark and Light themes.

static func render(markdown: String, is_light: bool = false) -> String:
	var lines: PackedStringArray = markdown.replace("\r\n", "\n").split("\n")
	var output := ""
	var in_code_block := false
	var language := ""
	var code := ""
	var index := 0

	var rule_color := "#D0D7DE" if is_light else "#30363D"
	var quote_bar := "#005FB8" if is_light else "#388BFD"
	var quote_text := "#48484A" if is_light else "#8B949E"
	var check_ok := "#107C41" if is_light else "#3FB950"
	var check_no := "#6E6E73" if is_light else "#8B949E"
	var list_bullet := "#005FB8" if is_light else "#58A6FF"

	while index < lines.size():
		var line := lines[index]
		var stripped := line.strip_edges()
		if stripped.begins_with("```") or stripped.begins_with("~~~"):
			if in_code_block:
				in_code_block = false
				var label_col := "#48484A" if is_light else "#8B949E"
				var bg_col := "#F2F2F7" if is_light else "#161B22"
				var fg_col := "#1C1C1E" if is_light else "#7EE787"
				var label := "[color=%s][i]%s[/i][/color]\n" % [label_col, language.to_upper()] if not language.is_empty() else ""
				output += label + "[bgcolor=%s][color=%s][code]" % [bg_col, fg_col] + code.strip_edges() + "[/code][/color][/bgcolor]\n\n"
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
			output += render_table(table_lines, is_light)
			continue
		if _is_horizontal_rule(stripped):
			output += "[color=%s]────────────────────────────────────────────────[/color]\n\n" % rule_color
			index += 1
			continue
		if stripped.begins_with("#"):
			var heading_level := 0
			while heading_level < stripped.length() and stripped[heading_level] == "#":
				heading_level += 1
			if heading_level <= 6 and heading_level < stripped.length() and stripped[heading_level] == " ":
				output += _heading(inline(stripped.substr(heading_level + 1), is_light), heading_level, is_light)
				index += 1
				continue
		if stripped.begins_with(">"):
			var quote := ""
			while index < lines.size() and lines[index].strip_edges().begins_with(">"):
				var quote_line := lines[index].strip_edges().trim_prefix(">").strip_edges()
				quote += inline(quote_line, is_light) + "\n"
				index += 1
			output += "[indent][color=%s]▎ [/color][color=%s][i]%s[/i][/color][/indent]\n\n" % [quote_bar, quote_text, quote.strip_edges()]
			continue
		if stripped.begins_with("- ") or stripped.begins_with("* ") or stripped.begins_with("+ "):
			while index < lines.size():
				var item := lines[index].strip_edges()
				if item.begins_with("- [ ] ") or item.begins_with("- [x] ") or item.begins_with("- [X] "):
					var checked := item.begins_with("- [x] ") or item.begins_with("- [X] ")
					var marker := "[color=%s]☑[/color] " % check_ok if checked else "[color=%s]☐[/color] " % check_no
					output += "  " + marker + inline(item.substr(6), is_light) + "\n"
				elif item.begins_with("- ") or item.begins_with("* ") or item.begins_with("+ "):
					output += "  [color=%s]•[/color] %s\n" % [list_bullet, inline(item.substr(2), is_light)]
				else:
					break
				index += 1
			output += "\n"
			continue
		if _ordered_list_item(stripped):
			var number := 1
			while index < lines.size() and _ordered_list_item(lines[index].strip_edges()):
				var item := lines[index].strip_edges()
				output += "  [color=%s]%d.[/color] %s\n" % [list_bullet, number, inline(item.substr(item.find(". ") + 2), is_light)]
				number += 1
				index += 1
			output += "\n"
			continue
		if stripped.is_empty():
			output += "\n"
		else:
			output += inline(stripped, is_light) + "\n\n"
		index += 1
	return output


static func is_table_row(line: String) -> bool:
	var value := line.strip_edges()
	return value.begins_with("|") and value.ends_with("|") and value.length() >= 3


static func is_table_separator(line: String) -> bool:
	var value := line.strip_edges()
	return value.begins_with("|") and value.ends_with("|") and value.replace(" ", "").replace(":", "").replace("-", "").replace("|", "").is_empty()


static func render_table(rows: Array[String], is_light: bool = false) -> String:
	if rows.is_empty():
		return ""
	var headers := split_table_row(rows[0])
	if headers.is_empty():
		return ""
	var hdr_bg := "#E5E5EA" if is_light else "#161B22"
	var hdr_fg := "#005FB8" if is_light else "#58A6FF"
	var cell_fg := "#1C1C1E" if is_light else "#C9D1D9"
	var row_bg_even := "#FFFFFF" if is_light else "#0D1117"
	var row_bg_odd := "#F2F2F7" if is_light else "#161B22"

	var result := "\n[table=%d]\n" % headers.size()
	for header in headers:
		result += "[cell][bgcolor=%s][color=%s][b]  %s  [/b][/color][/bgcolor][/cell]" % [hdr_bg, hdr_fg, inline(header, is_light)]
	result += "\n"
	var row_start := 2 if rows.size() > 1 and is_table_separator(rows[1]) else 1
	var count := 0
	for row_index in range(row_start, rows.size()):
		var cells := split_table_row(rows[row_index])
		var background := row_bg_even if count % 2 == 0 else row_bg_odd
		for column in range(headers.size()):
			var cell := cells[column] if column < cells.size() else ""
			result += "[cell][bgcolor=%s][color=%s]  %s  [/color][/bgcolor][/cell]" % [background, cell_fg, inline(cell, is_light)]
		result += "\n"
		count += 1
	return result + "[/table]\n\n"


static func split_table_row(row: String) -> Array[String]:
	var trimmed := row.strip_edges().trim_prefix("|").trim_suffix("|")
	var values: Array[String] = []
	for value in trimmed.split("|"):
		values.append(value.strip_edges())
	return values


static func inline(text: String, is_light: bool = false) -> String:
	var kbd_bg := "#E5E5EA" if is_light else "#21262D"
	var kbd_fg := "#1C1C1E" if is_light else "#F0F6FC"
	var code_bg := "#E5E5EA" if is_light else "#161B22"
	var code_fg := "#005FB8" if is_light else "#79C0FF"
	var link_col := "#005FB8" if is_light else "#58A6FF"

	var result := text
	for pair in [
		["(?i)<kbd>(.*?)</kbd>", "[bgcolor=%s][color=%s][b] $1 [/b][/color][/bgcolor]" % [kbd_bg, kbd_fg]],
		["(?i)<code>(.*?)</code>", "[bgcolor=%s][color=%s][code] $1 [/code][/color][/bgcolor]" % [code_bg, code_fg]],
		["(?i)<(?:b|strong)>(.*?)</(?:b|strong)>", "[b]$1[/b]"],
		["(?i)<(?:i|em)>(.*?)</(?:i|em)>", "[i]$1[/i]"],
		["(?i)<(?:s|del|strike)>(.*?)</(?:s|del|strike)>", "[s]$1[/s]"],
		["(?i)<br\\s*/?>", "\n"],
		["`([^`]+)`", "[bgcolor=%s][color=%s][code] $1 [/code][/color][/bgcolor]" % [code_bg, code_fg]],
		["\\*\\*\\*(.+?)\\*\\*\\*", "[b][i]$1[/i][/b]"],
		["___(.+?)___", "[b][i]$1[/i][/b]"],
		["\\*\\*(.+?)\\*\\*", "[b]$1[/b]"],
		["__(.+?)__", "[b]$1[/b]"],
		["\\*(.+?)\\*", "[i]$1[/i]"],
		["(?<![\\w])_(.+?)_(?![\\w])", "[i]$1[/i]"],
		["~~(.+?)~~", "[s]$1[/s]"],
		["\\[([^\\]]+)\\]\\(([^)]+)\\)", "[color=%s][url=$2]$1[/url][/color]" % link_col],
		["!\\[([^\\]]*?)\\]\\(([^)]+)\\)", "[color=%s]$1[/color]" % code_fg],
		["<[^>]+>", ""],
	]:
		var regex := RegEx.new()
		regex.compile(pair[0])
		result = regex.sub(result, pair[1], true)
	return result


static func _heading(text: String, level: int, is_light: bool = false) -> String:
	var sizes: Array[int] = [24, 20, 17, 15, 14, 13]
	var colours_dark: Array[String] = ["#F0F6FC", "#58A6FF", "#79C0FF", "#D2A8FF", "#D2A8FF", "#D2A8FF"]
	var colours_light: Array[String] = ["#1C1C1E", "#005FB8", "#0066CC", "#5C2D91", "#5C2D91", "#5C2D91"]
	var colour: String = colours_light[level - 1] if is_light else colours_dark[level - 1]
	var rule_color := "#D0D7DE" if is_light else "#30363D"
	var result := "\n[font_size=%d][b][color=%s]%s[/color][/b][/font_size]\n" % [sizes[level - 1], colour, text]
	return result + "[color=%s]────────────────────────────────────────────────[/color]\n\n" % rule_color if level <= 2 else result + "\n"


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
