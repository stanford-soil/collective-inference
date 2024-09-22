import React, { useState, useEffect } from "react";
import { usePlayer, useGame } from "@empirica/core/player/classic/react";

export function Lobby() {
  const player = usePlayer();
  const game = useGame();
  const [position, setPosition] = useState({ top: 50, left: 50 });
  const avatarUrl = `https://api.dicebear.com/9.x/adventurer/svg?seed=${player.id}`;

  // Debugging: Log the current players
  useEffect(() => {
    if (game && game.players) {
      game.players.forEach((player, i) => {
        console.log("Current player index:", i, "Player ID:", player.id);
      });
    }
  }, [game]);

  const handleKeyDown = (event) => {
    setPosition((pos) => {
      let newTop = pos.top;
      let newLeft = pos.left;

      switch (event.key) {
        case "ArrowUp":
          newTop = Math.max(0, pos.top - 5); // Prevent moving off the top
          break;
        case "ArrowDown":
          newTop = Math.min(80, pos.top + 5); // Prevent moving under the text
          break;
        case "ArrowLeft":
          newLeft = Math.max(0, pos.left - 5); // Prevent moving off the left
          break;
        case "ArrowRight":
          newLeft = Math.min(90, pos.left + 5); // Prevent moving off the right
          break;
        default:
          break;
      }

      return { top: newTop, left: newLeft };
    });
  };

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const playerCount = game && game.players ? game.players.length : 0;

  return (
    <div style={{ position: "relative", height: "100vh", textAlign: "center" }}>
      <div style={{ position: "absolute", top: `${position.top}%`, left: `${position.left}%` }}>
        <img src={avatarUrl} alt="player-avatar" width="100" height="100" />
      </div>
      <div
        style={{
          position: "absolute",
          top: "30%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          fontSize: "2rem", // Make the text bigger
          fontWeight: "bold",
        }}
      >
        <h1>Thank you for waiting, the game will start soon.</h1>
           <p> This avatar is how the other players will see you! </p>
        <p>{playerCount}/4 players ready</p>
      </div>
    </div>
  );
}



