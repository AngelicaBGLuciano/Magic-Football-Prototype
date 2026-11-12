class_name EventDB
extends RefCounted
## Eventos de partida com escolha do jogador.
## Efeitos suportados em "effect":
##   buff: {attr: n}        -> bônus permanente (até o fim da partida) para todo o time
##   vigor: n               -> recupera/perde Vigor de todo o time
##   opp_vigor: n           -> altera o Vigor de todo o time adversário
##   shot_p: p              -> chance p de criar uma finalização para o seu melhor atacante
##   risk_opp_shot: p       -> chance p de o adversário finalizar

const MAJOR := [
	{
		"title": "Torcida enlouquecida",
		"text": "As arquibancadas tremem e o time sente a energia no ar.",
		"choices": [
			{"label": "Aproveitar o embalo", "desc": "+1 POT e +1 PRE até o fim.",
			 "effect": {"buff": {"pot": 1, "pre": 1}}},
			{"label": "Respirar fundo", "desc": "+3 de Vigor para todos.",
			 "effect": {"vigor": 3.0}},
		],
	},
	{
		"title": "O técnico pede ajuste",
		"text": "A beira do campo grita: a linha de marcação precisa mudar.",
		"choices": [
			{"label": "Linha alta", "desc": "+2 TAT, mas 30% de risco de contra-ataque.",
			 "effect": {"buff": {"tat": 2}, "risk_opp_shot": 0.3}},
			{"label": "Bloco baixo", "desc": "+2 RES e +1 de Vigor.",
			 "effect": {"buff": {"res": 2}, "vigor": 1.0}},
		],
	},
	{
		"title": "Lance polêmico",
		"text": "O juiz marca algo estranho e os ânimos esquentam.",
		"choices": [
			{"label": "Reclamar", "desc": "50% de chance de criar uma finalização; -2 de Vigor.",
			 "effect": {"shot_p": 0.5, "vigor": -2.0}},
			{"label": "Manter a calma", "desc": "+2 de Vigor e +1 TAT.",
			 "effect": {"vigor": 2.0, "buff": {"tat": 1}}},
		],
	},
	{
		"title": "Feitiço no gramado",
		"text": "Uma névoa mágica cobre parte do campo.",
		"choices": [
			{"label": "Aproveitar a névoa", "desc": "+2 AGI; adversário perde 2 de Vigor.",
			 "effect": {"buff": {"agi": 2}, "opp_vigor": -2.0}},
			{"label": "Dissipar a névoa", "desc": "+2 PRE.",
			 "effect": {"buff": {"pre": 2}}},
		],
	},
]

const GRAND := [
	{
		"title": "Contra-ataque nos acréscimos",
		"text": "O tempo está acabando e a defesa adversária está aberta!",
		"choices": [
			{"label": "All-in", "desc": "65% de finalização, 40% de risco de contra.",
			 "effect": {"shot_p": 0.65, "risk_opp_shot": 0.4}},
			{"label": "Segurar o resultado", "desc": "+2 de Vigor, sem riscos.",
			 "effect": {"vigor": 2.0}},
		],
	},
	{
		"title": "Bola parada no último lance",
		"text": "Escanteio! Todos sobem para a área.",
		"choices": [
			{"label": "Cobrar na área", "desc": "50% de finalização.",
			 "effect": {"shot_p": 0.5}},
			{"label": "Escanteio curto", "desc": "35% de finalização e +1 de Vigor.",
			 "effect": {"shot_p": 0.35, "vigor": 1.0}},
		],
	},
	{
		"title": "Chance de ouro",
		"text": "A bola sobra limpa na entrada da área.",
		"choices": [
			{"label": "Chute de primeira", "desc": "55% de finalização.",
			 "effect": {"shot_p": 0.55}},
			{"label": "Ajeitar o corpo", "desc": "40% de finalização, +1 PRE até o fim.",
			 "effect": {"shot_p": 0.4, "buff": {"pre": 1}}},
		],
	},
]


static func random_major() -> Dictionary:
	return MAJOR.pick_random()


static func random_grand() -> Dictionary:
	return GRAND.pick_random()
