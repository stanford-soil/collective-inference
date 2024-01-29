import React from "react";
import { Button } from "../components/Button";

export function Introduction({ next }) {

  return (
     <div className="flex items-center justify-center w-screen"><div className="w-1/2">
    <div className="mt-3 sm:mt-5 p-20">
      <h3 className="text-lg leading-6 font-medium text-gray-900">
        Overview
      </h3> <br/>
      <div className="mt-2 mb-6">
        <p className="text-sm text-gray-700">
       <b> Please read the instructions carefully. There will be a quiz. You cannot continue to the game if you do not pass the quiz.</b> <br/>
        <br/>        
          In this game, you are part of a team of 6-8 players. You are all <b>neighbors </b>in the same area, using a semi-anonymous messaging app to talk to each other. 
          While each individual message is only sent to and received by one person, everyone is talking to multiple people. At the current stage of this experiment, you are not exchanging messages, but <b>leaving a message for someone else to read.</b><br />
          <br/>Picture it like this, with each line being an interaction:

          <div className="network" style={{ margin: "20px" }}>
            <center><img width="500px" src="./network.png" /></center>
          </div>
          <br />
        </p>
        </div> 

        <h3 className="text-lg leading-6 font-medium text-gray-900">
            Goal of the Game
          </h3> <br/>
                     <div className="mt-2 mb-6">

        <p className="text-sm text-gray-700">
          Your neighborhood has quite a lot of wildlife, particularly <b>rabbits</b> and <b>squirrels</b>. <br /><br/>
          What everyone wants to know is - <b>are there more rabbits or squirrels in the neighborhood?</b> <br/><br/>
          
         However, you only know what's going on in your part of the neighborhood - how many critters you see outside your <b>window</b>. <br />
 </p>
        </div> <br/>
         <h3 className="text-lg leading-6 font-medium text-gray-900">
            Interface
         </h3>
         <div className="mt-2 mb-6">
	     <p className="text-sm text-gray-700">
		 <br/>
		 Everyone on the team has a single  <b>window</b> they're looking out of, which you can see on the left of the image below.
		 You will only be seeing <b>one set of critters</b> that will stay the same throughout the entire study.
		 A new "round" (typing a message to a new neighbor) does not signal a new day or new animals. 
		 <br/>
		 <div className="window" style={{ margin: "20px" }}>
		     <center><img width="700px" src="./interaction.png" /></center>
		 </div>

		 You're going to share what you think with your neighbor using the <b>messaging app</b>, seen to the right of the image.<br/> <br/>

		 Following this, you will read someone else's thoughts and make a judgment of the ratio of rabbits to squirrels using the <b>slider</b>. <br/> <br/> 
		 The <b>slider</b> measures the proportion of the population as a percentage <b> of rabbits</b>.
		 So if you think the population is half (or 50%) rabbits, you would put the slider in the middle.
		 If you think it's all squirrels (0% rabbits) you would put it at the leftmost end. 
		 <br/>
		 <div className="slider" style={{ margin: "20px" }}>
		     <center><img width="300px" src="./slider.png" /></center>
		 </div>
								    This process will repeat several times as you continue sharing with your neighbors how many rabbits and squirrels you think there are. 

           <br/> <br/>You can be informative or uninformative, sharing as much or as little information as you like, with a caveat!<br/>
          <br/><b>If, by the end of the game, all of you are in agreement as to the ratio of critters, you will receive a bonus. The base pay for this experiment is 15$/hr. </b>
          On the next page is a quiz to test your knowledge of the UI and game!
        </p> 
      </div>
      <Button handleClick={next}>
        Next
      </Button>
    </div> </div> </div>
  );
}
