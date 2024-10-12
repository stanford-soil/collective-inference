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



const critterDistribution = critterDistributionInital.flatMap((critter, index) => {
  const critterElement = [];

  if (critter === '🐇') {
    critterElement.push(<img key={`critter-${index}`} src="/rabbit.svg" style={{ width: '3em', height: '3em' }} alt="rabbit" />);
  } else if (critter === '🐿️') {
    critterElement.push(<img key={`critter-${index}`} src="/squirrel.png" style={{ width: '3em', height: '2.5em' }} alt="squirrel" />);
  } else if (critter.trim() === "") {
    critterElement.push(<span key={`critter-${index}`} style={{ display: 'inline-block', width: '30em' }}>&nbsp;&nbsp;&nbsp;&nbsp;</span>);
  }

  // Add a block of different size based on index
  if (index < critterDistributionInital.length - 1) {
    critterElement.push(
      <span key={`block-${index}`} style={{ display: 'inline-block', width: `${(index + 1) * 10}px`, height: '20px', margin: '0 5px' }} />
    );
  }

  return critterElement;
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
        left: '40%',
    }}
>
    {isVisible ? "Close" : "Peek Outside"}
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
      opacity: 0.5, 
      borderRadius: '20px',
      zIndex: 8, 
    }}>
    </div>

    {/* Solid background color in the same area as the background image */}
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
      alignItems: 'center',
	     margin: '0 auto',
	     top: '50%',
      left: '25%',
      right: '25%',
      zIndex: 9, // Critters zIndex higher than background
      position: 'absolute', // Ensure critters are positioned relative to the parent
    }}>
      {critterDistribution}
    </div>
  </div>
)}

    </div>
  );
}


