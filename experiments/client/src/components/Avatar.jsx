import React from "react";

export function Avatar({ className, style, src }) {
  return (
    <img
      className={`avatar ${className}`}
      style={style}
      src={src}
    />
  )
}
