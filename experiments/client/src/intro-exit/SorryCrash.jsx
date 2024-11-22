import React from "react";
import { Alert } from "../components/Alert";

export function SorryCrash() {
  return (
    <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh", textAlign: "center" }}>
      <p>
        <br /> <br />
        Sorry, it seems the game has crashed or been cancelled! Unfortunately, we do not re-run players, but please submit the following code to receive your compensation:{" "}
        <strong>CYEDW6HZ</strong>.
      </p>
    </div>
  );
}

