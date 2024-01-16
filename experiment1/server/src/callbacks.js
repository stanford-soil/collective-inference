import { ClassicListenersCollector } from "@empirica/core/admin/classic";
export const Empirica = new ClassicListenersCollector();
import _ from "lodash";

Empirica.onGameStart(({ game }) => {
  const trueP = 0.7; //was 'treatment.trueP' in Robert's pseudocode

  const binomial = (p, n) => {
    const flips = _.range(n).map((i) => {
      return Math.random() < p;
    });
    return _.sum(flips);
  };

  game.players.forEach((player, i) => {
    const n = Math.floor(Math.random() * 9);
    const nRabbits = binomial(trueP, n);
    const nSquirrels = n - nRabbits;

    console.log(
      `Player ${i + 1}: nRabbits - ${nRabbits}, nSquirrels - ${nSquirrels}`
    );

    // Convert to emojis
    const rabbits = _.repeat("🐇 ", nRabbits).split(" ");
    const squirrels = _.repeat("🐿️ ", nSquirrels).split(" ");

    // Create spaces with roughly 50% probability
    const nSpaces = (1 / 2) * (nRabbits + nSquirrels);
    const spaces = _.repeat("\u00A0 \u00A0 \u00A0 \u00A0", nSpaces);

    // Scramble spaces and critters
    const emojiArray = _.shuffle(_.concat(rabbits, squirrels, spaces));

    player.set("name", "player " + (i + 1));
    player.set("emojiArray", emojiArray);
  });

  [1, 2, 3, 4, 5, 6].forEach((i) => {
    const round = game.addRound({
      idx: i,
      name: "Round " + i + " / 6",
      task: "Chat",
    });
    round.addStage({ name: "send", duration: 10 });
    round.addStage({ name: "observe", duration: 10});
  });
  
});





Empirica.onRoundStart(({ round }) => {
  const players = round.currentGame.players;
  players.forEach((player, i) => {
    const otherPlayers = players.filter((p) => p.id != player.id);
    console.log(
      "setting player id",
      player.id,
      "recipient to ",
      otherPlayers[(i + round.get("idx")) % otherPlayers.length].id
    );
    player.set(
      "recipient",
      otherPlayers[(i + round.get("idx")) % otherPlayers.length].id
    );
  });
});

Empirica.onStageStart(({ stage }) => {});

Empirica.onStageEnded(({ stage, game }) => {


  const scopeArray = game.get("scope");

  // Save 'scope.value.text' to player's stage
  stage.players.forEach((player) => {
    player.stage.set("scopeText", scopeArray.value.text);
  });


});


Empirica.onRoundEnded(({ round }) => {});

Empirica.onGameEnded(({ game }) => {});
