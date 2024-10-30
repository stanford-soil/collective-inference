import React, { useState } from "react";
import { Button } from "../components/Button";
import { Sorry } from "./Sorry.jsx";

export function AttentionQuiz({ next }) {
  const [answer, setAnswer] = useState("");
  const [charCount, setCharCount] = useState(0);
  const [showSorry, setShowSorry] = useState(false);

  const handleAnswerChange = (event) => {
    const input = event.target.value;
    setAnswer(input);
    setCharCount(input.length);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    if (charCount < 100) {
      setShowSorry(true);
      return;
    }
    alert("Thank you! Proceeding to consent form.");
    next();
  };

  if (showSorry) {
    return <Sorry />;
  }

  return (
    <div className="flex items-center justify-center w-screen" style={{ margin: "50px" }}>
      <div className="w-1/2">
        <h3 className="text-lg leading-6 text-gray-900">
          <center>Comprehension Quiz</center>
        </h3>
        <br />
        <form onSubmit={handleSubmit}>
          <div>
            <h2><b>Describe the main objective of this game in your own words. Participants who submit less than 100 characters will be booted.</b></h2>
            <br />
            <textarea
              className="w-full h-24 mt-2 mb-2"
              value={answer}
              onChange={handleAnswerChange}
              placeholder="Please write at least 100 characters."
            />
            <p>Character count: {charCount}</p>
          </div>
          <br />
          <Button handleClick={handleSubmit}>Submit</Button>
        </form>
      </div>
    </div>
  );
}
