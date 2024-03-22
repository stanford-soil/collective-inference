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

function partition(remaining, current, ...previous) {
  const validPartitions = []; // Array to store valid partitions
  const min = previous.length > 0 ? previous[0] : 1;
  const max = Math.floor(remaining / 2);
  
  for (let i = min; i <= max; i++) { // Renamed 'n' to 'i' for clarity
    validPartitions.push([...previous, i]); // Store the valid partition
    if (i < game.players.length) {
      partition(remaining - i, i, ...previous); // Fixed recursive call parameters
    }
  }

  // Randomly select one partition from validPartitions array
  if (validPartitions.length === game.players.length) {
    const randomIndex = Math.floor(Math.random() * validPartitions.length);
    console.log("Randomly selected partition:", validPartitions[randomIndex]);
    return validPartitions[randomIndex];
  }
}

console.log("partitionCritters:", partitionCritters);


const critters = generateCritters(trueP);
const partitionCritters = partition(total);

console.log("Number of players:", game.players.length)

game.players.forEach((player, i) => {
    console.log("Current player index:", i);

    const spaces = _.repeat("\u00A0 \u00A0 \u00A0 \u00A0", 5);

    const selectCritters = critters.splice(0, partitionCritters[i]); // Adjust indexing

    // Scramble spaces and critters
    const emojiArray = _.shuffle(_.concat(selectCritters, spaces));

    player.set("name", "player " + (i + 1));
    player.set("emojiArray", emojiArray);
}); });

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
