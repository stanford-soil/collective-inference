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
    }
    
    const handleSubmit = () => {
        player.stage.set("guess", sliderValue);
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

    //return opinion input based on treatment
    return(
        <div> {game.get("treatment")["opinion"] === "slider" ? (
            <div>
                <h2 className="text-center mb-5">What proportion of the population are rabbits?</h2><br/>
                <p className="text-gray-600 text-sm text-center mb-2">
                    The stage will advance when all players click submit
                </p>
                <div className = "flex items-center space-x-4">
                    <Slider
                        defaultValue={50}
                        aria-label="Default"
                        valueLabelDisplay="auto"
                        onChange={handleSlider}
                        value={sliderValue}
                        className = "flex-grow"
                    />
                    <button
                        onClick={handleSubmit}
                        disabled={!isSliderChanged}
                        className={`bg-blue-500 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline
                                   ${!isSliderChanged ? 'opacity-50 cursor-not-allowed hover:bg-blue-500' : 'hover:bg-blue-700'}`}
                    >
                        Submit
                    </button>
                </div>
            </div>
        ) : (
            <div>
                <h2 className="align-center text-gray-500 text-center" style={{ marginBottom: '20px' }}>What proportion of the population are rabbits? Please enter your opinion and what convinced you to make this choice.</h2>
                <InputBox onNewMessage ={handleNewMessage} buttonPosition="below" buttonText="Submit" buttonStyles='w-auto h-auto py-2 px-4 text-base'/>
            </div>
        )}
        </div>
    )
}
