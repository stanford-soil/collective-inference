import { useGame } from "@empirica/core/player/classic/react";
import React, { useState } from "react";
import { Button } from "../components/Button";

export function Introduction({ next }) {
  const game = useGame();
  const { condition } = game.get("treatment");
  const [page, setPage] = useState(1);

  const goNextPage = () => setPage(page + 1);
  const goPreviousPage = () => setPage(page - 1);

  return (
    <div className="flex items-center justify-center w-screen h-screen">
      <div className="w-2/3 p-10 bg-white rounded-lg shadow-lg">
        <div className="mt-5 sm:mt-8 p-8">

          {page === 1 && (
            <>
              <h3 className="text-2xl font-medium text-gray-900 text-center mb-6">
                Overview
              </h3>
              <p className="text-sm text-red-700 text-center mb-4">
                <b>Please read the instructions carefully. There will be a quiz. You cannot continue to the game if you do not pass the quiz.</b>
              </p>
              <p className="text-sm text-gray-700 mb-6">
                In this game, you are part of a team of 4 players. You are all <b>neighbors</b> in the same area, using an app to talk to each other.
                Each individual message is only sent to and received by <b>one person</b>, but you will take turns communicating with multiple people. This is pictured in the diagram below, with each line being one conversation.
                {
                  condition === 'slider' ?
                    <b> Specifically, you will be communicating by changing a slider for someone else to see.</b> :
                    (condition === 'unidirectional' ?
                      <b> Specifically, instead of talking back and forth, you will be communicating by leaving a message for someone else to read.</b> :
                      <b> Specifically, you will be using a chat box to interactively communicate back-and-forth.</b>)
                }
              </p>
              <center><img width="500px" src="./network.png" alt="Network Diagram" /></center>
            </>
          )}

          {page === 2 && (
            <>
              <h3 className="text-2xl font-medium text-gray-900 text-center mb-6">
                Goal of the Game
              </h3>
              <p className="text-sm text-gray-700 mb-6">
                Your neighborhood has a lot of wildlife, particularly <b>rabbits</b> and <b>squirrels</b>. What everyone wants to know is - <b>are there more rabbits or squirrels in the neighborhood?</b>
                Unfortunately, you only know what's going on in your part of the neighborhood – how many critters you see outside your <b>window</b>.
                You will be looking outside once, then discussing what you saw.
                Everyone has a single window they're looking out of.
              </p>
              <center><img width="1000px" src="./first_window.png" alt="Window View" /></center>
              <p className="text-sm text-gray-700 mt-6">
                If you need to look out your window again, there will be a <b>peek outside</b> button in the following stages. This button is pictured below. The critters will <b>remain the same throughout the game </b> – they're busy chewing!
              </p>
              <center><img width="100px" src="./peek.png" alt="Peek Button" /></center>
            </>
          )}

          {page === 3 && (
            <>
              <h3 className="text-2xl font-medium text-gray-900 text-center mb-6">
                Interface
              </h3>
              <p className="text-sm text-gray-700 mb-6">
                {
                  condition !== 'slider' ? (
                    <>
                      You're going to share what you think with your neighbor using the <b>messaging app</b>.
                      <center><img width="300px" src="./interaction.png" alt="Interaction Example" /></center>
                      In the following stage, you will make a judgment of the ratio of rabbits to squirrels using the <b>slider</b>.
                      This slider is <b>only seen by researchers</b> – it’s not shared with your neighbors!
                      We want to know your <b>estimate</b> of the critters’ ratio in the neighborhood, <b>based on your observations and your neighbors' opinions.</b> You cannot submit your answer without also filling in your confidence!
                    </>
                  ) : (
                    <>
                      You're going to share what you think with your neighbor using the <b>slider</b>.
                      Following this, you will see someone else's slider output, and will be asked to submit another opinion. <br /> You cannot submit your answer without also filling in your confidence!
                    </>
                  )
                }
              </p>
              <center><img width="1000px" src="./slider.png" alt="Slider Example" /></center>
            </>
          )}

          {page === 4 && (
            <>
              <p className="text-sm text-gray-700 mb-6">
                This process will repeat several times as you continue sharing your estimation of rabbits and squirrels with your neighbors.
                {
                  condition !== 'slider' && (
                    <p>You can be informative or uninformative, sharing as much or as little as you like, with a caveat!</p>
                  )
                }
                <b>If all players are correct</b> about the critter ratio at the end, you will receive a bonus.
                <b> The base pay for this experiment is $15/hr.</b>
              </p>
              <p className="text-sm text-gray-700">
                On the next page, you’ll take a quiz to test your knowledge of the UI and game!
              </p>
            </>
          )}

          <div className="flex justify-between mt-8">
            {page > 1 && (
              <Button handleClick={goPreviousPage}>Back</Button>
            )}
            {page < 4 ? (
              <Button handleClick={goNextPage} className="ml-auto">Next</Button>
            ) : (
              <Button handleClick={next} className="ml-auto">Next</Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

