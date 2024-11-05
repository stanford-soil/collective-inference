import React, { useState } from "react";
import { InputBox } from "./InputBox";
import { usePlayer, useStage, useRound, useGame } from "@empirica/core/player/classic/react";
import { Slider } from '@mui/material';


//*
// Please note, there is a slider input ("treatment".opinion) and a slider game condition("treatment".condition). 
// This makes sense in the front end but may catch one by surprise in here. 
//*

export function Opinion({ scope, attribute }) {
    const round = useRound();
    const player = usePlayer();
    const game = useGame();
    const stage = useStage();

    const handleNewOpinion = (text) => {
        scope.append(attribute, {
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

    const renderIcons = () => {
        const totalIcons = 98; 
        const rabbitCount = Math.round((sliderValue / 100) * totalIcons);
        const icons = [];

        // Generate initial array of rabbit and squirrel icons
const sliderDirection = game.get("treatment").sliderDirection === "RabbitsSquirrels";
   console.log("sliderDirection value:", game.get("sliderDirection"));

for (let i = 0; i < totalIcons; i++) {
    icons.push(
        <span key={i} style={{ fontSize: "12px", margin: "0px" }}> 
            {sliderDirection ?  (i < rabbitCount ? "🐿️" : "🐇") :(i < rabbitCount ? "🐇" : "🐿️")}
        </span>
    );
}

        const positionArray = icons.map((icon, index) => ({
            icon,
            position: Math.sin(index * 0.1) * Math.cos(index * 0.3),
        }));

        const sortedIcons = positionArray.sort((a, b) => a.position - b.position);

        return sortedIcons.map((item, index) => (
            <span key={index} style={{ display: 'inline-block', margin: '0px' }}>{item.icon}</span>
        ));
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
        
        // Reset the state to disable the button until values are changed again
        setIsSliderChanged(false);
        setIsConfidenceChanged(false);
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
    const sliderDirection = game.get("treatment").sliderDirection === "RabbitsSquirrels";
    return game.get("treatment").opinion === "slider" ? (
        <div>
            <div className="flex">
                <div className="flex flex-col items-center space-y-4">
                    <h2>What proportion of the population are rabbits?</h2>
                    <div className="flex items-center space-x-4">
                        <h2 className="text-gray-600 text-sm text-center mb-2">
                            {sliderDirection ? "All Rabbits 🐇" : "All Squirrels 🐿️"}
                        </h2>
                        <Slider
                            defaultValue={null}
                            aria-label="Default"
                            valueLabelDisplay="auto"
                            onChange={handleSlider}
                            value={sliderValue}
                            style={{ width: '200px' }}
                            track={false}
                        />
                        <h2 className="text-gray-600 text-sm text-center mb-2">
                            {sliderDirection ? "All Squirrels 🐿️" : "All Rabbits 🐇"}
                        </h2>
                    </div>
                </div>
                    <div style={{
                        marginLeft: '15px',
                        marginRight: '15px',
                        marginBottom: '15px',
                        textAlign: 'center',
                        width: '220px', // Container width
                        height: '180px', // Adjusted height
                        display: 'inline-block',
                        boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
                        borderRadius: '10px',
                        border: '1px solid #ccc',
                        overflow: 'hidden',
                    }}>
                        {renderIcons()}
                    </div>
                    <div>
                        <h2 className="text-center">How confident are you in your answer?</h2><br />
                        <div className="flex items-center space-x-4">
                            <h2 className="text-gray-600 text-sm text-center mb-2">Very Uncertain</h2>
                            <Slider
                                defaultValue={null}
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
                                    className={`bg-blue-500 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline ${
                                        (!isConfidenceChanged || !isSliderChanged) ? 'opacity-50 cursor-not-allowed' : 'hover:bg-blue-700'
                                    }`}
                                >
                                    Submit
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        ) : (
            <div>
                <h2 className="align-center text-gray-500 text-center" style={{ marginBottom: '20px' }}>
                    What proportion of the population are rabbits? Please enter your opinion and what convinced you to make this choice.
                </h2>
                <InputBox onNewMessage={handleNewOpinion} buttonPosition="below" buttonText="Submit" buttonStyles='w-auto h-auto py-2 px-4 text-base' />
            </div>
        );
    }
}

