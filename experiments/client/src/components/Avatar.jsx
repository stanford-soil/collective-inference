import React from "react";

export function Avatar({ className, style, player }) {
  const src = `https://api.dicebear.com/9.x/adventurer/svg?seed=${player.id}`;
  return (
    <img
      className={`avatar ${className}`}
      style={style}
      src={src}
    />
  )
}

