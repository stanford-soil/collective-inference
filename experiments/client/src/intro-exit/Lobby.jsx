import React, { useState } from 'react';

const Lobby = ({next, players }) => {
    const [readyPlayers, setReadyPlayers] = useState([]);

    const handlePlayerReady = (playerId) => {
        setReadyPlayers((prevReadyPlayers) => [...prevReadyPlayers, playerId]);
    };

    if (readyPlayers.length === players.length) {
        next();
    }

    return (
        <div>
            <h1>Waiting Lobby</h1>
            <p>Players: {players.length}</p>
            <p>Ready Players: {readyPlayers.length}</p>
        </div>
    );
};

export default Lobby;
