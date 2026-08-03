extends RefCounted

# Keeps rude words out of usernames and friend names.
#
# DAD: if something slips through (or a perfectly nice name gets blocked
# by mistake), just add or remove words in the two lists below.
#
# BLOCKED_ANYWHERE - blocked even hidden inside a longer name
# BLOCKED_WHOLE    - only blocked when it's the WHOLE name, because these
#                    letters turn up inside innocent words too
#                    (CLASSY contains "ass", SHELLY contains "hell")

const BLOCKED_ANYWHERE := [
	# the usual swear words
	"FUCK", "FUK", "FCK", "FUX", "SHIT", "SHT", "SHYT", "CUNT", "BITCH",
	"BASTARD", "ASSHOLE", "MOTHERF", "WANK", "TOSSER", "PRICK", "DICK",
	"COCK", "KNOBHEAD", "BOLLOCK", "BOLLOX", "BUGGER", "ARSE", "PISS",
	"TWAT", "SHAG", "SLAG", "SKANK", "MINGE", "FANNY", "MUFF", "CLIT",
	# rude words about bodies
	"PUSSY", "PENIS", "VAGINA", "SCROTUM", "TESTICLE", "NIPPLE",
	"TITTY", "TITTIES", "BOOB", "SPUNK", "JIZZ", "BONER", "HORNY",
	"ORGASM", "BLOWJOB", "HANDJOB", "DILDO", "PORN", "PERV", "SLUT",
	"WHORE", "DOUCHE", "SEX", "RAPE", "NONCE", "PAEDO", "PEDOPHILE",
	# nasty words about people - these are the very worst ones
	"NIGG", "FAGG", "PAKI", "CHINK", "WOG", "GYPO", "GYPPO", "TRANNY",
	"HOMO", "RETARD", "SPAZ", "SPASTIC", "NAZI", "HITLER", "KKK",
]

const BLOCKED_WHOLE := [
	"ASS", "HELL", "DAMN", "CRAP", "POO", "POOP", "WEE", "FART",
	"BUM", "BUTT", "TURD", "SNOT", "GOD", "TIT", "TITS", "CUM",
	"KNOB", "WILLY", "DONG", "ANAL", "ANUS", "HOE", "FAG", "PEDO",
	"SPIC", "COON", "JAP", "MONG", "PRAT", "PLONKER", "BLOODY",
	"SUCK", "SUCKS", "FECK", "FRIG", "GIT",
]

# Letters people swap in to sneak words past a filter: 4 for A, 3 for E...
const LEET := {
	"4": "A", "@": "A", "3": "E", "1": "I", "!": "I", "|": "I",
	"0": "O", "5": "S", "$": "S", "7": "T", "+": "T", "8": "B", "9": "G",
}

# Perfectly nice words that happen to contain rude letters. Famously,
# a filter that blocks "cunt" also blocks the town of Scunthorpe!
const ALWAYS_ALLOWED := [
	"SCUNTHORPE", "PENISTONE", "ARSENAL", "SUSSEX", "ESSEX", "MIDDLESEX",
	"LIGHTWATER", "CLITHEROE", "COCKERMOUTH",
	# perfectly good words a kid might actually pick
	"GRAPE", "GRAPES", "TITAN", "TITANIC", "PEACOCK", "COCKROACH",
	"COCKPIT", "COCKTAIL", "SHUTTLECOCK", "DICKENS", "PAKISTAN",
	"PRICKLY", "SPARSE", "COARSE", "HEARSE",
]

# "5h1t" -> "SHIT". Swaps sneaky numbers for letters and throws away
# anything that isn't a letter, so "s.h.i.t" and "s h i t" get caught too.
static func _plain(name: String) -> String:
	var text := name.to_upper()
	var out := ""
	for i in text.length():
		var ch := text[i]
		if LEET.has(ch):
			ch = LEET[ch]
		if ch >= "A" and ch <= "Z":
			out += ch
	return out

# "SHIIIIT" -> "SHIT" (squashes repeated letters)
static func _squash(text: String) -> String:
	var out := ""
	for i in text.length():
		if out.length() == 0 or out[out.length() - 1] != text[i]:
			out += text[i]
	return out

# Returns true if the name is fine to use
static func is_clean(name: String) -> bool:
	var plain := _plain(name)
	if plain == "":
		return false
	if ALWAYS_ALLOWED.has(plain):
		return true

	var squashed := _squash(plain)

	for word in BLOCKED_ANYWHERE:
		var w := _plain(word)
		if plain.contains(w):
			return false
		# Also catch stretched-out spellings - but only for words that have
		# no double letters of their own, or "BOOB" would block "BOBBY"!
		if w.length() >= 3 and _squash(w) == w and squashed.contains(w):
			return false

	for word in BLOCKED_WHOLE:
		var w := _plain(word)
		if plain == w or squashed == _squash(w):
			return false
	return true
