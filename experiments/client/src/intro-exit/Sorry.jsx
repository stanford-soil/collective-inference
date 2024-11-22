import React from "react";
import { Alert } from "../components/Alert";

export function Sorry() {
  return (
    <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh", textAlign: "center" }}>
      <p>
        <br />
        <br />
        Sorry, you did not pass our attention check! Please return this experiment. Unfortunately, we do not re-run players.
      </p>
    </div>
  );
}

