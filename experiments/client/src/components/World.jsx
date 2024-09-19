import React from "react";
import { useGame, usePlayer } from "@empirica/core/player/classic/react";
import _ from "lodash";


export function World() {
  const game = useGame();
  const player = usePlayer();

  // turn critter distribution into emoji arrays
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

  return (
    <div style={{
      position: 'relative',
      width: '90%',
      height: '90%',
      borderRadius: '20px',
      display: 'flex',
      flexDirection: 'row', // Arrange items in a row
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
  );
}

