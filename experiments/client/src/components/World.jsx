import React, { useState } from "react";
import { useGame, usePlayer, useStage } from "@empirica/core/player/classic/react";

export function World() {
  const game = useGame();
  const player = usePlayer();
  const stage = useStage();
  
  const [isVisible, setIsVisible] = useState(false);

  const critterDistributionInital = player.get('emojiArray') || [];

  const rabbitCount = critterDistributionInital.filter(critter => critter === '🐇').length;
  const squirrelCount = critterDistributionInital.filter(critter => critter === '🐿️').length;
  const totalCritters = rabbitCount + squirrelCount;

  const critterDistribution = critterDistributionInital.flatMap((critter, index) => {
    const critterElement = [];

    if (critter === '🐇') {
      critterElement.push(<img key={`critter-${index}`} src="/rabbit.svg" style={{ width: '5em', height: '5em' }} alt="rabbit" />);
    } else if (critter === '🐿️') {
      critterElement.push(<img key={`critter-${index}`} src="/squirrel.png" style={{ width: '4em', height: '3.5em' }} alt="squirrel" />);
    } else if (critter.trim() === "") {
      critterElement.push(<span key={`critter-${index}`} style={{ display: 'inline-block', width: '5em' }}>&nbsp;&nbsp;&nbsp;&nbsp;</span>);
    }

    if (index < critterDistributionInital.length - 1) {
      critterElement.push(
        <span key={`block-${index}`} style={{ display: 'inline-block', width: `${(index + 1) * 10}px`, height: '20px', margin: '0 5px' }} />
      );
    }

    return critterElement;
  });

  if (stage.get('name') === "looking at your yard") {
    return (
      <div style={{
        position: 'fixed',
        top: "10%",
        bottom: '5%',
        left: '15%',
        right: '15%',
        borderRadius: '8px', 
        display: 'flex',
        backgroundColor: '#268b07',
        zIndex: 9999,
        padding: '1em',
        border: '10px solid #8B4513', 
        boxShadow: '0px 0px 15px rgba(0, 0, 0, 0.3)', 
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
          alignItems: totalCritters > 20 ? 'flex-start' : 'center',  // Position based on critter count
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
        disabled={false}
        className={`bg-blue-500 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline 
            ${false ? 'opacity-50 cursor-not-allowed' : 'hover:bg-blue-700'}`}
        style={{
            position: 'absolute',
            top: '12%',
            transform: 'translateX(-50%)', 
        }}
      >
        {isVisible ? "Hide photo" : "Look at photo"}
      </button>

      {isVisible && (
        <div>  
       

          <div style={{
            position: 'absolute',
            top: '18%',
            right: '3%',
            bottom: '3%',
            left: '3%',
            backgroundImage: 'url("/freepik.png")',
            opacity: 0.8, 
            borderRadius: '20px',
            zIndex: 8, 
            border: '10px solid #8B4513', 
            boxShadow: '0px 0px 15px rgba(0, 0, 0, 0.3)', 
          }}>
          </div>

          <div style={{
            position: 'absolute',
            top: '18%',
            right: '3%',
            bottom: '0%',
            left: '3%',
            backgroundColor: 'white', 
            borderRadius: '20px',
            zIndex: 7, 
          }}>
          </div>

          <div style={{
            display: 'flex',
            flexWrap: 'wrap', 
            justifyContent: 'center',
            alignItems: totalCritters > 20 ? 'flex-start' : 'center',  // Adjust position here as well
            margin: '0 auto',
            top: '25%',
            left: '15%',
            right: '15%',
            zIndex: 9,
            position: 'absolute',
          }}>
            {critterDistribution}
          </div>
        </div>
      )}
    </div>
  );
}

