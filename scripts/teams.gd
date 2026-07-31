extends RefCounted

# THE FOUR TEAMS! Pick one on the TEAM screen and your hero wears
# that team's armour for the whole game.

const LIST := ["red", "blue", "green", "yellow"]

const DATA := {
	"red": {
		"name": "RED",
		"armour": Color(0.82, 0.20, 0.22),
		"light": Color(0.98, 0.44, 0.42),
		"dark": Color(0.48, 0.10, 0.14),
		"cape": Color(0.18, 0.20, 0.34),      # midnight blue cape
		"motto": "Fast and fearless!",
	},
	"blue": {
		"name": "BLUE",
		"armour": Color(0.20, 0.45, 0.88),
		"light": Color(0.44, 0.70, 1.00),
		"dark": Color(0.10, 0.24, 0.55),
		"cape": Color(0.92, 0.62, 0.15),      # orange cape
		"motto": "Cool and clever!",
	},
	"green": {
		"name": "GREEN",
		"armour": Color(0.20, 0.62, 0.32),
		"light": Color(0.38, 0.85, 0.48),
		"dark": Color(0.10, 0.36, 0.20),
		"cape": Color(0.55, 0.18, 0.22),      # red cape
		"motto": "Sneaky and strong!",
	},
	"yellow": {
		"name": "YELLOW",
		"armour": Color(0.93, 0.78, 0.18),
		"light": Color(1.00, 0.93, 0.48),
		"dark": Color(0.58, 0.46, 0.07),
		"cape": Color(0.38, 0.20, 0.58),      # purple cape
		"motto": "Bright and bold!",
	},
}

# Always gives back a real team, even if the saved name is nonsense
static func get_team(id: String) -> Dictionary:
	return DATA.get(id, DATA["green"])
