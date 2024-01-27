import { useGame } from "@empirica/core/player/classic/react";

import React from "react";
import { Chat } from "./components/Chat"
import { Profile } from "./components/Profile"
import { World } from "./components/World";

export function Game() {
  const game = useGame();

  return (
    <div className="h-full w-full flex flex-col">
      <div className="w-full flex">
        <Profile />
      </div>
      <div className="h-full w-full flex flex-row">
        <div className="h-full w-full flex items-center justify-center">
          <World />
        </div>
        <div className="h-full w-full flex items-center justify-center">
          <Chat scope={game} attribute="chat" />
        </div>
      </div>
    </div>
  );
}
