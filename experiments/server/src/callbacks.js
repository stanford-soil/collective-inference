import { ClassicListenersCollector } from "@empirica/core/admin/classic";
export const Empirica = new ClassicListenersCollector();
import _ from "lodash";

Empirica.onGameStart(({ game }) => {
  const treatment = game.get("treatment");
  const { trueP, condition } = treatment;
  const total = 20;

  const generateCritters = (trueP) => {
    const nRabbits = Math.round(trueP * total);
    const nSquirrels = total - nRabbits;

    // Convert to emojis
    const rabbits = _.split(_.repeat("🐇", nRabbits), "");
    const squirrels = _.split(_.repeat("🐿️", nSquirrels), "");
    const critters = _.shuffle(_.concat(rabbits, squirrels));

    return critters;
  };

  const critters = generateCritters(trueP);

  function partition(total, groups = game.players.length, current = []) {
    const validPartitions = [];
    if (groups === 1) {
      if (current.concat(total).every(num => num > 1)) {
        validPartitions.push(current.concat(total));
      }
    } else {
      for (let i = 1; i < total; i++) {
        const newPartition = partition(total - i, groups - 1, current.concat(i));
        validPartitions.push(...newPartition);
      }
    }
    return validPartitions;
  }

  const divisions = partition(total);
  const randomPartition = Math.floor(Math.random() * divisions.length);
  const chosenPartition = divisions[randomPartition];

  game.players.forEach((player, i) => {
    const spaces = _.repeat("\u00A0 \u00A0 \u00A0 \u00A0", 5);

    const selectCritters = critters.splice(0, chosenPartition[i]);

    const emojiArray = _.shuffle(_.concat(selectCritters, spaces));
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

    if (condition !== 'slider') {
      round.addStage({ name: "send", duration: 30 });
    }

    round.addStage({ name: "observe", duration: 30 });
  });
});

Empirica.onRoundStart(({ round }) => {
  const players = round.currentGame.players;
  players.forEach((player, i) => {
    const otherPlayers = players.filter((p) => p.id != player.id);
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
