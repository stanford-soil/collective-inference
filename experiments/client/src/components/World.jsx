import React, { useState } from "react";
import { useGame, usePlayer, useStage } from "@empirica/core/player/classic/react";
import _ from "lodash";

export function World() {
  const game = useGame();
  const player = usePlayer();
  const stage = useStage();
  
  // State to control if the window is visible
  const [isVisible, setIsVisible] = useState(false);

  // Turn critter distribution into emoji arrays
  const critterDistributionInital = player.get('emojiArray') || [];

  const critterDistribution = critterDistributionInital.map((critter, index) => {
    if (critter === '🐇') {
      return <img key={index} src="/rabbit.svg" style={{ width: '3em', height: '3em' }} alt="rabbit" />;
    } else if (critter === '🐿️') {
      return <img key={index} src="/squirrel.png" style={{ width: '3em', height: '2.5em' }} alt="squirrel" />;
    } else if (critter.trim() === "") { 
      return <span key={index} style={{ display: 'inline-block', width: '4em' }}>&nbsp;&nbsp;&nbsp;&nbsp;</span>;
    }
  });

  // Check if the current stage is "special"
  if (stage.get('name') ===  "looking at your yard") {
    return (
      // Full-screen mode when the stage is "special"
      <div style={{
        position: 'fixed',
        top: 100,
        left: '15%',
        right: '15%',
        width: '70%',
        height: '90%',
        borderRadius: '0',
        display: 'flex',
        flexDirection: 'row',
        flexWrap: 'wrap',
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#268b07',
        zIndex: 9999,
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
          zIndex: -1,
        }}></div>

        {critterDistribution}
      </div>
    );
  }

return (
  <div>
    <button
      onClick={() => setIsVisible(!isVisible)}
      style={{
        position: 'absolute',
        top: '15%',
        left: '20%',
      }}
    >
      {isVisible ? "Hide World" : "Show World"}
    </button>

    {isVisible && (
      <div style={{
        position: 'fixed',
        width: '90%',
        height: '90%',
        borderRadius: '20px',
        display: 'flex',
        flexDirection: 'row',
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

        {critterDistribution}
      </div>
    )}
  </div>
);

}

