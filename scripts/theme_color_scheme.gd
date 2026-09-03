class_name ThemeColorScheme
extends RefCounted

## Centralised colour palette definitions for all built-in themes.
## Each palette follows the same key schema so the theme resource builder
## can consume any of them interchangeably.
##
## JetBrains / VS Code IDE influence: balanced contrast surfaces,
## clear depth hierarchy, muted borders, and high-readability syntax highlighting.

const DARK_THEMES: Dictionary = {
	"adwaita_darker": {
		"label": "Adwaita Darker",
		"variant": "dark",
		"bg_black":   "#141416", "bg_darker":  "#19191d", "bg_surface": "#1e1e24",
		"bg_card":    "#24242c", "bg_lighter": "#2c2c36",
		"fg":         "#dcdce0", "fg_bright":  "#ffffff", "muted":      "#7e7e8a",
		"blue":       "#4c8bf5", "green":      "#38c776", "cyan":       "#3bbdbd", "red": "#e05561",
		"hl_number":  "#b5cea8", "hl_symbol":  "#c8d0dc", "hl_func":    "#4c8bf5",
		"hl_member":  "#9cdcfe", "hl_comment": "#6a737d", "hl_string":  "#ce9178",
		"hl_keyword": "#569cd6", "hl_type":    "#4ec9b0", "hl_const":   "#b5cea8",
	},
	"monokai": {
		"label": "Monokai",
		"variant": "dark",
		"bg_black":   "#161715", "bg_darker":  "#1e1f1c", "bg_surface": "#272822",
		"bg_card":    "#2d2e27", "bg_lighter": "#383830",
		"fg":         "#f8f8f2", "fg_bright":  "#ffffff", "muted":      "#75715e",
		"blue":       "#66d9e8", "green":      "#a6e22e", "cyan":       "#66d9e8", "red": "#f92672",
		"hl_number":  "#ae81ff", "hl_symbol":  "#f8f8f2", "hl_func":    "#a6e22e",
		"hl_member":  "#fd971f", "hl_comment": "#75715e", "hl_string":  "#e6db74",
		"hl_keyword": "#f92672", "hl_type":    "#66d9e8", "hl_const":   "#ae81ff",
	},
	"tokyo_night": {
		"label": "Tokyo Night",
		"variant": "dark",
		"bg_black":   "#13131e", "bg_darker":  "#16161f", "bg_surface": "#1a1b26",
		"bg_card":    "#1f2035", "bg_lighter": "#292e42",
		"fg":         "#a9b1d6", "fg_bright":  "#c0caf5", "muted":      "#565f89",
		"blue":       "#7aa2f7", "green":      "#9ece6a", "cyan":       "#2ac3de", "red": "#f7768e",
		"hl_number":  "#ff9e64", "hl_symbol":  "#89ddff", "hl_func":    "#7aa2f7",
		"hl_member":  "#73daca", "hl_comment": "#565f89", "hl_string":  "#9ece6a",
		"hl_keyword": "#bb9af7", "hl_type":    "#2ac3de", "hl_const":   "#ff9e64",
	},
	"dracula": {
		"label": "Dracula",
		"variant": "dark",
		"bg_black":   "#191a24", "bg_darker":  "#21222c", "bg_surface": "#282a36",
		"bg_card":    "#313444", "bg_lighter": "#3d4054",
		"fg":         "#f8f8f2", "fg_bright":  "#ffffff", "muted":      "#6272a4",
		"blue":       "#8be9fd", "green":      "#50fa7b", "cyan":       "#8be9fd", "red": "#ff5555",
		"hl_number":  "#bd93f9", "hl_symbol":  "#ff79c6", "hl_func":    "#50fa7b",
		"hl_member":  "#ffb86c", "hl_comment": "#6272a4", "hl_string":  "#f1fa8c",
		"hl_keyword": "#ff79c6", "hl_type":    "#8be9fd", "hl_const":   "#bd93f9",
	},
	"catppuccin": {
		"label": "Catppuccin Mocha",
		"variant": "dark",
		"bg_black":   "#11111b", "bg_darker":  "#181825", "bg_surface": "#1e1e2e",
		"bg_card":    "#252538", "bg_lighter": "#313244",
		"fg":         "#cdd6f4", "fg_bright":  "#ffffff", "muted":      "#6c7086",
		"blue":       "#89b4fa", "green":      "#a6e3a1", "cyan":       "#94e2d5", "red": "#f38ba8",
		"hl_number":  "#fab387", "hl_symbol":  "#89dceb", "hl_func":    "#89b4fa",
		"hl_member":  "#cba6f7", "hl_comment": "#6c7086", "hl_string":  "#a6e3a1",
		"hl_keyword": "#cba6f7", "hl_type":    "#94e2d5", "hl_const":   "#fab387",
	},
	"nord": {
		"label": "Nord",
		"variant": "dark",
		"bg_black":   "#1e222b", "bg_darker":  "#242933", "bg_surface": "#2e3440",
		"bg_card":    "#383f4d", "bg_lighter": "#434c5e",
		"fg":         "#d8dee9", "fg_bright":  "#eceff4", "muted":      "#6b7a99",
		"blue":       "#88c0d0", "green":      "#a3be8c", "cyan":       "#8fbcbb", "red": "#bf616a",
		"hl_number":  "#b48ead", "hl_symbol":  "#81a1c1", "hl_func":    "#88c0d0",
		"hl_member":  "#81a1c1", "hl_comment": "#616e88", "hl_string":  "#a3be8c",
		"hl_keyword": "#81a1c1", "hl_type":    "#8fbcbb", "hl_const":   "#b48ead",
	},
	"jakes_theme": {
		"label": "Jake's Theme",
		"variant": "dark",
		"bg_black":   "#0a0a0c", "bg_darker":  "#101014", "bg_surface": "#16161c",
		"bg_card":    "#1c1c24", "bg_lighter": "#242430",
		"fg":         "#e4e4e8", "fg_bright":  "#ffffff", "muted":      "#7c7c88",
		"blue":       "#8be9fd", "green":      "#57e389", "cyan":       "#62a0ea", "red": "#ed333b",
		"hl_number":  "#ffa348", "hl_symbol":  "#9a9996", "hl_func":    "#62a0ea",
		"hl_member":  "#99c1f1", "hl_comment": "#9a9996", "hl_string":  "#57e389",
		"hl_keyword": "#8be9fd", "hl_type":    "#62a0ea", "hl_const":   "#ffa348",
	},
	"terminal": {
		"label": "Terminal (Antigravity)",
		"variant": "dark",
		"bg_black":   "#000000", "bg_darker":  "#050505", "bg_surface": "#0a0a0c",
		"bg_card":    "#121216", "bg_lighter": "#1a1a20",
		"fg":         "#deddda", "fg_bright":  "#ffffff", "muted":      "#9a9996",
		"blue":       "#62a0ea", "green":      "#57e389", "cyan":       "#5bc8af", "red": "#ed333b",
		"hl_number":  "#ffa348", "hl_symbol":  "#5bc8af", "hl_func":    "#62a0ea",
		"hl_member":  "#99c1f1", "hl_comment": "#9a9996", "hl_string":  "#57e389",
		"hl_keyword": "#62a0ea", "hl_type":    "#5bc8af", "hl_const":   "#ffa348",
	},
	"solarized_dark": {
		"label": "Solarized Dark",
		"variant": "dark",
		"bg_black":   "#001920", "bg_darker":  "#00212b", "bg_surface": "#002b36",
		"bg_card":    "#073642", "bg_lighter": "#0e4a5a",
		"fg":         "#839496", "fg_bright":  "#fdf6e3", "muted":      "#586e75",
		"blue":       "#268bd2", "green":      "#859900", "cyan":       "#2aa198", "red": "#dc322f",
		"hl_number":  "#d33682", "hl_symbol":  "#657b83", "hl_func":    "#268bd2",
		"hl_member":  "#b58900", "hl_comment": "#586e75", "hl_string":  "#859900",
		"hl_keyword": "#cb4b16", "hl_type":    "#2aa198", "hl_const":   "#6c71c4",
	},
}

