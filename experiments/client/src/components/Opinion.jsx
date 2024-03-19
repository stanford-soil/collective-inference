import React from "react";
import {InputBox} from "./InputBox";
import {usePlayer, useRound, useGame } from "@empirica/core/player/classic/react";
import { Slider } from '@mui/material';
import { useState } from "react";

export function Opinion({ scope, attribute}){
    const round = useRound();
    const player = usePlayer();
    const game = useGame();

    const [sliderValue, setSliderValue] = useState(50);
    const [isSliderChanged, setIsSliderChanged] = useState(false); //track if slider has changed for submit
    const [confidenceValue, setConfidenceValue] = useState(50);
    const [isConfidenceChanged, setIsConfidenceChanged] = useState(false);

    //method for input box sends data of user's opinion to Empirica's mongoDB
    const handleNewMessage = (text) => {
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

    const handleSlider = (event, value) => {
        setSliderValue(value);
        setIsSliderChanged(true);
    };

      const handleConfidence = (event, value) => {
        setConfidenceValue(value);
        setIsConfidenceChanged(true);
    };
    
    const handleSubmit = () => {
        player.stage.set("guess", sliderValue);
        player.stage.set("confidence", confidenceValue);
        if(game.get("treatment")["condition"] === "slider") {
            scope.append(attribute, {
                text: "I think the population is " + sliderValue + "% rabbits",
                time: Date.now(),
                recipient: player.get('recipient'),
                round: round.get('idx') + 1,
                sender: {
                    id: player.id,
                    name: player.get("name") || player.id,
                    avatar: player.get("avatar"),
                },
            });
        }
        player.stage.set("submit", true);
    };

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

    // Reorder icons based on Fibonacci sequence so that there's visual consistency :)
    const reorderedIcons = [];
    let fib1 = 1, fib2 = 1;
    for (let i = icons.length - 1; i >= 0; i--) {
        const index = (fib1 - 1) % icons.length;
        reorderedIcons[index] = icons[i];
        const temp = fib1 + fib2;
        fib1 = fib2;
        fib2 = temp;
    }

    return reorderedIcons;
};

    //return opinion input based on treatment
return (
        <div>
            {game.get("treatment").opinion === "slider" ? (
                <div>
                    <h2 className="text-center">What proportion of the population are rabbits?</h2><br />
                    <div className="flex items-center flex-col space-y-4">
                        <div className="flex items-center space-x-4">
                            <h2 className="text-gray-600 text-sm text-center mb-2">All Squirrels<br />🐿️</h2>
                            <Slider
                                defaultValue={50}
                                aria-label="Default"
                                valueLabelDisplay="off"
                                onChange={handleSlider}
                                value={sliderValue}
                                style={{ width: '300px' }}
                                track={false}
                            />
                            <h2 className="text-gray-600 text-sm text-center mb-2">All Rabbits <br />🐇</h2>
                        </div>
                    </div>
                         <div style={{ marginTop: '20px', textAlign: 'center', width: '300px', height: '300px', display: 'grid', gridTemplateColumns: 'repeat(10, 1fr)', gridTemplateRows: 'repeat(10, 1fr)' }}>
                {renderIcons()}
            </div>
                    <div>
                        <h2 className="text-center">How confident are you in your answer?</h2><br />
                        <div className="flex items-center flex-col space-y-4">
                            <div className="flex items-center space-x-4">
                                <h2 className="text-gray-600 text-sm text-center mb-2">Very Uncertain</h2>
                                <Slider
                                    defaultValue={50}
                                    aria-label="Default"
                                    valueLabelDisplay="off"
                                    onChange={handleConfidence}
                                    value={confidenceValue}
                                    style={{ width: '300px' }}

                                />
                                <h2 className="text-gray-600 text-sm text-center mb-2">Fully Certain</h2>
                            </div>
                        </div>
                    </div>
                    <button
                        onClick={handleSubmit}
                        disabled={!isConfidenceChanged}
                        className={`bg-blue-500 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline
                        ${!isConfidenceChanged ? 'opacity-50 cursor-not-allowed hover:bg-blue-500' : 'hover:bg-blue-700'}`}
                    >
                        Submit
                    </button>
                </div>
            ) : (
                <div>
                    <h2 className="align-center text-gray-500 text-center" style={{ marginBottom: '20px' }}>What proportion of the population are rabbits? Please enter your opinion and what convinced you to make this choice.</h2>
                    <InputBox onNewMessage={handleNewMessage} buttonPosition="below" buttonText="Submit" buttonStyles='w-auto h-auto py-2 px-4 text-base' />
                </div>
            )}
        </div>
    );
}
