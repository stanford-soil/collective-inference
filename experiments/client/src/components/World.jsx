import React, { useState } from "react";
import { useGame, usePlayer, useStage } from "@empirica/core/player/classic/react";

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
      return <span key={index} style={{ display: 'inline-block', width: '30em' }}>&nbsp;&nbsp;&nbsp;&nbsp;</span>;
    }
  });

  // Check if the current stage is "special"
  if (stage.get('name') ===  "looking at your yard") {
    return (
      <div style={{
        position: 'fixed',
        top: "10%",
        left: '15%',
        right: '15%',
        width: '70%',
        height: '90%',
        borderRadius: '0',
        display: 'flex',
        backgroundColor: '#268b07',
        zIndex: 9999,
        padding: '1em', 
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

        <div style={{
          display: 'flex',
          flexWrap: 'wrap', 
          justifyContent: 'center',
          alignItems: 'center',
          maxWidth: '85%', 
        }}>
          {critterDistribution}
        </div>
      </div>
    );
  }

  return (
    <div>
     <button
    onClick={() => setIsVisible(!isVisible)}
    disabled={false} // Set this as per your logic if needed
    className={`bg-blue-500 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline 
        ${false ? 'opacity-50 cursor-not-allowed' : 'hover:bg-blue-700'}`}
    style={{
        position: 'absolute',
        top: '12%',
        left: '20%',
    }}
>
    {isVisible ? "Close" : "Peek Outside"}
</button>


      {isVisible && (
        <div>
          <div style={{
            position: 'absolute',
            top: '18%',
            right: '50%',
            bottom: '20%',
            left: '3%',
            backgroundImage: 'url("/freepik.png")',
            backgroundColor: '#268b07',
            opacity: 0.7,
            borderRadius: '20px',
            zIndex: -1,
          }}>
          </div>

          <div style={{
            display: 'flex',
            flexWrap: 'wrap', 
            justifyContent: 'center',
            alignItems: 'center',
            margin: '0 auto', 
            maxWidth: '85%', 
          }}>
            {critterDistribution}
          </div>
        </div>
      )}
    </div>
  );
}