const LIGHT_THEMES: Dictionary = {
	"adwaita_lighter": {
		"label": "Adwaita Lighter (Light)",
		"variant": "light",
		"bg_black":   "#ffffff", "bg_darker":  "#f4f4f5", "bg_surface": "#eaebee",
		"bg_card":    "#dedfe3", "bg_lighter": "#d0d2d8",
		"fg":         "#202124", "fg_bright":  "#000000", "muted":      "#656a73",
		"blue":       "#1a73e8", "green":      "#188038", "cyan":       "#127272", "red": "#d93025",
		"hl_number":  "#0969da", "hl_symbol":  "#6e7781", "hl_func":    "#1a73e8",
		"hl_member":  "#0550ae", "hl_comment": "#6e7781", "hl_string":  "#0a8754",
		"hl_keyword": "#cf222e", "hl_type":    "#116329", "hl_const":   "#0969da",
	},
	"monokai_light": {
		"label": "Monokai Light",
		"variant": "light",
		"bg_black":   "#ffffff", "bg_darker":  "#f8f8f6", "bg_surface": "#f0f0ea",
		"bg_card":    "#e4e4dc", "bg_lighter": "#d8d8ce",
		"fg":         "#2d2d2a", "fg_bright":  "#000000", "muted":      "#737166",
		"blue":       "#0594a6", "green":      "#568a0c", "cyan":       "#0594a6", "red": "#c2084c",
		"hl_number":  "#7945d4", "hl_symbol":  "#55544d", "hl_func":    "#568a0c",
		"hl_member":  "#b35d04", "hl_comment": "#7c796b", "hl_string":  "#948505",
		"hl_keyword": "#c2084c", "hl_type":    "#0594a6", "hl_const":   "#7945d4",
	},
	"tokyo_night_light": {
		"label": "Tokyo Night Light",
		"variant": "light",
		"bg_black":   "#ffffff", "bg_darker":  "#f2f4f8", "bg_surface": "#e6eaf0",
		"bg_card":    "#d8deea", "bg_lighter": "#c8d2e2",
		"fg":         "#343b58", "fg_bright":  "#000000", "muted":      "#68708c",
		"blue":       "#34548a", "green":      "#387038", "cyan":       "#0f6b78", "red": "#8c4351",
		"hl_number":  "#965027", "hl_symbol":  "#343b58", "hl_func":    "#34548a",
		"hl_member":  "#385f80", "hl_comment": "#848cb5", "hl_string":  "#387038",
		"hl_keyword": "#5a4a78", "hl_type":    "#0f6b78", "hl_const":   "#965027",
	},
	"dracula_light": {
		"label": "Dracula Light",
		"variant": "light",
		"bg_black":   "#ffffff", "bg_darker":  "#f4f2f8", "bg_surface": "#e9e6f2",
		"bg_card":    "#ded8eb", "bg_lighter": "#d0c7e2",
		"fg":         "#323340", "fg_bright":  "#000000", "muted":      "#6272a4",
		"blue":       "#0080a0", "green":      "#16823b", "cyan":       "#0080a0", "red": "#cf222e",
		"hl_number":  "#7a44c7", "hl_symbol":  "#a02568", "hl_func":    "#16823b",
		"hl_member":  "#a35200", "hl_comment": "#6272a4", "hl_string":  "#8a7700",
		"hl_keyword": "#a02568", "hl_type":    "#0080a0", "hl_const":   "#7a44c7",
	},
	"catppuccin_light": {
		"label": "Catppuccin Latte (Light)",
		"variant": "light",
		"bg_black":   "#ffffff", "bg_darker":  "#f4f5f9", "bg_surface": "#e6e9ef",
		"bg_card":    "#ccd0da", "bg_lighter": "#bcc0cc",
		"fg":         "#4c4f69", "fg_bright":  "#000000", "muted":      "#7c7f93",
		"blue":       "#1e66f5", "green":      "#40a02b", "cyan":       "#179299", "red": "#d20f39",
		"hl_number":  "#fe640b", "hl_symbol":  "#04a5e5", "hl_func":    "#1e66f5",
		"hl_member":  "#8839ef", "hl_comment": "#7c7f93", "hl_string":  "#40a02b",
		"hl_keyword": "#8839ef", "hl_type":    "#179299", "hl_const":   "#fe640b",
	},
	"nord_light": {
		"label": "Nord Light",
		"variant": "light",
		"bg_black":   "#ffffff", "bg_darker":  "#f5f7fa", "bg_surface": "#e5e9f0",
		"bg_card":    "#d8dee9", "bg_lighter": "#c6d0df",
		"fg":         "#2e3440", "fg_bright":  "#000000", "muted":      "#4c566a",
		"blue":       "#5e81ac", "green":      "#658a47", "cyan":       "#4c7a78", "red": "#bf616a",
		"hl_number":  "#9b6293", "hl_symbol":  "#5e81ac", "hl_func":    "#5e81ac",
		"hl_member":  "#437194", "hl_comment": "#7b88a1", "hl_string":  "#658a47",
		"hl_keyword": "#81a1c1", "hl_type":    "#4c7a78", "hl_const":   "#9b6293",
	},
	"solarized_light": {
		"label": "Solarized Light",
		"variant": "light",
		"bg_black":   "#fdf6e3", "bg_darker":  "#f6f0dc", "bg_surface": "#eee8d5",
		"bg_card":    "#e4dcbf", "bg_lighter": "#d6cca8",
		"fg":         "#586e75", "fg_bright":  "#073642", "muted":      "#839496",
		"blue":       "#268bd2", "green":      "#859900", "cyan":       "#2aa198", "red": "#dc322f",
		"hl_number":  "#d33682", "hl_symbol":  "#657b83", "hl_func":    "#268bd2",
		"hl_member":  "#b58900", "hl_comment": "#93a1a1", "hl_string":  "#859900",
		"hl_keyword": "#cb4b16", "hl_type":    "#2aa198", "hl_const":   "#6c71c4",
	},
}

