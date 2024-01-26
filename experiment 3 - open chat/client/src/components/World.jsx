import React from "react";
import { useGame, usePlayer } from "@empirica/core/player/classic/react";
import _ from "lodash";

export function World() {
  const game = useGame();
  const player = usePlayer();

  // turn critter distribution into emoji arrays
  const critterDistribution = player.get('emojiArray')
 

return (
  <div style={{
    position: 'relative',
    width: '90%',
    height: '90%',
    borderRadius: '20px',
    display: 'flex',
    flexWrap: 'wrap',
    justifyContent: 'center',
    alignItems: 'center',
  }}>
    <div style={{
      position: 'absolute',
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
      backgroundImage: 'url("/freepik.png")',
      backgroundColor: '#268b07',
      opacity: 0.7,
      borderRadius: '20px',
      zIndex: -1,
    }}></div>

    {[...Array(1)].map((_, index) => (
      <span key={index} style={{ fontSize: '70px' }}>
        {critterDistribution}
      </span>
    ))}
  </div>

  );
}

