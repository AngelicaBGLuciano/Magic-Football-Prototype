class_name Const
extends RefCounted


# --- Campo ---
const COLS := 10
const ROWS := 5
const PLACE_MAX_X := 4          # jogadores só podem ser posicionados nas colunas 1..4 
const SHOOT_RANGE := 4          # distância máxima para finalizar

# --- Estrutura de partida (turnos) ---
const TICKS_PER_HALF := 12      # lances por tempo
const WINDOW_TICKS := [4, 9]    # Janelas de Oportunidade
const MAJOR_TICK := 6           # Evento Maior (perto da metade do tempo)

# --- Run ---
const MAX_CYCLES := 4          # Ciclos 1-4 
const ATTR_CAP := 10            # limite global de atributo
const MIN_PRICE := 3
const SIXTH_STAR_EXTRA := 4     # a 6ª estrela aumenta drasticamente a manutenção

const ATTRS := ["pot", "pre", "vig", "tat", "res", "agi"]
const ATTR_NAMES := {
	"pot": "Potência", "pre": "Precisão", "vig": "Vigor",
	"tat": "Tático", "res": "Resistência", "agi": "Agilidade",
}
const ATTR_SHORT := {
	"pot": "POT", "pre": "PRE", "vig": "VIG",
	"tat": "TAT", "res": "RES", "agi": "AGI",
}

# Gasto de manutenção por rodada
const MAINTENANCE := [1, 2, 3, 5, 8, 12]

# Formações 
const FORMATIONS := {
	"Retranca (2-1)": [Vector2i(1, 1), Vector2i(1, 3), Vector2i(3, 2)],
	"Equilibrada": [Vector2i(1, 2), Vector2i(3, 1), Vector2i(3, 3)],
	"Ofensiva (1-2)": [Vector2i(1, 2), Vector2i(4, 0), Vector2i(4, 4)],
}

# Áreas de jogo
const FIELDS := [
	{"name": "Gramado ameno", "temp": 20, "wet": false},
	{"name": "Manhã gelada e seca", "temp": 6, "wet": false},
	{"name": "Chuva de verão", "temp": 22, "wet": true},
	{"name": "Tarde escaldante", "temp": 35, "wet": false},
	{"name": "Garoa de inverno", "temp": 8, "wet": true},
]

# Itens
const EQUIPMENT := [
	{"name": "Chuteira Faísca", "slot": "boot", "mods": {"pot": 1, "pre": 1}},
	{"name": "Chuteira Pluma", "slot": "boot", "mods": {"agi": 2}},
	{"name": "Luvas Arcanas", "slot": "boot", "mods": {"res": 1, "tat": 1}},
	{"name": "Caneleira Rúnica", "slot": "boot", "mods": {"res": 2}},
]
const KITS := [
	{"name": "Uniforme Solar", "slot": "kit", "mods": {"vig": 1}},
	{"name": "Uniforme Estratégico", "slot": "kit", "mods": {"tat": 1}},
	{"name": "Uniforme Veloz", "slot": "kit", "mods": {"agi": 1}},
]


static func mods_text(mods: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in mods:
		parts.append("+%d %s" % [int(mods[k]), ATTR_SHORT[k]])
	return ", ".join(parts)
