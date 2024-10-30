import { ClassicListenersCollector } from "@empirica/core/admin/classic";
export const Empirica = new ClassicListenersCollector();
import _ from "lodash";
import fs from 'fs'; // Import fs to read JSON file

  const gamesData = JSON.parse(fs.readFileSync('games.json'));
    console.log(gamesData)
      // Load pre-generated critters from games.json

    
Empirica.onGameStart(({ game }) => {
  const treatment = game.get("treatment");
  const gameRow = _.toInteger(treatment.gameRow);
      console.log(gameRow)
// Assuming game_row is passed in treatment
  // const total = 20;
 


  const critterData = gamesData[gameRow];
  console.log(JSON.stringify(critterData, null, 2))
  if (!critterData) {
    console.error("Invalid game row data");
    return;
  }

  // Extract nRabbits and nSquirrels from the arrays
  const nRabbitsArray = critterData.nRabbits; // Array of rabbits for each player
  const nSquirrelsArray = critterData.nSquirrels; // Array of squirrels for each player

  const generateCritters = (nRabbits, nSquirrels) => {
    const rabbits = _.split(_.repeat("🐇", nRabbits), "");
    const squirrels = _.split(_.repeat("🐿️", nSquirrels), "");
    const critters = _.shuffle(_.concat(rabbits, squirrels));

    return critters;
  };

  // Generate critters for each player based on their order
  const critters = game.players.map((player, i) => generateCritters(nRabbitsArray[i], nSquirrelsArray[i]));

  game.players.forEach((player, i) => {
    const spaces = _.repeat("\u00A0 \u00A0 \u00A0 \u00A0", 5);
    
    const emojiArray = _.shuffle(_.concat(critters[i], spaces));
    player.set(
      "avatar",
      `https://api.dicebear.com/9.x/personas/svg?seed=${player.id}`
    );
    player.set("name", "player " + (i + 1));
    player.set("emojiArray", emojiArray);
  });

  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].forEach((i) => {
    const round = game.addRound({
      idx: i,
      name: "Round " + (i) + " / 12",
      task: "Chat",
    });

    if (i === 1) {
      round.addStage({ name: "looking at your yard", duration: 30 });
    }

    if (treatment.condition !== 'slider') {
      round.addStage({ name: "send", duration: 30 });
    }

    round.addStage({ name: "observe", duration: 30 });
  });
});

Empirica.onRoundStart(({ round }) => {
  const players = round.currentGame.players;
  players.forEach((player, i) => {
    const otherPlayers = players.filter((p) => p.id !== player.id);
    player.set(
      "recipient",
      otherPlayers[(i + round.get("idx")) % otherPlayers.length].id
    );
  });
});

Empirica.onStageStart(({ stage }) => {});

Empirica.onStageEnded(({ stage }) => {});

Empirica.onRoundEnded(({ round }) => {});

Empirica.onGameEnded(({ game }) => {});
