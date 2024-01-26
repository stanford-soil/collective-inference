import { ClassicListenersCollector } from "@empirica/core/admin/classic";
export const Empirica = new ClassicListenersCollector();
import _ from "lodash";

Empirica.onGameStart(({ game }) => {
  const treatment = game.get("treatment");
  const { trueP } = treatment;

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

    [1, 2, 3, 4, 5, 6, 7, 8, 9].forEach((i) => {
    const round = game.addRound({
      idx: i,
      name: "Round " + i + " / 9",
      task: "Chat",
    });
    round.addStage({ name: "send", duration: 30 });
    round.addStage({ name: "observe", duration: 30});
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

Empirica.onStageEnded(({ stage }) => {});

Empirica.onRoundEnded(({ round }) => {});

Empirica.onGameEnded(({ game }) => {});