const ALL_THEMES: Dictionary = {
	"adwaita_darker": DARK_THEMES.adwaita_darker,
	"monokai": DARK_THEMES.monokai,
	"tokyo_night": DARK_THEMES.tokyo_night,
	"dracula": DARK_THEMES.dracula,
	"catppuccin": DARK_THEMES.catppuccin,
	"nord": DARK_THEMES.nord,
	"jakes_theme": DARK_THEMES.jakes_theme,
	"terminal": DARK_THEMES.terminal,
	"solarized_dark": DARK_THEMES.solarized_dark,
	"adwaita_lighter": LIGHT_THEMES.adwaita_lighter,
	"monokai_light": LIGHT_THEMES.monokai_light,
	"tokyo_night_light": LIGHT_THEMES.tokyo_night_light,
	"dracula_light": LIGHT_THEMES.dracula_light,
	"catppuccin_light": LIGHT_THEMES.catppuccin_light,
	"nord_light": LIGHT_THEMES.nord_light,
	"solarized_light": LIGHT_THEMES.solarized_light,
}

const RESOURCE_PATHS: Dictionary = {
	"adwaita_darker": "res://themes/ui_grid_outline.theme",
	"monokai": "res://themes/ui_material3_monokai.theme",
	"tokyo_night": "res://themes/ui_material3_tokyo_night.theme",
	"dracula": "res://themes/ui_material3_dracula.theme",
	"catppuccin": "res://themes/ui_material3_catppuccin.theme",
	"nord": "res://themes/ui_material3_nord.theme",
	"jakes_theme": "res://themes/ui_material3_jakes_theme.theme",
	"terminal": "res://themes/ui_material3_terminal.theme",
	"solarized_dark": "res://themes/ui_material3_solarized_dark.theme",
	"adwaita_lighter": "res://themes/ui_material3_adwaita_lighter.theme",
	"monokai_light": "res://themes/ui_material3_monokai_light.theme",
	"tokyo_night_light": "res://themes/ui_material3_tokyo_night_light.theme",
	"dracula_light": "res://themes/ui_material3_dracula_light.theme",
	"catppuccin_light": "res://themes/ui_material3_catppuccin_light.theme",
	"nord_light": "res://themes/ui_material3_nord_light.theme",
	"solarized_light": "res://themes/ui_material3_solarized_light.theme",
}

static func is_light(theme_name: String) -> bool:
	var info: Dictionary = ALL_THEMES.get(theme_name, {})
	return str(info.get("variant", "dark")) == "light"

static func get_light_variant(dark_name: String) -> String:
	match dark_name:
		"adwaita_darker": return "adwaita_lighter"
		"monokai": return "monokai_light"
		"tokyo_night": return "tokyo_night_light"
		"dracula": return "dracula_light"
		"catppuccin": return "catppuccin_light"
		"nord": return "nord_light"
		"jakes_theme": return "adwaita_lighter"
		"terminal": return "adwaita_lighter"
		"solarized_dark": return "solarized_light"
		_:
			if is_light(dark_name):
				return dark_name
			return "adwaita_lighter"

static func get_dark_variant(light_name: String) -> String:
	match light_name:
		"adwaita_lighter": return "adwaita_darker"
		"monokai_light": return "monokai"
		"tokyo_night_light": return "tokyo_night"
		"dracula_light": return "dracula"
		"catppuccin_light": return "catppuccin"
		"nord_light": return "nord"
		"solarized_light": return "solarized_dark"
		_:
			if not is_light(light_name):
				return light_name
			return "adwaita_darker"
