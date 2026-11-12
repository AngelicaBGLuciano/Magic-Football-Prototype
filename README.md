# Magic Football - Protótipo 

Roguelike de futebol com partidas em estilo Auto Chess. 

## Fluxo da run
1. **Menu** -> Nova Run
2. **Criação de capitão**: o player distribue 8 pontos nos 6 atributos e escolhe 1 de 3 Dons, ou usa o **modo Caos** (atributos sorteados + 2 Dons).
3. **Compra inicial**: 3 rodadas de sorteio (1 de 3 por rodada; 1ª = goleiro). Custa Futmoedas.
4. **Partida** (ciclos 1-4):
   - *Definição de área de jogo*: escolha 1 de 3 campos/climas (ativam Cabeça fria/quente/molhada) e a 6ª estrela.
   - *Turno de posicionamento*: clique num jogador e numa casa azul, ou use uma formação.
   - *Jogo rolando*: simulação automática por lances (2 tempos x 12 lances).
   - *Janela de Oportunidade* (lances 4 e 9): escolha uma Jogada gastando Vigor (ataque ou defesa).
   - *Evento Menor*: falta a favor -> escolha como cobrar.
   - *Evento Maior* (lance 6) e *Grande Acontecimento* (último lance): escolha entre 2 opções.
   - *Intervalo*: reposicione; todos recuperam 3 de Vigor.
   - *Resultados*: empate vai para pênaltis; **perder encerra a run**.
5. **Escolha por rodada**: após vitória, 1 de 3 recompensas (treino, Dom, equipamento, uniforme, futmoedas). Manutenção por tier é cobrada (sem dinheiro = jogador começa cansado).

## Estrutura
- `scripts/Const.gd` - constantes, formações, climas, itens
- `scripts/SkillDB.gd` - 19 Dons da planilha (valores por estrela, incl. 6ª)
- `scripts/EventDB.gd` - eventos Maior / Grande Acontecimento
- `scripts/PlayerData.gd`, `PlayerFactory.gd`, `GameState.gd` (autoload)
- `scripts/MatchEngine.gd`, `MatchPlayer.gd` - simulação (lógica pura)
- `scripts/Match.gd`, `PitchView.gd`, `PlayerToken.gd` - cena de partida
- `scenes/*.tscn` - MainMenu, CaptainCreation, Draft, Match, Reward, EndScreen, PlayerCard, PlayerToken

