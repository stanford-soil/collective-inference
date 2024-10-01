import React from "react";


export function Avatar({ className, player, style }) {


  const src = `https://api.dicebear.com/9.x/adventurer/svg?seed=${player.id}`;

  return (
    <img
      className={`avatar ${className}`}
      style={style}
      src={src}
      alt="Player Avatar"
    />
  );
}

