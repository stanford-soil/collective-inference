import { usePlayer } from "@empirica/core/player/classic/react";
import React, { useState } from "react";
import { Button } from "../components/Button";

export function ExitSurveyMinimal({ next }) {
  const player = usePlayer();
  const [usedCalculator, setUsedCalculator] = useState("");

  function handleSubmit(event) {
    event.preventDefault();
    player.set("exitSurvey", { usedCalculator });
    next();
  }

  return (
    <div className="py-8 max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
      <form className="mt-12 space-y-8" onSubmit={handleSubmit}>
        <h3 className="text-lg leading-6 font-medium text-gray-900">Exit Survey</h3>
        <p className="mt-1 text-sm text-gray-500">
          Did you use a calculator during the game?
        </p>
        
        <div className="flex items-center space-x-4 mt-4">
          <label>
            <input
              type="radio"
              name="calculator"
              value="yes"
              checked={usedCalculator === "yes"}
              onChange={() => setUsedCalculator("yes")}
              className="mr-2"
            />
            Yes
          </label>
          <label>
            <input
              type="radio"
              name="calculator"
              value="no"
              checked={usedCalculator === "no"}
              onChange={() => setUsedCalculator("no")}
              className="mr-2"
            />
            No
          </label>
        </div>

        <div className="mt-8">
          <Button type="submit">Submit</Button>
        </div>
      </form>
    </div>
  );
}

