import React from "react";
import {InputBox} from "./InputBox";
import {usePlayer, useStage, useRound, useGame } from "@empirica/core/player/classic/react";
import { Slider } from '@mui/material';
import { useState } from "react";

//*
// Please note, there is a slider input ("treatment".opinion) and a slider game condition("treatment".condition). 
// This makes sense in the front end but may catch one by surprise in here. 
//*

export function Opinion({ scope, attribute}){
    const round = useRound();
    const player = usePlayer();
    const game = useGame();
    const stage = useStage();
    const { condition } = game.get("treatment");


    

//*
// If the opinion is a text box input, this appends it to the scope file so we can read it later.
//*
    const handleNewOpinion = (text) => {
        console.log("handle opinion triggered with ", sliderValue,scope, scope.append)
        scope.append(opinion, {
            opinion: text,
            round: round.get('idx'),
            sender: {
                id: player.id,
                name: player.get("name") || player.id,
                avatar: player.get("avatar"),
            },
        });
        player.stage.set("submit", true);
    };

//*
// If the opinion input is a slider, there are two sliders: opinion and confidence. 
// Here we create the sliders and save their contents if they are changed
//*
    const [sliderValue, setSliderValue] = useState(50);
    const [isSliderChanged, setIsSliderChanged] = useState(false); 
    const [confidenceValue, setConfidenceValue] = useState(50);
    const [isConfidenceChanged, setIsConfidenceChanged] = useState(false);


    const handleSlider = (event, value) => {
        setSliderValue(value);
        setIsSliderChanged(true);
        console.log("changed");
    };

      const handleConfidence = (event, value) => {
        setConfidenceValue(value);
        setIsConfidenceChanged(true);
        console.log("confidence changed");
    };
    

        
//*
// Render the example icons for the players
//*

        const renderIcons = () => {
    const numberOfIcons = 100;
    const rabbitCount = Math.round((sliderValue / 100) * numberOfIcons);
    const icons = [];

    for (let i = 0; i < numberOfIcons; i++) {
        if (i < rabbitCount) {
            icons.push(<span key={i}>🐇</span>);
        } else {
            icons.push(<span key={i}>🐿️</span>);
        }
    }

    const reorderedIcons = [];
    let fib1 = 1, fib2 = 1;
    for (let i = 0; i < icons.length; i++) {
    const index = (fib1 - 1) % icons.length;
    reorderedIcons[index] = icons[i];
    const temp = fib1 + fib2;
    fib1 = fib2;
    fib2 = temp;
    }

    return reorderedIcons;
};

//*
// When the user clicks submit, save their data. If in slider condition, create a fixed message.
//*

 const handleButtonClick = () => {
                console.log("handle button triggered")

        if (game.get("treatment").condition === "slider") {
            handleSliderSubmit(sliderValue);
        } else {
            handleSubmit();
        }
    };

const handleSliderSubmit = (sliderValue) => {
    console.log("handle slidersubmit triggered with ", sliderValue,scope, scope.getAttribute(attribute)?.items );
    player.stage.set("guess", sliderValue);
    const text = "I think the population is " + sliderValue + "% rabbits";
    console.log(text);
    player.stage.set("confidence", confidenceValue);
    scope.append(attribute, {
    text,
        likes : {},
        time: Date.now(),
        round: round.get('idx'),
        recipient: player.get("recipient"),
        sender: {
            id: player.id,
            name: player.get("name") || player.id,
            avatar: player.get("avatar"),
        },
    });

    const playerStageData = scope.getAttribute(attribute)?.items || [];
    game.set("messages", playerStageData.map((msg, i) => msg.val._value));

    player.stage.set("submit", true);
};

const handleSubmit = () => {
    console.log("handle submit triggered")
    player.stage.set("guess", sliderValue);
    player.stage.set("confidence", confidenceValue);
    player.stage.set("submit", true);
};


//*
// How the slider input box looks is here. How the text one looks is in InputBox.jsx
//*

if (stage.get('name') === 'observe') {
     console.log("guess", sliderValue); console.log("confidence", confidenceValue);
    return game.get("treatment").opinion === "slider" ? (
<div >
<div className="flex">
    
    <div className="flex flex-col items-center space-y-4">
    <h2>What proportion of the population are rabbits?</h2>
    <div className="flex items-center space-x-4">
        <h2 className="text-gray-600 text-sm text-center mb-2">All Squirrels<br />🐿️</h2>
        <Slider
            defaultValue={50}
            aria-label="Default"
            valueLabelDisplay="off"
            onChange={handleSlider}
            value={sliderValue}
            style={{ width: '200px' }}
            track={false}
        />
        <h2 className="text-gray-600 text-sm text-center mb-2">All Rabbits <br />🐇</h2>
    </div>
</div>

    <div style={{
        marginLeft: '30px',
         marginRight: '30px',
        marginBottom: '30px',
        marginTop: '0 px',
        textAlign: 'center',
        width: '220px',
        height: '150px',
        display: 'inline-block',
        boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
        borderRadius: '10px',
        border: '1px solid #ccc',
        overflow: 'hidden' 
    }}>
        {renderIcons()}
    </div>
    <div>
        <h2 className="text-center">How confident are you in your answer?</h2><br />
        <div className="flex items-center space-x-4">
            <h2 className="text-gray-600 text-sm text-center mb-2">Very Uncertain</h2>
            <Slider
                defaultValue={50}
                aria-label="Default"
                valueLabelDisplay="off"
                onChange={handleConfidence}
                value={confidenceValue}
                style={{ width: '200px' }}
            />
            <h2 className="text-gray-600 text-sm text-center mb-2">Fully Certain</h2>
            <div>

               <button
   onClick={handleButtonClick}
   disabled={!isConfidenceChanged || !isSliderChanged}
   className={`bg-blue-500 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline
      ${(!isConfidenceChanged || !isSliderChanged) ? 'opacity-50 cursor-not-allowed' : 'hover:bg-blue-700'}`}
>
   Submit
</button>

            </div>
        </div>
    </div>
</div> </div>
    ) : (
        <div>
            <h2 className="align-center text-gray-500 text-center" style={{ marginBottom: '20px' }}>What proportion of the population are rabbits? Please enter your opinion and what convinced you to make this choice.</h2>
            <InputBox onNewMessage={handleNewOpinion} buttonPosition="below" buttonText="Submit" buttonStyles='w-auto h-auto py-2 px-4 text-base' />
        </div>
    );
}
}
